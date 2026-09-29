import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_preseason_weekly_handoff.dart';
import 'package:test/test.dart';

class _FailOnWeekNineteen extends MatchEngine {
  const _FailOnWeekNineteen();

  @override
  MatchResult simulate({
    required Fixture fixture,
    required Club home,
    required Club away,
    required SimulationConfig config,
  }) {
    if (fixture.round == 19) {
      throw StateError('Injected real M2 MatchEngine failure at W19.');
    }
    return super.simulate(
      fixture: fixture, home: home, away: away, config: config,
    );
  }
}

class _UnadvancedCandidateCore extends WeeklyWorldFixtureResultCore {
  const _UnadvancedCandidateCore();

  @override
  WeeklyWorldFixtureSnapshot advanceRound({
    required WeeklyWorldFixtureSnapshot snapshot,
    required int expectedRound,
    required List<Club> effectiveClubs,
  }) => snapshot;
}

class _WrongStrengthCandidateCore extends WeeklyWorldFixtureResultCore {
  const _WrongStrengthCandidateCore();

  @override
  WeeklyWorldFixtureSnapshot advanceRound({
    required WeeklyWorldFixtureSnapshot snapshot,
    required int expectedRound,
    required List<Club> effectiveClubs,
  }) => super.advanceRound(
    snapshot: snapshot,
    expectedRound: expectedRound,
    effectiveClubs: [
      for (final club in effectiveClubs)
        if (club.id == 't1_01')
          club.copyWith(strength: club.strength == 40 ? 100 : 40)
        else
          club,
    ],
  );
}

List<Object?> _resultIdentity(WeeklyWorldFixture entry) => [
  entry.globalKey,
  entry.fixture.id,
  entry.fixture.result?.matchSeed,
  entry.fixture.result?.homeGoals,
  entry.fixture.result?.awayGoals,
  entry.fixture.result?.homeExpectedGoals,
  entry.fixture.result?.awayExpectedGoals,
];

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

  PlayerPresidentPreseasonWeeklyState open(
    PlayerPresidentInteractiveDecisionApplicationSession session,
  ) {
    final boundary = session.startPreseasonPromise(
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    final applied = boundary.submit(
      pending: pending,
      choice: pending.context.allowedTypes.first,
    );
    expect(session.appliedPreseasonPromises, same(applied));
    return session.openPreseasonWeeklyHandoff();
  }

  test('W4-W30 commits exactly one real world round and preserves accepted promise', () {
    final session = app();
    final w0 = open(session);
    final boundary = w0.boundary;
    final applied = w0.applied;
    final openingFinance = boundary.opening.financeStates
        .map((entry) => entry.signature).toList();
    final plan = List<WeeklyWorldFixture>.of(w0.fixtureSnapshot.fixtures);
    final firstWeek = <WeeklyWorldFixture>[];
    final checkpoints = <int, List<int>>{
      3: [4, 72, 24],
      4: [5, 96, 32],
      15: [16, 360, 120],
      29: [30, 696, 232],
      30: [31, 720, 240],
    };
    var state = w0;
    expect(plan.length, 720);
    expect(plan.map((entry) => entry.globalKey).toSet().length, 720);
    expect(plan.every((entry) => !entry.isPlayed), isTrue);
    for (var round = 1; round <= 30; round++) {
      final previous = state;
      final before = previous.fixtureSnapshot.fixtures;
      state = session.advancePreseasonWeek(
        expectedState: previous, expectedRound: round,
      );
      final after = state.fixtureSnapshot.fixtures;
      expect(session.preseasonWeeklyState, same(state));
      expect(state.boundary, same(boundary));
      expect(state.applied, same(applied));
      expect(state.activePromises, same(applied.activePromises));
      expect(state.sourceIdentity, applied.sourceIdentity);
      expect(state.applied.acceptedRequestKey, applied.acceptedRequestKey);
      expect(state.applied.acceptedChoice, applied.acceptedChoice);
      expect(state.applied.consequence, same(applied.consequence));
      expect(state.applied.controlledClubId, applied.controlledClubId);
      expect(state.applied.controlledPresidentId, applied.controlledPresidentId);
      expect(state.effectiveClubs.map((club) => club.id).toList(),
          w0.effectiveClubs.map((club) => club.id).toList());
      expect(state.effectiveClubs.map((club) => club.strength).toList(),
          w0.effectiveClubs.map((club) => club.strength).toList());
      expect(state.nextRound, round + 1);
      expect(state.completedMatchCount, round * 24);
      expect(state.fixtureSnapshot.isComplete, round == 30);
      expect(after.length, 720);
      expect(after.map((entry) => entry.globalKey).toSet().length, 720);
      var newResults = 0;
      for (var i = 0; i < 720; i++) {
        final oldEntry = before[i];
        final entry = after[i];
        expect(entry.globalKey, plan[i].globalKey);
        expect(entry.fixture.id, plan[i].fixture.id);
        expect(entry.fixture.homeClubId, plan[i].fixture.homeClubId);
        expect(entry.fixture.awayClubId, plan[i].fixture.awayClubId);
        if (entry.round == round) {
          expect(oldEntry.isPlayed, isFalse);
          expect(entry.isPlayed, isTrue);
          newResults++;
        } else {
          expect(entry, same(oldEntry));
          if (entry.round > round) expect(entry.fixture.result, isNull);
          if (entry.round < round) expect(entry.isPlayed, isTrue);
        }
      }
      expect(newResults, 24);
      expect(previous.completedMatchCount, (round - 1) * 24);
      expect(previous.nextRound, round);
      expect(
        previous.fixtureSnapshot.fixtures.where(
          (entry) => entry.round >= round,
        ).every((entry) => !entry.isPlayed),
        isTrue,
      );
      if (round == 1) {
        firstWeek.addAll(state.fixtureSnapshot.fixturesForRound(1));
      } else {
        final currentFirst = state.fixtureSnapshot.fixturesForRound(1);
        for (var i = 0; i < 24; i++) {
          expect(currentFirst[i], same(firstWeek[i]));
        }
      }
      for (final tier in LeagueTier.values) {
        final played = after.where(
          (entry) => entry.tier == tier && entry.isPlayed,
        ).toList();
        final table = state.fixtureSnapshot.tableFor(tier);
        expect(played.length, round * 8);
        expect(after.where((entry) => entry.tier == tier &&
            entry.round == round && entry.isPlayed).length, 8);
        expect(table.length, 16);
        expect(table.every((entry) => entry.played == round), isTrue);
        if (checkpoints.containsKey(round)) {
          expect(played.length, checkpoints[round]![2]);
        }
      }
      if (checkpoints.containsKey(round)) {
        expect(state.nextRound, checkpoints[round]![0]);
        expect(state.completedMatchCount, checkpoints[round]![1]);
      }
    }

    expect(w0.nextRound, 1);
    expect(w0.completedMatchCount, 0);
    expect(w0.fixtureSnapshot, same(boundary.proof.seasonOpening.fixtureSnapshot));
    expect(w0.fixtureSnapshot.fixtures.every((entry) => !entry.isPlayed), isTrue);
    expect(state.fixtureSnapshot.fixtures.every((entry) => entry.isPlayed), isTrue);
    expect(state.fixtureSnapshot.nextRound, 31);
    expect(state.fixtureSnapshot.isComplete, isTrue);
    expect(state.fixtureSnapshot.fixtures.map((entry) => entry.globalKey).toSet().length, 720);
    final byId = {for (final club in w0.effectiveClubs) club.id: club};
    for (final league in world.leagues) {
      final rows = state.fixtureSnapshot.tableFor(league.tier);
      expect(rows.length, 16);
      expect(rows.every((row) => row.played == 30), isTrue);
      expect(
        state.fixtureSnapshot.fixtures.where(
          (entry) => entry.tier == league.tier && entry.isPlayed,
        ).length,
        240,
      );
      final legacy = const SeasonEngine().simulate(
        clubs: league.clubIds.map((id) => byId[id]!).toList(),
        config: config,
      );
      final weekly = state.fixtureSnapshot.fixtures
          .where((entry) => entry.tier == league.tier).toList();
      expect(weekly.length, legacy.fixtures.length);
      for (var i = 0; i < weekly.length; i++) {
        expect(weekly[i].fixture.id, legacy.fixtures[i].id);
        final actual = weekly[i].fixture.result!;
        final old = legacy.fixtures[i].result!;
        expect(actual.matchSeed, old.matchSeed);
        expect(actual.homeGoals, old.homeGoals);
        expect(actual.awayGoals, old.awayGoals);
        expect(actual.homeExpectedGoals, old.homeExpectedGoals);
        expect(actual.awayExpectedGoals, old.awayExpectedGoals);
      }
      expect(rows.map((row) => row.toJson()).toList(),
          legacy.table.map((row) => row.toJson()).toList());
    }
    expect(boundary.opening.financeStates.map((entry) => entry.signature).toList(),
        openingFinance);
    expect(session.completed, isNull);
    expect(session.canPersist, isFalse);
    expect(session.canPersistBootstrap, isFalse);
    expect(() => session.advance(), throwsStateError);
    expect(() => session.newGameBootstrapSnapshot, throwsStateError);
    expect(() => session.persistenceBundle, throwsStateError);
    expect(() => session.continuePlayerCareerToNextSeason(), throwsStateError);
    expect(() => session.advancePreseasonWeek(
      expectedState: state, expectedRound: 31,
    ), throwsStateError);
    expect(session.preseasonWeeklyState, same(state));
  });

  test('W4 rejects foreign owner, stale or duplicate predecessor and wrong round', () {
    final a = app();
    final b = app(controlledClubId: 't1_02');
    var state = open(a);
    final foreign = open(b);
    expect(state.sourceIdentity, isNot(foreign.sourceIdentity));
    final w0 = state;
    PlayerPresidentPreseasonWeeklyState? w2;
    for (var round = 1; round <= 3; round++) {
      state = a.advancePreseasonWeek(
        expectedState: state, expectedRound: round,
      );
      if (round == 2) w2 = state;
    }
    final w3 = state;
    expect(w3.nextRound, 4);
    expect(() => a.advancePreseasonWeek(
      expectedState: w2!, expectedRound: 4,
    ), throwsStateError);
    expect(() => a.advancePreseasonWeek(
      expectedState: foreign, expectedRound: 4,
    ), throwsStateError);
    expect(() => a.advancePreseasonWeek(
      expectedState: w3, expectedRound: 5,
    ), throwsStateError);
    expect(() => a.advancePreseasonWeek(
      expectedState: w0, expectedRound: 4,
    ), throwsStateError);
    expect(a.preseasonWeeklyState, same(w3));
    final w4 = a.advancePreseasonWeek(expectedState: w3, expectedRound: 4);
    expect(w4.completedMatchCount, 96);
    expect(() => a.advancePreseasonWeek(
      expectedState: w3, expectedRound: 4,
    ), throwsStateError);
    expect(() => a.advancePreseasonWeek(
      expectedState: w4, expectedRound: 4,
    ), throwsStateError);
    expect(a.preseasonWeeklyState, same(w4));
  });

  test('bad M2 candidate, wrong strengths and unsupported decision fail closed', () {
    final session = app();
    var state = open(session);
    for (var round = 1; round <= 3; round++) {
      state = session.advancePreseasonWeek(
        expectedState: state, expectedRound: round,
      );
    }
    final w3 = state;
    final locked = w3.fixtureSnapshot.fixtures.map(_resultIdentity).toList();
    expect(() => session.advancePreseasonWeek(
      expectedState: w3, expectedRound: 4,
      core: const _UnadvancedCandidateCore(),
    ), throwsStateError);
    expect(session.preseasonWeeklyState, same(w3));
    expect(() => session.advancePreseasonWeek(
      expectedState: w3, expectedRound: 4,
      core: const _WrongStrengthCandidateCore(),
    ), throwsStateError);
    expect(session.preseasonWeeklyState, same(w3));
    expect(() => session.advancePreseasonWeek(
      expectedState: w3, expectedRound: 4, decision: Object(),
    ), throwsUnsupportedError);
    expect(session.preseasonWeeklyState, same(w3));
    expect(w3.fixtureSnapshot.fixtures.map(_resultIdentity).toList(), locked);
    final w4 = session.advancePreseasonWeek(
      expectedState: w3, expectedRound: 4,
    );
    expect(w4.completedMatchCount, 96);
    expect(w3.fixtureSnapshot.fixtures.map(_resultIdentity).toList(), locked);
  });

  test('W19 real MatchEngine exception retains exact W18 and retries once', () {
    final session = app();
    final w0 = open(session);
    var state = w0;
    for (var round = 1; round <= 18; round++) {
      state = session.advancePreseasonWeek(
        expectedState: state, expectedRound: round,
      );
    }
    final w18 = state;
    final locked = w18.fixtureSnapshot.fixtures.map(_resultIdentity).toList();
    final history = w18.fixtureSnapshot.fixtures
        .where((entry) => entry.isPlayed).toList();
    expect(w18.completedMatchCount, 432);
    expect(() => session.advancePreseasonWeek(
      expectedState: w18,
      expectedRound: 19,
      core: const WeeklyWorldFixtureResultCore(
        matchEngine: _FailOnWeekNineteen(),
      ),
    ), throwsStateError);
    expect(session.preseasonWeeklyState, same(w18));
    expect(w18.nextRound, 19);
    expect(w18.fixtureSnapshot.fixtures.map(_resultIdentity).toList(), locked);
    expect(w18.fixtureSnapshot.fixtures.where((entry) => entry.round > 18)
        .every((entry) => !entry.isPlayed), isTrue);
    final w19 = session.advancePreseasonWeek(
      expectedState: w18, expectedRound: 19,
    );
    expect(w19.completedMatchCount, 456);
    expect(w19.nextRound, 20);
    expect(w19.applied, same(w18.applied));
    expect(session.preseasonWeeklyState, same(w19));
    final afterHistory = w19.fixtureSnapshot.fixtures
        .where((entry) => entry.round <= 18).toList();
    expect(afterHistory.length, history.length);
    for (var i = 0; i < history.length; i++) {
      expect(afterHistory[i], same(history[i]));
    }
    expect(w18.fixtureSnapshot.fixtures.map(_resultIdentity).toList(), locked);
    expect(() => session.advancePreseasonWeek(
      expectedState: w18, expectedRound: 19,
    ), throwsStateError);
    expect(session.preseasonWeeklyState, same(w19));
  });
}
