import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
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
      expect(state.effectiveClubs, same(w0.effectiveClubs));
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
