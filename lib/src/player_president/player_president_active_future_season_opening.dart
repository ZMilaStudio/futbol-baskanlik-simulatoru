part of 'player_president_interactive_decision_application_session.dart';

/// Opening evidence only: Pending is not an accepted promise or W1 authority.
final class PlayerPresidentActiveFutureSeasonOpening {
  PlayerPresidentActiveFutureSeasonOpening._(
      this.application,
      this.admission,
      this.w0,
      this.promiseContexts,
      this.controlledPromiseContext,
      this.promisePending);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final TrustedFuturePreparedRuntimeAdmission admission;
  PreparedTicketRuntimeSeason get prepared => admission.prepared;
  PreparedWorldOpening get opening => prepared.opening;
  ManagerSeasonAuthority get managerAuthority => prepared.managerAuthority!;
  int get targetSeasonIndex => admission.targetSeasonIndex;
  PostoffseasonRuntimeOrigin get origin => admission.origin;
  String get controlledClubId => admission.controlledClubId;
  PlayerPresidentTenureControlState get control => admission.control;
  Object get sourceExecutionIdentity => admission.sourceExecutionIdentity;
  Object get targetExecutionIdentity => admission.targetExecutionIdentity;
  final WeeklyWorldFixtureSnapshot w0;
  final List<PresidentPromiseContext> promiseContexts;
  final PlayerPromiseDecisionContext controlledPromiseContext;
  final PlayerPresidentInteractiveDecisionPending promisePending;
}

/// Private-minted common reservation proof. No controller/engine escapes.
final class ApplicationFutureOpeningClaim {
  ApplicationFutureOpeningClaim._(this.application, this.admission);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final TrustedFuturePreparedRuntimeAdmission admission;
  PlayerPresidentActiveFutureSeasonOpening? _candidate;
  void validatePreparation(PreparedTicketRuntimeSeason prepared) {
    if (!application._futureOpeningInProgress ||
        application._activeFutureSeasonOpening != null) {
      throw StateError('Future opening must be staged by its application.');
    }
    application._validateFutureOpeningSource(admission, prepared);
  }

  void validateReservation(PreparedTicketRuntimeSeason prepared) {
    validatePreparation(prepared);
    final candidate = _candidate;
    if (candidate == null ||
        !identical(candidate.application, application) ||
        !identical(candidate.admission, admission) ||
        !identical(candidate.prepared, prepared)) {
      throw StateError('Future opening reservation has no exact candidate.');
    }
  }
}

extension _ActiveFutureSeasonApplication
    on PlayerPresidentInteractiveDecisionApplicationSession {
  void _validateFutureOpeningSource(
      TrustedFuturePreparedRuntimeAdmission admission,
      PreparedTicketRuntimeSeason prepared) {
    final manager = prepared.managerAuthority;
    final world = prepared.opening;
    final entry = _futureRuntimeEntry;
    if (!identical(_futureRuntimeAdmission, admission) ||
        !identical(admission.applicationOwner, this) ||
        !identical(admission.prepared, prepared) ||
        entry == null ||
        !identical(admission.applicationEntryIdentity, entry) ||
        !identical(prepared.owner, this) ||
        !identical(prepared.revision, entry.revision) ||
        !identical(prepared.provenance, admission.sourceGraph) ||
        !identical(
            prepared.executionIdentity, admission.targetExecutionIdentity) ||
        prepared.state != PreparedExecutionState.prepared ||
        prepared.origin != PreparedRuntimeOrigin.futureContinuation ||
        admission.sourceGraph.admissionState !=
            FutureRuntimeAdmissionState.prepared ||
        world.seasonIndex != admission.targetSeasonIndex ||
        world.seasonIndex <= 0 ||
        world.seasonIndex !=
            admission.sourceGraph.worldSuccessor.nextSeasonIndex ||
        world.config.careerSeed != admission.careerSeed ||
        world.config.simulationVersion != admission.simulationVersion ||
        manager == null ||
        !identical(manager.owner, this) ||
        !identical(manager.sourceRevision, prepared.revision) ||
        manager.seasonIndex != world.seasonIndex ||
        !identical(manager.effectiveClubs, world.effectiveClubs) ||
        !identical(prepared.tenureControl, admission.control) ||
        admission.controlledClubId != _newGameControlledClubId ||
        world.effectiveClubs
                .where((c) => c.id == admission.controlledClubId)
                .length !=
            1 ||
        !identical(world.players,
            admission.sourceGraph.worldSuccessor.nextSeasonPlayers) ||
        !identical(world.financeStates,
            admission.sourceGraph.worldSuccessor.nextSeasonFinanceStates) ||
        !identical(world.leagues,
            admission.sourceGraph.worldSuccessor.nextSeasonLeagues) ||
        !identical(prepared.facilities, admission.sourceGraph.facilities)) {
      throw StateError('Foreign, stale or mismatched future opening source.');
    }
    entry.validate(admission.sourceGraph);
    final ids = world.effectiveClubs.map((c) => c.id).toSet();
    final members = world.leagues.expand((league) => league.clubIds).toList();
    final financeIds = world.financeStates.map((state) => state.clubId).toSet();
    if (ids.length != 48 ||
        world.effectiveClubs.length != 48 ||
        world.leagues.length != 3 ||
        world.leagues.map((league) => league.tier).toSet().length != 3 ||
        world.leagues.any((league) => league.clubIds.length != 16) ||
        members.length != 48 ||
        members.toSet().length != 48 ||
        !ids.containsAll(members) ||
        world.financeStates.length != 48 ||
        financeIds.length != 48 ||
        !financeIds.containsAll(ids) ||
        world.players.map((p) => p.id).toSet().length != world.players.length ||
        world.players.any((p) => !p.isFreeAgent && !ids.contains(p.clubId))) {
      throw StateError('Invalid future opening roster coverage.');
    }
  }

  PlayerPresidentActiveFutureSeasonOpening _openFutureSeason({
    required TrustedFuturePreparedRuntimeAdmission expectedAdmission,
    required PreparedTicketRuntimeSeason expectedPrepared,
  }) {
    _validateFutureOpeningSource(expectedAdmission, expectedPrepared);
    final previous = _activeFutureSeasonOpening;
    if (previous != null) {
      if (!identical(previous.admission, expectedAdmission) ||
          !identical(previous.prepared, expectedPrepared)) {
        throw StateError('Conflicting future opening publication.');
      }
      return previous;
    }
    if (_futureOpeningInProgress)
      throw StateError('Future opening is already staging.');
    _futureOpeningInProgress = true;
    try {
      final claim = ApplicationFutureOpeningClaim._(this, expectedAdmission);
      final w0 = expectedPrepared.prepareFutureOpeningW0(claim);
      final world = expectedPrepared.opening;
      final contexts = const PromiseOpeningContextBuilder().build(
          seasonIndex: world.seasonIndex,
          effectiveClubs: world.effectiveClubs,
          leagues: world.leagues,
          openingFinanceStates: world.financeStates);
      if (contexts.length != 48 ||
          contexts.map((c) => c.clubId).toSet().length != 48 ||
          contexts.any((c) => c.seasonIndex != world.seasonIndex)) {
        throw StateError('Future contexts require exact 48-club coverage.');
      }
      final controlled = contexts
          .singleWhere((c) => c.clubId == expectedAdmission.controlledClubId);
      final decision = PlayerPromiseDecisionContext(
          context: controlled,
          aiPromise: const PromiseGenerator().generate(
              context: controlled,
              careerSeed: world.config.careerSeed,
              simulationVersion: world.config.simulationVersion),
          allowedTypes:
              PlayerPresidentPromiseGenerator.allowedPromiseTypes(controlled));
      final pending =
          PlayerPresidentInteractiveDecisionRequest.futurePromisePending(
              claim: claim, prepared: expectedPrepared, context: decision);
      final candidate = PlayerPresidentActiveFutureSeasonOpening._(
          this, expectedAdmission, w0, contexts, decision, pending);
      claim._candidate = candidate;
      // Both commits are callback-free. All fallible candidate work is above.
      expectedPrepared.reserveFutureOpening(claim);
      _activeFutureSeasonOpening = candidate;
      return candidate;
    } finally {
      _futureOpeningInProgress = false;
    }
  }
}
