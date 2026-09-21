import '../season/season_report.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';

/// Immutable value copy of one authoritative completed-season standing row.
///
/// Values are copied from the existing [SeasonReport.table] order. This type
/// never retains the mutable source StandingRow and never recalculates ranking.
class PlayerPresidentCompletedSeasonLeagueTableRow {
  const PlayerPresidentCompletedSeasonLeagueTableRow({
    required this.position,
    required this.clubId,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  final int position;
  final String clubId;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  String get signature =>
      '$position|$clubId|$played|$wins|$draws|$losses|$goalsFor|'
      '$goalsAgainst|$goalDifference|$points';
}

/// Read-only M96 projection of the authoritative final completed-season table.
///
/// [SeasonReport.table] already owns ranking and ordering. This projection only
/// validates structural integrity and copies values in the exact source order.
class PlayerPresidentCompletedSeasonLeagueTableSnapshot {
  PlayerPresidentCompletedSeasonLeagueTableSnapshot._({
    required this.seasonIndex,
    required this.controlledClubId,
    required this.leagueTier,
    required this.championClubId,
    required Iterable<PlayerPresidentCompletedSeasonLeagueTableRow> rows,
  }) : rows = List.unmodifiable(rows);

  factory PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport({
    required String controlledClubId,
    required WorldLeague completedLeague,
    required SeasonReport report,
  }) {
    if (controlledClubId.isEmpty) {
      throw StateError('Completed-season league table controlled club is empty.');
    }
    if (report.seasonIndex < 0) {
      throw StateError('Completed-season league table season index is invalid.');
    }

    final leagueIds = completedLeague.clubIds;
    if (leagueIds.isEmpty) {
      throw StateError('Completed-season league membership is empty.');
    }
    if (leagueIds.any((id) => id.isEmpty) ||
        leagueIds.toSet().length != leagueIds.length) {
      throw StateError(
        'Completed-season league membership must contain unique non-empty IDs.',
      );
    }

    final sourceRows = report.table;
    if (sourceRows.isEmpty) {
      throw StateError('Completed-season authoritative table is empty.');
    }
    if (sourceRows.length != leagueIds.length) {
      throw StateError(
        'Completed-season table count does not match league membership.',
      );
    }

    final sourceIds = <String>[];
    final projectedRows =
        <PlayerPresidentCompletedSeasonLeagueTableRow>[];
    var controlledCount = 0;

    for (var index = 0; index < sourceRows.length; index++) {
      final source = sourceRows[index];
      if (source.clubId.isEmpty) {
        throw StateError('Completed-season table contains an empty club ID.');
      }
      if (source.played < 0 ||
          source.wins < 0 ||
          source.draws < 0 ||
          source.losses < 0 ||
          source.goalsFor < 0 ||
          source.goalsAgainst < 0 ||
          source.points < 0) {
        throw StateError('Completed-season table contains negative statistics.');
      }
      if (source.played != source.wins + source.draws + source.losses) {
        throw StateError(
          'Completed-season table played total is internally inconsistent.',
        );
      }

      sourceIds.add(source.clubId);
      if (source.clubId == controlledClubId) controlledCount++;

      final row = PlayerPresidentCompletedSeasonLeagueTableRow(
        position: index + 1,
        clubId: source.clubId,
        played: source.played,
        wins: source.wins,
        draws: source.draws,
        losses: source.losses,
        goalsFor: source.goalsFor,
        goalsAgainst: source.goalsAgainst,
        goalDifference: source.goalDifference,
        points: source.points,
      );
      if (row.goalDifference != source.goalDifference) {
        throw StateError(
          'Completed-season table goal difference copy is inconsistent.',
        );
      }
      projectedRows.add(row);
    }

    if (sourceIds.toSet().length != sourceIds.length) {
      throw StateError('Completed-season table contains duplicate club IDs.');
    }
    if (sourceIds.toSet().difference(leagueIds.toSet()).isNotEmpty ||
        leagueIds.toSet().difference(sourceIds.toSet()).isNotEmpty) {
      throw StateError(
        'Completed-season table membership diverges from completed league.',
      );
    }
    if (controlledCount != 1) {
      throw StateError(
        'Completed-season table requires exactly one controlled club row.',
      );
    }

    final championClubId = report.championClubId;
    if (championClubId.isEmpty ||
        !leagueIds.contains(championClubId) ||
        sourceRows.first.clubId != championClubId) {
      throw StateError(
        'Completed-season champion does not match the authoritative first row.',
      );
    }

    for (var index = 0; index < projectedRows.length; index++) {
      if (projectedRows[index].position != index + 1) {
        throw StateError(
          'Completed-season table positions are not contiguous.',
        );
      }
    }

    return PlayerPresidentCompletedSeasonLeagueTableSnapshot._(
      seasonIndex: report.seasonIndex,
      controlledClubId: controlledClubId,
      leagueTier: completedLeague.tier,
      championClubId: championClubId,
      rows: projectedRows,
    );
  }

  final int seasonIndex;
  final String controlledClubId;
  final LeagueTier leagueTier;
  final String championClubId;
  final List<PlayerPresidentCompletedSeasonLeagueTableRow> rows;

  String get leagueName => leagueTier.displayName;

  /// Runtime-only deterministic observation signature. Row order is preserved.
  String get signature =>
      '$seasonIndex|${leagueTier.level}|$controlledClubId|$championClubId|'
      '${rows.map((row) => row.signature).join('||')}';
}
