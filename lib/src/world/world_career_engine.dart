import '../core/simulation_config.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../player/player_pool_generator.dart';
import '../player/team_strength_calculator.dart';
import '../season/season_engine.dart';
import '../transfer/transfer_deal.dart';
import '../transfer/transfer_market_engine.dart';
import 'league_tier.dart';
import 'world_career_report.dart';
import 'world_career_season.dart';
import 'world_league.dart';

class WorldCareerEngine {
  const WorldCareerEngine({
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

  WorldCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount', 'Must be positive.');
    }
    _validateSetup(clubs, leagues);

    final baseClubs = List<Club>.unmodifiable(clubs);
    final initialLeagues = _sortedLeagues(leagues);
    var currentLeagues = initialLeagues;
    var currentPlayers = poolGenerator.generate(
      clubs: baseClubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final initialPlayerCount = currentPlayers.length;
    final initialFinanceStates = _initialFinanceStates(
      clubs: baseClubs,
      leagues: currentLeagues,
      config: config,
    );
    var currentFinanceStates = initialFinanceStates;
    final seasons = <WorldCareerSeason>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final seasonIndex = config.seasonIndex + offset;
      final leaguesBeforeSeason = currentLeagues;
      final seasonPlayers = List<Player>.unmodifiable(currentPlayers);
      final currentClubs = strengthCalculator.deriveClubs(
        baseClubs: baseClubs,
        players: seasonPlayers,
      );
      final clubById = {for (final club in currentClubs) club.id: club};
      final financeById = {
        for (final state in currentFinanceStates) state.clubId: state,
      };
      final leagueResults = <LeagueSeasonSnapshot>[];
      final financeResults = <ClubFinanceSeason>[];

      for (final league in leaguesBeforeSeason) {
        final leagueClubs = league.clubIds
            .map((clubId) => clubById[clubId]!)
            .toList(growable: false);
        final leagueClubIds = league.clubIds.toSet();
        final leaguePlayers = seasonPlayers
            .where((player) => leagueClubIds.contains(player.clubId))
            .toList(growable: false);
        final openingStates = league.clubIds
            .map((clubId) => financeById[clubId]!)
            .toList(growable: false);
        final report = seasonEngine.simulate(
          clubs: leagueClubs,
          config: config.copyWith(seasonIndex: seasonIndex),
        );
        leagueResults.add(
          LeagueSeasonSnapshot(tier: league.tier, report: report),
        );
        financeResults.addAll(
          economyEngine.simulateSeason(
            clubs: leagueClubs,
            players: leaguePlayers,
            seasonReport: report,
            openingStates: openingStates,
            economicScaleBps: league.tier.economicScaleBps,
            costScaleBps: league.tier.costScaleBps,
          ),
        );
      }

      financeResults.sort((a, b) => a.clubId.compareTo(b.clubId));
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
      List<TransferDeal> transfersAfterSeason = const [];
      List<LeagueMovement> movementsAfterSeason = const [];
      var financeStatesAfterWindow = closingFinanceStates;
      var leaguesAfterTransition = leaguesBeforeSeason;

      if (offset < seasonCount - 1) {
        final transition = _promoteAndRelegate(
          currentLeagues: leaguesBeforeSeason,
          leagueResults: leagueResults,
        );
        movementsAfterSeason = transition.movements;
        leaguesAfterTransition = transition.leagues;

        final lifecycle = lifecycleEngine.advance(
          currentPlayers: seasonPlayers,
          currentClubs: currentClubs,
          referenceClubs: baseClubs,
          careerSeed: config.careerSeed,
          nextSeasonIndex: seasonIndex + 1,
          simulationVersion: config.simulationVersion,
        );
        retiredAfterSeason = lifecycle.retiredPlayers;
        youthIntakeAfterSeason = lifecycle.youthIntake;

        final postLifecycleClubs = strengthCalculator.deriveClubs(
          baseClubs: baseClubs,
          players: lifecycle.activePlayers,
        );
        final market = transferMarketEngine.simulateWindow(
          clubs: postLifecycleClubs,
          players: lifecycle.activePlayers,
          financeStates: closingFinanceStates,
          careerSeed: config.careerSeed,
          seasonIndex: seasonIndex,
          simulationVersion: config.simulationVersion,
        );
        currentPlayers = market.players;
        currentFinanceStates = market.financeStates;
        financeStatesAfterWindow = market.financeStates;
        transfersAfterSeason = market.deals;
        currentLeagues = leaguesAfterTransition;
      } else {
        currentFinanceStates = closingFinanceStates;
      }

      seasons.add(
        WorldCareerSeason(
          seasonIndex: seasonIndex,
          leaguesBeforeSeason: leaguesBeforeSeason,
          clubs: currentClubs,
          players: seasonPlayers,
          leagueResults: leagueResults,
          finances: financeResults,
          retiredAfterSeason: retiredAfterSeason,
          youthIntakeAfterSeason: youthIntakeAfterSeason,
          transfersAfterSeason: transfersAfterSeason,
          financeStatesAfterWindow: financeStatesAfterWindow,
          movementsAfterSeason: movementsAfterSeason,
          leaguesAfterTransition: leaguesAfterTransition,
        ),
      );
    }

    final finalClubs = strengthCalculator.deriveClubs(
      baseClubs: baseClubs,
      players: currentPlayers,
    );

    return WorldCareerReport(
      careerSeed: config.careerSeed,
      initialPlayerCount: initialPlayerCount,
      initialFinanceStates: initialFinanceStates,
      initialLeagues: initialLeagues,
      seasons: List.unmodifiable(seasons),
      finalPlayers: List.unmodifiable(currentPlayers),
      finalFinanceStates: List.unmodifiable(currentFinanceStates),
      finalClubs: List.unmodifiable(finalClubs),
      finalLeagues: List.unmodifiable(currentLeagues),
    );
  }

  List<ClubFinanceState> _initialFinanceStates({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
  }) {
    final byId = {for (final club in clubs) club.id: club};
    final states = <ClubFinanceState>[];
    for (final league in leagues) {
      final leagueClubs = league.clubIds
          .map((clubId) => byId[clubId]!)
          .toList(growable: false);
      states.addAll(
        economyEngine.initialStates(
          clubs: leagueClubs,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
          economicScaleBps: league.tier.economicScaleBps,
        ),
      );
    }
    states.sort((a, b) => a.clubId.compareTo(b.clubId));
    return List.unmodifiable(states);
  }

  _LeagueTransition _promoteAndRelegate({
    required List<WorldLeague> currentLeagues,
    required List<LeagueSeasonSnapshot> leagueResults,
  }) {
    final leagueByTier = {
      for (final league in currentLeagues) league.tier: league,
    };
    final reportByTier = {
      for (final result in leagueResults) result.tier: result.report,
    };
    final first = leagueByTier[LeagueTier.first]!;
    final second = leagueByTier[LeagueTier.second]!;
    final third = leagueByTier[LeagueTier.third]!;
    final firstReport = reportByTier[LeagueTier.first]!;
    final secondReport = reportByTier[LeagueTier.second]!;
    final thirdReport = reportByTier[LeagueTier.third]!;

    const slots = 3;
    final relegatedFromFirst = firstReport.table
        .skip(firstReport.table.length - slots)
        .map((row) => row.clubId)
        .toList(growable: false);
    final promotedFromSecond = secondReport.table
        .take(slots)
        .map((row) => row.clubId)
        .toList(growable: false);
    final relegatedFromSecond = secondReport.table
        .skip(secondReport.table.length - slots)
        .map((row) => row.clubId)
        .toList(growable: false);
    final promotedFromThird = thirdReport.table
        .take(slots)
        .map((row) => row.clubId)
        .toList(growable: false);

    final firstIds = first.clubIds.toSet()
      ..removeAll(relegatedFromFirst)
      ..addAll(promotedFromSecond);
    final secondIds = second.clubIds.toSet()
      ..removeAll(promotedFromSecond)
      ..removeAll(relegatedFromSecond)
      ..addAll(relegatedFromFirst)
      ..addAll(promotedFromThird);
    final thirdIds = third.clubIds.toSet()
      ..removeAll(promotedFromThird)
      ..addAll(relegatedFromSecond);

    final nextLeagues = [
      WorldLeague(
        tier: LeagueTier.first,
        clubIds: firstIds.toList()..sort(),
      ),
      WorldLeague(
        tier: LeagueTier.second,
        clubIds: secondIds.toList()..sort(),
      ),
      WorldLeague(
        tier: LeagueTier.third,
        clubIds: thirdIds.toList()..sort(),
      ),
    ];
    final movements = <LeagueMovement>[
      ...promotedFromSecond.map(
        (clubId) => LeagueMovement(
          clubId: clubId,
          from: LeagueTier.second,
          to: LeagueTier.first,
        ),
      ),
      ...relegatedFromFirst.map(
        (clubId) => LeagueMovement(
          clubId: clubId,
          from: LeagueTier.first,
          to: LeagueTier.second,
        ),
      ),
      ...promotedFromThird.map(
        (clubId) => LeagueMovement(
          clubId: clubId,
          from: LeagueTier.third,
          to: LeagueTier.second,
        ),
      ),
      ...relegatedFromSecond.map(
        (clubId) => LeagueMovement(
          clubId: clubId,
          from: LeagueTier.second,
          to: LeagueTier.third,
        ),
      ),
    ];
    return _LeagueTransition(
      leagues: List.unmodifiable(nextLeagues),
      movements: List.unmodifiable(movements),
    );
  }

  List<WorldLeague> _sortedLeagues(List<WorldLeague> leagues) {
    final sorted = List<WorldLeague>.of(leagues)
      ..sort((a, b) => a.tier.level.compareTo(b.tier.level));
    return List.unmodifiable(sorted);
  }

  void _validateSetup(List<Club> clubs, List<WorldLeague> leagues) {
    if (clubs.length != 48) {
      throw ArgumentError('M5 world requires exactly 48 clubs.');
    }
    if (clubs.map((club) => club.id).toSet().length != clubs.length) {
      throw ArgumentError('Club IDs must be unique.');
    }
    if (leagues.length != LeagueTier.values.length) {
      throw ArgumentError('M5 world requires exactly 3 leagues.');
    }
    final tiers = leagues.map((league) => league.tier).toSet();
    if (tiers.length != LeagueTier.values.length ||
        !tiers.containsAll(LeagueTier.values)) {
      throw ArgumentError('Every league tier must be present exactly once.');
    }
    final membership = <String>[];
    for (final league in leagues) {
      if (league.clubIds.length != 16) {
        throw ArgumentError('${league.name} must contain exactly 16 clubs.');
      }
      membership.addAll(league.clubIds);
    }
    final clubIds = clubs.map((club) => club.id).toSet();
    if (membership.toSet().length != 48 ||
        !clubIds.containsAll(membership) ||
        !membership.toSet().containsAll(clubIds)) {
      throw ArgumentError('League membership must contain every club once.');
    }
  }
}

class _LeagueTransition {
  const _LeagueTransition({
    required this.leagues,
    required this.movements,
  });

  final List<WorldLeague> leagues;
  final List<LeagueMovement> movements;
}
