import '../player_president/player_president_committed_season_result_projection.dart';
import 'manager_career_season.dart';
import 'manager_assignment.dart';

enum ManagerPostseasonBoundaryStatus {
  authorityUnavailable,
  openingMismatch,
  compatible,
}

/// A read-only boundary: B3-A never completes or mutates a manager season.
class ManagerPostseasonBoundaryProjection {
  const ManagerPostseasonBoundaryProjection();

  ManagerPostseasonBoundaryResult inspect(
    PlayerPresidentCommittedSeasonResultCandidate source,
  ) {
    return ManagerPostseasonBoundaryResult(
      source: source,
      status: ManagerPostseasonBoundaryStatus.authorityUnavailable,
      managerCompletionEvaluated: false,
    );
  }
}

class ManagerPostseasonBoundaryResult {
  const ManagerPostseasonBoundaryResult({
    required this.source,
    required this.status,
    required this.managerCompletionEvaluated,
  });
  final PlayerPresidentCommittedSeasonResultCandidate source;
  final ManagerPostseasonBoundaryStatus status;
  final bool managerCompletionEvaluated;
  // Absence is explicit; these are not a reconstructed manager history.
  ManagerCareerSeason? get authoritativeSeason => null;
  List<ManagerAssignment> get authoritativeAssignments => const [];
}
