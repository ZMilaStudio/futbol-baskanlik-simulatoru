part of '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';

/// Consumer contract only. AR-D's owned committed-result producer must be in
/// this library to construct a concrete capability. There is deliberately no
/// production constructor/factory accepting caller-provided reports.
sealed class CommittedSeasonSettlementCapability {
  CommittedSeasonSettlementCapability._(
      {required this.owner,
      required this.revision,
      required this.provenance,
      required this.executionIdentity,
      required this.completedSource,
      required PreparedWorldOpening opening,
      required List<LeagueSeasonSnapshot> reports})
      : _opening = opening,
        reports = List.unmodifiable(reports),
        _signature = _reportSignature(reports),
        _fixtureIdentities = [
          for (final r in reports) List<Object>.unmodifiable(r.report.fixtures)
        ],
        _resultIdentities = [
          for (final r in reports)
            List<Object?>.unmodifiable(r.report.fixtures.map((f) => f.result))
        ],
        _standingIdentities = [
          for (final r in reports) List<Object>.unmodifiable(r.report.table)
        ];
  final Object owner, revision, provenance, executionIdentity, completedSource;
  final PreparedWorldOpening _opening;
  final List<LeagueSeasonSnapshot> reports;
  final String _signature;
  final List<List<Object>> _fixtureIdentities, _standingIdentities;
  final List<List<Object?>> _resultIdentities;
  int get seasonIndex => _opening.seasonIndex;
  List<Club> get effectiveClubs => _opening.effectiveClubs;

  bool _preservesIdentities() {
    for (var i = 0; i < reports.length; i++) {
      final report = reports[i].report;
      if (report.fixtures.length != _fixtureIdentities[i].length ||
          report.table.length != _standingIdentities[i].length) return false;
      for (var j = 0; j < report.fixtures.length; j++) {
        if (!identical(report.fixtures[j], _fixtureIdentities[i][j]) ||
            !identical(report.fixtures[j].result, _resultIdentities[i][j]))
          return false;
      }
      for (var j = 0; j < report.table.length; j++) {
        if (!identical(report.table[j], _standingIdentities[i][j]))
          return false;
      }
    }
    return true;
  }

  void _validate(FullM65RuntimeEconomyContinuationAuthority authority) {
    if (!identical(owner, authority.owner) ||
        !identical(revision, authority.revision) ||
        !identical(provenance, authority.provenance) ||
        !identical(executionIdentity, authority.executionIdentity) ||
        !identical(_opening, authority.opening) ||
        !_preservesIdentities() ||
        _signature != _reportSignature(reports) ||
        reports.length != 3 ||
        reports.map((r) => r.tier).toSet().length != 3 ||
        effectiveClubs.length != 48 ||
        effectiveClubs.map((c) => c.id).toSet().length != 48) {
      throw StateError('Foreign, stale or altered committed capability.');
    }
    final fixtureIds = <String>{};
    for (final league in _opening.leagues) {
      final report = reports.singleWhere((r) => r.tier == league.tier).report;
      final ids = league.clubIds.toSet();
      if (ids.length != 16 ||
          report.seasonIndex != seasonIndex ||
          report.seed != _opening.config.careerSeed ||
          report.table.length != 16 ||
          report.table.map((r) => r.clubId).toSet().length != 16 ||
          !report.table
              .every((r) => ids.contains(r.clubId) && r.played == 30) ||
          report.fixtures.length != 240)
        throw StateError('Incomplete committed league.');
      final pairs = <String>{};
      for (final f in report.fixtures) {
        if (f.seasonIndex != seasonIndex ||
            !f.isPlayed ||
            f.round < 1 ||
            f.round > 30 ||
            !ids.contains(f.homeClubId) ||
            !ids.contains(f.awayClubId) ||
            f.homeClubId == f.awayClubId ||
            !fixtureIds.add('${league.tier.level}:${f.id}') ||
            !pairs.add('${f.homeClubId}/${f.awayClubId}')) {
          throw StateError('Invalid committed fixture coverage.');
        }
      }
      for (var round = 1; round <= 30; round++) {
        final fixtures =
            report.fixtures.where((f) => f.round == round).toList();
        final participants =
            fixtures.expand((f) => [f.homeClubId, f.awayClubId]).toSet();
        if (fixtures.length != 8 || participants.length != 16) {
          throw StateError('Incomplete committed round.');
        }
      }
    }
    if (fixtureIds.length != 720)
      throw StateError('Incomplete committed season.');
  }
}

final class _FutureCommittedSeasonSettlementCapability
    extends CommittedSeasonSettlementCapability {
  _FutureCommittedSeasonSettlementCapability._({
    required Object owner,
    required Object revision,
    required Object provenance,
    required Object executionIdentity,
    required PlayerPresidentFutureCommittedSeasonResult completedSource,
    required PreparedWorldOpening opening,
    required List<LeagueSeasonSnapshot> reports,
    required this.managerAuthority,
    required List<PresidentPromiseContext> promiseContexts,
    required List<PresidentPromise> activePromises,
    required this.origin,
  })  : promiseContexts = promiseContexts,
        activePromises = activePromises,
        super._(
          owner: owner,
          revision: revision,
          provenance: provenance,
          executionIdentity: executionIdentity,
          completedSource: completedSource,
          opening: opening,
          reports: reports,
        );

  final ManagerSeasonAuthority managerAuthority;
  final List<PresidentPromiseContext> promiseContexts;
  final List<PresidentPromise> activePromises;
  final PostoffseasonRuntimeOrigin origin;

  void validateFuture(FullM65RuntimeEconomyContinuationAuthority authority) {
    _validate(authority);
    final source =
        completedSource as PlayerPresidentFutureCommittedSeasonResult;
    if (!identical(source.capability, this) ||
        !identical(source.managerAuthority, managerAuthority) ||
        !identical(managerAuthority, authority.managerAuthority) ||
        source.origin != origin ||
        promiseContexts.length != 48 ||
        activePromises.length != 48 ||
        promiseContexts.map((c) => c.clubId).toSet().length != 48 ||
        activePromises.map((p) => p.clubId).toSet().length != 48 ||
        activePromises.map((p) => p.id).toSet().length != 48 ||
        activePromises.any((p) => p.seasonIndex != seasonIndex) ||
        !identical(source.applied.activePromises, activePromises)) {
      throw StateError('Foreign or altered future committed authority.');
    }
  }
}

String _reportSignature(List<LeagueSeasonSnapshot> reports) => jsonEncode([
      for (final r in reports)
        [
          r.tier.level,
          r.report.toJson(),
          for (final f in r.report.fixtures)
            [
              f.id,
              f.seasonIndex,
              f.round,
              f.homeClubId,
              f.awayClubId,
              [
                f.result?.homeGoals,
                f.result?.awayGoals,
                f.result?.homeExpectedGoals,
                f.result?.awayExpectedGoals,
                f.result?.matchSeed
              ]
            ]
        ]
    ]);

enum RuntimeEconomyState {
  awaitingCommittedSeason,
  awaitingTicketDecision,
  decisionContractUnavailable,
  ready,
  settling,
  settled,
  failed
}

final class RuntimeEconomyTicketPending {
  RuntimeEconomyTicketPending._(this._authority, this.context);
  final FullM65RuntimeEconomyContinuationAuthority _authority;
  final PlayerPresidentTicketPricingDecisionContext context;
  Object get owner => _authority.owner;
  Object get revision => _authority.revision;
  Object get executionIdentity => _authority.executionIdentity;
  int get seasonIndex => context.seasonIndex;
  String get controlledClubId => context.clubId;
}

final class FullM65CommittedSeasonSettlementResult {
  FullM65CommittedSeasonSettlementResult._(
      this.committedSource, this.receipt, this.executionIdentity)
      : closingFinanceStates = List.unmodifiable(receipt.results.map((r) =>
            ClubFinanceState(
                clubId: r.clubId, cash: r.closingCash, debt: r.closingDebt)));
  final CommittedSeasonSettlementCapability committedSource;
  final SeasonFinanceAuthorityReceipt receipt;
  final Object executionIdentity;
  final List<ClubFinanceState> closingFinanceStates;
  Object get owner => receipt.owner;
  Object get revision => receipt.sourceRevision;
  Object get provenance => receipt.provenance;
}

/// Runtime-only owner of the original, unattempted full-M65 graph.
final class FullM65RuntimeEconomyContinuationAuthority {
  FullM65RuntimeEconomyContinuationAuthority._(
      this._source, this._pipeline, this.managerAuthority,
      [this._futureCommitted]);

  factory FullM65RuntimeEconomyContinuationAuthority.claim(
      PreparedTicketRuntimeSeason source,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance,
      required Object expectedExecution}) {
    source._requireUnreservedOpening();
    return _claimPrepared(
      source,
      expectedOwner: expectedOwner,
      expectedRevision: expectedRevision,
      expectedProvenance: expectedProvenance,
      expectedExecution: expectedExecution,
    );
  }

  static FullM65RuntimeEconomyContinuationAuthority _claimFuture(
    PreparedTicketRuntimeSeason source,
    CommittedSeasonSettlementCapability capability,
  ) {
    if (capability is! _FutureCommittedSeasonSettlementCapability) {
      throw StateError('Future economy requires its genuine W30 capability.');
    }
    final authority = _claimPrepared(
      source,
      expectedOwner: source.owner,
      expectedRevision: source.revision,
      expectedProvenance: source.provenance,
      expectedExecution: source.executionIdentity,
      futureCommitted: capability,
    );
    capability.validateFuture(authority);
    return authority;
  }

  static FullM65RuntimeEconomyContinuationAuthority _claimPrepared(
    PreparedTicketRuntimeSeason source, {
    required Object expectedOwner,
    required Object expectedRevision,
    required Object expectedProvenance,
    required Object expectedExecution,
    _FutureCommittedSeasonSettlementCapability? futureCommitted,
  }) {
    final manager = source.managerAuthority;
    if (source.state != PreparedExecutionState.prepared ||
        source._annualCaptureAttempted ||
        !identical(source.owner, expectedOwner) ||
        !identical(source.revision, expectedRevision) ||
        !identical(source.provenance, expectedProvenance) ||
        !identical(source.executionIdentity, expectedExecution) ||
        manager == null ||
        !identical(manager.owner, expectedOwner) ||
        !identical(manager.sourceRevision, expectedRevision) ||
        manager.seasonIndex != source.opening.seasonIndex ||
        !identical(manager.effectiveClubs, source.opening.effectiveClubs) ||
        source._pricing.financeRecording != null ||
        source._pricing._decisions.isNotEmpty) {
      throw StateError(
          'Economy claim requires genuine unattempted manager-bound preparation.');
    }
    source._facility.validateEconomyHandoff();
    final pipeline = FullM65SeasonFinancePipeline(
        owner: expectedOwner,
        sourceRevision: expectedRevision,
        provenance: expectedProvenance,
        seasonIndex: source.opening.seasonIndex,
        effectiveClubSource: manager);
    final authority = FullM65RuntimeEconomyContinuationAuthority._(
      source,
      pipeline,
      manager,
      futureCommitted,
    );
    final recipient = source._facility.moveToEconomy(
        authority: authority,
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance,
        recording: pipeline);
    source._pricing._claimedRecording = pipeline;
    authority._recipient = recipient;
    return authority;
  }

  final PreparedTicketRuntimeSeason _source;
  late final FacilityEconomyRecipient _recipient;
  final FullM65SeasonFinancePipeline _pipeline;
  final ManagerSeasonAuthority managerAuthority;
  final _FutureCommittedSeasonSettlementCapability? _futureCommitted;
  Object get owner => _source.owner;
  Object get revision => _source.revision;
  Object get provenance => _source.provenance;
  Object get executionIdentity => _source.executionIdentity;
  PreparedWorldOpening get opening => _source.opening;
  int get contractCount => _recipient.contractCount;
  int get sponsorProcessedClubCount => _recipient.processedSponsorClubCount;
  int get ticketDecisionCount => _source.ticketDecisionCount;
  RuntimeEconomyState _state = RuntimeEconomyState.awaitingCommittedSeason;
  RuntimeEconomyState get state => _state;
  CommittedSeasonSettlementCapability? _committed;
  RuntimeEconomyTicketPending? _pending;
  RuntimeEconomyTicketPending? get pending => _pending;
  MatchdayTicketPricingChoice? _answer;
  FullM65CommittedSeasonSettlementResult? _result;
  FullM65CommittedSeasonSettlementResult? get result => _result;
  bool _releaseAttempted = false;
  bool _released = false;
  List<PresidentPromiseContext>? _releasedPromiseContexts;
  List<PresidentPromise>? _releasedPromises;
  List<PresidentPromiseContext>? get releasedPromiseContexts =>
      _releasedPromiseContexts;
  List<PresidentPromise>? get releasedPromises => _releasedPromises;
  bool permitsAnnualRelease(PreparedWorldOpening expectedOpening,
          Object expectedExecution, SeasonFinanceAuthorityReceipt receipt) =>
      _state == RuntimeEconomyState.settled &&
      _releaseAttempted &&
      !_released &&
      identical(expectedOpening, opening) &&
      identical(expectedExecution, executionIdentity) &&
      identical(receipt, _result?.receipt);

  /// Settled-only original-graph handoff. This does not mint an AR-D committed
  /// capability and never recalculates the annual settlement.
  OwnedAnnualClosingBoundary releaseSettledAnnualClosing({
    required FullM65CommittedSeasonSettlementResult expectedResult,
    required Object expectedOwner,
    required Object expectedRevision,
    required Object expectedProvenance,
    required Object expectedExecution,
    required SinglePassPostseasonRuntimeTransition recipient,
    required bool hasNextSeason,
  }) {
    if (_state != RuntimeEconomyState.settled ||
        _releaseAttempted ||
        _released ||
        !identical(expectedResult, _result) ||
        !identical(expectedOwner, owner) ||
        !identical(expectedRevision, revision) ||
        !identical(expectedProvenance, provenance) ||
        !identical(expectedExecution, executionIdentity) ||
        !recipient.permitsSettledEconomyRelease(this, expectedResult)) {
      throw StateError('Foreign, unsettled or consumed economy release.');
    }
    expectedResult.receipt.verify(
        expectedOwner: owner,
        expectedRevision: revision,
        expectedProvenance: provenance,
        expectedSeason: opening.seasonIndex,
        expectedResults: expectedResult.receipt.results,
        expectedEffectiveClubSource: managerAuthority);
    _releaseAttempted = true;
    _source._annualCaptureAttempted = true;
    final future = _futureCommitted;
    final List<PresidentPromiseContext> contexts;
    final List<PresidentPromise> promises;
    if (future != null) {
      future.validateFuture(this);
      contexts = future.promiseContexts;
      promises = future.activePromises;
    } else {
      contexts = const PromiseOpeningContextBuilder().build(
          seasonIndex: opening.seasonIndex,
          effectiveClubs: opening.effectiveClubs,
          leagues: opening.leagues,
          openingFinanceStates: opening.financeStates);
      promises = List<PresidentPromise>.unmodifiable(contexts.map((context) =>
          _source._producer.sourceEngine.promiseEngine.generator.generate(
              context: context,
              careerSeed: opening.config.careerSeed,
              simulationVersion: opening.config.simulationVersion)));
    }
    final closing = _recipient.releaseSettledAnnualClosing(
        authority: this,
        committed: expectedResult.committedSource,
        receipt: expectedResult.receipt);
    _source._facility
        .bindReleasedAnnualClosing(closing, this, expectedResult.receipt);
    final boundary = OwnedAnnualClosingBoundary._(_source, closing,
        expectedResult.receipt, contexts, promises, hasNextSeason);
    _releasedPromiseContexts = contexts;
    _releasedPromises = promises;
    _released = true;
    return boundary;
  }

  /// Read-only cross-library gates. They do not mint or accept caller authority.
  bool ownsPreparedGraph(
          PreparedWorldOpening expectedOpening, Object expectedExecution) =>
      _state == RuntimeEconomyState.awaitingCommittedSeason &&
      identical(opening, expectedOpening) &&
      identical(executionIdentity, expectedExecution);
  bool permitsCommittedExecution(
          CommittedSeasonSettlementCapability expectedCommitted,
          PreparedWorldOpening expectedOpening,
          Object expectedExecution) =>
      _state == RuntimeEconomyState.settling &&
      identical(_committed, expectedCommitted) &&
      identical(opening, expectedOpening) &&
      identical(executionIdentity, expectedExecution);

  RuntimeEconomyState prepareSettlement(
      CommittedSeasonSettlementCapability source) {
    if (_state != RuntimeEconomyState.awaitingCommittedSeason) {
      if (identical(source, _committed) &&
          (_state == RuntimeEconomyState.awaitingTicketDecision ||
              _state == RuntimeEconomyState.ready ||
              _state == RuntimeEconomyState.decisionContractUnavailable)) {
        source._validate(this);
        return _state;
      }
      throw StateError('Committed admission already consumed.');
    }
    source._validate(this);
    final future = _futureCommitted;
    if (future != null) {
      if (!identical(source, future)) {
        throw StateError('Future economy requires its exact W30 capability.');
      }
      future.validateFuture(this);
    }
    final clubs = {for (final c in opening.effectiveClubs) c.id: c};
    final contexts = <String, PlayerPresidentTicketPricingDecisionContext>{};
    final attendance = <String, FinanceAttendanceEvidence>{};
    for (final league in source.reports) {
      for (var i = 0; i < league.report.table.length; i++) {
        final club = clubs[league.report.table[i].clubId]!;
        final context =
            _source._pricing._prepareContext(club, opening.seasonIndex, i + 1);
        final evidence = _recipient.prepareAttendance(club, i + 1);
        if (evidence.multiplierBps !=
            context.baseAttendance.revenueMultiplierBps) {
          throw StateError('Attendance/pricing preflight mismatch.');
        }
        contexts[club.id] = context;
        attendance[club.id] = evidence;
      }
    }
    final tenure = _source.tenureControl;
    final controlled = contexts[tenure.controlledClubId]!;
    final unavailable = tenure.active &&
        controlled.president.presidentId != tenure.playerPresidentId;
    final pending = tenure.active && !unavailable
        ? RuntimeEconomyTicketPending._(this, controlled)
        : null;
    // All fallible construction/validation precedes admission publication.
    _recipient.cacheAttendance(attendance);
    _source._pricing._preparedContexts = Map.unmodifiable(contexts);
    _committed = source;
    _pending = pending;
    _state = unavailable
        ? RuntimeEconomyState.decisionContractUnavailable
        : pending != null
            ? RuntimeEconomyState.awaitingTicketDecision
            : RuntimeEconomyState.ready;
    return _state;
  }

  void submitTicket(RuntimeEconomyTicketPending expectedPending, Object choice,
      {required Object expectedRevision}) {
    if (!identical(expectedPending, _pending) ||
        !identical(expectedPending._authority, this) ||
        !identical(expectedRevision, revision) ||
        choice is! MatchdayTicketPricingChoice ||
        choice.runtimeType != MatchdayTicketPricingChoice) {
      throw StateError('Foreign, stale or wrongly typed ticket answer.');
    }
    if (_answer != null && _state == RuntimeEconomyState.ready) {
      if (_answer!.tier == choice.tier) return;
      throw StateError('Conflicting duplicate ticket answer.');
    }
    if (_state != RuntimeEconomyState.awaitingTicketDecision)
      throw StateError('Stale ticket phase.');
    _committed!._validate(this);
    _answer = choice;
    _state = RuntimeEconomyState.ready;
  }

  FullM65CommittedSeasonSettlementResult executeSettlement(
      {required CommittedSeasonSettlementCapability expectedCommitted}) {
    if (_state != RuntimeEconomyState.ready ||
        !identical(expectedCommitted, _committed)) {
      throw StateError(
          'Settlement is not ready or has already been attempted.');
    }
    expectedCommitted._validate(this);
    final strictProvider = _pending == null
        ? null
        : _AcceptedTicketProvider(
            _pending!.context, _answer!, _source._pricing.playerProvider);
    _source._pricing._strictProvider = strictProvider;
    _state = RuntimeEconomyState.settling;
    try {
      final rows = _pipeline.record(() => _recipient.executeCommittedFinance(
          expectedExecution: executionIdentity, committed: expectedCommitted));
      final receipt = _pipeline.receipt!;
      receipt.verify(
          expectedOwner: owner,
          expectedRevision: revision,
          expectedProvenance: provenance,
          expectedSeason: opening.seasonIndex,
          expectedResults: rows,
          expectedEffectiveClubSource: managerAuthority);
      final result = FullM65CommittedSeasonSettlementResult._(
          expectedCommitted, receipt, executionIdentity);
      _result = result;
      _state = RuntimeEconomyState.settled;
      return result;
    } catch (_) {
      _state = RuntimeEconomyState.failed;
      rethrow;
    }
  }
}

final class _AcceptedTicketProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  _AcceptedTicketProvider(this.context, this.answer, this.original);
  final PlayerPresidentTicketPricingDecisionContext context;
  final MatchdayTicketPricingChoice answer;
  final PlayerMatchdayTicketPricingDecisionProvider? original;
  @override
  MatchdayTicketPricingChoice choose(
      PlayerPresidentTicketPricingDecisionContext value) {
    if (!identical(context, value))
      throw StateError('Foreign execution context.');
    return answer;
  }

  @override
  void onApplied(PlayerPresidentTicketPricingDecision value) =>
      original?.onApplied(value);
}
