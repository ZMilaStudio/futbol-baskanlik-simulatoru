import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_preseason_weekly_handoff.dart';
import 'package:test/test.dart';

class _Run {
  const _Run(this.application, this.w0, this.w30, this.b1, this.b2);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentPreseasonWeeklyState w0;
  final PlayerPresidentPreseasonWeeklyState w30;
  final PlayerPresidentCommittedSeasonResultCandidate b1;
  final PlayerPresidentAcceptedPromiseClosingCandidate b2;
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();

  _Run build({required bool hasFutureSeasonAfterReport, int seasonCount = 1}) {
    final application = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: 't1_01',
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    final boundary = application.startPreseasonPromise(
      sourceClubs: world.clubs, sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    final applied = boundary.submit(
      pending: pending, choice: pending.context.allowedTypes.first,
    );
    final w0 = application.openPreseasonWeeklyHandoff();
    expect(w0.activePromises, same(applied.activePromises));
    var state = w0;
    for (var round = 1; round <= 30; round++) {
      state = application.advancePreseasonWeek(
        expectedState: state, expectedRound: round,
      );
    }
    final b1 = application.projectCommittedSeason(expectedState: state);
    final b2 = application.closeAcceptedPromises(expectedResultCandidate: b1);
    return _Run(application, w0, state, b1, b2);
  }

  late _Run future;
  late _Run terminal;
  late _Run multiSeason;
  late WorldCareerSeason futureLegacy;
  late WorldCareerSeason terminalLegacy;

  setUpAll(() {
    future = build(hasFutureSeasonAfterReport: true);
    terminal = build(hasFutureSeasonAfterReport: false);
    multiSeason = build(hasFutureSeasonAfterReport: false, seasonCount: 2);
    // Independent legacy oracles: B2 production does not invoke either world
    // engine, generate fixtures, or run a promise generator.
    futureLegacy = const AdvancedTransferWorldCareerEngine().simulate(
      clubs: world.clubs, leagues: world.leagues,
      config: config, seasonCount: 2,
    ).worldReport.seasons.first;
    terminalLegacy = const AdvancedTransferWorldCareerEngine().simulate(
      clubs: world.clubs, leagues: world.leagues,
      config: config, seasonCount: 1,
    ).worldReport.seasons.single;
  });

  test('real M79 → W30 → B1 → B2 preserves 720 committed matches and owner', () {
    final candidate = future.b2;
    expect(candidate.sourceResultCandidate, same(future.b1));
    expect(candidate.sourceState, same(future.w30));
    expect(candidate.applied, same(future.w30.applied));
    expect(candidate.activePromises, same(future.b1.activePromises));
    expect(candidate.activePromises.length, 48);
    expect(candidate.acceptedChoice, future.w30.applied.acceptedChoice);
    expect(candidate.acceptedRequestKey, future.w30.applied.acceptedRequestKey);
    expect(candidate.controlledPresidentId, future.w30.applied.controlledPresidentId);
    expect(future.application.preseasonWeeklyState, same(future.w30));
    expect(future.application.committedSeasonResultCandidate, same(future.b1));
    expect(future.application.acceptedPromiseClosingCandidate, same(candidate));
    expect(future.w0.completedMatchCount, 0);
    expect(future.w30.completedMatchCount, 720);
    expect(future.w30.nextRound, 31);
    expect(candidate.leagueResults.length, 3);
    for (final tier in LeagueTier.values) {
      final a = candidate.leagueResults.singleWhere((v) => v.tier == tier).report;
      final b = future.b1.reportFor(tier);
      expect(a.table.map((row) => row.toJson()).toList(),
          b.table.map((row) => row.toJson()).toList());
      expect(a.fixtures.length, 240);
      for (var i = 0; i < 240; i++) {
        expect(a.fixtures[i], same(b.fixtures[i]));
      }
    }
  });

  test('X1 opening wages, empty pristine flows, and all 48 finance records match legacy', () {
    final boundary = future.w30.boundary;
    final proof = boundary.proof;
    final contracts = proof.initialContracts;
    expect(boundary.opening.players.length, 864);
    expect(boundary.opening.financeStates.length, 48);
    expect(contracts.activeContracts.length, 864);
    expect(contracts.initialEvents.length, 864);
    final hook = AdvancedTransferController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      activeContracts: contracts.activeContracts,
      contractEvents: contracts.initialEvents,
      activeLoans: const [],
      loanHistory: const [],
      installmentObligations: const [],
    );
    final wages = hook.annualWagesByClub(
      seasonIndex: config.seasonIndex,
      players: boundary.opening.players,
      clubs: future.w30.effectiveClubs,
      leagues: boundary.opening.leagues,
      financeStates: boundary.opening.financeStates,
    )!;
    final flows = hook.flowsForSeason(
      seasonIndex: config.seasonIndex,
      clubs: future.w30.effectiveClubs,
      leagues: boundary.opening.leagues,
      openingFinanceStates: boundary.opening.financeStates,
    );
    expect(wages.length, 48);
    expect(flows.transferInstallmentIncomeByClub, isEmpty);
    expect(flows.transferInstallmentExpenseByClub, isEmpty);
    expect(future.b2.finances.length, 48);
    expect(future.b2.closingFinanceStates.length, 48);
    final legacyById = {for (final f in futureLegacy.finances) f.clubId: f};
    final initialById = {for (final f in boundary.opening.financeStates) f.clubId: f};
    expect(legacyById.length, 48);
    for (final finance in future.b2.finances) {
      final prior = initialById[finance.clubId]!;
      final legacy = legacyById[finance.clubId]!;
      expect(finance.wageExpense, wages[finance.clubId]);
      expect(finance.openingCash, prior.cash);
      expect(finance.openingDebt, prior.debt);
      expect(finance.transferInstallmentIncome, Money.zero);
      expect(finance.transferInstallmentExpense, Money.zero);
      expect(finance.expectedClosingCash, finance.closingCash);
      expect(finance.expectedClosingDebt, finance.closingDebt);
      expect(finance.signature, legacy.signature);
      final next = future.b2.closingFinanceStates.singleWhere(
        (s) => s.clubId == finance.clubId,
      );
      expect(next.cash, finance.closingCash);
      expect(next.debt, finance.closingDebt);
      expect(finance.emergencyBorrowing, legacy.emergencyBorrowing);
      expect(finance.health, legacy.health);
    }
    expect(future.b2.finances.map((f) => f.clubId).toSet().length, 48);
    expect(future.b2.finances.map((f) => f.clubId).toList(),
        [...future.b2.finances.map((f) => f.clubId)]..sort());
  });

  test('shared movement seam exactly matches legacy future and terminal seasons', () {
    expect(future.b2.hasNextSeason, isTrue);
    expect(future.b2.movements.length, 12);
    expect(future.b2.movements.map((m) => m.signature).toList(),
        futureLegacy.movementsAfterSeason.map((m) => m.signature).toList());
    // Independent test oracle freezes the pre-refactor slot/order semantics.
    final tables = {for (final result in future.b1.leagueResults)
      result.tier: result.report.table.map((row) => row.clubId).toList()};
    final expectedOrder = <String>[
      ...tables[LeagueTier.second]!.take(3).map((id) => id + ':2>1'),
      ...tables[LeagueTier.first]!.skip(13).map((id) => id + ':1>2'),
      ...tables[LeagueTier.third]!.take(3).map((id) => id + ':3>2'),
      ...tables[LeagueTier.second]!.skip(13).map((id) => id + ':2>3'),
    ];
    expect(future.b2.movements.map((m) => m.signature).toList(), expectedOrder);
    expect(multiSeason.b2.hasNextSeason, isTrue);
    expect(multiSeason.b2.movements.map((m) => m.signature).toList(), expectedOrder);
    for (final tier in LeagueTier.values) {
      final next = future.b2.candidateNextLeagues.singleWhere((l) => l.tier == tier);
      final legacy = futureLegacy.leaguesAfterTransition.singleWhere((l) => l.tier == tier);
      expect(next.clubIds, legacy.clubIds);
      expect(next.clubIds.length, 16);
    }
    expect(future.b2.candidateNextLeagues.expand((l) => l.clubIds).toSet().length, 48);
    expect(terminal.b2.hasNextSeason, isFalse);
    expect(terminal.b2.movements, isEmpty);
    expect(terminalLegacy.movementsAfterSeason, isEmpty);
    for (final tier in LeagueTier.values) {
      expect(terminal.b2.candidateNextLeagues.singleWhere((l) => l.tier == tier).clubIds,
          terminal.w30.boundary.opening.leagues.singleWhere((l) => l.tier == tier).clubIds);
    }
    final invalid = [
      WorldLeague(tier: LeagueTier.first, clubIds:
          future.w30.boundary.opening.leagues.first.clubIds.take(15)),
      ...future.w30.boundary.opening.leagues.skip(1),
    ];
    expect(() => const WorldLeagueMovementProjection().project(
      currentLeagues: invalid,
      leagueResults: future.b1.leagueResults,
      hasNextSeason: true,
    ), throwsStateError);
  });

  test('48 original accepted promises produce exact finance/movement outcomes', () {
    final byId = {for (final p in future.w30.applied.activePromises) p.clubId: p};
    final movements = {for (final m in future.b2.movements) m.clubId: m};
    expect(future.b2.promiseSnapshots.length, 48);
    expect(future.b2.promiseSnapshots.map((p) => p.promise.id).toSet().length, 48);
    for (final snapshot in future.b2.promiseSnapshots) {
      final promise = byId[snapshot.promise.clubId]!;
      final finance = future.b2.financeFor(promise.clubId);
      final movement = movements[promise.clubId];
      final outcome = snapshot.outcome;
      expect(snapshot.promise, same(promise));
      expect(snapshot.resolution.promise, same(promise));
      expect(snapshot.context.clubId, promise.clubId);
      expect(snapshot.context, same(future.w30.boundary.contexts
          .singleWhere((item) => item.context.clubId == promise.clubId).context));
      expect(outcome.clubId, promise.clubId);
      expect(outcome.seasonIndex, promise.seasonIndex);
      expect(outcome.openingDebt, finance.openingDebt);
      expect(outcome.closingDebt, finance.closingDebt);
      expect(outcome.emergencyBorrowing, finance.emergencyBorrowing);
      expect(outcome.promoted, movement != null &&
          movement.to.level < movement.from.level);
      expect(outcome.relegated, movement != null &&
          movement.to.level > movement.from.level);
      expect(snapshot.resolution.signature,
          const PromiseResolver().resolve(promise: promise, outcome: outcome).signature);
    }
    final controlled = future.b2.promiseFor('t1_01');
    expect(controlled.promise, same(future.w30.applied.consequence.promise));
    expect(controlled.promise.type, future.w30.applied.acceptedChoice);
    for (final snapshot in terminal.b2.promiseSnapshots) {
      expect(snapshot.outcome.promoted, isFalse);
      expect(snapshot.outcome.relegated, isFalse);
    }
  });

  test('six legacy resolver promise types retain fulfilled semantics', () {
    for (final type in PresidentPromiseType.values) {
      final promise = PresidentPromise(
        id: 'type_' + type.name,
        clubId: 't1_01',
        seasonIndex: 0,
        type: type,
        targetLeaguePosition: 8,
        targetDebtReductionBps: 800,
      );
      final outcome = PresidentPromiseOutcome(
        clubId: promise.clubId,
        seasonIndex: promise.seasonIndex,
        leaguePosition: 1,
        leagueSize: 16,
        openingDebt: const Money.fromUnits(10000000),
        closingDebt: const Money.fromUnits(8000000),
        emergencyBorrowing: Money.zero,
        promoted: true,
        relegated: false,
      );
      final resolution = const PromiseResolver().resolve(
        promise: promise, outcome: outcome,
      );
      expect(resolution.promise, same(promise));
      expect(resolution.status, PromiseStatus.fulfilled);
      expect(resolution.score, 100);
    }
  });

  test('foreign/stale input cannot publish; same exact B1 retries successfully', () {
    final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs, leagues: world.leagues,
      config: config, controlledClubId: 't1_01', seasonCount: 1,
    );
    expect(app.acceptedPromiseClosingCandidate, isNull);
    expect(() => app.closeAcceptedPromises(expectedResultCandidate: future.b1),
        throwsStateError);
    expect(app.acceptedPromiseClosingCandidate, isNull);
    final boundary = app.startPreseasonPromise(
      sourceClubs: world.clubs, sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    boundary.submit(pending: pending, choice: pending.context.allowedTypes.first);
    var state = app.openPreseasonWeeklyHandoff();
    expect(() => app.closeAcceptedPromises(expectedResultCandidate: future.b1),
        throwsStateError);
    for (var round = 1; round <= 30; round++) {
      state = app.advancePreseasonWeek(expectedState: state, expectedRound: round);
    }
    final b1 = app.projectCommittedSeason(expectedState: state);
    expect(() => app.closeAcceptedPromises(expectedResultCandidate: future.b1),
        throwsStateError);
    expect(app.acceptedPromiseClosingCandidate, isNull);
    final candidate = app.closeAcceptedPromises(expectedResultCandidate: b1);
    expect(app.acceptedPromiseClosingCandidate, same(candidate));
    expect(app.closeAcceptedPromises(expectedResultCandidate: b1), same(candidate));
    expect(app.preseasonWeeklyState, same(state));
    expect(app.committedSeasonResultCandidate, same(b1));
    expect(() => app.closeAcceptedPromises(expectedResultCandidate: terminal.b1),
        throwsStateError);
    expect(app.acceptedPromiseClosingCandidate, same(candidate));
  });

  test('immutable B2 collections and B1 mutable report views cannot mutate authority', () {
    final c = future.b2;
    final first = c.leagueResults.first.report;
    final before = first.table.first.toJson();
    final finance = c.finances.first.signature;
    first.table.first.points = -999;
    expect(c.leagueResults.first.report.table.first.toJson(), before);
    expect(c.finances.first.signature, finance);
    expect(() => c.finances.clear(), throwsUnsupportedError);
    expect(() => c.closingFinanceStates.clear(), throwsUnsupportedError);
    expect(() => c.movements.clear(), throwsUnsupportedError);
    expect(() => c.candidateNextLeagues.clear(), throwsUnsupportedError);
    expect(() => c.promiseSnapshots.clear(), throwsUnsupportedError);
    expect(() => c.activePromises.clear(), throwsUnsupportedError);
    expect(c.sourceState, same(future.w30));
    expect(c.sourceResultCandidate, same(future.b1));
    expect(future.application.canPersist, isFalse);
    expect(future.application.canPersistBootstrap, isFalse);
    expect(() => future.application.persistenceBundle, throwsStateError);
    expect(() => future.application.newGameBootstrapSnapshot, throwsStateError);
    expect(future.application.completed, isNull);
    expect(future.application.checkpointOrNull, isNull);
  });
}
