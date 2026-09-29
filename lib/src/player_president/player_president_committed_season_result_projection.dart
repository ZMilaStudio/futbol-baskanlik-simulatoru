import '../core/stable_hash.dart';
import '../league/fixture.dart';
import '../league/standing_row.dart';
import '../promise/president_promise.dart';
import '../season/season_report.dart';
import '../season/season_validator.dart';
import '../world/league_tier.dart';
import '../world/world_career_season.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_preseason_weekly_handoff.dart';

/// B1 projects ONLY the already committed M2 season. It never simulates a match,
/// creates a fixture plan, settles finance or produces a completed career.
class PlayerPresidentCommittedSeasonResultProjection {
  const PlayerPresidentCommittedSeasonResultProjection();

  PlayerPresidentCommittedSeasonResultCandidate project({
    required PlayerPresidentPreseasonWeeklyState state,
  }) {
    final boundary = state.boundary;
    final application = boundary.application;
    final applied = state.applied;
    final proof = boundary.proof;
    final opening = proof.seasonOpening;
    final snapshot = state.fixtureSnapshot;
    final plan = opening.fixtureSnapshot;
    final config = opening.config;

    if (!identical(application.preseasonPromiseBoundary, boundary) ||
        !identical(application.preseasonWeeklyState, state) ||
        !identical(application.appliedPreseasonPromises, applied) ||
        !identical(boundary.applied, applied) ||
        boundary.phase != PlayerPresidentPreseasonPromisePhase.applied ||
        !identical(state.activePromises, applied.activePromises) ||
        state.sourceIdentity != opening.originSourceDigest ||
        applied.sourceIdentity != opening.originSourceDigest ||
        applied.seasonIndex != opening.seasonIndex ||
        applied.controlledClubId != proof.controlledClubId ||
        applied.controlledPresidentId !=
            proof.presidentOpening.controlledPresidentId ||
        boundary.controlledPresidentId != applied.controlledPresidentId ||
        !identical(
          applied.consequence.promise,
          applied.activePromises.singleWhere(
            (promise) => promise.clubId == applied.controlledClubId,
            orElse: () => throw StateError('Missing accepted controlled promise.'),
          ),
        ) ||
        config.seasonIndex != opening.seasonIndex ||
        snapshot.seasonIndex != opening.seasonIndex ||
        plan.seasonIndex != opening.seasonIndex ||
        snapshot.totalRounds != 30 ||
        plan.totalRounds != 30 ||
        snapshot.nextRound != 31 ||
        !snapshot.isComplete ||
        snapshot.completedMatchCount != 720 ||
        plan.nextRound != 1 ||
        plan.completedMatchCount != 0 ||
        snapshot.fixtures.length != 720 ||
        plan.fixtures.length != 720) {
      throw StateError('B1 requires the exact owned, committed W30 boundary.');
    }
    opening.assertOpeningProjectionMatches(boundary.opening);

    final memberships = <LeagueTier, List<String>>{};
    final seenClubs = <String>{};
    if (LeagueTier.values.length != 3 || boundary.opening.leagues.length != 3 ||
        state.effectiveClubs.length != 48 ||
        state.effectiveClubs.map((club) => club.id).toSet().length != 48 ||
        applied.activePromises.length != 48 ||
        applied.activePromises.map((promise) => promise.id).toSet().length != 48 ||
        applied.activePromises.map((promise) => promise.clubId).toSet().length != 48) {
      throw StateError('B1 canonical club/promise coverage mismatch.');
    }
    for (final tier in LeagueTier.values) {
      final leagues = boundary.opening.leagues.where((league) => league.tier == tier).toList();
      if (leagues.length != 1) throw StateError('B1 missing or duplicate league.');
      final ids = leagues.single.clubIds;
      if (ids.length != 16 || ids.toSet().length != 16 ||
          ids.any((id) => id.isEmpty || !seenClubs.add(id))) {
        throw StateError('B1 invalid ordered league membership.');
      }
      memberships[tier] = ids;
    }
    final effectiveById = {for (final club in state.effectiveClubs) club.id: club};
    final acceptedById = {for (final promise in applied.activePromises) promise.clubId: promise};
    if (seenClubs.length != 48 ||
        !effectiveById.keys.toSet().containsAll(seenClubs) ||
        !acceptedById.keys.toSet().containsAll(seenClubs) ||
        acceptedById.values.any((promise) =>
            promise.seasonIndex != opening.seasonIndex ||
            promise.id != 'promise_' + promise.clubId + '_s' + opening.seasonIndex.toString())) {
      throw StateError('B1 opening effective clubs or accepted promises diverged.');
    }

    final keys = <String>{};
    final fixturesByTier = <LeagueTier, List<Fixture>>{
      for (final tier in LeagueTier.values) tier: <Fixture>[],
    };
    final roundCount = <int, int>{};
    final tierRoundCount = <LeagueTier, Map<int, int>>{
      for (final tier in LeagueTier.values) tier: <int, int>{},
    };
    final clubRoundCount = <LeagueTier, Map<int, Set<String>>>{
      for (final tier in LeagueTier.values) tier: <int, Set<String>>{},
    };
    final clubCount = <String, int>{};
    final homeCount = <String, int>{};
    final awayCount = <String, int>{};
    for (var i = 0; i < 720; i++) {
      final entry = snapshot.fixtures[i];
      final source = plan.fixtures[i];
      final fixture = entry.fixture;
      final planned = source.fixture;
      final members = memberships[entry.tier];
      final result = fixture.result;
      final expectedKey = fixture.seasonIndex.toString() + ':' +
          entry.tier.level.toString() + ':' + fixture.id;
      if (members == null || !keys.add(entry.globalKey) ||
          entry.globalKey != expectedKey || entry.globalKey != source.globalKey ||
          entry.tier != source.tier || fixture.id.isEmpty ||
          fixture.id != planned.id || fixture.seasonIndex != planned.seasonIndex ||
          fixture.round != planned.round || fixture.homeClubId != planned.homeClubId ||
          fixture.awayClubId != planned.awayClubId ||
          fixture.seasonIndex != opening.seasonIndex ||
          fixture.round < 1 || fixture.round > 30 || source.isPlayed ||
          fixture.homeClubId == fixture.awayClubId ||
          !members.contains(fixture.homeClubId) || !members.contains(fixture.awayClubId) ||
          result == null || !entry.isPlayed ||
          result.homeGoals < 0 || result.awayGoals < 0 ||
          !result.homeExpectedGoals.isFinite || !result.awayExpectedGoals.isFinite ||
          result.homeExpectedGoals < config.minExpectedGoals ||
          result.homeExpectedGoals > config.maxExpectedGoals ||
          result.awayExpectedGoals < config.minExpectedGoals ||
          result.awayExpectedGoals > config.maxExpectedGoals ||
          result.matchSeed != StableHash.combine32([
            config.careerSeed, config.seasonIndex, config.simulationVersion,
            StableHash.string32(fixture.id),
          ])) {
        throw StateError('B1 committed fixture identity/result mismatch.');
      }
      fixturesByTier[entry.tier]!.add(fixture);
      roundCount.update(fixture.round, (count) => count + 1, ifAbsent: () => 1);
      tierRoundCount[entry.tier]!.update(fixture.round,
          (count) => count + 1, ifAbsent: () => 1);
      final participants = clubRoundCount[entry.tier]!
          .putIfAbsent(fixture.round, () => <String>{});
      if (!participants.add(fixture.homeClubId) ||
          !participants.add(fixture.awayClubId)) {
        throw StateError('B1 club appears twice in the same round.');
      }
      clubCount.update(fixture.homeClubId, (count) => count + 1, ifAbsent: () => 1);
      clubCount.update(fixture.awayClubId, (count) => count + 1, ifAbsent: () => 1);
      homeCount.update(fixture.homeClubId, (count) => count + 1, ifAbsent: () => 1);
      awayCount.update(fixture.awayClubId, (count) => count + 1, ifAbsent: () => 1);
    }
    if (keys.length != 720 || roundCount.length != 30 ||
        clubCount.length != 48 ||
        roundCount.values.any((count) => count != 24) ||
        seenClubs.any((id) => clubCount[id] != 30 ||
            homeCount[id] != 15 || awayCount[id] != 15)) {
      throw StateError('B1 incomplete committed world.');
    }

    final values = <_LeagueResultValue>[];
    for (final tier in LeagueTier.values) {
      final fixtures = fixturesByTier[tier]!;
      final ids = memberships[tier]!;
      if (fixtures.length != 240 || tierRoundCount[tier]!.length != 30 ||
          tierRoundCount[tier]!.values.any((count) => count != 8) ||
          clubRoundCount[tier]!.length != 30 ||
          clubRoundCount[tier]!.values.any((idsInRound) =>
              idsInRound.length != 16 || !idsInRound.containsAll(ids))) {
        throw StateError('B1 incomplete committed league.');
      }
      final rows = {for (final id in ids) id: StandingRow(clubId: id)};
      var homeWins = 0;
      var draws = 0;
      var awayWins = 0;
      var totalGoals = 0;
      for (final fixture in fixtures) {
        final result = fixture.result!;
        rows[fixture.homeClubId]!.record(
          scored: result.homeGoals, conceded: result.awayGoals,
        );
        rows[fixture.awayClubId]!.record(
          scored: result.awayGoals, conceded: result.homeGoals,
        );
        totalGoals += result.homeGoals + result.awayGoals;
        if (result.homeGoals > result.awayGoals) {
          homeWins++;
        } else if (result.homeGoals == result.awayGoals) {
          draws++;
        } else {
          awayWins++;
        }
      }
      final ranked = rows.values.toList()
        ..sort((a, b) {
          var difference = b.points.compareTo(a.points);
          if (difference != 0) return difference;
          difference = b.goalDifference.compareTo(a.goalDifference);
          if (difference != 0) return difference;
          difference = b.goalsFor.compareTo(a.goalsFor);
          if (difference != 0) return difference;
          difference = b.wins.compareTo(a.wins);
          return difference != 0 ? difference : a.clubId.compareTo(b.clubId);
        });
      final observed = snapshot.tableFor(tier);
      if (ranked.length != 16 || observed.length != 16 ||
          ranked.any((row) => row.played != 30) ||
          homeWins + draws + awayWins != 240) {
        throw StateError('B1 invalid final standing/aggregate.');
      }
      for (var i = 0; i < 16; i++) {
        final row = ranked[i];
        final actual = observed[i];
        if (row.clubId != actual.clubId || row.played != actual.played ||
            row.wins != actual.wins || row.draws != actual.draws ||
            row.losses != actual.losses || row.goalsFor != actual.goalsFor ||
            row.goalsAgainst != actual.goalsAgainst || row.points != actual.points) {
          throw StateError('B1 final table differs from committed M2 result.');
        }
      }
      final value = _LeagueResultValue(
        tier: tier, seasonIndex: opening.seasonIndex, seed: config.careerSeed,
        fixtures: fixtures, rows: ranked.map(_StandingValue.fromRow),
        homeWins: homeWins, draws: draws, awayWins: awayWins,
        totalGoals: totalGoals,
      );
      final report = value.toReport();
      if (report.fixtures.length != 240 || report.table.length != 16 ||
          report.championClubId != report.table.first.clubId ||
          report.totalGoals != totalGoals ||
          report.homeWins != homeWins || report.draws != draws ||
          report.awayWins != awayWins ||
          const SeasonValidator().validate(report).isNotEmpty) {
        throw StateError('B1 projected SeasonReport validation failed.');
      }
      values.add(value);
    }
    if (values.length != 3) throw StateError('B1 requires three league reports.');
    return PlayerPresidentCommittedSeasonResultCandidate._(
      sourceState: state, applied: applied, values: values,
    );
  }
}

/// A stable candidate identity whose report views are defensive copies.
/// Neither its fixtures nor its underlying committed W30 can be mutated here.
class PlayerPresidentCommittedSeasonResultCandidate {
  PlayerPresidentCommittedSeasonResultCandidate._({
    required this.sourceState,
    required this.applied,
    required Iterable<_LeagueResultValue> values,
  }) : _values = List<_LeagueResultValue>.unmodifiable(values);

  final PlayerPresidentPreseasonWeeklyState sourceState;
  final PlayerPresidentPreseasonPromiseApplied applied;
  final List<_LeagueResultValue> _values;

  int get seasonIndex => sourceState.fixtureSnapshot.seasonIndex;
  String get sourceIdentity => sourceState.sourceIdentity;
  String get controlledClubId => applied.controlledClubId;
  String get controlledPresidentId => applied.controlledPresidentId;
  String get acceptedRequestKey => applied.acceptedRequestKey;
  PresidentPromiseType get acceptedChoice => applied.acceptedChoice;
  List<PresidentPromise> get activePromises => applied.activePromises;

  /// Fresh views: mutable legacy StandingRows never escape from stored values.
  List<LeagueSeasonSnapshot> get leagueResults => List.unmodifiable([
        for (final value in _values)
          LeagueSeasonSnapshot(tier: value.tier, report: value.toReport()),
      ]);

  SeasonReport reportFor(LeagueTier tier) => _values
      .singleWhere((value) => value.tier == tier).toReport();
}

class _StandingValue {
  const _StandingValue({
    required this.clubId, required this.played, required this.wins,
    required this.draws, required this.losses, required this.goalsFor,
    required this.goalsAgainst, required this.points,
  });
  factory _StandingValue.fromRow(StandingRow row) => _StandingValue(
        clubId: row.clubId, played: row.played, wins: row.wins,
        draws: row.draws, losses: row.losses, goalsFor: row.goalsFor,
        goalsAgainst: row.goalsAgainst, points: row.points,
      );
  final String clubId;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  StandingRow toRow() => StandingRow(clubId: clubId)
    ..played = played
    ..wins = wins
    ..draws = draws
    ..losses = losses
    ..goalsFor = goalsFor
    ..goalsAgainst = goalsAgainst
    ..points = points;
}

class _LeagueResultValue {
  _LeagueResultValue({
    required this.tier, required this.seasonIndex, required this.seed,
    required Iterable<Fixture> fixtures, required Iterable<_StandingValue> rows,
    required this.homeWins, required this.draws, required this.awayWins,
    required this.totalGoals,
  }) : fixtures = List<Fixture>.unmodifiable(fixtures),
       rows = List<_StandingValue>.unmodifiable(rows);
  final LeagueTier tier;
  final int seasonIndex;
  final int seed;
  final List<Fixture> fixtures;
  final List<_StandingValue> rows;
  final int homeWins;
  final int draws;
  final int awayWins;
  final int totalGoals;
  SeasonReport toReport() => SeasonReport(
        seasonIndex: seasonIndex, seed: seed,
        championClubId: rows.first.clubId,
        table: List<StandingRow>.unmodifiable(rows.map((row) => row.toRow())),
        fixtures: fixtures, homeWins: homeWins, draws: draws,
        awayWins: awayWins, totalGoals: totalGoals,
      );
}
