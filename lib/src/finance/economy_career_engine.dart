import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import '../player/player_career_engine.dart';
import 'basic_economy_engine.dart';
import 'club_finance_state.dart';
import 'economy_career_report.dart';
import 'economy_career_season.dart';

class EconomyCareerEngine {
  const EconomyCareerEngine({
    this.playerCareerEngine = const PlayerCareerEngine(),
    this.economyEngine = const BasicEconomyEngine(),
  });

  final PlayerCareerEngine playerCareerEngine;
  final BasicEconomyEngine economyEngine;

  EconomyCareerReport simulate({
    required List<Club> clubs,
    required SimulationConfig config,
    int seasonCount = 20,
    GameDate startDate = const GameDate(2026, 7, 1),
  }) {
    final playerCareer = playerCareerEngine.simulate(
      clubs: clubs,
      config: config,
      seasonCount: seasonCount,
      startDate: startDate,
    );

    final initialStates = economyEngine.initialStates(
      clubs: clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    var currentStates = List<ClubFinanceState>.of(
      initialStates,
      growable: false,
    );
    final financeSeasons = <EconomyCareerSeason>[];

    for (var i = 0; i < playerCareer.seasons.length; i++) {
      final playerSeason = playerCareer.seasons[i];
      final financeResults = economyEngine.simulateSeason(
        clubs: playerSeason.clubs,
        players: playerSeason.players,
        seasonReport: playerSeason.report,
        openingStates: currentStates,
      );
      financeSeasons.add(
        EconomyCareerSeason(
          seasonIndex: playerSeason.report.seasonIndex,
          clubs: financeResults,
        ),
      );
      currentStates = financeResults
          .map(
            (club) => ClubFinanceState(
              clubId: club.clubId,
              cash: club.closingCash,
              debt: club.closingDebt,
            ),
          )
          .toList(growable: false);
    }

    return EconomyCareerReport(
      playerCareer: playerCareer,
      initialStates: initialStates,
      seasons: financeSeasons,
      finalStates: currentStates,
    );
  }
}
