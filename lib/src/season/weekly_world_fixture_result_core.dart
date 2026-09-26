import '../core/simulation_config.dart';
import '../league/club.dart';
import '../league/fixture.dart';
import '../league/fixture_generator.dart';
import '../league/standing_row.dart';
import '../match/match_engine.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';

/// A fixture in its world-wide league namespace. Legacy fixture IDs remain
/// unchanged because MatchEngine includes them in its established match seed.
class WeeklyWorldFixture {
  const WeeklyWorldFixture({required this.tier, required this.fixture});

  final LeagueTier tier;
  final Fixture fixture;

  int get round => fixture.round;
  bool get isPlayed => fixture.isPlayed;

  /// A fixture ID alone is reused independently by the three leagues.
  String get globalKey =>
      fixture.seasonIndex.toString() +
      ':' +
      tier.level.toString() +
      ':' +
      fixture.id;

  WeeklyWorldFixture withResult(Fixture playedFixture) =>
      WeeklyWorldFixture(tier: tier, fixture: playedFixture);
}

/// An immutable presentation projection. StandingRow itself is mutable and
/// therefore must not escape as an authoritative snapshot value.
class WeeklyStanding {
  WeeklyStanding._(StandingRow row)
      : clubId = row.clubId,
        played = row.played,
        wins = row.wins,
        draws = row.draws,
        losses = row.losses,
        goalsFor = row.goalsFor,
        goalsAgainst = row.goalsAgainst,
        points = row.points;

  final String clubId;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  int get goalDifference => goalsFor - goalsAgainst;

  Map<String, Object> toJson() => {
        'clubId': clubId,
        'played': played,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'goalDifference': goalDifference,
        'points': points,
      };
}

/// Pure in-memory week projection for the three canonical 16-club leagues.
///
/// This is NOT a persisted weekly checkpoint, game-state authority, M73
/// session, or financial/transfer runtime. Callers must not present it as a
/// resumable career until the separately designed M65 contract is implemented.
class WeeklyWorldFixtureSnapshot {
  WeeklyWorldFixtureSnapshot._({
    required this.seasonIndex,
    required this.nextRound,
    required this.totalRounds,
    required List<WeeklyWorldFixture> fixtures,
    required Map<LeagueTier, List<String>> members,
    required SimulationConfig config,
  })  : fixtures = List.unmodifiable(fixtures),
        _members = Map.unmodifiable({
          for (final entry in members.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        }),
        _config = config {
    tables = Map.unmodifiable(
      _tablesFor(this.fixtures, _members).map(
        (tier, rows) => MapEntry(tier, List<WeeklyStanding>.unmodifiable(rows)),
      ),
    );
  }

  final int seasonIndex;
  final int nextRound;
  final int totalRounds;
  final List<WeeklyWorldFixture> fixtures;
  final Map<LeagueTier, List<String>> _members;
  final SimulationConfig _config;
  late final Map<LeagueTier, List<WeeklyStanding>> tables;

  int get completedRounds => nextRound - 1;
  bool get isComplete => nextRound > totalRounds;
  int get completedMatchCount =>
      fixtures.where((entry) => entry.isPlayed).length;

  List<WeeklyWorldFixture> fixturesForRound(int round) {
    if (round < 1 || round > totalRounds) {
      throw RangeError.range(round, 1, totalRounds, 'round');
    }
    return List.unmodifiable(
      fixtures.where((entry) => entry.round == round),
    );
  }

  List<WeeklyStanding> tableFor(LeagueTier tier) => tables[tier]!;

  static Map<LeagueTier, List<WeeklyStanding>> _tablesFor(
    List<WeeklyWorldFixture> fixtures,
    Map<LeagueTier, List<String>> members,
  ) {
    final standings = {
      for (final entry in members.entries)
        entry.key: {
          for (final clubId in entry.value)
            clubId: StandingRow(clubId: clubId),
        },
    };
    for (final entry in fixtures) {
      final fixture = entry.fixture;
      final result = fixture.result;
      if (result == null) continue;
      final rows = standings[entry.tier]!;
      rows[fixture.homeClubId]!.record(
        scored: result.homeGoals,
        conceded: result.awayGoals,
      );
      rows[fixture.awayClubId]!.record(
        scored: result.awayGoals,
        conceded: result.homeGoals,
      );
    }

    return {
      for (final entry in standings.entries)
        entry.key: (entry.value.values.toList()
              ..sort((a, b) {
                var cmp = b.points.compareTo(a.points);
                if (cmp != 0) return cmp;
                cmp = b.goalDifference.compareTo(a.goalDifference);
                if (cmp != 0) return cmp;
                cmp = b.goalsFor.compareTo(a.goalsFor);
                if (cmp != 0) return cmp;
                cmp = b.wins.compareTo(a.wins);
                if (cmp != 0) return cmp;
                return a.clubId.compareTo(b.clubId);
              }))
            .map(WeeklyStanding._)
            .toList(growable: false),
    };
  }
}

/// A first, deliberately non-persistent seam for computing only one league
/// round at a time. Existing full-season engines and save codecs are untouched.
class WeeklyWorldFixtureResultCore {
  const WeeklyWorldFixtureResultCore({
    this.fixtureGenerator = const FixtureGenerator(),
    this.matchEngine = const MatchEngine(),
  });

  final FixtureGenerator fixtureGenerator;
  final MatchEngine matchEngine;

  WeeklyWorldFixtureSnapshot prepare({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
  }) {
    if (clubs.length != 48 || leagues.length != LeagueTier.values.length) {
      throw ArgumentError('Weekly world requires 48 clubs in three leagues.');
    }
    final clubsById = {for (final club in clubs) club.id: club};
    if (clubsById.length != 48 || clubsById.containsKey('')) {
      throw ArgumentError('Weekly world club IDs must be unique and nonempty.');
    }
    final leaguesByTier = {for (final league in leagues) league.tier: league};
    if (leaguesByTier.length != LeagueTier.values.length) {
      throw ArgumentError('Weekly world league tiers must be unique.');
    }

    final allMembers = <String>{};
    final members = <LeagueTier, List<String>>{};
    final fixtures = <WeeklyWorldFixture>[];
    final globalKeys = <String>{};

    for (final tier in LeagueTier.values) {
      final ids = leaguesByTier[tier]!.clubIds;
      if (ids.length != 16 ||
          ids.toSet().length != 16 ||
          ids.any((id) => !clubsById.containsKey(id))) {
        throw ArgumentError('Each weekly league requires 16 distinct clubs.');
      }
      for (final id in ids) {
        if (!allMembers.add(id)) {
          throw ArgumentError('A club cannot appear in multiple leagues.');
        }
      }
      members[tier] = List.unmodifiable(ids);
      final leagueFixtures = fixtureGenerator.generateDoubleRoundRobin(
        clubs: ids.map((id) => clubsById[id]!).toList(growable: false),
        seasonIndex: config.seasonIndex,
      );
      if (leagueFixtures.length != 240) {
        throw StateError('Each canonical league requires 240 fixtures.');
      }
      for (final fixture in leagueFixtures) {
        final entry = WeeklyWorldFixture(tier: tier, fixture: fixture);
        if (!globalKeys.add(entry.globalKey) || fixture.isPlayed) {
          throw StateError('Weekly plan requires unique, unplayed fixtures.');
        }
        fixtures.add(entry);
      }
    }
    if (allMembers.length != 48 ||
        !allMembers.containsAll(clubsById.keys) ||
        fixtures.length != 720) {
      throw StateError('Incomplete canonical weekly world.');
    }
    for (var round = 1; round <= 30; round++) {
      final current = fixtures.where((entry) => entry.round == round).toList();
      if (current.length != 24) {
        throw StateError('Each world round requires exactly 24 fixtures.');
      }
      for (final tier in LeagueTier.values) {
        final leagueRound = current.where((entry) => entry.tier == tier).toList();
        final participants = <String>{};
        for (final entry in leagueRound) {
          participants
            ..add(entry.fixture.homeClubId)
            ..add(entry.fixture.awayClubId);
        }
        if (leagueRound.length != 8 || participants.length != 16) {
          throw StateError('Each club must appear once per league round.');
        }
      }
    }

    return WeeklyWorldFixtureSnapshot._(
      seasonIndex: config.seasonIndex,
      nextRound: 1,
      totalRounds: 30,
      fixtures: fixtures,
      members: members,
      config: config,
    );
  }

  /// Simulates only expectedRound. Earlier results are never recalculated;
  /// effectiveClubs can reflect decisions made since the preceding round.
  ///
  /// The stale-round guard is local to this pure API, not a persistence or
  /// transaction-idempotency guarantee. That belongs to the later M65 seam.
  WeeklyWorldFixtureSnapshot advanceRound({
    required WeeklyWorldFixtureSnapshot snapshot,
    required int expectedRound,
    required List<Club> effectiveClubs,
  }) {
    if (snapshot.isComplete || expectedRound != snapshot.nextRound) {
      throw StateError('Weekly round is complete or request is stale.');
    }
    final byId = {for (final club in effectiveClubs) club.id: club};
    final plannedIds = snapshot._members.values.expand((ids) => ids).toSet();
    if (byId.length != plannedIds.length ||
        effectiveClubs.length != plannedIds.length ||
        !byId.keys.toSet().containsAll(plannedIds)) {
      throw ArgumentError('Effective clubs must match the prepared world.');
    }
    var playedThisRound = 0;
    final nextFixtures = <WeeklyWorldFixture>[];
    for (final entry in snapshot.fixtures) {
      if (entry.round != expectedRound) {
        nextFixtures.add(entry);
        continue;
      }
      if (entry.isPlayed) {
        throw StateError('A committed fixture cannot be simulated again.');
      }
      final fixture = entry.fixture;
      final result = matchEngine.simulate(
        fixture: fixture,
        home: byId[fixture.homeClubId]!,
        away: byId[fixture.awayClubId]!,
        config: snapshot._config,
      );
      nextFixtures.add(entry.withResult(fixture.withResult(result)));
      playedThisRound++;
    }
    if (playedThisRound != 24) {
      throw StateError('A world round must commit exactly 24 matches.');
    }
    return WeeklyWorldFixtureSnapshot._(
      seasonIndex: snapshot.seasonIndex,
      nextRound: expectedRound + 1,
      totalRounds: snapshot.totalRounds,
      fixtures: nextFixtures,
      members: snapshot._members,
      config: snapshot._config,
    );
  }
}
