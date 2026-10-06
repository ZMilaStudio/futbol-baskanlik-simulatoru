part of '../player_president/player_president_postseason_runtime_transition.dart';

enum PostoffseasonRuntimeOrigin {
  firstFutureBootstrap,
  postOffseasonContinuation
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
}
