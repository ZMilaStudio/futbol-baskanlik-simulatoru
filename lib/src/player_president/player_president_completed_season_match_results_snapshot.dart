import '../season/season_report.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';

/// Immutable value copy of one authoritative completed-season match result.
///
/// The row stores only controlled-club perspective values. It never retains
/// the source Fixture or MatchResult and never recalculates gameplay state.
class PlayerPresidentCompletedSeasonMatchResult {
  const PlayerPresidentCompletedSeasonMatchResult({
    required this.fixtureId,
    required this.round,
    required this.opponentClubId,
    required this.isHome,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  /// Deterministic source fixture observation identity. Never persisted or
  /// displayed as product copy.
  final String fixtureId;
  final int round;

  /// Canonical club reference only. Product UI resolves the display name.
  final String opponentClubId;
  final bool isHome;
  final int goalsFor;
  final int goalsAgainst;

  String get signature =>
      '$fixtureId|$round|$opponentClubId|${isHome ? 'home' : 'away'}|'
      '$goalsFor|$goalsAgainst';
}

/// Read-only M97 projection of authoritative completed-season match results.
///
/// [SeasonReport.fixtures] already owns source order. This projection validates
/// only bounded structural integrity and copies controlled-club results in that
/// exact order. It does not sort, regenerate fixtures, or aggregate standings.
class PlayerPresidentCompletedSeasonMatchResultsSnapshot {
  PlayerPresidentCompletedSeasonMatchResultsSnapshot._({
    required this.seasonIndex,
    required this.controlledClubId,
    required this.leagueTier,
    required Iterable<PlayerPresidentCompletedSeasonMatchResult> matches,
  }) : matches = List.unmodifiable(matches);

  factory PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport({
    required String controlledClubId,
    required WorldLeague completedLeague,
    required SeasonReport report,
  }) {
    if (controlledClubId.isEmpty) {
      throw StateError(
        'Completed-season match results controlled club is empty.',
      );
    }
    if (report.seasonIndex < 0) {
      throw StateError(
        'Completed-season match results season index is invalid.',
      );
    }

    final leagueIds = completedLeague.clubIds;
    if (leagueIds.isEmpty ||
        leagueIds.any((id) => id.isEmpty) ||
        leagueIds.toSet().length != leagueIds.length) {
      throw StateError(
        'Completed-season league membership must contain unique non-empty IDs.',
      );
    }
    if (!leagueIds.contains(controlledClubId)) {
      throw StateError(
        'Completed-season league does not contain the controlled club.',
      );
    }

    final sourceFixtures = report.fixtures;
    if (sourceFixtures.isEmpty) {
      throw StateError('Completed-season authoritative fixtures are empty.');
    }

    final leagueSize = leagueIds.length;
    final expectedFullCount = leagueSize * (leagueSize - 1);
    if (sourceFixtures.length != expectedFullCount) {
      throw StateError(
        'Completed-season fixture count does not match league membership.',
      );
    }

    final fixtureIds = <String>{};
    for (final fixture in sourceFixtures) {
      if (fixture.id.isEmpty) {
        throw StateError('Completed-season fixture ID cannot be empty.');
      }
      if (!fixtureIds.add(fixture.id)) {
        throw StateError('Completed-season fixture IDs must be unique.');
      }
      if (fixture.seasonIndex != report.seasonIndex) {
        throw StateError(
          'Completed-season fixture season index does not match report.',
        );
      }
    }

    final projected = <PlayerPresidentCompletedSeasonMatchResult>[];
    for (final fixture in sourceFixtures) {
      final homeControlled = fixture.homeClubId == controlledClubId;
      final awayControlled = fixture.awayClubId == controlledClubId;
      if (!homeControlled && !awayControlled) continue;
      if (homeControlled == awayControlled) {
        throw StateError(
          'Selected completed fixture must contain controlled club exactly once.',
        );
      }

      final result = fixture.result;
      if (result == null) {
        throw StateError(
          'Selected completed fixture requires an authoritative result.',
        );
      }

      final opponentClubId =
          homeControlled ? fixture.awayClubId : fixture.homeClubId;
      if (opponentClubId.isEmpty ||
          opponentClubId == controlledClubId ||
          !leagueIds.contains(opponentClubId)) {
        throw StateError(
          'Selected completed fixture opponent is outside completed league.',
        );
      }
      if (fixture.round <= 0) {
        throw StateError('Selected completed fixture round must be positive.');
      }

      final goalsFor =
          homeControlled ? result.homeGoals : result.awayGoals;
      final goalsAgainst =
          homeControlled ? result.awayGoals : result.homeGoals;
      if (goalsFor < 0 || goalsAgainst < 0) {
        throw StateError(
          'Selected completed fixture contains negative score values.',
        );
      }

      projected.add(
        PlayerPresidentCompletedSeasonMatchResult(
          fixtureId: fixture.id,
          round: fixture.round,
          opponentClubId: opponentClubId,
          isHome: homeControlled,
          goalsFor: goalsFor,
          goalsAgainst: goalsAgainst,
        ),
      );
    }

    final expectedControlledCount = 2 * (leagueSize - 1);
    if (projected.length != expectedControlledCount) {
      throw StateError(
        'Completed-season controlled fixture count is inconsistent.',
      );
    }

    return PlayerPresidentCompletedSeasonMatchResultsSnapshot._(
      seasonIndex: report.seasonIndex,
      controlledClubId: controlledClubId,
      leagueTier: completedLeague.tier,
      matches: projected,
    );
  }

  final int seasonIndex;
  final String controlledClubId;
  final LeagueTier leagueTier;
  final List<PlayerPresidentCompletedSeasonMatchResult> matches;

  String get leagueName => leagueTier.displayName;

  /// Runtime-only deterministic observation signature. Source order is kept.
  String get signature =>
      '$seasonIndex|${leagueTier.level}|$controlledClubId|'
      '${matches.map((match) => match.signature).join('||')}';
}
