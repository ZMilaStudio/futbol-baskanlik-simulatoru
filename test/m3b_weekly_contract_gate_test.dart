import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('FBS-03 boundary: M2 cursor/phase and past/future truth remain aligned', () {
    const config = SimulationConfig(careerSeed: 20260903);
    final world = const FictionalWorldFactory().build();
    final session = WeeklyWorldCommitSession.open(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    expect(session.phase, WeeklyWorldCommitPhase.awaitingRound);
    expect(session.nextRound, 1);
    final originalKeys = session.snapshot.fixtures
        .map((entry) => entry.globalKey)
        .toList(growable: false);
    expect(originalKeys.toSet().length, 720);
    final locked = <WeeklyWorldFixtureSnapshot>[];
    for (var round = 1; round <= 3; round++) {
      final current = session.commitRound(
        expectedSeasonIndex: config.seasonIndex,
        expectedRound: round,
        effectiveClubs: world.clubs,
      );
      locked.add(current);
      expect(session.nextRound, round + 1);
      expect(session.completedMatchCount, round * 24);
      expect(session.phase, WeeklyWorldCommitPhase.awaitingRound);
      expect(current.fixtures.map((entry) => entry.globalKey).toList(),
          originalKeys);
      expect(
        current.fixtures.where((entry) => entry.round <= round)
            .every((entry) => entry.isPlayed),
        isTrue,
      );
      expect(
        current.fixtures.where((entry) => entry.round > round)
            .every((entry) => !entry.isPlayed),
        isTrue,
      );
      for (final tier in LeagueTier.values) {
        expect(current.tableFor(tier).every((row) => row.played == round),
            isTrue);
      }
      expect(
        () => session.commitRound(
          expectedSeasonIndex: config.seasonIndex,
          expectedRound: round,
          effectiveClubs: world.clubs,
        ),
        throwsStateError,
      );
      expect(identical(current, session.snapshot), isTrue);
    }
    expect(locked[0].completedMatchCount, 24);
    expect(locked[1].completedMatchCount, 48);
    expect(locked[2].completedMatchCount, 72);
    expect(locked[0].fixtures.where((entry) => entry.round > 1)
        .every((entry) => !entry.isPlayed), isTrue);

    for (var round = 4; round <= 30; round++) {
      session.commitRound(
        expectedSeasonIndex: config.seasonIndex,
        expectedRound: round,
        effectiveClubs: world.clubs,
      );
    }
    expect(session.nextRound, 31);
    expect(session.completedMatchCount, 720);
    expect(session.phase, WeeklyWorldCommitPhase.seasonComplete);
    expect(() => session.commitRound(
        expectedSeasonIndex: config.seasonIndex,
        expectedRound: 31,
        effectiveClubs: world.clubs,
      ), throwsStateError);
    // This is only an in-memory M2 boundary, not a completed M65 career save.
  });
}
