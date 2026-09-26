import '../core/simulation_config.dart';
import '../league/club.dart';
import '../world/world_league.dart';
import 'weekly_world_fixture_result_core.dart';

/// Only meaningful M2 phases: a round can be committed, or all 30 are done.
/// The synchronous commit has no externally observable intermediate phase.
enum WeeklyWorldCommitPhase { awaitingRound, seasonComplete }

/// Single-owner, in-memory commit boundary over the M1 fixture/result core.
///
/// The M1 snapshot is the only fixture/result authority. There is no separate
/// score ledger, persisted checkpoint or M65 save integration. Hold this
/// session for the lifetime of one active in-memory season; do not recreate it
/// from the opening inputs to recover a committed game.
class WeeklyWorldCommitSession {
  WeeklyWorldCommitSession._(this._core, this._snapshot);

  factory WeeklyWorldCommitSession.open({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    WeeklyWorldFixtureResultCore core = const WeeklyWorldFixtureResultCore(),
  }) =>
      WeeklyWorldCommitSession._(
        core,
        core.prepare(clubs: clubs, leagues: leagues, config: config),
      );

  final WeeklyWorldFixtureResultCore _core;
  WeeklyWorldFixtureSnapshot _snapshot;

  /// Read-only M1 snapshot. Prior references do not change on later commits.
  WeeklyWorldFixtureSnapshot get snapshot => _snapshot;
  int get seasonIndex => _snapshot.seasonIndex;
  int get nextRound => _snapshot.nextRound;
  int get completedRounds => _snapshot.completedRounds;
  int get completedMatchCount => _snapshot.completedMatchCount;
  WeeklyWorldCommitPhase get phase => _snapshot.isComplete
      ? WeeklyWorldCommitPhase.seasonComplete
      : WeeklyWorldCommitPhase.awaitingRound;

  /// Atomically accepts exactly the currently unplayed world round.
  ///
  /// A stale/duplicate round, wrong season, finished season or invalid club
  /// inputs fail closed without publishing a candidate snapshot. The match
  /// engine is called only for this round, retaining older M1 result objects,
  /// legacy fixture IDs and the original match seed contract.
  ///
  /// This guards one live session, not disk retries or separately opened
  /// sessions. Persistence, transaction IDs and restore require the later
  /// M65/FBS-03 design.
  WeeklyWorldFixtureSnapshot commitRound({
    required int expectedSeasonIndex,
    required int expectedRound,
    required List<Club> effectiveClubs,
  }) {
    final previous = _snapshot;
    if (expectedSeasonIndex != previous.seasonIndex ||
        previous.isComplete ||
        expectedRound != previous.nextRound) {
      throw StateError('Stale or invalid weekly commit boundary.');
    }

    // No session mutation occurs until the pure M1 calculation is complete.
    final candidate = _core.advanceRound(
      snapshot: previous,
      expectedRound: expectedRound,
      effectiveClubs: effectiveClubs,
    );
    if (candidate.seasonIndex != previous.seasonIndex ||
        candidate.totalRounds != previous.totalRounds ||
        candidate.nextRound != expectedRound + 1 ||
        candidate.completedMatchCount != previous.completedMatchCount + 24 ||
        candidate.fixtures.length != previous.fixtures.length) {
      throw StateError('Weekly core returned an invalid commit transition.');
    }
    _snapshot = candidate;
    return candidate;
  }
}
