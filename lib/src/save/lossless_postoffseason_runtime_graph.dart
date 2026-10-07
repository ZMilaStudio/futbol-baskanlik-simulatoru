part of '../player_president/player_president_postseason_runtime_transition.dart';

enum PostoffseasonRuntimeOrigin {
  firstFutureBootstrap,
  postOffseasonContinuation
}

enum FutureRuntimeAdmissionState {
  available,
  claimedForFuturePreparation,
  prepared,
  failed,
}

/// Runtime-only recipient. There is no public data constructor and none of its
/// mutable controller/coordinator children is exposed by a getter.
final class LosslessPostOffseasonRuntimeGraph {
  LosslessPostOffseasonRuntimeGraph._(
      SinglePassPostseasonRuntimeTransition source)
      : _token = source._applicationToken,
        _annual = source._annualClosing,
        _transfer = source._transfer,
        _manager = source._managerSuccessor!,
        _facility = source._facilityGraph!,
        _domain = source._domainSuccessor!,
        _crisis = source._crisisSuccessor!,
        _investment = source._facilitySuccessor!,
        control = source._controlSuccessor!,
        acceptedAnswers = source.acceptedAnswers;
  final ApplicationPostseasonTransitionToken? _token;
  final OwnedAnnualClosingBoundary? _annual;
  final AdvancedTransferController? _transfer;
  final ManagerContinuationAuthority _manager;
  final FacilitySponsorPostseasonContinuation _facility;
  final PresidentDomainSeasonEffects _domain;
  final CrisisRuntimeEffects _crisis;
  final PresidentFacilityInvestmentEffects _investment;
  final PlayerPresidentTenureControlState control;
  final List<PostseasonAcceptedAnswer> acceptedAnswers;
  FutureRuntimeAdmissionState _admissionState =
      FutureRuntimeAdmissionState.available;
  FutureRuntimeAdmissionState get admissionState => _admissionState;

  TrustedFuturePreparedRuntimeAdmission admitFutureRuntime(
      ApplicationFutureRuntimeEntry entry) {
    entry.validatePreparationInvocation(this);
    validateFutureAdmissionSource(
        expectedOwner: owner,
        expectedRevision: revision,
        expectedProvenance: provenance,
        expectedExecution: executionIdentity,
        expectedOrigin: origin,
        expectedTargetSeason: targetSeasonIndex,
        expectedCareerSeed: worldSuccessor.config.careerSeed,
        expectedSimulationVersion: worldSuccessor.config.simulationVersion);
    final claim = FutureRuntimeClaim._(this, entry);
    claim.prepareTransferRecipient();
    claim.prepareManagerRecipient();
    _facility.validateFuturePreparation(claim);
    final ticket = _annual == null
        ? PreparedTicketRuntimeSeason.stageFirstFuture(claim)
        : _annual.stageFutureTicket(claim);
    _facility.validateFutureTicketBinding(claim, ticket);
    // Callback-free ownership commit. All recipient allocations/preflight above
    // are detached; fallible engine work starts only after these assignments.
    _admissionState = FutureRuntimeAdmissionState.claimedForFuturePreparation;
    claim._committed = true;
    try {
      final prepared = ticket.prepare();
      final result = TrustedFuturePreparedRuntimeAdmission._(claim, prepared);
      _admissionState = FutureRuntimeAdmissionState.prepared;
      return result;
    } catch (_) {
      _admissionState = FutureRuntimeAdmissionState.failed;
      rethrow;
    }
  }

  /// Pure source preflight. Observing a published graph never grants ownership.
  void validateFutureAdmissionSource({
    required Object expectedOwner,
    required Object expectedRevision,
    required Object expectedProvenance,
    required Object expectedExecution,
    required PostoffseasonRuntimeOrigin expectedOrigin,
    required int expectedTargetSeason,
    required int expectedCareerSeed,
    required int expectedSimulationVersion,
  }) {
    if (_admissionState != FutureRuntimeAdmissionState.available ||
        !identical(owner, expectedOwner) ||
        !identical(revision, expectedRevision) ||
        !identical(provenance, expectedProvenance) ||
        !identical(executionIdentity, expectedExecution) ||
        origin != expectedOrigin ||
        targetSeasonIndex != expectedTargetSeason ||
        worldSuccessor.config.careerSeed != expectedCareerSeed ||
        worldSuccessor.config.simulationVersion != expectedSimulationVersion ||
        _manager.seasonIndex != targetSeasonIndex ||
        !identical(_manager.owner, owner) ||
        !identical(_manager.revision, revision)) {
      throw StateError('Foreign, stale or consumed future runtime source.');
    }
    worldSuccessor.validate();
    control.validate();
    if (!identical(_facility.owner, owner) ||
        !identical(_facility.revision, revision) ||
        !identical(_facility.provenance, provenance) ||
        !identical(_investment.facilities.world, worldSuccessor) ||
        _crisis.presidentClubs.length != 48 ||
        _domain.clubs.length != 48 ||
        _crisis.presidentClubs.map((club) => club.clubId).toSet().length !=
            48 ||
        !_crisis.presidentClubs
            .any((club) => club.clubId == control.controlledClubId)) {
      throw StateError('Foreign facility/domain/control runtime successor.');
    }
    transferEvidence.validate(worldSuccessor);
    _facility.facilities.validateAgainst(
        worldSuccessor.baseClubs.map((club) => club.id).toSet());
    if (origin == PostoffseasonRuntimeOrigin.firstFutureBootstrap) {
      _token!.validate();
      if (_transfer == null ||
          _annual != null ||
          _manager.completedSeasons.isNotEmpty) {
        throw StateError('Invalid first future runtime lineage.');
      }
    } else {
      _annual!.validate();
      if (_transfer != null || _manager.completedSeasons.isEmpty) {
        throw StateError('Missing completed annual runtime lineage.');
      }
    }
  }

  PostoffseasonRuntimeOrigin get origin => _annual == null
      ? PostoffseasonRuntimeOrigin.firstFutureBootstrap
      : PostoffseasonRuntimeOrigin.postOffseasonContinuation;
  Object get owner => _annual?.owner ?? _token!.owner;
  Object get revision => _annual?.revision ?? _token!.revision;
  Object get provenance => _annual?.provenance ?? _token!.provenance;
  Object get executionIdentity =>
      _annual?.executionIdentity ?? _token!.executionIdentity;
  int get targetSeasonIndex => _facility.world.nextSeasonIndex;
  WorldCheckpoint get worldSuccessor => _facility.world;
  ManagerContinuationAuthority get managerEvidence => _manager;
  FacilityPortfolioRuntimeState get facilities => _facility.facilities;
  PresidentDomainSeasonEffects get domainEvidence => _domain;
  CrisisRuntimeEffects get crisisEvidence => _crisis;
  List<PresidentFacilityInvestmentRuntimeDecision> get investmentDecisions =>
      _investment.decisions;
  // Read-only lineage evidence, not controller ownership or a restore API.
  Object get transferLineageIdentity => executionIdentity;
  int get contractCount =>
      _annual?.advanced.contractCount ?? _transfer!.activeContracts.length;
  AdvancedTransferRuntimeState get transferEvidence =>
      _annual?.advanced.transferEvidence ??
      AdvancedTransferRuntimeState(
          activeContracts: _transfer!.activeContracts,
          contractEvents: _transfer.contractEvents,
          activeLoans: _transfer.activeLoans,
          loanHistory: _transfer.loanHistory,
          installmentObligations: _transfer.installmentObligations);
}
