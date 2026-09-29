import '../league/club.dart';
import '../league/standing_row.dart';
import '../match/match_engine.dart';
import '../promise/president_promise.dart';
import '../player/team_strength_calculator.dart';
import '../season/weekly_world_fixture_result_core.dart';
import '../world/league_tier.dart';
import 'player_president_interactive_decision_session.dart';

/// Immutable, runtime-only observation. The application owns publication.
class PlayerPresidentPreseasonWeeklyState {
  PlayerPresidentPreseasonWeeklyState._(
    this.boundary, this.applied, this.fixtureSnapshot, Iterable<Club> clubs,
  ) : effectiveClubs = List<Club>.unmodifiable(clubs);

  final PlayerPresidentPreseasonPromiseBoundary boundary;
  final PlayerPresidentPreseasonPromiseApplied applied;
  final WeeklyWorldFixtureSnapshot fixtureSnapshot;
  final List<Club> effectiveClubs;
  String get sourceIdentity => applied.sourceIdentity;
  int get nextRound => fixtureSnapshot.nextRound;
  int get completedMatchCount => fixtureSnapshot.completedMatchCount;
  List<PresidentPromise> get activePromises => applied.activePromises;

  static PlayerPresidentPreseasonWeeklyState opening(
    PlayerPresidentPreseasonPromiseBoundary boundary,
  ) {
    final proof = boundary.proof;
    final applied = boundary.applied;
    if (!identical(boundary.application.preseasonPromiseBoundary, boundary) ||
        applied == null ||
        !identical(boundary.application.appliedPreseasonPromises, applied) ||
        applied.seasonIndex != 0 ||
        applied.sourceIdentity != proof.seasonOpening.originSourceDigest ||
        applied.controlledClubId != proof.controlledClubId ||
        applied.controlledPresidentId != proof.presidentOpening.controlledPresidentId ||
        applied.activePromises.length != 48 ||
        applied.activePromises.map((p) => p.clubId).toSet().length != 48 ||
        applied.activePromises.map((p) => p.id).toSet().length != 48 ||
        applied.activePromises.any((p) => p.seasonIndex != 0 ||
          p.id != 'promise_${p.clubId}_s0') ||
        !identical(applied.consequence.promise,
          applied.activePromises.singleWhere((p) => p.clubId == applied.controlledClubId))) {
      throw StateError('W0 requires the exact applied 48-promise boundary.');
    }
    proof.seasonOpening.assertOpeningProjectionMatches(boundary.opening);
    final clubs = const TeamStrengthCalculator().deriveClubs(
      baseClubs: boundary.opening.baseClubs, players: boundary.opening.players,
    );
    final snapshot = proof.seasonOpening.fixtureSnapshot;
    if (clubs.length != 48 || clubs.map((c) => c.id).toSet().length != 48 ||
        !clubs.map((c) => c.id).toSet().containsAll(applied.activePromises.map((p) => p.clubId)) ||
        snapshot.seasonIndex != 0 || snapshot.totalRounds != 30 ||
        snapshot.nextRound != 1 || snapshot.completedMatchCount != 0 ||
        snapshot.fixtures.length != 720 ||
        snapshot.fixtures.map((f) => f.globalKey).toSet().length != 720 ||
        snapshot.fixtures.any((f) => f.isPlayed) ||
        snapshot.tables.length != 3 ||
        snapshot.tables.values.any((v) => v.length != 16 || v.any((s) => s.played != 0))) {
      throw StateError('W0 must reuse the pristine P1/M2 opening.');
    }
    return PlayerPresidentPreseasonWeeklyState._(boundary, applied, snapshot, clubs);
  }

  /// Detached M2 calculation; never mutates any application state.
  static PlayerPresidentPreseasonWeeklyState successor({
    required PlayerPresidentPreseasonWeeklyState current,
    required int expectedRound,
    WeeklyWorldFixtureResultCore core = const WeeklyWorldFixtureResultCore(),
  }) {
    final boundary = current.boundary;
    if (!identical(boundary.application.preseasonPromiseBoundary, boundary) ||
        !identical(boundary.application.appliedPreseasonPromises, current.applied) ||
        current.sourceIdentity != boundary.proof.seasonOpening.originSourceDigest ||
        current.fixtureSnapshot.seasonIndex != 0 ||
        expectedRound < 1 || expectedRound > 3 ||
        expectedRound != current.nextRound ||
        current.completedMatchCount != (expectedRound - 1) * 24) {
      throw StateError('Stale or foreign W1-W3 predecessor.');
    }
    final candidate = core.advanceRound(
      snapshot: current.fixtureSnapshot, expectedRound: expectedRound,
      effectiveClubs: current.effectiveClubs,
    );
    _check(current, candidate, expectedRound);
    return PlayerPresidentPreseasonWeeklyState._(
      boundary, current.applied, candidate, current.effectiveClubs,
    );
  }

  static void _check(PlayerPresidentPreseasonWeeklyState current,
      WeeklyWorldFixtureSnapshot next, int round) {
    final prev = current.fixtureSnapshot;
    final plan = current.boundary.proof.seasonOpening.fixtureSnapshot;
    final byId = {for (final c in current.effectiveClubs) c.id: c};
    if (byId.length != 48 || next.seasonIndex != 0 ||
        next.totalRounds != 30 || next.nextRound != round + 1 ||
        next.completedMatchCount != round * 24 ||
        next.fixtures.length != 720 ||
        next.fixturesForRound(round).length != 24 ||
        next.fixtures.map((f) => f.globalKey).toSet().length != 720 ||
        !identical(current.boundary.applied, current.applied)) {
      throw StateError('Invalid detached M2 successor.');
    }
    var newResults = 0;
    for (var i = 0; i < 720; i++) {
      final a = prev.fixtures[i];
      final b = next.fixtures[i];
      final p = plan.fixtures[i];
      if (a.globalKey != b.globalKey || b.globalKey != p.globalKey ||
          a.tier != b.tier || a.fixture.id != b.fixture.id ||
          a.fixture.round != b.round ||
          a.fixture.homeClubId != b.fixture.homeClubId ||
          a.fixture.awayClubId != b.fixture.awayClubId ||
          b.fixture.id != p.fixture.id || b.round != p.round ||
          b.fixture.homeClubId != p.fixture.homeClubId ||
          b.fixture.awayClubId != p.fixture.awayClubId) {
        throw StateError('Canonical fixture identity changed.');
      }
      if (b.round < round) {
        if (!identical(a, b) || !b.isPlayed) {
          throw StateError('Committed history changed.');
        }
      } else if (b.round > round) {
        if (!identical(a, b) || b.isPlayed) {
          throw StateError('Future results must remain empty.');
        }
      } else {
        if (a.isPlayed || !b.isPlayed) {
          throw StateError('This round must play exactly once.');
        }
        final result = b.fixture.result!;
        final actual = const MatchEngine().simulate(
          fixture: a.fixture,
          home: byId[a.fixture.homeClubId]!,
          away: byId[a.fixture.awayClubId]!,
          config: current.boundary.proof.seasonOpening.config,
        );
        if (result.matchSeed != actual.matchSeed ||
            result.homeGoals != actual.homeGoals ||
            result.awayGoals != actual.awayGoals ||
            result.homeExpectedGoals != actual.homeExpectedGoals ||
            result.awayExpectedGoals != actual.awayExpectedGoals) {
          throw StateError('Real MatchEngine score/xG/seed mismatch.');
        }
        newResults++;
      }
    }
    if (newResults != 24) throw StateError('World round requires 24 matches.');
    for (final tier in LeagueTier.values) {
      final ids = current.boundary.opening.leagues
          .singleWhere((l) => l.tier == tier).clubIds;
      final rows = {for (final id in ids) id: StandingRow(clubId: id)};
      final played = next.fixtures.where((f) => f.tier == tier && f.isPlayed);
      if (ids.length != 16 || rows.length != 16 ||
          played.length != round * 8 ||
          next.fixturesForRound(round).where((f) => f.tier == tier && f.isPlayed).length != 8) {
        throw StateError('Wrong league match count.');
      }
      for (final f in played) {
        final m = f.fixture.result!;
        rows[f.fixture.homeClubId]!.record(
          scored: m.homeGoals, conceded: m.awayGoals);
        rows[f.fixture.awayClubId]!.record(
          scored: m.awayGoals, conceded: m.homeGoals);
      }
      final expected = rows.values.toList()
        ..sort((a,b) {
          var c = b.points.compareTo(a.points);
          if (c != 0) return c;
          c = b.goalDifference.compareTo(a.goalDifference);
          if (c != 0) return c;
          c = b.goalsFor.compareTo(a.goalsFor);
          if (c != 0) return c;
          c = b.wins.compareTo(a.wins);
          return c != 0 ? c : a.clubId.compareTo(b.clubId);
        });
      final table = next.tableFor(tier);
      if (table.length != 16) throw StateError('Invalid table size.');
      for (var i = 0; i < 16; i++) {
        final a = expected[i];
        final b = table[i];
        if (b.clubId != a.clubId || b.played != round ||
            b.played != a.played || b.wins != a.wins ||
            b.draws != a.draws || b.losses != a.losses ||
            b.goalsFor != a.goalsFor || b.goalsAgainst != a.goalsAgainst ||
            b.points != a.points) {
          throw StateError('Partial table differs from committed scores.');
        }
      }
    }
  }
}
