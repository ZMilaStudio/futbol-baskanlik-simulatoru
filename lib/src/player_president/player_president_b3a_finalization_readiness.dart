import '../manager/manager_postseason_boundary_projection.dart';
import 'player_president_accepted_promise_closing_projection.dart';
import 'player_president_b3a_finance_equivalence.dart';

enum PlayerPresidentB3AFinalizationReadinessStatus {
  readyForFurtherDesign,
  financeEquivalenceBlocked,
  managerAuthorityUnavailable,
  managerOpeningMismatch,
  decisionRequired,
  decisionContractUnavailable,
  sourceMismatch,
}

enum PlayerPresidentB3AOffseasonEligibility {
  terminalNoWork,
  sourceAuthorityBlocked,
  sourceMismatch,
}

/// Immutable, side-effect-free B3-A observation of exact B2 ownership.
class PlayerPresidentB3AFinalizationReadiness {
  const PlayerPresidentB3AFinalizationReadiness({
    this.finance = const PlayerPresidentB3AFinanceEquivalence(),
    this.manager = const ManagerPostseasonBoundaryProjection(),
  });
  final PlayerPresidentB3AFinanceEquivalence finance;
  final ManagerPostseasonBoundaryProjection manager;

  PlayerPresidentB3AFinalizationReadinessResult inspect({
    required PlayerPresidentAcceptedPromiseClosingCandidate
        expectedClosingCandidate,
  }) {
    final b1 = expectedClosingCandidate.sourceResultCandidate;
    final state = b1.sourceState;
    final boundary = state.boundary;
    final application = boundary.application;
    final owned = identical(
          application.acceptedPromiseClosingCandidate,
          expectedClosingCandidate,
        ) &&
        identical(application.committedSeasonResultCandidate, b1) &&
        identical(application.preseasonWeeklyState, state) &&
        identical(application.preseasonPromiseBoundary, boundary) &&
        identical(boundary.applied, state.applied) &&
        identical(application.appliedPreseasonPromises, state.applied) &&
        identical(expectedClosingCandidate.activePromises,
            state.applied.activePromises) &&
        expectedClosingCandidate.activePromises.length == 48 &&
        expectedClosingCandidate.hasNextSeason ==
            (application.resumeConfig.seasonCount > 1 ||
                application.resumeConfig.hasFutureSeasonAfterReport) &&
        expectedClosingCandidate.promiseSnapshots.length == 48 &&
        state.completedMatchCount == 720 &&
        state.fixtureSnapshot.isComplete;
    final financeResult = finance.inspect(expectedClosingCandidate);
    final managerResult = manager.inspect(b1);
    final blockers = <PlayerPresidentB3AFinalizationReadinessStatus>[
      if (!owned || !financeResult.sourceOwned)
        PlayerPresidentB3AFinalizationReadinessStatus.sourceMismatch,
      if (!financeResult.fullM65Equivalent)
        PlayerPresidentB3AFinalizationReadinessStatus.financeEquivalenceBlocked,
      if (managerResult.status ==
          ManagerPostseasonBoundaryStatus.authorityUnavailable)
        PlayerPresidentB3AFinalizationReadinessStatus
            .managerAuthorityUnavailable,
      if (managerResult.status ==
          ManagerPostseasonBoundaryStatus.openingMismatch)
        PlayerPresidentB3AFinalizationReadinessStatus.managerOpeningMismatch,
      // No B3-A next-season player-decision boundary exists in this source
      // chain. Never run an AI fallback or advance the application session.
      if (expectedClosingCandidate.hasNextSeason)
        application.pendingDecision != null
            ? PlayerPresidentB3AFinalizationReadinessStatus.decisionRequired
            : PlayerPresidentB3AFinalizationReadinessStatus
                .decisionContractUnavailable,
    ];
    final status = blockers.isEmpty
        ? PlayerPresidentB3AFinalizationReadinessStatus.readyForFurtherDesign
        : blockers.first;
    return PlayerPresidentB3AFinalizationReadinessResult(
      source: expectedClosingCandidate,
      status: status,
      finance: financeResult,
      manager: managerResult,
      blockers: blockers,
      offseasonEligibility: !owned || !financeResult.sourceOwned
          ? PlayerPresidentB3AOffseasonEligibility.sourceMismatch
          : expectedClosingCandidate.hasNextSeason
              ? PlayerPresidentB3AOffseasonEligibility.sourceAuthorityBlocked
              : PlayerPresidentB3AOffseasonEligibility.terminalNoWork,
    );
  }
}

class PlayerPresidentB3AFinalizationReadinessResult {
  PlayerPresidentB3AFinalizationReadinessResult({
    required this.source,
    required this.status,
    required this.finance,
    required this.manager,
    required this.offseasonEligibility,
    required Iterable<PlayerPresidentB3AFinalizationReadinessStatus> blockers,
  }) : blockers = List.unmodifiable(blockers);
  final PlayerPresidentAcceptedPromiseClosingCandidate source;
  final PlayerPresidentB3AFinalizationReadinessStatus status;
  final PlayerPresidentB3AFinanceEquivalenceResult finance;
  final ManagerPostseasonBoundaryResult manager;
  final PlayerPresidentB3AOffseasonEligibility offseasonEligibility;
  final List<PlayerPresidentB3AFinalizationReadinessStatus> blockers;
  bool get finalizationReady => blockers.isEmpty;
}
