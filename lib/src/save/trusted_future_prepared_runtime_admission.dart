part of '../player_president/player_president_postseason_runtime_transition.dart';

/// Immutable evidence of an application-bound, exclusive future preparation.
/// The concrete mint lives in the graph's producer library, not in a raw DTO
/// constructor. Controllers and coordinators never escape this object.
final class TrustedFuturePreparedRuntimeAdmission {
  TrustedFuturePreparedRuntimeAdmission._(this._claim, this.prepared);
  final FutureRuntimeClaim _claim;
  final PreparedTicketRuntimeSeason prepared;
  LosslessPostOffseasonRuntimeGraph get sourceGraph => _claim.source;
  int get careerSeed => sourceGraph.worldSuccessor.config.careerSeed;
  int get simulationVersion =>
      sourceGraph.worldSuccessor.config.simulationVersion;
  String get controlledClubId => sourceGraph.control.controlledClubId;
  PlayerPresidentTenureControlState get control => sourceGraph.control;
  Object get managerLineageIdentity => prepared.managerLineage;
  Object get transferLineageIdentity => prepared.transferLineage;
  Object get sourceOwner => _claim.source.owner;
  Object get sourceRevision => _claim.source.revision;
  Object get sourceProvenance => _claim.source.provenance;
  Object get sourceExecutionIdentity => _claim.source.executionIdentity;
  Object get applicationOwner => _claim.entry.owner;
  Object get applicationEntryIdentity => _claim.entry;
  Object get targetExecutionIdentity => _claim.entry.executionIdentity;
  int get targetSeasonIndex => _claim.source.targetSeasonIndex;
  PostoffseasonRuntimeOrigin get origin => _claim.source.origin;
}

/// Common unforgeable root for cross-library child recipients. It is issued
/// only after pure graph/application preflight and commits without callbacks.
final class FutureRuntimeClaim {
  FutureRuntimeClaim._(this.source, this.entry);
  final LosslessPostOffseasonRuntimeGraph source;
  final ApplicationFutureRuntimeEntry entry;
  bool _committed = false;
  FutureTransferRuntime? _stagedTransfer;
  FutureManagerRecipient? _manager;
  FutureTransferRuntime get transferRecipient => _stagedTransfer!;
  FutureManagerRecipient get managerRecipient => _manager!;
  bool _worldPrepared = false;
  Object get owner => entry.owner;
  Object get revision => entry.revision;
  Object get provenance => source;
  Object get executionIdentity => entry.executionIdentity;
  FacilitySponsorPostseasonContinuation get facilityRecipient =>
      source._facility;
  List<PresidentClubRuntimeState> get presidentClubs =>
      source._crisis.presidentClubs;
  int get electionInterval =>
      source._annual?.electionInterval ??
      source._token!.source.sourceState.boundary.proof.presidentOpening
          .electionInterval;
  int get completedElectionTerms => source._domain.completedElectionTerms;
  int get seasonsIntoCurrentTerm => source._domain.seasonsIntoCurrentTerm;
  Map<String, List<int>> get termPromiseScores =>
      source._domain.termPromiseScores;
  void validateChild(Object child) {
    entry.validate(source);
    if (!(_committed
            ? source._admissionState ==
                    FutureRuntimeAdmissionState.claimedForFuturePreparation ||
                source._admissionState == FutureRuntimeAdmissionState.prepared
            : source._admissionState ==
                FutureRuntimeAdmissionState.available) ||
        !(identical(child, source._manager) ||
            identical(child, source._facility) ||
            identical(child, source._annual?.advanced) ||
            identical(child, source.worldSuccessor))) {
      throw StateError('Foreign or inactive future runtime child claim.');
    }
  }

  FutureTransferRuntime prepareTransferRecipient() {
    if (_stagedTransfer != null)
      throw StateError('Transfer recipient already staged.');
    return _stagedTransfer = source._annual == null
        ? _FirstFutureTransferRecipient._(this, source._transfer!)
        : source._annual!.advanced.stageFutureTransfer(this);
  }

  FutureManagerRecipient prepareManagerRecipient() {
    if (_manager != null) throw StateError('Manager recipient already staged.');
    return _manager = source._manager.stageFutureRecipient(this);
  }

  void validateRecipients(
      FutureTransferRuntime transfer, FutureManagerRecipient manager) {
    validateChild(source.worldSuccessor);
    if (!identical(transfer, _stagedTransfer) ||
        !identical(manager, _manager)) {
      throw StateError('Foreign future child recipients.');
    }
  }

  void claimWorldPreparation(
      FutureTransferRuntime transfer, FutureManagerRecipient manager) {
    validateRecipients(transfer, manager);
    if (!_committed || _worldPrepared) {
      throw StateError('Future preparation is not exclusively owned.');
    }
    _worldPrepared = true;
  }

  void requirePreparationCommit() {
    validateChild(source.worldSuccessor);
    if (!_committed ||
        source.admissionState !=
            FutureRuntimeAdmissionState.claimedForFuturePreparation) {
      throw StateError(
          'Future recipient has not acquired exclusive ownership.');
    }
  }
}

/// Opaque operational recipient, not a controller getter or restore source.
/// Only the common claim's exact staged recipient authorizes preparation.
abstract interface class FutureTransferRuntime
    implements WorldRosterHooks, WorldFinanceHooks, WorldTransferHooks {
  Object get lineageIdentity;
  int get contractCount;
  AdvancedTransferRuntimeState snapshot();

  /// Rebinds the same private controller to the next genuine application
  /// claim. No snapshot restore, reconstruction or controller escape occurs.
  FutureTransferRuntime restage(FutureRuntimeClaim claim);
}

final class _FirstFutureTransferRecipient implements FutureTransferRuntime {
  _FirstFutureTransferRecipient._(this._claim, this._controller);
  final FutureRuntimeClaim _claim;
  final AdvancedTransferController _controller;
  void _check() => _claim.validateChild(_claim.source.worldSuccessor);
  @override
  Object get lineageIdentity => _claim.source.transferLineageIdentity;
  @override
  int get contractCount => _controller.activeContracts.length;
  @override
  AdvancedTransferRuntimeState snapshot() {
    _check();
    return AdvancedTransferRuntimeState(
        activeContracts: _controller.activeContracts,
        contractEvents: _controller.contractEvents,
        activeLoans: _controller.activeLoans,
        loanHistory: _controller.loanHistory,
        installmentObligations: _controller.installmentObligations);
  }

  @override
  FutureTransferRuntime restage(FutureRuntimeClaim claim) {
    _check();
    return _FirstFutureTransferRecipient._(claim, _controller);
  }

  @override
  Map<String, Money>? annualWagesByClub(
      {required int seasonIndex,
      required List<Player> players,
      required List<Club> clubs,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> financeStates}) {
    _check();
    return _controller.annualWagesByClub(
        seasonIndex: seasonIndex,
        players: players,
        clubs: clubs,
        leagues: leagues,
        financeStates: financeStates);
  }

  @override
  WorldFinanceSeasonFlows flowsForSeason(
      {required int seasonIndex,
      required List<Club> clubs,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> openingFinanceStates}) {
    _check();
    return _controller.flowsForSeason(
        seasonIndex: seasonIndex,
        clubs: clubs,
        leagues: leagues,
        openingFinanceStates: openingFinanceStates);
  }

  @override
  List<Player> prepareNextSeasonPlayers(
      {required int seasonIndex,
      required int nextSeasonIndex,
      required List<Player> activePlayers,
      required List<Player> retiredPlayers,
      required List<Player> youthIntake,
      required List<Club> clubs,
      required List<WorldLeague> leaguesForNextSeason,
      required List<ClubFinanceState> financeStates}) {
    _check();
    return _controller.prepareNextSeasonPlayers(
        seasonIndex: seasonIndex,
        nextSeasonIndex: nextSeasonIndex,
        activePlayers: activePlayers,
        retiredPlayers: retiredPlayers,
        youthIntake: youthIntake,
        clubs: clubs,
        leaguesForNextSeason: leaguesForNextSeason,
        financeStates: financeStates);
  }

  @override
  Map<String, int>? contractYearsRemainingForTransfer(
      {required int nextSeasonIndex, required List<Player> players}) {
    _check();
    return _controller.contractYearsRemainingForTransfer(
        nextSeasonIndex: nextSeasonIndex, players: players);
  }

  @override
  void onTransferWindowCompleted(
      {required int seasonIndex,
      required int nextSeasonIndex,
      required List<Player> playersBeforeWindow,
      required List<Player> playersAfterWindow,
      required List<TransferDeal> transfers,
      required List<Club> clubs,
      required List<WorldLeague> leaguesForNextSeason,
      required List<ClubFinanceState> financeStates}) {
    _check();
    _controller.onTransferWindowCompleted(
        seasonIndex: seasonIndex,
        nextSeasonIndex: nextSeasonIndex,
        playersBeforeWindow: playersBeforeWindow,
        playersAfterWindow: playersAfterWindow,
        transfers: transfers,
        clubs: clubs,
        leaguesForNextSeason: leaguesForNextSeason,
        financeStates: financeStates);
  }

  @override
  WorldTransferPostProcessResult afterPermanentTransfers(
      {required int seasonIndex,
      required int nextSeasonIndex,
      required List<Player> players,
      required List<ClubFinanceState> financeStates,
      required List<TransferDeal> permanentTransfers,
      required List<Club> clubs,
      required List<WorldLeague> leaguesForNextSeason}) {
    _check();
    return _controller.afterPermanentTransfers(
        seasonIndex: seasonIndex,
        nextSeasonIndex: nextSeasonIndex,
        players: players,
        financeStates: financeStates,
        permanentTransfers: permanentTransfers,
        clubs: clubs,
        leaguesForNextSeason: leaguesForNextSeason);
  }
}
