import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../player/player_pool_generator.dart';
import '../player/team_strength_calculator.dart';
import '../season/season_engine.dart';
import 'transfer_career_report.dart';
import 'transfer_career_season.dart';
import 'transfer_market_engine.dart';

class TransferCareerEngine {
  const TransferCareerEngine({
    this.seasonEngine = const SeasonEngine(),
    this.poolGenerator = const PlayerPoolGenerator(),
    this.lifecycleEngine = const PlayerLifecycleEngine(),
    this.strengthCalculator = const TeamStrengthCalculator(),
    this.economyEngine = const BasicEconomyEngine(),
    this.transferMarketEngine = const TransferMarketEngine(),
  });

  final SeasonEngine seasonEngine;
  final PlayerPoolGenerator poolGenerator;
  final PlayerLifecycleEngine lifecycleEngine;
  final TeamStrengthCalculator strengthCalculator;
  final BasicEconomyEngine economyEngine;
  final TransferMarketEngine transferMarketEngine;

  TransferCareerReport simulate({
    required List<Club> clubs,
    required SimulationConfig config,
    int seasonCount = 20,
    GameDate startDate = const GameDate(2026, 7, 1),
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount', 'Must be positive.');
    }

    var currentPlayers = poolGenerator.generate(
      clubs: clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final initialPlayerCount = currentPlayers.length;
    final initialFinanceStates = economyEngine.initialStates(
      clubs: clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    var currentFinanceStates = List<ClubFinanceState>.of(
      initialFinanceStates,
      growable: false,
    );
    final seasons = <TransferCareerSeason>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final seasonIndex = config.seasonIndex + offset;
      final currentClubs = strengthCalculator.deriveClubs(
        baseClubs: clubs,
        players: currentPlayers,
      );
      final seasonReport = seasonEngine.simulate(
        clubs: currentClubs,
        config: config.copyWith(seasonIndex: seasonIndex),
      );
      final financeResults = economyEngine.simulateSeason(
        clubs: currentClubs,
        players: currentPlayers,
        seasonReport: seasonReport,
        openingStates: currentFinanceStates,
      );
      final closingFinanceStates = financeResults
          .map(
            (finance) => ClubFinanceState(
              clubId: finance.clubId,
              cash: finance.closingCash,
              debt: finance.closingDebt,
            ),
          )
          .toList(growable: false);

      List<Player> retiredAfterSeason = const [];
      List<Player> youthIntakeAfterSeason = const [];
      var transfersAfterSeason = const <dynamic>[];
      var financeStatesAfterWindow = closingFinanceStates;

      if (offset < seasonCount - 1) {
        final transition = lifecycleEngine.advance(
          currentPlayers: currentPlayers,
          currentClubs: currentClubs,
          referenceClubs: clubs,
          careerSeed: config.careerSeed,
          nextSeasonIndex: seasonIndex + 1,
          simulationVersion: config.simulationVersion,
        );
        retiredAfterSeason = transition.retiredPlayers;
        youthIntakeAfterSeason = transition.youthIntake;

        final postLifecycleClubs = strengthCalculator.deriveClubs(
          baseClubs: clubs,
          players: transition.activePlayers,
        );
        final market = transferMarketEngine.simulateWindow(
          clubs: postLifecycleClubs,
          players: transition.activePlayers,
          financeStates: closingFinanceStates,
          careerSeed: config.careerSeed,
          seasonIndex: seasonIndex,
          simulationVersion: config.simulationVersion,
        );
        currentPlayers = market.players;
        currentFinanceStates = market.financeStates;
        financeStatesAfterWindow = market.financeStates;
        transfersAfterSeason = market.deals;
      } else {
        currentFinanceStates = closingFinanceStates;
      }

      seasons.add(
        TransferCareerSeason(
          seasonIndex: seasonIndex,
          clubs: currentClubs,
          players: offset < seasonCount - 1
              ? _seasonPlayersBeforeTransition(
                  currentPlayers: currentPlayers,
                  originalSeasonPlayers: null,
                )
              : currentPlayers,
          report: seasonReport,
          finances: financeResults,
          retiredAfterSeason: retiredAfterSeason,
          youthIntakeAfterSeason: youthIntakeAfterSeason,
          transfersAfterSeason: transfersAfterSeason.cast(),
          financeStatesAfterWindow: financeStatesAfterWindow,
        ),
      );
    }

    final finalClubs = strengthCalculator.deriveClubs(
      baseClubs: clubs,
      players: currentPlayers,
    );

    return TransferCareerReport(
      careerSeed: config.careerSeed,
      initialPlayerCount: initialPlayerCount,
      initialFinanceStates: initialFinanceStates,
      seasons: seasons,
      finalPlayers: currentPlayers,
      finalFinanceStates: currentFinanceStates,
      finalClubs: finalClubs,
    );
  }

  List<Player> _seasonPlayersBeforeTransition({
    required List<Player> currentPlayers,
    required List<Player>? originalSeasonPlayers,
  }) => originalSeasonPlayers ?? currentPlayers;
}
