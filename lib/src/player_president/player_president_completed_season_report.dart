import '../finance/club_finance_season.dart';
import '../league/standing_row.dart';
import '../manager/manager.dart';
import '../manager/manager_career_season.dart';
import '../promise/promise_season_snapshot.dart';
import '../world/league_tier.dart';
import '../world/world_career_season.dart';
import 'player_president_completed_season_league_table_snapshot.dart';
import 'player_president_completed_season_match_results_snapshot.dart';
import 'player_president_interactive_decision_session.dart';

/// Read-only application projection for exactly one completed interactive season.
///
/// This is not persisted state and does not introduce gameplay authority. Every
/// field is selected from the authoritative [PlayerPresidentInteractiveSessionCompleted]
/// result produced by the existing M71/M65 runtime chain.
///
/// The current playable application runs one season per interactive session.
/// Multi-season Completed results therefore fail closed instead of silently
/// choosing an arbitrary boundary.
class PlayerPresidentCompletedSeasonReport {
  const PlayerPresidentCompletedSeasonReport._({
    required this.seasonIndex,
    required this.controlledClubId,
    required this.leagueTier,
    required this.finalPosition,
    required this.standing,
    required this.championClubId,
    required this.movement,
    required this.finance,
    required this.manager,
    required this.managerSeason,
    required this.promise,
    required this.leagueTable,
    required this.matchResults,
  });

  factory PlayerPresidentCompletedSeasonReport.fromCompleted(
    PlayerPresidentInteractiveSessionCompleted completed,
  ) {
    final boundaries = completed.result.boundaries;
    if (boundaries.length != 1) {
      throw StateError(
        'Completed-season report requires exactly one interactive season '
        'boundary, got ${boundaries.length}.',
      );
    }

    final boundary = boundaries.single;
    final resultCheckpoint = completed.result.checkpoint;
    if (resultCheckpoint.signature != boundary.checkpoint.signature) {
      throw StateError(
        'Completed-season report boundary checkpoint does not match the '
        'career result checkpoint.',
      );
    }

    final controlledClubId = resultCheckpoint.controlledClubId;
    if (controlledClubId.isEmpty ||
        boundary.checkpoint.controlledClubId != controlledClubId) {
      throw StateError(
        'Completed-season report controlled-club identity is inconsistent.',
      );
    }

    final seasonIndex = boundary.seasonIndex;
    final presidentReport = boundary.source.source.source.sponsor.report;
    final worldSeasons =
        presidentReport.sourceReport.advancedTransferReport.worldReport.seasons;
    if (worldSeasons.length != 1) {
      throw StateError(
        'Completed-season report requires exactly one authoritative world '
        'season, got ${worldSeasons.length}.',
      );
    }
    final worldSeason = worldSeasons.single;
    if (worldSeason.seasonIndex != seasonIndex) {
      throw StateError(
        'Completed-season report season index mismatch: boundary '
        '$seasonIndex, world ${worldSeason.seasonIndex}.',
      );
    }

    final league = _singleWhere(
      worldSeason.leaguesBeforeSeason,
      (item) => item.clubIds.contains(controlledClubId),
      'controlled-club league',
    );
    final leagueResult = _singleWhere(
      worldSeason.leagueResults,
      (item) => item.tier == league.tier,
      'controlled-club league result',
    );
    final seasonReport = leagueResult.report;
    if (seasonReport.seasonIndex != seasonIndex) {
      throw StateError(
        'Completed-season league report season index does not match the '
        'interactive boundary.',
      );
    }
    if (seasonReport.table.isEmpty ||
        seasonReport.championClubId != seasonReport.table.first.clubId) {
      throw StateError(
        'Completed-season league report champion/table authority is '
        'inconsistent.',
      );
    }

    final rowIndexes = <int>[];
    for (var index = 0; index < seasonReport.table.length; index++) {
      if (seasonReport.table[index].clubId == controlledClubId) {
        rowIndexes.add(index);
      }
    }
    if (rowIndexes.length != 1) {
      throw StateError(
        'Completed-season report requires exactly one standing row for '
        '$controlledClubId, got ${rowIndexes.length}.',
      );
    }
    final rowIndex = rowIndexes.single;
    final standing = seasonReport.table[rowIndex];

    final movements = worldSeason.movementsAfterSeason
        .where((item) => item.clubId == controlledClubId)
        .toList(growable: false);
    if (movements.length > 1) {
      throw StateError(
        'Completed-season report found multiple league movements for '
        '$controlledClubId.',
      );
    }
    final movement = movements.isEmpty ? null : movements.single;
    if (movement != null && movement.from != league.tier) {
      throw StateError(
        'Completed-season movement does not start from the completed-season '
        'league tier.',
      );
    }

    final finance = boundary.source.financeFor(controlledClubId);
    if (finance.clubId != controlledClubId) {
      throw StateError(
        'Completed-season finance record belongs to a different club.',
      );
    }
    final worldFinance = _singleWhere(
      worldSeason.finances,
      (item) => item.clubId == controlledClubId,
      'controlled-club completed finance',
    );
    if (worldFinance.signature != finance.signature) {
      throw StateError(
        'Completed-season finance seam diverges from the world-season result.',
      );
    }

    final managerState = boundary
        .checkpoint
        .runtime
        .runtime
        .domain
        .presidentRuntime
        .runtime
        .runtime
        .manager;
    final managerCareerSeason = _singleWhere(
      managerState.seasons,
      (item) => item.seasonIndex == seasonIndex,
      'completed manager season',
    );
    final managerSeason = _singleWhere(
      managerCareerSeason.clubs,
      (item) => item.clubId == controlledClubId,
      'controlled-club manager season',
    );
    if (managerSeason.actualPosition != rowIndex + 1) {
      throw StateError(
        'Completed manager actual position diverges from the authoritative '
        'league table.',
      );
    }
    final manager = _singleWhere(
      managerState.managers,
      (item) => item.id == managerSeason.managerId,
      'completed-season manager identity',
    );

    final promiseMatches = presidentReport.sourceReport.promiseReport.snapshots
        .where(
          (item) =>
              item.context.clubId == controlledClubId &&
              item.context.seasonIndex == seasonIndex,
        )
        .toList(growable: false);
    if (promiseMatches.length > 1) {
      throw StateError(
        'Completed-season report found multiple promise snapshots for '
        '$controlledClubId in season $seasonIndex.',
      );
    }
    final promise = promiseMatches.isEmpty ? null : promiseMatches.single;
    if (promise != null) {
      if (promise.promise.clubId != controlledClubId ||
          promise.promise.seasonIndex != seasonIndex ||
          promise.outcome.clubId != controlledClubId ||
          promise.outcome.seasonIndex != seasonIndex ||
          promise.resolution.promise.signature != promise.promise.signature) {
        throw StateError(
          'Completed-season promise snapshot authority is inconsistent.',
        );
      }
    }

    PlayerPresidentCompletedSeasonLeagueTableSnapshot? leagueTable;
    try {
      final candidate =
          PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: controlledClubId,
        completedLeague: league,
        report: seasonReport,
      );
      final controlledRows = candidate.rows
          .where((row) => row.clubId == controlledClubId)
          .toList(growable: false);
      if (candidate.seasonIndex != seasonIndex ||
          candidate.controlledClubId != controlledClubId ||
          candidate.leagueTier != league.tier ||
          candidate.championClubId != seasonReport.championClubId ||
          controlledRows.length != 1) {
        throw StateError(
          'Completed-season league table diverges from M91 authority.',
        );
      }
      final controlledRow = controlledRows.single;
      if (controlledRow.position != rowIndex + 1 ||
          controlledRow.clubId != controlledClubId ||
          controlledRow.played != standing.played ||
          controlledRow.wins != standing.wins ||
          controlledRow.draws != standing.draws ||
          controlledRow.losses != standing.losses ||
          controlledRow.goalsFor != standing.goalsFor ||
          controlledRow.goalsAgainst != standing.goalsAgainst ||
          controlledRow.goalDifference != standing.goalDifference ||
          controlledRow.points != standing.points) {
        throw StateError(
          'Completed-season league table controlled row diverges from M91.',
        );
      }
      leagueTable = candidate;
    } on StateError {
      leagueTable = null;
    }

    PlayerPresidentCompletedSeasonMatchResultsSnapshot? matchResults;
    try {
      final candidate =
          PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
        controlledClubId: controlledClubId,
        completedLeague: league,
        report: seasonReport,
      );
      if (candidate.seasonIndex != seasonIndex ||
          candidate.controlledClubId != controlledClubId ||
          candidate.leagueTier != league.tier) {
        throw StateError(
          'Completed-season match results diverge from M91 authority.',
        );
      }
      matchResults = candidate;
    } on StateError {
      matchResults = null;
    }

    return PlayerPresidentCompletedSeasonReport._(
      seasonIndex: seasonIndex,
      controlledClubId: controlledClubId,
      leagueTier: league.tier,
      finalPosition: rowIndex + 1,
      standing: standing,
      championClubId: seasonReport.championClubId,
      movement: movement,
      finance: finance,
      manager: manager,
      managerSeason: managerSeason,
      promise: promise,
      leagueTable: leagueTable,
      matchResults: matchResults,
    );
  }

  final int seasonIndex;
  final String controlledClubId;
  final LeagueTier leagueTier;

  /// Existing canonical display metadata; no duplicate league-name authority.
  String get leagueName => leagueTier.displayName;

  /// 1-based index in the already-authoritative sorted SeasonReport.table.
  final int finalPosition;

  final StandingRow standing;
  final String championClubId;
  final LeagueMovement? movement;
  final ClubFinanceSeason finance;

  /// Manager who actually managed the completed season, not the post-season
  /// assignment that may already exist in the continuation checkpoint.
  final Manager manager;
  final ManagerClubSeason managerSeason;

  /// Canonical completed-season promise result when one exists.
  ///
  /// No synthetic "no promise" result is created.
  final PromiseSeasonSnapshot? promise;

  /// Optional M96 read-only table projection. Existing M91 authority failures
  /// still fail the report; only M96-specific integrity failures yield null.
  final PlayerPresidentCompletedSeasonLeagueTableSnapshot? leagueTable;

  /// Optional M97 read-only match-results projection. Existing M91 authority
  /// failures still fail the report; only M97-specific integrity failures
  /// yield null. This projection is derived-only and never persisted.
  final PlayerPresidentCompletedSeasonMatchResultsSnapshot? matchResults;
}

T _singleWhere<T>(
  Iterable<T> values,
  bool Function(T item) predicate,
  String label,
) {
  final matches = values.where(predicate).toList(growable: false);
  if (matches.length != 1) {
    throw StateError(
      'Completed-season report requires exactly one $label, '
      'got ${matches.length}.',
    );
  }
  return matches.single;
}
