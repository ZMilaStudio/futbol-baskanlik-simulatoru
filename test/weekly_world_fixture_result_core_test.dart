import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  final world = const FictionalWorldFactory().build();
  const core = WeeklyWorldFixtureResultCore();
  const config = SimulationConfig(careerSeed: 20260903);

  WeeklyWorldFixtureSnapshot start() => core.prepare(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
      );

  WeeklyWorldFixtureSnapshot play(
    WeeklyWorldFixtureSnapshot snapshot, {
    List<Club>? clubs,
  }) =>
      core.advanceRound(
        snapshot: snapshot,
        expectedRound: snapshot.nextRound,
        effectiveClubs: clubs ?? world.clubs,
      );

  test('canonical plan qualifies reused fixture IDs with league identity', () {
    final initial = start();
    expect(initial.nextRound, 1);
    expect(initial.totalRounds, 30);
    expect(initial.fixtures.length, 720);
    expect(initial.completedMatchCount, 0);
    expect(initial.fixtures.every((entry) => !entry.isPlayed), isTrue);
    expect(initial.fixtures.map((entry) => entry.fixture.id).toSet().length, 240);
    expect(initial.fixtures.map((entry) => entry.globalKey).toSet().length, 720);
    for (final tier in LeagueTier.values) {
      expect(initial.fixtures.where((entry) => entry.tier == tier).length, 240);
      expect(initial.tableFor(tier).length, 16);
      expect(initial.tableFor(tier).every((row) => row.played == 0), isTrue);
    }
    for (var round = 1; round <= 30; round++) {
      final entries = initial.fixturesForRound(round);
      expect(entries.length, 24);
      for (final league in world.leagues) {
        final inLeague = entries.where((entry) => entry.tier == league.tier);
        final clubIds = inLeague
            .expand((entry) => [
                  entry.fixture.homeClubId,
                  entry.fixture.awayClubId,
                ])
            .toList();
        expect(clubIds.length, 16);
        expect(clubIds.toSet(), league.clubIds.toSet());
      }
    }
    expect(() => initial.fixtures.clear(), throwsUnsupportedError);
    expect(
      () => initial.tableFor(LeagueTier.first).clear(),
      throwsUnsupportedError,
    );
  });

  test('W1-W3 commit 24/48/72 real results with no future scores', () {
    var snapshot = start();
    final opening = snapshot;
    for (var round = 1; round <= 3; round++) {
      snapshot = play(snapshot);
      expect(snapshot.completedRounds, round);
      expect(snapshot.nextRound, round + 1);
      expect(snapshot.completedMatchCount, round * 24);
      expect(
        snapshot.fixtures.where((entry) => entry.round <= round)
            .every((entry) => entry.isPlayed),
        isTrue,
      );
      expect(
        snapshot.fixtures.where((entry) => entry.round > round)
            .every((entry) => !entry.isPlayed),
        isTrue,
      );
      for (final tier in LeagueTier.values) {
        expect(
          snapshot.tableFor(tier).every((row) => row.played == round),
          isTrue,
        );
      }
      final controlled = snapshot.fixturesForRound(round).where(
        (entry) =>
            entry.fixture.homeClubId == 't1_01' ||
            entry.fixture.awayClubId == 't1_01',
      );
      expect(controlled.length, 1);
      expect(controlled.single.fixture.result, isNotNull);
    }
    expect(opening.completedMatchCount, 0);
    expect(opening.nextRound, 1);
  });

  test('same inputs replay exactly and committed past survives future changes', () {
    final initial = start();
    final first = play(initial);
    final repeat = play(start());
    expect(
      first.fixtures.map((entry) => entry.fixture.result?.matchSeed).toList(),
      repeat.fixtures.map((entry) => entry.fixture.result?.matchSeed).toList(),
    );
    expect(
      first.fixtures.map((entry) => entry.fixture.result?.homeGoals).toList(),
      repeat.fixtures.map((entry) => entry.fixture.result?.homeGoals).toList(),
    );
    final changedClubs = [
      for (final club in world.clubs)
        club.id == 't1_01' ? club.copyWith(strength: 120) : club,
    ];
    final ordinaryWeek2 = play(first);
    final modifiedWeek2 = play(first, clubs: changedClubs);
    final firstPast = first.fixturesForRound(1);
    expect(
      modifiedWeek2.fixturesForRound(1)
          .map((entry) => entry.fixture.result?.matchSeed).toList(),
      firstPast.map((entry) => entry.fixture.result?.matchSeed).toList(),
    );
    expect(
      modifiedWeek2.fixturesForRound(1)
          .map((entry) => entry.fixture.result?.homeGoals).toList(),
      firstPast.map((entry) => entry.fixture.result?.homeGoals).toList(),
    );
    final ordinaryMatch = ordinaryWeek2.fixturesForRound(2).singleWhere(
      (entry) =>
          entry.fixture.homeClubId == 't1_01' ||
          entry.fixture.awayClubId == 't1_01',
    );
    final alteredMatch = modifiedWeek2.fixturesForRound(2).singleWhere(
      (entry) => entry.globalKey == ordinaryMatch.globalKey,
    );
    expect(
      alteredMatch.fixture.result!.matchSeed,
      ordinaryMatch.fixture.result!.matchSeed,
    );
    final oldExpectation = ordinaryMatch.fixture.homeClubId == 't1_01'
        ? ordinaryMatch.fixture.result!.homeExpectedGoals
        : ordinaryMatch.fixture.result!.awayExpectedGoals;
    final newExpectation = alteredMatch.fixture.homeClubId == 't1_01'
        ? alteredMatch.fixture.result!.homeExpectedGoals
        : alteredMatch.fixture.result!.awayExpectedGoals;
    expect(newExpectation, isNot(equals(oldExpectation)));
    expect(first.completedMatchCount, 24);
  });

  test('full 30-round static run retains legacy match and standing parity', () {
    var snapshot = start();
    while (!snapshot.isComplete) {
      snapshot = play(snapshot);
    }
    expect(snapshot.nextRound, 31);
    expect(snapshot.completedMatchCount, 720);
    expect(snapshot.fixtures.every((entry) => entry.isPlayed), isTrue);
    for (final league in world.leagues) {
      final leagueClubs = league.clubIds.map(
        (id) => world.clubs.singleWhere((club) => club.id == id),
      ).toList();
      final legacy = const SeasonEngine().simulate(
        clubs: leagueClubs,
        config: config,
      );
      final weekly = snapshot.fixtures
          .where((entry) => entry.tier == league.tier)
          .map((entry) => entry.fixture)
          .toList();
      expect(weekly.map((fixture) => fixture.id).toList(),
          legacy.fixtures.map((fixture) => fixture.id).toList());
      for (var i = 0; i < weekly.length; i++) {
        final actual = weekly[i].result!;
        final old = legacy.fixtures[i].result!;
        expect(actual.matchSeed, old.matchSeed);
        expect(actual.homeGoals, old.homeGoals);
        expect(actual.awayGoals, old.awayGoals);
        expect(actual.homeExpectedGoals, old.homeExpectedGoals);
        expect(actual.awayExpectedGoals, old.awayExpectedGoals);
      }
      expect(
        snapshot.tableFor(league.tier).map((row) => row.toJson()).toList(),
        legacy.table.map((row) => row.toJson()).toList(),
      );
    }
    expect(
      () => play(snapshot),
      throwsStateError,
    );
  });

  test('invalid world and stale round fail without modifying input', () {
    final initial = start();
    expect(
      () => core.advanceRound(
        snapshot: initial,
        expectedRound: 2,
        effectiveClubs: world.clubs,
      ),
      throwsStateError,
    );
    expect(
      () => core.advanceRound(
        snapshot: initial,
        expectedRound: 1,
        effectiveClubs: world.clubs.sublist(1),
      ),
      throwsArgumentError,
    );
    final badMembership = [
      for (final league in world.leagues)
        league.tier == LeagueTier.second
            ? WorldLeague(
                tier: league.tier,
                clubIds: ['t1_01', ...league.clubIds.skip(1)],
              )
            : league,
    ];
    expect(
      () => core.prepare(
        clubs: world.clubs,
        leagues: badMembership,
        config: config,
      ),
      throwsArgumentError,
    );
    expect(initial.completedMatchCount, 0);
    expect(initial.nextRound, 1);
  });
}
