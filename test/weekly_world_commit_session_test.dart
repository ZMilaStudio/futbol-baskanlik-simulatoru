import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 20260903);

  WeeklyWorldCommitSession open() => WeeklyWorldCommitSession.open(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
      );

  WeeklyWorldFixtureSnapshot commit(
    WeeklyWorldCommitSession session, {
    int? round,
    int? seasonIndex,
    List<Club>? clubs,
  }) =>
      session.commitRound(
        expectedSeasonIndex: seasonIndex ?? config.seasonIndex,
        expectedRound: round ?? session.nextRound,
        effectiveClubs: clubs ?? world.clubs,
      );

  List<Object?> results(WeeklyWorldFixtureSnapshot snapshot, {int? round}) => [
        for (final entry in snapshot.fixtures)
          if (round == null || entry.round == round)
            <Object?>[
              entry.globalKey,
              entry.fixture.id,
              entry.fixture.result?.matchSeed,
              entry.fixture.result?.homeGoals,
              entry.fixture.result?.awayGoals,
              entry.fixture.result?.homeExpectedGoals,
              entry.fixture.result?.awayExpectedGoals,
            ],
      ];

  test('W1-W3 advance only once: 24/48/72 and truthful partial tables', () {
    final session = open();
    final opening = session.snapshot;
    expect(session.phase, WeeklyWorldCommitPhase.awaitingRound);
    expect(session.nextRound, 1);
    expect(session.completedMatchCount, 0);
    expect(opening.fixtures.length, 720);
    expect(opening.fixtures.map((entry) => entry.globalKey).toSet().length,
        720);

    for (var round = 1; round <= 3; round++) {
      final committed = commit(session);
      expect(identical(session.snapshot, committed), isTrue);
      expect(session.phase, WeeklyWorldCommitPhase.awaitingRound);
      expect(session.completedRounds, round);
      expect(session.nextRound, round + 1);
      expect(session.completedMatchCount, round * 24);
      expect(committed.fixturesForRound(round).length, 24);
      expect(
        committed.fixtures.where((entry) => entry.round <= round)
            .every((entry) => entry.isPlayed),
        isTrue,
      );
      expect(
        committed.fixtures.where((entry) => entry.round > round)
            .every((entry) => !entry.isPlayed),
        isTrue,
      );
      for (final tier in LeagueTier.values) {
        final played = committed.fixtures.where(
          (entry) => entry.tier == tier && entry.isPlayed,
        );
        expect(played.length, round * 8);
        final table = committed.tableFor(tier);
        expect(table.length, 16);
        expect(table.every((row) => row.played == round), isTrue);
        expect(
          table.fold<int>(0, (sum, row) => sum + row.goalsFor),
          played.fold<int>(
            0,
            (sum, entry) =>
                sum +
                entry.fixture.result!.homeGoals +
                entry.fixture.result!.awayGoals,
          ),
        );
        expect(
          table.fold<int>(0, (sum, row) => sum + row.points),
          played.fold<int>(
            0,
            (sum, entry) => sum +
                (entry.fixture.result!.homeGoals ==
                        entry.fixture.result!.awayGoals
                    ? 2
                    : 3),
          ),
        );
      }
    }
    expect(opening.nextRound, 1);
    expect(opening.completedMatchCount, 0);
    expect(opening.fixtures.every((entry) => !entry.isPlayed), isTrue);
  });

  test('duplicate, stale, wrong season and invalid inputs fail atomically', () {
    final session = open();
    final w1 = commit(session);
    final locked = results(w1);
    expect(
      () => commit(session, round: 1),
      throwsStateError,
    );
    expect(
      () => commit(session, round: 3),
      throwsStateError,
    );
    expect(
      () => commit(session, round: 2, seasonIndex: config.seasonIndex + 1),
      throwsStateError,
    );
    expect(
      () => commit(session, round: 2, clubs: world.clubs.sublist(1)),
      throwsArgumentError,
    );
    expect(session.nextRound, 2);
    expect(session.completedMatchCount, 24);
    expect(identical(session.snapshot, w1), isTrue);
    expect(results(session.snapshot), locked);
    final w2 = commit(session, round: 2);
    expect(w2.completedMatchCount, 48);
    expect(() => commit(session, round: 2), throwsStateError);
    expect(results(w1), locked);
  });

  test('week-two inputs cannot revise committed week-one results', () {
    final ordinary = open();
    final changing = open();
    final ordinaryW1 = commit(ordinary);
    final changedW1 = commit(changing);
    final lockedW1 = results(changedW1, round: 1);
    expect(results(ordinaryW1, round: 1), lockedW1);
    final changedClubs = [
      for (final club in world.clubs)
        club.id == 't1_01' ? club.copyWith(strength: 100) : club,
    ];
    final normalW2 = commit(ordinary);
    final alteredW2 = commit(changing, clubs: changedClubs);
    expect(results(alteredW2, round: 1), lockedW1);
    expect(results(changedW1, round: 1), lockedW1);
    expect(alteredW2.fixtures.where((entry) => entry.round > 2)
        .every((entry) => !entry.isPlayed), isTrue);
    final normalMatch = normalW2.fixturesForRound(2).singleWhere(
      (entry) =>
          entry.fixture.homeClubId == 't1_01' ||
          entry.fixture.awayClubId == 't1_01',
    );
    final alteredMatch = alteredW2.fixturesForRound(2).singleWhere(
      (entry) => entry.globalKey == normalMatch.globalKey,
    );
    expect(alteredMatch.fixture.result!.matchSeed,
        normalMatch.fixture.result!.matchSeed);
    final normalXg = normalMatch.fixture.homeClubId == 't1_01'
        ? normalMatch.fixture.result!.homeExpectedGoals
        : normalMatch.fixture.result!.awayExpectedGoals;
    final changedXg = alteredMatch.fixture.homeClubId == 't1_01'
        ? alteredMatch.fixture.result!.homeExpectedGoals
        : alteredMatch.fixture.result!.awayExpectedGoals;
    expect(changedXg, isNot(normalXg));
    expect(ordinaryW1.completedMatchCount, 24);
    expect(changedW1.completedMatchCount, 24);
  });

  test('same opening and weekly inputs replay deterministically', () {
    final a = open();
    final b = open();
    for (var round = 1; round <= 3; round++) {
      final first = commit(a);
      final second = commit(b);
      expect(results(first), results(second));
      for (final tier in LeagueTier.values) {
        expect(
          first.tableFor(tier).map((row) => row.toJson()).toList(),
          second.tableFor(tier).map((row) => row.toJson()).toList(),
        );
      }
    }
    final before = a.snapshot;
    expect(() => before.fixtures.clear(), throwsUnsupportedError);
    expect(() => before.tableFor(LeagueTier.first).clear(),
        throwsUnsupportedError);
  });

  test('30th round closes session and preserves legacy static parity', () {
    final session = open();
    for (var round = 1; round <= 30; round++) {
      commit(session, round: round);
      expect(session.completedMatchCount, round * 24);
    }
    expect(session.nextRound, 31);
    expect(session.phase, WeeklyWorldCommitPhase.seasonComplete);
    expect(session.completedMatchCount, 720);
    expect(session.snapshot.fixtures.every((entry) => entry.isPlayed), isTrue);
    expect(() => commit(session, round: 30), throwsStateError);
    expect(() => commit(session, round: 31), throwsStateError);
    for (final league in world.leagues) {
      final clubs = [
        for (final id in league.clubIds)
          world.clubs.singleWhere((club) => club.id == id),
      ];
      final legacy = const SeasonEngine().simulate(
        clubs: clubs,
        config: config,
      );
      final weekly = session.snapshot.fixtures
          .where((entry) => entry.tier == league.tier)
          .map((entry) => entry.fixture)
          .toList();
      expect(weekly.length, 240);
      for (var i = 0; i < weekly.length; i++) {
        expect(weekly[i].id, legacy.fixtures[i].id);
        expect(weekly[i].result!.matchSeed, legacy.fixtures[i].result!.matchSeed);
        expect(weekly[i].result!.homeGoals, legacy.fixtures[i].result!.homeGoals);
        expect(weekly[i].result!.awayGoals, legacy.fixtures[i].result!.awayGoals);
        expect(weekly[i].result!.homeExpectedGoals,
            legacy.fixtures[i].result!.homeExpectedGoals);
        expect(weekly[i].result!.awayExpectedGoals,
            legacy.fixtures[i].result!.awayExpectedGoals);
      }
      expect(
        session.snapshot.tableFor(league.tier)
            .map((row) => row.toJson()).toList(),
        legacy.table.map((row) => row.toJson()).toList(),
      );
    }
  });
}
