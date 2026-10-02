import '../core/simulation_config.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../player/player_pool_generator.dart';
import '../player/team_strength_calculator.dart';
import '../season/season_engine.dart';
import '../transfer/transfer_deal.dart';
import '../transfer/transfer_market_engine.dart';
import 'league_tier.dart';
import 'world_career_hooks.dart';
import 'world_career_report.dart';
import 'world_career_season.dart';
import 'world_career_simulation_result.dart';
import 'world_checkpoint.dart';
import 'world_finance_hooks.dart';
import 'world_league.dart';
import 'world_league_movement_projection.dart';
import 'world_opening_state_initializer.dart';
import 'world_offseason_projection.dart';
import 'world_roster_hooks.dart';
import 'world_transfer_hooks.dart';

enum PreparedExecutionState { prepared, moved, executing, completed, failed }

/// Evidence only: it deliberately exposes neither hooks nor an execution lease.
final class PreparedWorldOpening {
  PreparedWorldOpening._({
    required this.config,
    required this.seasonIndex,
    required this.players,
    required this.squadClubs,
    required this.effectiveClubs,
    required this.financeStates,
    required this.leagues,
  });
  final SimulationConfig config;
  final int seasonIndex;
  final List<Player> players;
  final List<Club> squadClubs, effectiveClubs;
  final List<ClubFinanceState> financeStates;
  final List<WorldLeague> leagues;
}

/// A single-owner, runtime-only lease over a genuinely prepared world run.
final class PreparedWorldExecution {
  PreparedWorldExecution._(this._engine, this.owner, this.revision,
      this.provenance, this._graph, this.opening, this.executionIdentity);
  final WorldCareerEngine _engine;
  final Object owner, revision, provenance, executionIdentity;
  final _PreparedWorldGraph _graph;
  final PreparedWorldOpening opening;
  PreparedExecutionState _state = PreparedExecutionState.prepared;
  PreparedExecutionState get state => _state;

  void _check(Object expectedOwner, Object expectedRevision,
      Object expectedProvenance) {
    if (_state != PreparedExecutionState.prepared ||
        !identical(owner, expectedOwner) ||
        !identical(revision, expectedRevision) ||
        !identical(provenance, expectedProvenance)) {
      throw StateError('Foreign, stale or consumed prepared world lease.');
    }
  }

  PreparedWorldExecution move(
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    _check(expectedOwner, expectedRevision, expectedProvenance);
    final successor = PreparedWorldExecution._(_engine, owner, revision,
        provenance, _graph, opening, executionIdentity);
    _state = PreparedExecutionState.moved;
    return successor;
  }
}

final class _PreparedWorldGraph {
  _PreparedWorldGraph(
      this.baseClubs,
      this.leagues,
      this.players,
      this.finance,
      this.config,
      this.completedBefore,
      this.seasonCount,
      this.advanceAfterFinalSeason,
      this.hooks,
      this.rosterHooks,
      this.financeHooks,
      this.transferHooks,
      this.enableTransferInstallments);
  final List<Club> baseClubs;
  final List<WorldLeague> leagues;
  final List<Player> players;
  final List<ClubFinanceState> finance;
  final SimulationConfig config;
  final int completedBefore, seasonCount;
  final bool advanceAfterFinalSeason, enableTransferInstallments;
  final WorldCareerHooks hooks;
  final WorldRosterHooks rosterHooks;
  final WorldFinanceHooks financeHooks;
  final WorldTransferHooks transferHooks;
}

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

  PreparedWorldExecution prepareInitial({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required Object owner,
    required Object revision,
    required Object provenance,
    int seasonCount = 1,
    bool advanceAfterFinalSeason = true,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
    WorldRosterHooks rosterHooks = const NoopWorldRosterHooks(),
    WorldFinanceHooks financeHooks = const NoopWorldFinanceHooks(),
    WorldTransferHooks transferHooks = const NoopWorldTransferHooks(),
    bool enableTransferInstallments = false,
  }) {
    _validateSeasonCount(seasonCount);
    _validateSetup(clubs, leagues);
    final opening = WorldOpeningStateInitializer(
            poolGenerator: poolGenerator, economyEngine: economyEngine)
        .prepare(clubs: clubs, leagues: leagues, config: config);
    return _prepareRun(
        _PreparedWorldGraph(
            opening.baseClubs,
            opening.leagues,
            opening.players,
            opening.financeStates,
            config,
            0,
            seasonCount,
            advanceAfterFinalSeason,
            hooks,
            rosterHooks,
            financeHooks,
            transferHooks,
            enableTransferInstallments),
        owner,
        revision,
        provenance);
  }

  PreparedWorldExecution prepareResume(
      {required WorldCheckpoint checkpoint,
      required Object owner,
      required Object revision,
      required Object provenance,
      int seasonCount = 1,
      WorldCareerHooks hooks = const NoopWorldCareerHooks(),
      WorldRosterHooks rosterHooks = const NoopWorldRosterHooks(),
      WorldFinanceHooks financeHooks = const NoopWorldFinanceHooks(),
      WorldTransferHooks transferHooks = const NoopWorldTransferHooks(),
      bool enableTransferInstallments = false}) {
    _validateSeasonCount(seasonCount);
    checkpoint.validate();
    _validateSetup(checkpoint.baseClubs, checkpoint.nextSeasonLeagues);
    return _prepareRun(
        _PreparedWorldGraph(
            checkpoint.baseClubs,
            _sortedLeagues(checkpoint.nextSeasonLeagues),
            checkpoint.nextSeasonPlayers,
            checkpoint.nextSeasonFinanceStates,
            checkpoint.config,
            checkpoint.completedSeasons,
            seasonCount,
            true,
            hooks,
            rosterHooks,
            financeHooks,
            transferHooks,
            enableTransferInstallments),
        owner,
        revision,
        provenance);
  }

  PreparedWorldExecution _prepareRun(_PreparedWorldGraph graph, Object owner,
      Object revision, Object provenance) {
    final opening = _prepareSeason(
        config: graph.config,
        seasonIndex: graph.config.seasonIndex + graph.completedBefore,
        baseClubs: graph.baseClubs,
        players: graph.players,
        finance: graph.finance,
        leagues: graph.leagues,
        hooks: graph.hooks);
    return PreparedWorldExecution._(
        this, owner, revision, provenance, graph, opening, Object());
  }

  PreparedWorldOpening _prepareSeason(
      {required SimulationConfig config,
      required int seasonIndex,
      required List<Club> baseClubs,
      required List<Player> players,
      required List<ClubFinanceState> finance,
      required List<WorldLeague> leagues,
      required WorldCareerHooks hooks}) {
    final seasonPlayers = List<Player>.unmodifiable(players);
    final currentFinance = List<ClubFinanceState>.unmodifiable(finance);
    final currentLeagues = List<WorldLeague>.unmodifiable(leagues);
    final squadClubs = strengthCalculator.deriveClubs(
        baseClubs: baseClubs, players: seasonPlayers);
    final effectiveClubs = hooks.adjustClubsForSeason(
        seasonIndex: seasonIndex,
        squadClubs: squadClubs,
        players: seasonPlayers,
        leagues: currentLeagues,
        financeStates: currentFinance);
    _validateHookClubs(squadClubs, effectiveClubs);
    return PreparedWorldOpening._(
        config: config,
        seasonIndex: seasonIndex,
        players: seasonPlayers,
        squadClubs: squadClubs,
        effectiveClubs: effectiveClubs,
        financeStates: currentFinance,
        leagues: currentLeagues);
  }

  WorldCareerSimulationResult executePrepared(PreparedWorldExecution prepared,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    prepared._check(expectedOwner, expectedRevision, expectedProvenance);
    if (!identical(prepared._engine, this)) {
      throw StateError('Prepared world belongs to another engine.');
    }
    prepared._state = PreparedExecutionState.executing;
    try {
      final g = prepared._graph;
      final run = _simulateSegment(
          baseClubs: g.baseClubs,
          openingLeagues: g.leagues,
          openingPlayers: g.players,
          openingFinanceStates: g.finance,
          config: g.config,
          completedBefore: g.completedBefore,
          seasonCount: g.seasonCount,
          advanceAfterFinalSeason: g.advanceAfterFinalSeason,
          hooks: g.hooks,
          rosterHooks: g.rosterHooks,
          financeHooks: g.financeHooks,
          transferHooks: g.transferHooks,
          enableTransferInstallments: g.enableTransferInstallments,
          preparedOpening: prepared.opening);
      final result = WorldCareerSimulationResult(
          report: run.report,
          checkpoint: _checkpointFromRun(
              run: run,
              config: g.config,
              completedSeasons: g.completedBefore + g.seasonCount));
      prepared._state = PreparedExecutionState.completed;
      return result;
    } catch (_) {
      prepared._state = PreparedExecutionState.failed;
      rethrow;
    }
  }

  /// Existing world simulation semantics are intentionally preserved.
  /// The final requested season does not prepare an offseason unless another
  /// season exists inside this same call.
  WorldCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
    WorldRosterHooks rosterHooks = const NoopWorldRosterHooks(),
    WorldFinanceHooks financeHooks = const NoopWorldFinanceHooks(),
    WorldTransferHooks transferHooks = const NoopWorldTransferHooks(),
    bool enableTransferInstallments = false,
  }) {
    _validateSeasonCount(seasonCount);
    _validateSetup(clubs, leagues);

    final opening = WorldOpeningStateInitializer(
      poolGenerator: poolGenerator,
      economyEngine: economyEngine,
    ).prepare(
      clubs: clubs,
      leagues: leagues,
      config: config,
    );
    final baseClubs = opening.baseClubs;
    final initialLeagues = opening.leagues;
    final initialPlayers = opening.players;
    final initialFinanceStates = opening.financeStates;

    return _simulateSegment(
      baseClubs: baseClubs,
      openingLeagues: initialLeagues,
      openingPlayers: initialPlayers,
      openingFinanceStates: initialFinanceStates,
      config: config,
      completedBefore: 0,
      seasonCount: seasonCount,
      advanceAfterFinalSeason: false,
      hooks: hooks,
      rosterHooks: rosterHooks,
      financeHooks: financeHooks,
      transferHooks: transferHooks,
      enableTransferInstallments: enableTransferInstallments,
    ).report;
  }

  /// Core-world checkpoint path for M26+. The checkpoint owns world state;
  /// optional hooks let later runtime snapshot layers preserve their own state
  /// without changing the legacy [simulate] behavior.
  WorldCareerSimulationResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
    WorldRosterHooks rosterHooks = const NoopWorldRosterHooks(),
    WorldFinanceHooks financeHooks = const NoopWorldFinanceHooks(),
    WorldTransferHooks transferHooks = const NoopWorldTransferHooks(),
    bool enableTransferInstallments = false,
  }) {
    _validateSeasonCount(seasonCount);
    _validateSetup(clubs, leagues);

    final opening = WorldOpeningStateInitializer(
      poolGenerator: poolGenerator,
      economyEngine: economyEngine,
    ).prepare(
      clubs: clubs,
      leagues: leagues,
      config: config,
    );
    final baseClubs = opening.baseClubs;
    final initialLeagues = opening.leagues;
    final initialPlayers = opening.players;
    final initialFinanceStates = opening.financeStates;
    final run = _simulateSegment(
      baseClubs: baseClubs,
      openingLeagues: initialLeagues,
      openingPlayers: initialPlayers,
      openingFinanceStates: initialFinanceStates,
      config: config,
      completedBefore: 0,
      seasonCount: seasonCount,
      advanceAfterFinalSeason: true,
      hooks: hooks,
      rosterHooks: rosterHooks,
      financeHooks: financeHooks,
      transferHooks: transferHooks,
      enableTransferInstallments: enableTransferInstallments,
    );

    return WorldCareerSimulationResult(
      report: run.report,
      checkpoint: _checkpointFromRun(
        run: run,
        config: config,
        completedSeasons: seasonCount,
      ),
    );
  }

  WorldCareerSimulationResult resume({
    required WorldCheckpoint checkpoint,
    required int seasonCount,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
    WorldRosterHooks rosterHooks = const NoopWorldRosterHooks(),
    WorldFinanceHooks financeHooks = const NoopWorldFinanceHooks(),
    WorldTransferHooks transferHooks = const NoopWorldTransferHooks(),
    bool enableTransferInstallments = false,
  }) {
    _validateSeasonCount(seasonCount);
    checkpoint.validate();
    _validateSetup(checkpoint.baseClubs, checkpoint.nextSeasonLeagues);

    final run = _simulateSegment(
      baseClubs: checkpoint.baseClubs,
      openingLeagues: _sortedLeagues(checkpoint.nextSeasonLeagues),
      openingPlayers: checkpoint.nextSeasonPlayers,
      openingFinanceStates: checkpoint.nextSeasonFinanceStates,
      config: checkpoint.config,
      completedBefore: checkpoint.completedSeasons,
      seasonCount: seasonCount,
      advanceAfterFinalSeason: true,
      hooks: hooks,
      rosterHooks: rosterHooks,
      financeHooks: financeHooks,
      transferHooks: transferHooks,
      enableTransferInstallments: enableTransferInstallments,
    );

    return WorldCareerSimulationResult(
      report: run.report,
      checkpoint: _checkpointFromRun(
        run: run,
        config: checkpoint.config,
        completedSeasons: checkpoint.completedSeasons + seasonCount,
      ),
    );
  }

  WorldCheckpoint _checkpointFromRun({
    required _WorldSegmentRun run,
    required SimulationConfig config,
    required int completedSeasons,
  }) =>
      WorldCheckpoint(
        config: config,
        completedSeasons: completedSeasons,
        baseClubs: run.baseClubs,
        nextSeasonLeagues: run.finalLeagues,
        nextSeasonPlayers: run.finalPlayers,
        nextSeasonFinanceStates: run.finalFinanceStates,
      );

  _WorldSegmentRun _simulateSegment({
    required List<Club> baseClubs,
    required List<WorldLeague> openingLeagues,
    required List<Player> openingPlayers,
    required List<ClubFinanceState> openingFinanceStates,
    required SimulationConfig config,
    required int completedBefore,
    required int seasonCount,
    required bool advanceAfterFinalSeason,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
    WorldRosterHooks rosterHooks = const NoopWorldRosterHooks(),
    WorldFinanceHooks financeHooks = const NoopWorldFinanceHooks(),
    WorldTransferHooks transferHooks = const NoopWorldTransferHooks(),
    bool enableTransferInstallments = false,
    PreparedWorldOpening? preparedOpening,
  }) {
    var currentLeagues = List<WorldLeague>.unmodifiable(openingLeagues);
    var currentPlayers = List<Player>.unmodifiable(openingPlayers);
    var currentFinanceStates = List<ClubFinanceState>.unmodifiable(
      openingFinanceStates,
    );
    final initialLeagues = currentLeagues;
    final initialFinanceStates = currentFinanceStates;
    final initialPlayerCount = currentPlayers.length;
    final seasons = <WorldCareerSeason>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final seasonIndex = config.seasonIndex + completedBefore + offset;
      final hasNextSeason = offset < seasonCount - 1 || advanceAfterFinalSeason;
      final opening = offset == 0 && preparedOpening != null
          ? preparedOpening
          : _prepareSeason(
              config: config,
              seasonIndex: seasonIndex,
              baseClubs: baseClubs,
              players: currentPlayers,
              finance: currentFinanceStates,
              leagues: currentLeagues,
              hooks: hooks);
      final leaguesBeforeSeason = opening.leagues;
      final seasonPlayers = opening.players;
      final squadClubs = opening.squadClubs;
      final currentClubs = opening.effectiveClubs;
      currentFinanceStates = opening.financeStates;

      final annualWagesByClub = rosterHooks.annualWagesByClub(
        seasonIndex: seasonIndex,
        players: seasonPlayers,
        clubs: squadClubs,
        leagues: leaguesBeforeSeason,
        financeStates: currentFinanceStates,
      );
      final financeFlows = financeHooks.flowsForSeason(
        seasonIndex: seasonIndex,
        clubs: squadClubs,
        leagues: leaguesBeforeSeason,
        openingFinanceStates: currentFinanceStates,
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
            annualWagesByClub: annualWagesByClub,
            transferInstallmentIncomeByClub:
                financeFlows.transferInstallmentIncomeByClub,
            transferInstallmentExpenseByClub:
                financeFlows.transferInstallmentExpenseByClub,
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
      List<TransferCashMovement> cashMovementsAfterWindow = const [];
      List<LeagueMovement> movementsAfterSeason = const [];
      var financeStatesAfterWindow = closingFinanceStates;
      var leaguesAfterTransition = leaguesBeforeSeason;

      if (hasNextSeason) {
        final transition = _promoteAndRelegate(
          currentLeagues: leaguesBeforeSeason,
          leagueResults: leagueResults,
        );
        movementsAfterSeason = transition.movements;
        leaguesAfterTransition = transition.leagues;
      }

      hooks.onSeasonCompleted(
        seasonIndex: seasonIndex,
        hasNextSeason: hasNextSeason,
        squadClubs: squadClubs,
        effectiveClubs: currentClubs,
        players: seasonPlayers,
        leaguesBeforeSeason: leaguesBeforeSeason,
        leaguesForNextSeason: leaguesAfterTransition,
        leagueResults: leagueResults,
        finances: financeResults,
      );

      final offseason = WorldOffseasonProjection(
        lifecycleEngine: lifecycleEngine,
        strengthCalculator: strengthCalculator,
        transferMarketEngine: transferMarketEngine,
      ).project(
        hasNextSeason: hasNextSeason,
        seasonIndex: seasonIndex,
        config: config,
        players: seasonPlayers,
        baseClubs: baseClubs,
        squadClubs: squadClubs,
        closingFinanceStates: closingFinanceStates,
        nextLeagues: leaguesAfterTransition,
        rosterHooks: rosterHooks,
        transferHooks: transferHooks,
        enableTransferInstallments: enableTransferInstallments,
      );
      retiredAfterSeason = offseason.retired;
      youthIntakeAfterSeason = offseason.youthIntake;
      transfersAfterSeason = offseason.transfers;
      cashMovementsAfterWindow = offseason.cashMovements;
      currentPlayers = List<Player>.unmodifiable(offseason.players);
      currentFinanceStates = List<ClubFinanceState>.unmodifiable(
        offseason.financeStates,
      );
      financeStatesAfterWindow = currentFinanceStates;
      if (hasNextSeason) {
        currentLeagues = offseason.nextLeagues;
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
          cashMovementsAfterWindow: cashMovementsAfterWindow,
        ),
      );
    }

    final finalClubs = strengthCalculator.deriveClubs(
      baseClubs: baseClubs,
      players: currentPlayers,
    );
    final report = WorldCareerReport(
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

    return _WorldSegmentRun(
      report: report,
      baseClubs: List.unmodifiable(baseClubs),
      finalPlayers: List.unmodifiable(currentPlayers),
      finalFinanceStates: List.unmodifiable(currentFinanceStates),
      finalLeagues: List.unmodifiable(currentLeagues),
    );
  }

  void _validateSeasonCount(int seasonCount) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(
          seasonCount, 'seasonCount', 'Must be positive.');
    }
  }

  _LeagueTransition _promoteAndRelegate({
    required List<WorldLeague> currentLeagues,
    required List<LeagueSeasonSnapshot> leagueResults,
  }) {
    // One production movement rule shared by the legacy world and detached B2.
    final result = const WorldLeagueMovementProjection().project(
      currentLeagues: currentLeagues,
      leagueResults: leagueResults,
      hasNextSeason: true,
    );
    return _LeagueTransition(
      leagues: result.nextLeagues,
      movements: result.movements,
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

  void _validateHookClubs(List<Club> squadClubs, List<Club> adjustedClubs) {
    if (adjustedClubs.length != squadClubs.length) {
      throw StateError('World career hooks must preserve club count.');
    }
    final expectedIds = squadClubs.map((club) => club.id).toSet();
    final adjustedIds = adjustedClubs.map((club) => club.id).toSet();
    if (adjustedIds.length != adjustedClubs.length ||
        adjustedIds.length != expectedIds.length ||
        !adjustedIds.containsAll(expectedIds)) {
      throw StateError('World career hooks must preserve unique club IDs.');
    }
    for (final club in adjustedClubs) {
      if (!club.strength.isFinite ||
          club.strength < 40 ||
          club.strength > 100) {
        throw StateError('Hook produced invalid strength for ${club.id}.');
      }
    }
  }
}

class _WorldSegmentRun {
  const _WorldSegmentRun({
    required this.report,
    required this.baseClubs,
    required this.finalPlayers,
    required this.finalFinanceStates,
    required this.finalLeagues,
  });

  final WorldCareerReport report;
  final List<Club> baseClubs;
  final List<Player> finalPlayers;
  final List<ClubFinanceState> finalFinanceStates;
  final List<WorldLeague> finalLeagues;
}

class _LeagueTransition {
  const _LeagueTransition({
    required this.leagues,
    required this.movements,
  });

  final List<WorldLeague> leagues;
  final List<LeagueMovement> movements;
}
