import '../core/money.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../promise/president_promise.dart';
import '../promise/promise_context.dart';
import '../promise/promise_opening_context_builder.dart';
import '../promise/promise_resolver.dart';
import '../promise/promise_season_snapshot.dart';
import '../season/season_validator.dart';
import '../transfer/advanced_transfer_controller.dart';
import '../world/league_tier.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import '../world/world_league_movement_projection.dart';
import 'player_president_committed_season_result_projection.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_preseason_weekly_handoff.dart';

/// B2 is an in-memory *candidate*, not a completed WorldCareerSeason or M65 save.
/// All values are detached calculations from the exact application-owned B1/W30.
class PlayerPresidentAcceptedPromiseClosingProjection {
  const PlayerPresidentAcceptedPromiseClosingProjection();

  PlayerPresidentAcceptedPromiseClosingCandidate project({
    required PlayerPresidentCommittedSeasonResultCandidate source,
  }) {
    final state = source.sourceState;
    final boundary = state.boundary;
    final application = boundary.application;
    final applied = state.applied;
    final proof = boundary.proof;
    final opening = boundary.opening;
    final config = proof.seasonOpening.config;
    final contracts = proof.initialContracts;

    if (!application.isNewGame ||
        !identical(application.committedSeasonResultCandidate, source) ||
        !identical(application.preseasonWeeklyState, state) ||
        !identical(application.preseasonPromiseBoundary, boundary) ||
        !identical(application.appliedPreseasonPromises, applied) ||
        !identical(boundary.applied, applied) ||
        boundary.phase != PlayerPresidentPreseasonPromisePhase.applied ||
        !identical(source.applied, applied) ||
        !identical(source.activePromises, applied.activePromises) ||
        !identical(applied.activePromises, state.activePromises) ||
        !identical(applied.consequence.promise,
          applied.activePromises.singleWhere(
            (promise) => promise.clubId == applied.controlledClubId,
            orElse: () => throw StateError('B2 controlled promise missing.'))) ||
        applied.consequence.promise.type != applied.acceptedChoice ||
        source.acceptedRequestKey != applied.acceptedRequestKey ||
        source.acceptedChoice != applied.acceptedChoice ||
        source.controlledPresidentId != applied.controlledPresidentId ||
        source.controlledClubId != applied.controlledClubId ||
        source.sourceIdentity != proof.seasonOpening.originSourceDigest ||
        applied.sourceIdentity != source.sourceIdentity ||
        source.seasonIndex != config.seasonIndex ||
        config.seasonIndex != 0 || proof.seasonIndex != 0 ||
        state.nextRound != 31 || state.completedMatchCount != 720 ||
        !state.fixtureSnapshot.isComplete ||
        opening.baseClubs.length != 48 ||
        opening.leagues.length != 3 ||
        opening.players.length != 864 ||
        opening.financeStates.length != 48 ||
        state.effectiveClubs.length != 48 ||
        applied.activePromises.length != 48 ||
        boundary.contexts.length != 48 ||
        application.resumeConfig.seasonCount < 1) {
      throw StateError('B2 requires pristine application-owned B1/W30 authority.');
    }
    proof.seasonOpening.assertOpeningProjectionMatches(opening);
    if (!contracts.matchesSource(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      seasonIndex: config.seasonIndex,
      players: opening.players,
      leagues: opening.leagues,
    ) || contracts.activeContracts.length != 864 ||
        contracts.initialEvents.length != 864) {
      throw StateError('B2 opening X1 contract proof mismatch.');
    }

    final ids = <String>{};
    final tiers = <LeagueTier>{};
    final leagueByTier = <LeagueTier, WorldLeague>{};
    for (final league in opening.leagues) {
      if (!tiers.add(league.tier) ||
          league.clubIds.length != 16 ||
          league.clubIds.toSet().length != 16) {
        throw StateError('B2 invalid opening league.');
      }
      leagueByTier[league.tier] = league;
      for (final id in league.clubIds) {
        if (!ids.add(id)) throw StateError('B2 duplicate league member.');
      }
    }
    if (ids.length != 48 || tiers.length != LeagueTier.values.length) {
      throw StateError('B2 incomplete opening membership.');
    }

    final clubsById = <String, Club>{};
    for (final club in state.effectiveClubs) {
      if (!ids.contains(club.id) || clubsById.containsKey(club.id)) {
        throw StateError('B2 unknown/duplicate effective club.');
      }
      clubsById[club.id] = club;
    }
    final openingFinanceById = <String, ClubFinanceState>{};
    for (final finance in opening.financeStates) {
      if (!ids.contains(finance.clubId) ||
          openingFinanceById.containsKey(finance.clubId)) {
        throw StateError('B2 unknown/duplicate opening finance.');
      }
      openingFinanceById[finance.clubId] = finance;
    }
    final playersById = <String, Player>{};
    for (final player in opening.players) {
      if (!ids.contains(player.clubId) || playersById.containsKey(player.id)) {
        throw StateError('B2 invalid opening player.');
      }
      playersById[player.id] = player;
    }
    final seenContracts = <String>{};
    for (final contract in contracts.activeContracts) {
      final player = playersById[contract.playerId];
      if (!seenContracts.add(contract.playerId) ||
          player == null || contract.clubId != player.clubId ||
          !contract.isActiveDuring(config.seasonIndex) ||
          contract.annualWage.isNegative) {
        throw StateError('B2 invalid opening X1 contract.');
      }
    }
    if (seenContracts.length != 864 ||
        contracts.initialEvents.map((event) => event.playerId).toSet().length != 864 ||
        contracts.initialEvents.any((event) => !seenContracts.contains(event.playerId))) {
      throw StateError('B2 X1 contract/event coverage mismatch.');
    }

    final promiseById = <String, PresidentPromise>{};
    for (final promise in applied.activePromises) {
      if (!ids.contains(promise.clubId) ||
          promiseById.containsKey(promise.clubId) ||
          promise.seasonIndex != config.seasonIndex ||
          promise.id != 'promise_' + promise.clubId + '_s' +
              config.seasonIndex.toString()) {
        throw StateError('B2 accepted promise coverage mismatch.');
      }
      promiseById[promise.clubId] = promise;
    }
    final contextsById = <String, PresidentPromiseContext>{};
    for (final item in boundary.contexts) {
      final context = item.context;
      final finance = openingFinanceById[context.clubId];
      final league = leagueByTier[context.tier];
      final accepted = promiseById[context.clubId];
      if (finance == null || league == null || accepted == null ||
          !league.clubIds.contains(context.clubId) ||
          contextsById.containsKey(context.clubId) ||
          context.seasonIndex != config.seasonIndex ||
          context.leagueSize != 16 ||
          context.openingCash != finance.cash ||
          context.openingDebt != finance.debt ||
          (context.clubId != applied.controlledClubId &&
              accepted.signature != item.aiPromise.signature) ||
          (context.clubId == applied.controlledClubId &&
              (!identical(accepted, applied.consequence.promise) ||
               !item.allowedTypes.contains(applied.acceptedChoice)))) {
        throw StateError('B2 original opening promise context mismatch.');
      }
      contextsById[context.clubId] = context;
    }
    if (contextsById.length != 48 || promiseById.length != 48 ||
        clubsById.length != 48 || openingFinanceById.length != 48 ||
        playersById.length != 864) {
      throw StateError('B2 opening world does not cover 48 clubs.');
    }

    // Validate the exact opening contexts independently, without regenerating
    // or substituting a single accepted promise.
    final independentContexts = const PromiseOpeningContextBuilder().build(
      seasonIndex: config.seasonIndex,
      effectiveClubs: state.effectiveClubs,
      leagues: opening.leagues,
      openingFinanceStates: opening.financeStates,
    );
    for (final context in independentContexts) {
      if (context.signature != contextsById[context.clubId]?.signature) {
        throw StateError('B2 opening context source parity failed.');
      }
    }

    // X1 is the authoritative pristine initial contract output. Detached
    // restore reproduces the advanced legacy finance hook; no unknown future
    // loans/installments may silently default to an empty collection.
    final financeHook = AdvancedTransferController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      activeContracts: contracts.activeContracts,
      contractEvents: contracts.initialEvents,
      activeLoans: const [],
      loanHistory: const [],
      installmentObligations: const [],
    );
    final wages = financeHook.annualWagesByClub(
      seasonIndex: config.seasonIndex,
      players: opening.players,
      clubs: state.effectiveClubs,
      leagues: opening.leagues,
      financeStates: opening.financeStates,
    );
    if (wages == null || wages.length != 48 ||
        wages.keys.toSet().difference(ids).isNotEmpty ||
        wages.values.any((value) => value.isNegative)) {
      throw StateError('B2 requires exact advanced X1 wages for 48 clubs.');
    }
    final flows = financeHook.flowsForSeason(
      seasonIndex: config.seasonIndex,
      clubs: state.effectiveClubs,
      leagues: opening.leagues,
      openingFinanceStates: opening.financeStates,
    );
    if (flows.transferInstallmentIncomeByClub.isNotEmpty ||
        flows.transferInstallmentExpenseByClub.isNotEmpty ||
        financeHook.activeLoans.isNotEmpty ||
        financeHook.loanHistory.isNotEmpty ||
        financeHook.installmentObligations.isNotEmpty) {
      throw StateError('B2 pristine source unexpectedly contains obligations.');
    }

    final observed = source.leagueResults;
    if (observed.length != 3 ||
        observed.map((item) => item.tier).toSet().length != 3) {
      throw StateError('B2 requires exactly three original B1 results.');
    }
    final reports = <LeagueSeasonSnapshot>[];
    final financeResults = <ClubFinanceSeason>[];
    final positions = <String, int>{};
    for (final tier in LeagueTier.values) {
      final league = leagueByTier[tier]!;
      final report = observed.singleWhere((item) => item.tier == tier).report;
      final expected = state.fixtureSnapshot.tableFor(tier);
      final originalFixtures = state.fixtureSnapshot.fixtures
          .where((fixture) => fixture.tier == tier)
          .map((fixture) => fixture.fixture).toList(growable: false);
      if (report.seasonIndex != config.seasonIndex ||
          report.seed != config.careerSeed ||
          report.fixtures.length != 240 ||
          report.table.length != 16 ||
          report.championClubId != report.table.first.clubId ||
          report.fixtures.length != originalFixtures.length ||
          const SeasonValidator().validate(report).isNotEmpty) {
        throw StateError('B2 invalid B1 season report.');
      }
      for (var i = 0; i < 240; i++) {
        if (!identical(report.fixtures[i], originalFixtures[i])) {
          throw StateError('B2 B1 result lost committed fixture identity.');
        }
      }
      for (var i = 0; i < 16; i++) {
        final actual = report.table[i];
        final committed = expected[i];
        if (actual.clubId != committed.clubId ||
            actual.played != committed.played ||
            actual.wins != committed.wins ||
            actual.draws != committed.draws ||
            actual.losses != committed.losses ||
            actual.goalsFor != committed.goalsFor ||
            actual.goalsAgainst != committed.goalsAgainst ||
            actual.points != committed.points ||
            !league.clubIds.contains(actual.clubId) ||
            positions.containsKey(actual.clubId)) {
          throw StateError('B2 B1 final table diverged from committed W30.');
        }
        positions[actual.clubId] = i + 1;
      }
      reports.add(LeagueSeasonSnapshot(tier: tier, report: report));
      final leagueFinance = const BasicEconomyEngine().simulateSeason(
        clubs: [for (final id in league.clubIds) clubsById[id]!],
        players: [for (final player in opening.players)
          if (league.clubIds.contains(player.clubId)) player],
        seasonReport: report,
        openingStates: [for (final id in league.clubIds) openingFinanceById[id]!],
        economicScaleBps: tier.economicScaleBps,
        costScaleBps: tier.costScaleBps,
        annualWagesByClub: wages,
        transferInstallmentIncomeByClub: flows.transferInstallmentIncomeByClub,
        transferInstallmentExpenseByClub: flows.transferInstallmentExpenseByClub,
      );
      if (leagueFinance.length != 16) {
        throw StateError('B2 finance engine returned incomplete league.');
      }
      financeResults.addAll(leagueFinance);
    }
    financeResults.sort((a, b) => a.clubId.compareTo(b.clubId));
    final financeById = <String, ClubFinanceSeason>{};
    final closingFinance = <ClubFinanceState>[];
    for (final finance in financeResults) {
      final initial = openingFinanceById[finance.clubId];
      if (initial == null || financeById.containsKey(finance.clubId) ||
          finance.openingCash != initial.cash ||
          finance.openingDebt != initial.debt ||
          finance.wageExpense != wages[finance.clubId] ||
          finance.transferInstallmentIncome != Money.zero ||
          finance.transferInstallmentExpense != Money.zero ||
          finance.expectedClosingCash != finance.closingCash ||
          finance.expectedClosingDebt != finance.closingDebt ||
          finance.closingCash.isNegative || finance.closingDebt.isNegative) {
        throw StateError('B2 annual finance conservation/source mismatch.');
      }
      financeById[finance.clubId] = finance;
      closingFinance.add(ClubFinanceState(
        clubId: finance.clubId, cash: finance.closingCash, debt: finance.closingDebt,
      ));
    }
    if (financeById.length != 48 || positions.length != 48) {
      throw StateError('B2 annual closing requires 48 unique finance records.');
    }

    // The application's *actual* first-season policy is the only source of
    // hasNextSeason. The caller cannot supply a standalone arbitrary boolean.
    final hasNextSeason =
        application.resumeConfig.seasonCount > 1 ||
        application.resumeConfig.hasFutureSeasonAfterReport;
    final movement = const WorldLeagueMovementProjection().project(
      currentLeagues: opening.leagues,
      leagueResults: reports,
      hasNextSeason: hasNextSeason,
    );
    final movementById = <String, LeagueMovement>{};
    for (final item in movement.movements) {
      final openingTier = contextsById[item.clubId]?.tier;
      if (movementById.containsKey(item.clubId) || openingTier != item.from ||
          item.from == item.to) {
        throw StateError('B2 invalid detached movement identity.');
      }
      movementById[item.clubId] = item;
    }
    if ((hasNextSeason && movement.movements.length != 12) ||
        (!hasNextSeason && movement.movements.isNotEmpty)) {
      throw StateError('B2 future-season movement policy mismatch.');
    }

    final snapshots = <PromiseSeasonSnapshot>[];
    final resolvedIds = <String>{};
    for (final context in independentContexts) {
      final originalContext = contextsById[context.clubId]!;
      final promise = promiseById[context.clubId]!;
      final finance = financeById[context.clubId]!;
      final movementForClub = movementById[context.clubId];
      final outcome = PresidentPromiseOutcome(
        clubId: promise.clubId,
        seasonIndex: promise.seasonIndex,
        leaguePosition: positions[context.clubId]!,
        leagueSize: originalContext.leagueSize,
        openingDebt: finance.openingDebt,
        closingDebt: finance.closingDebt,
        emergencyBorrowing: finance.emergencyBorrowing,
        promoted: movementForClub != null &&
            movementForClub.to.level < movementForClub.from.level,
        relegated: movementForClub != null &&
            movementForClub.to.level > movementForClub.from.level,
      );
      final resolution = const PromiseResolver().resolve(
        promise: promise, outcome: outcome,
      );
      if (!resolvedIds.add(promise.id) ||
          outcome.clubId != promise.clubId ||
          outcome.seasonIndex != promise.seasonIndex ||
          !identical(resolution.promise, promise) ||
          outcome.openingDebt != finance.openingDebt ||
          outcome.closingDebt != finance.closingDebt ||
          outcome.emergencyBorrowing != finance.emergencyBorrowing ||
          (outcome.promoted && outcome.relegated) ||
          resolution.score < 0 || resolution.score > 100) {
        throw StateError('B2 accepted-promise resolution mismatch.');
      }
      snapshots.add(PromiseSeasonSnapshot(
        context: originalContext, promise: promise,
        outcome: outcome, resolution: resolution,
      ));
    }
    if (snapshots.length != 48 || resolvedIds.length != 48 ||
        !identical(
          snapshots.singleWhere((item) =>
            item.promise.clubId == applied.controlledClubId).promise,
          applied.consequence.promise,
        )) {
      throw StateError('B2 failed to preserve 48 original promise identities.');
    }
    if (!identical(application.committedSeasonResultCandidate, source) ||
        !identical(application.preseasonWeeklyState, state) ||
        !identical(application.appliedPreseasonPromises, applied)) {
      throw StateError('B2 application authority changed during calculation.');
    }
    return PlayerPresidentAcceptedPromiseClosingCandidate._(
      sourceResultCandidate: source,
      hasNextSeason: hasNextSeason,
      finances: financeResults,
      closingFinanceStates: closingFinance,
      movement: movement,
      promiseSnapshots: snapshots,
    );
  }
}

/// Private, immutable value ownership; no mutable SeasonReport row is stored.
/// Getter-based report views delegate to B1's defensive reconstruction.
class PlayerPresidentAcceptedPromiseClosingCandidate {
  PlayerPresidentAcceptedPromiseClosingCandidate._({
    required this.sourceResultCandidate,
    required this.hasNextSeason,
    required Iterable<ClubFinanceSeason> finances,
    required Iterable<ClubFinanceState> closingFinanceStates,
    required this.movement,
    required Iterable<PromiseSeasonSnapshot> promiseSnapshots,
  }) : finances = List<ClubFinanceSeason>.unmodifiable(finances),
       closingFinanceStates =
           List<ClubFinanceState>.unmodifiable(closingFinanceStates),
       promiseSnapshots =
           List<PromiseSeasonSnapshot>.unmodifiable(promiseSnapshots);

  final PlayerPresidentCommittedSeasonResultCandidate sourceResultCandidate;
  final bool hasNextSeason;
  final List<ClubFinanceSeason> finances;
  final List<ClubFinanceState> closingFinanceStates;
  final WorldLeagueMovementResult movement;
  final List<PromiseSeasonSnapshot> promiseSnapshots;

  PlayerPresidentPreseasonWeeklyState get sourceState =>
      sourceResultCandidate.sourceState;
  PlayerPresidentPreseasonPromiseApplied get applied =>
      sourceResultCandidate.applied;
  int get seasonIndex => sourceResultCandidate.seasonIndex;
  String get sourceIdentity => sourceResultCandidate.sourceIdentity;
  String get controlledClubId => sourceResultCandidate.controlledClubId;
  String get controlledPresidentId =>
      sourceResultCandidate.controlledPresidentId;
  String get acceptedRequestKey =>
      sourceResultCandidate.acceptedRequestKey;
  PresidentPromiseType get acceptedChoice =>
      sourceResultCandidate.acceptedChoice;
  List<PresidentPromise> get activePromises =>
      sourceResultCandidate.activePromises;
  List<LeagueSeasonSnapshot> get leagueResults =>
      sourceResultCandidate.leagueResults;
  List<LeagueMovement> get movements => movement.movements;
  List<WorldLeague> get candidateNextLeagues => movement.nextLeagues;

  ClubFinanceSeason financeFor(String clubId) =>
      finances.singleWhere((finance) => finance.clubId == clubId);
  PromiseSeasonSnapshot promiseFor(String clubId) =>
      promiseSnapshots.singleWhere((item) => item.promise.clubId == clubId);
}
