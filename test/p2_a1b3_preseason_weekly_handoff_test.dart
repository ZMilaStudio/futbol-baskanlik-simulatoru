import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_preseason_weekly_handoff.dart';
import 'package:test/test.dart';

class _FailOnWeekTwo extends MatchEngine {
  const _FailOnWeekTwo();
  @override
  MatchResult simulate({
    required Fixture fixture,
    required Club home,
    required Club away,
    required SimulationConfig config,
  }) {
    if (fixture.round == 2) throw StateError('Injected production M2 seam failure.');
    return super.simulate(fixture: fixture, home: home, away: away, config: config);
  }
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();

  PlayerPresidentInteractiveDecisionApplicationSession app({
    String controlledClubId = 't1_01',
  }) => PlayerPresidentInteractiveDecisionApplicationSession.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );

  PlayerPresidentPreseasonPromiseBoundary begin(
    PlayerPresidentInteractiveDecisionApplicationSession session,
  ) => session.startPreseasonPromise(
    sourceClubs: world.clubs,
    sourceLeagues: world.leagues,
  );

  PlayerPresidentPreseasonPromiseApplied apply(
    PlayerPresidentPreseasonPromiseBoundary boundary,
  ) {
    final pending = boundary.pending!;
    return boundary.submit(
      pending: pending,
      choice: pending.context.allowedTypes.first,
    );
  }

  List<Object?> score(WeeklyWorldFixture f) => [
    f.globalKey, f.fixture.id, f.fixture.result?.matchSeed,
    f.fixture.result?.homeGoals, f.fixture.result?.awayGoals,
    f.fixture.result?.homeExpectedGoals, f.fixture.result?.awayExpectedGoals,
  ];

  test('single application boundary; direct start shares the same claim gate', () {
    final session = app();
    final boundary = begin(session);
    expect(session.preseasonPromiseBoundary, same(boundary));
    expect(session.appliedPreseasonPromises, isNull);
    expect(() => begin(session), throwsStateError);
    expect(
      () => PlayerPresidentPreseasonPromiseBoundary.start(
        application: session, sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    final foreign = begin(app());
    expect(
      () => session.claimPreseasonPromiseBoundary(
        boundary: foreign, proof: foreign.proof,
        sourceClubs: world.clubs, sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(session.preseasonPromiseBoundary, same(boundary));
  });

  test('proof failure leaves pristine M79, annual Pending rejects opt-in', () {
    final session = app();
    expect(
      () => session.startPreseasonPromise(
        sourceClubs: world.clubs.sublist(1),
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(session.preseasonPromiseBoundary, isNull);
    expect(session.canPersistBootstrap, isTrue);
    final annual = session.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(
      () => begin(session),
      throwsStateError,
    );
    expect(session.pendingDecision, same(annual.request));
  });

  test('pending/rejected choice cannot hand off; retry owns same applied object', () {
    final session = app();
    final boundary = begin(session);
    final pending = boundary.pending!;
    expect(() => session.openPreseasonWeeklyHandoff(), throwsStateError);
    final invalid = PresidentPromiseType.values.firstWhere(
      (t) => !pending.context.allowedTypes.contains(t),
    );
    expect(() => boundary.submit(pending: pending, choice: invalid), throwsArgumentError);
    expect(boundary.pending, same(pending));
    expect(session.appliedPreseasonPromises, isNull);
    final result = apply(boundary);
    expect(session.appliedPreseasonPromises, same(result));
    expect(result.consequence.promise, same(
      result.activePromises.singleWhere((p) => p.clubId == pending.clubId)));
    expect(result.activePromises.length, 48);
    expect(result.activePromises.map((p) => p.clubId).toSet().length, 48);
    expect(() => boundary.submit(
      pending: pending, choice: pending.context.allowedTypes.first,
    ), throwsStateError);
    expect(session.appliedPreseasonPromises, same(result));
  });

  test('W0 uses the exact P1 fixture and real accepted promise authorities', () {
    final session = app();
    final boundary = begin(session);
    final applied = apply(boundary);
    final w0 = session.openPreseasonWeeklyHandoff();
    expect(session.preseasonWeeklyState, same(w0));
    expect(w0.fixtureSnapshot, same(boundary.proof.seasonOpening.fixtureSnapshot));
    expect(w0.applied, same(applied));
    expect(w0.activePromises, same(applied.activePromises));
    expect(w0.sourceIdentity, applied.sourceIdentity);
    expect(w0.nextRound, 1);
    expect(w0.completedMatchCount, 0);
    expect(w0.fixtureSnapshot.fixtures.length, 720);
    expect(w0.fixtureSnapshot.fixtures.every((f) => !f.isPlayed), isTrue);
    expect(w0.effectiveClubs.length, 48);
    expect(() => w0.effectiveClubs.clear(), throwsUnsupportedError);
    expect(() => session.openPreseasonWeeklyHandoff(), throwsStateError);
    expect(() => session.advance(), throwsStateError);
    expect(() => session.newGameBootstrapSnapshot, throwsStateError);
    expect(() => session.encodeNewGameBootstrapSnapshot(), throwsStateError);
    expect(() => session.persistenceBundle, throwsStateError);
    expect(() => session.encodePersistenceBundle(), throwsStateError);
    expect(() => session.continuePlayerCareerToNextSeason(), throwsStateError);
    expect(session.canPersist, isFalse);
    expect(session.canPersistBootstrap, isFalse);
  });

  test('real detached M2 W1-W3 has 24/48/72 results, seeds and table parity', () {
    final session = app();
    final boundary = begin(session);
    final applied = apply(boundary);
    final w0 = session.openPreseasonWeeklyHandoff();
    var state = w0;
    var oracle = w0.fixtureSnapshot;
    final frozenW1 = <List<Object?>>[];
    for (var round = 1; round <= 3; round++) {
      oracle = const WeeklyWorldFixtureResultCore().advanceRound(
        snapshot: oracle, expectedRound: round,
        effectiveClubs: w0.effectiveClubs,
      );
      state = session.advancePreseasonWeek(
        expectedState: state, expectedRound: round,
      );
      expect(session.preseasonWeeklyState, same(state));
      expect(state.applied, same(applied));
      expect(state.activePromises, same(applied.activePromises));
      expect(state.fixtureSnapshot.nextRound, round + 1);
      expect(state.completedMatchCount, round * 24);
      expect(state.fixtureSnapshot.fixtures.map(score).toList(),
          oracle.fixtures.map(score).toList());
      expect(state.fixtureSnapshot.fixtures.map((f) => f.globalKey).toList(),
          w0.fixtureSnapshot.fixtures.map((f) => f.globalKey).toList());
      expect(state.fixtureSnapshot.fixtures.where((f) => f.round > round)
          .every((f) => !f.isPlayed), isTrue);
      for (final tier in LeagueTier.values) {
        final leagueResults = state.fixtureSnapshot.fixtures.where(
          (f) => f.tier == tier && f.isPlayed,
        );
        expect(leagueResults.length, round * 8);
        final table = state.fixtureSnapshot.tableFor(tier);
        expect(table.length, 16);
        expect(table.every((r) => r.played == round), isTrue);
        expect(table.map((r) => r.toJson()).toList(),
            oracle.tableFor(tier).map((r) => r.toJson()).toList());
      }
      if (round == 1) {
        frozenW1.addAll(state.fixtureSnapshot.fixturesForRound(1).map(score));
      } else {
        expect(state.fixtureSnapshot.fixturesForRound(1).map(score).toList(),
            frozenW1);
      }
    }
    expect(w0.nextRound, 1);
    expect(w0.completedMatchCount, 0);
    expect(w0.fixtureSnapshot.fixtures.every((f) => !f.isPlayed), isTrue);
    expect(() => session.advancePreseasonWeek(
      expectedState: state, expectedRound: 4,
    ), throwsStateError);
    expect(state.nextRound, 4);
  });

  test('foreign state, wrong source, stale/duplicate and wrong round fail closed', () {
    final a = app();
    final b = app(controlledClubId: 't1_02');
    apply(begin(a));
    apply(begin(b));
    final a0 = a.openPreseasonWeeklyHandoff();
    final b0 = b.openPreseasonWeeklyHandoff();
    expect(a0.sourceIdentity, isNot(b0.sourceIdentity));
    expect(() => a.advancePreseasonWeek(
      expectedState: b0, expectedRound: 1,
    ), throwsStateError);
    expect(() => a.advancePreseasonWeek(
      expectedState: a0, expectedRound: 2,
    ), throwsStateError);
    expect(a.preseasonWeeklyState, same(a0));
    final a1 = a.advancePreseasonWeek(expectedState: a0, expectedRound: 1);
    expect(() => a.advancePreseasonWeek(
      expectedState: a0, expectedRound: 1,
    ), throwsStateError);
    expect(() => a.advancePreseasonWeek(
      expectedState: b0, expectedRound: 2,
    ), throwsStateError);
    expect(a.preseasonWeeklyState, same(a1));
  });

  test('unsupported weekly decision rejects before any result publication', () {
    final session = app();
    apply(begin(session));
    final w0 = session.openPreseasonWeeklyHandoff();
    expect(() => session.advancePreseasonWeek(
      expectedState: w0, expectedRound: 1, decision: Object(),
    ), throwsUnsupportedError);
    expect(session.preseasonWeeklyState, same(w0));
    expect(session.preseasonWeeklyState!.completedMatchCount, 0);
    expect(session.advancePreseasonWeek(
      expectedState: w0, expectedRound: 1,
    ).completedMatchCount, 24);
  });

  test('actual M2 injected exception at W2 retains the same W1 then retries', () {
    final session = app();
    final applied = apply(begin(session));
    final w0 = session.openPreseasonWeeklyHandoff();
    final w1 = session.advancePreseasonWeek(
      expectedState: w0, expectedRound: 1,
    );
    final locked = w1.fixtureSnapshot.fixtures.map(score).toList();
    expect(() => session.advancePreseasonWeek(
      expectedState: w1, expectedRound: 2,
      core: const WeeklyWorldFixtureResultCore(matchEngine: _FailOnWeekTwo()),
    ), throwsStateError);
    expect(session.preseasonWeeklyState, same(w1));
    expect(w1.fixtureSnapshot.fixtures.map(score).toList(), locked);
    expect(w1.fixtureSnapshot.nextRound, 2);
    expect(w1.completedMatchCount, 24);
    final w2 = session.advancePreseasonWeek(
      expectedState: w1, expectedRound: 2,
    );
    expect(w2.completedMatchCount, 48);
    expect(w2.applied, same(applied));
    expect(w1.fixtureSnapshot.fixtures.map(score).toList(), locked);
  });
}
