import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../crisis/crisis_runtime_integration.dart';
import '../crisis/facility_sponsor_crisis_runtime_composition.dart';
import '../crisis/president_facility_investment_runtime_integration.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_management_profile.dart';
import '../election/president_opening_state_initializer.dart';
import '../fan/fan_state.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../finance/season_finance_authority_receipt.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_career_season.dart';
import '../player/player.dart';
import '../promise/promise_media_career_engine.dart';
import '../promise/promise_context.dart';
import '../promise/promise_resolution.dart';
import '../promise/promise_season_snapshot.dart';
import '../promise/promise_opening_context_builder.dart';
import '../promise/president_promise.dart';
import '../save/president_runtime_checkpoint.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/facility_runtime_checkpoint.dart';
import '../save/save_checksum.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/save_load_exception.dart';
import '../season/season_report.dart';
import '../sponsor/sponsor_system.dart';
import '../world/world_career_engine.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import '../world/world_checkpoint.dart';
import '../player_president/player_president_postseason_runtime_transition.dart';
import 'player_president_tenure_gated_ticket_pricing_control.dart';
import 'stadium_facility.dart';

part '../finance/full_m65_runtime_economy_continuation_authority.dart';

class PlayerPresidentTicketPricingRuntimeCheckpoint {
  PlayerPresidentTicketPricingRuntimeCheckpoint({
    required this.runtime,
    required this.tenureControl,
  }) {
    validate();
  }

  final FacilitySponsorCrisisRuntimeCheckpoint runtime;
  final PlayerPresidentTenureControlState tenureControl;

  int get nextSeasonIndex => runtime.nextSeasonIndex;
  int get completedSeasons => runtime.completedSeasons;
  String get controlledClubId => tenureControl.controlledClubId;
  bool get playerControlActive => tenureControl.active;

  void validate() {
    runtime.validate();
    tenureControl.validate();
    final clubIds = runtime
        .runtime.domain.presidentRuntime.runtime.runtime.world.baseClubs
        .map((club) => club.id)
        .toSet();
    if (!clubIds.contains(tenureControl.controlledClubId)) {
      throw ArgumentError(
        'Unknown ticket-pricing controlled club ${tenureControl.controlledClubId}.',
      );
    }
  }

  String get signature =>
      'tenure=${tenureControl.signature}:runtime=${runtime.signature}';
}

class PlayerPresidentTicketPricingRuntimeSaveCodec {
  const PlayerPresidentTicketPricingRuntimeSaveCodec({
    this.runtimeCodec = const FacilitySponsorCrisisRuntimeSaveCodec(),
    this.tenureCodec = const PlayerPresidentTenureControlSaveCodec(),
  });

  static const String format =
      'zmila-fbs-player-president-ticket-pricing-runtime';
  static const int currentSaveVersion = 1;

  final FacilitySponsorCrisisRuntimeSaveCodec runtimeCodec;
  final PlayerPresidentTenureControlSaveCodec tenureCodec;

  String encode(PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'runtimeSave': runtimeCodec.encode(checkpoint.runtime),
      'tenureControlSave': tenureCodec.encode(checkpoint.tenureControl),
    };
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': SaveChecksum.forPayload(
        saveVersion: currentSaveVersion,
        payload: payload,
      ),
    });
  }

  PlayerPresidentTicketPricingRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Ticket-pricing runtime save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Ticket-pricing runtime save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown ticket-pricing runtime save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported ticket-pricing runtime save version $version.',
      );
    }
    final payloadObject = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum !=
            SaveChecksum.forPayload(
              saveVersion: version,
              payload: payloadObject,
            )) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Ticket-pricing runtime save checksum mismatch.',
      );
    }
    if (version != 1 || payloadObject is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Ticket-pricing runtime save payload is invalid.',
      );
    }
    final payload = Map<String, Object?>.from(payloadObject);
    final runtimeSave = payload['runtimeSave'];
    final tenureControlSave = payload['tenureControlSave'];
    if (runtimeSave is! String || tenureControlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Ticket-pricing runtime payload fields are invalid.',
      );
    }
    try {
      return PlayerPresidentTicketPricingRuntimeCheckpoint(
        runtime: runtimeCodec.decode(runtimeSave),
        tenureControl: tenureCodec.decode(tenureControlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid ticket-pricing runtime payload: $error',
      );
    }
  }
}

class PlayerPresidentTicketPricingRuntimeSeasonBoundary {
  PlayerPresidentTicketPricingRuntimeSeasonBoundary({
    required this.source,
    required Iterable<PlayerPresidentTicketPricingDecision> pricingDecisions,
    required this.checkpoint,
  }) : pricingDecisions = List.unmodifiable(
          pricingDecisions.toList(growable: false)
            ..sort((a, b) => a.context.clubId.compareTo(b.context.clubId)),
        ) {
    if (this.pricingDecisions.length != 48) {
      throw StateError(
        'Ticket-pricing runtime must resolve all 48 clubs, got '
        '${this.pricingDecisions.length}.',
      );
    }
  }

  final PresidentFacilityInvestmentRuntimeSeasonBoundary source;
  final List<PlayerPresidentTicketPricingDecision> pricingDecisions;
  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;

  int get seasonIndex => source.seasonIndex;

  PlayerPresidentTicketPricingDecision decisionFor(String clubId) =>
      pricingDecisions.firstWhere((item) => item.context.clubId == clubId);

  ClubFinanceSeason financeFor(String clubId) => source.source.sponsor.report
      .sourceReport.advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == clubId);

  String get signature => 'season=$seasonIndex:pricing='
      '${pricingDecisions.map((item) => item.signature).join('|')}:'
      'source=${source.signature}:final=${checkpoint.signature}';
}

class PlayerPresidentTicketPricingRuntimeCareerResult {
  PlayerPresidentTicketPricingRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<PlayerPresidentTicketPricingRuntimeSeasonBoundary>
        boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  final List<PlayerPresidentTicketPricingRuntimeSeasonBoundary> boundaries;

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M65 wires M64 ticket-pricing decisions into the real M47/M48 economy seam.
///
/// M47 already computes the authoritative stadium + fan-trust matchday revenue
/// multiplier and forwards it to [BasicEconomyEngine]. This integration wraps
/// that final economy delegate, verifies the received multiplier still matches
/// the same M40/M41 attendance model, then replaces only that multiplier with
/// M64's pricing outcome. Sponsor, crisis, facility investment, election, fan,
/// media, save/resume, and world semantics stay on the existing runtime path.
/// The player provider remains runtime-only; tenure ownership is persisted in
/// this checkpoint and refreshed after every completed season.
/// Owns the actual pricing graph and its nested facility/advanced lease.
/// Execution yields the advanced result only; no new domain publisher is added.
/// Genuine legacy production closing, captured after annual settlement and
/// before movement, manager completion or offseason. Not an AR-D W30 producer.
final class OwnedAnnualClosingBoundary {
  OwnedAnnualClosingBoundary._(this._prepared, this.advanced, this.receipt,
      this.promiseContexts, this.acceptedPromises, this.hasNextSeason) {
    validate();
  }
  final PreparedTicketRuntimeSeason _prepared;
  final OwnedAdvancedAnnualClosing advanced;
  final SeasonFinanceAuthorityReceipt receipt;
  final List<PresidentPromiseContext> promiseContexts;
  final List<PresidentPromise> acceptedPromises;
  final bool hasNextSeason;
  Object get owner => _prepared.owner;
  Object get revision => _prepared.revision;
  Object get provenance => _prepared.provenance;
  Object get executionIdentity => _prepared.executionIdentity;
  PlayerPresidentTenureControlState get tenureControl =>
      _prepared.tenureControl;
  List<PresidentClubRuntimeState> get presidentStates =>
      _prepared._context.presidentStates;
  int get electionInterval => _prepared._context.electionInterval;
  int get completedElectionTerms => _prepared._context.completedElectionTerms;
  int get seasonsIntoCurrentTerm => _prepared._context.seasonsIntoCurrentTerm;
  Map<String, List<int>> get termPromiseScores =>
      _prepared._context.termPromiseScores;
  FacilityPortfolioRuntimeState get facilities => _prepared.facilities;

  /// Uses the exact accepted promise and resolver owned by the producer graph.
  /// It neither regenerates a promise nor replays the annual runtime.
  PromiseResolution resolveOwnedPromise({
    required SinglePassPostseasonRuntimeTransition transition,
    required PresidentPromise promise,
    required PresidentPromiseOutcome outcome,
  }) {
    advanced.validateTransition(transition);
    if (!acceptedPromises.any((p) => identical(p, promise))) {
      throw StateError('Foreign annual-closing promise.');
    }
    return _prepared._producer.sourceEngine.promiseEngine.resolver
        .resolve(promise: promise, outcome: outcome);
  }

  Object? _claim;
  bool _domainProjected = false;
  bool _crisisProjected = false;
  bool _investmentProjected = false;
  bool _controlRefreshed = false;

  void _requireCalculation(SinglePassPostseasonRuntimeTransition transition,
      PostseasonRuntimeTransitionPhase phase) {
    advanced.validateTransition(transition);
    if (transition.phase != phase) {
      throw StateError('Wrong owned successor calculation phase.');
    }
  }

  PresidentDomainSeasonEffects projectOwnedDomain({
    required SinglePassPostseasonRuntimeTransition transition,
    required WorldCareerSeason season,
    required Iterable<PromiseSeasonSnapshot> acceptedPromises,
    required ManagerCareerSeason managerSeason,
  }) {
    _requireCalculation(
        transition, PostseasonRuntimeTransitionPhase.transferFollowupComplete);
    if (_domainProjected)
      throw StateError('Domain projection already consumed.');
    _domainProjected = true;
    return _prepared._facility.projectOwnedDomainSeason(
        closing: advanced,
        transition: transition,
        season: season,
        priorClubs: presidentStates,
        acceptedPromises: acceptedPromises,
        electionInterval: electionInterval,
        completedElectionTerms: completedElectionTerms,
        seasonsIntoCurrentTerm: seasonsIntoCurrentTerm,
        priorTermPromiseScores: termPromiseScores,
        hasNextSeason: hasNextSeason,
        managerSeason: managerSeason);
  }

  CrisisRuntimeEffects projectOwnedCrisis({
    required SinglePassPostseasonRuntimeTransition transition,
    required Iterable<PresidentClubRuntimeState> presidentClubs,
    required Iterable<ClubFinanceState> financeStates,
  }) {
    _requireCalculation(
        transition, PostseasonRuntimeTransitionPhase.domainReady);
    if (_crisisProjected)
      throw StateError('Crisis projection already consumed.');
    _crisisProjected = true;
    return _prepared._producer.crisisIntegration.projectEffects(
        seasonIndex: advanced.world.opening.seasonIndex,
        presidentClubs: presidentClubs,
        financeStates: financeStates);
  }

  PresidentFacilityInvestmentEffects projectOwnedInvestment({
    required SinglePassPostseasonRuntimeTransition transition,
    required WorldCheckpoint world,
    required Iterable<PresidentClubRuntimeState> presidentClubs,
  }) {
    _requireCalculation(
        transition, PostseasonRuntimeTransitionPhase.sponsorSuccessorReady);
    if (_investmentProjected) {
      throw StateError('Investment projection already consumed.');
    }
    _investmentProjected = true;
    return _prepared._producer.investment.projectRuntimeView(
        facilities: FacilityRuntimeCheckpoint(
            world: world,
            academyFacilities: facilities.academyFacilities,
            stadiumFacilities: facilities.stadiumFacilities,
            trainingGroundFacilities: facilities.trainingGroundFacilities,
            totalInvestmentSpent: facilities.totalInvestmentSpent),
        profiles: {
          for (final c in presidentClubs) c.clubId: c.managementProfile
        });
  }

  PlayerPresidentTenureControlState refreshOwnedControl({
    required SinglePassPostseasonRuntimeTransition transition,
    required PresidentClubRuntimeState incumbent,
    required int completedSeasons,
  }) {
    _requireCalculation(
        transition, PostseasonRuntimeTransitionPhase.facilityReady);
    if (_controlRefreshed)
      throw StateError('Control refresh already consumed.');
    _controlRefreshed = true;
    return _prepared._producer.tenureGate.refreshRuntimeView(
        state: tenureControl,
        incumbent: incumbent,
        completedSeasons: completedSeasons);
  }

  FacilitySponsorPostseasonContinuation? _successor;
  Map<String, int>? _nextStadiumLevels;
  Map<String, FanState>? _nextFans;
  Map<String, PresidentManagementProfile>? _nextProfiles;
  PlayerPresidentTenureControlState? _nextControl;
  bool _moved = false;
  FutureTicketPreparationBinding stageFutureTicket(FutureRuntimeClaim claim) {
    claim.validateChild(advanced);
    if (!_moved || !identical(claim.source.worldSuccessor, _successor?.world)) {
      throw StateError('Annual successor has not been published.');
    }
    return PreparedTicketRuntimeSeason._stageFuture(
        claim, _prepared._producer, _prepared._pricing);
  }

  FacilitySponsorPostseasonContinuation stageSuccessor({
    required SinglePassPostseasonRuntimeTransition transition,
    required WorldCheckpoint world,
    required FacilityPortfolioRuntimeState facilities,
    required List<PresidentClubRuntimeState> domainClubs,
    required PlayerPresidentTenureControlState control,
  }) {
    advanced.validateTransition(transition);
    if (!transition.permitsOuterSuccessor(
        this, world, facilities, domainClubs, control)) {
      throw StateError('Unowned outer successor evidence.');
    }
    if (_successor != null || _moved || !hasNextSeason) {
      throw StateError('Annual runtime successor already staged or terminal.');
    }
    control.validate();
    _nextStadiumLevels = Map.unmodifiable(
        {for (final s in facilities.stadiumFacilities) s.clubId: s.level});
    _nextFans = Map.unmodifiable(
        {for (final c in domainClubs) c.clubId: c.fanReputation});
    _nextProfiles = Map.unmodifiable(
        {for (final c in domainClubs) c.clubId: c.managementProfile});
    _nextControl = control;
    return _successor = _prepared._runtime.stageOwnedPostseason(
        prepared: _prepared._facility,
        closing: advanced,
        transition: transition,
        world: world,
        facilities: facilities,
        domainClubs: domainClubs);
  }

  void validateSuccessorMove(Object transition) {
    advanced.validateTransition(transition);
    if (_successor == null || _moved)
      throw StateError('Unprepared annual move.');
  }

  void commitSuccessorMove(Object transition) {
    validateSuccessorMove(transition);
    _successor!.commitOwnedSuccessor();
    final pricing = _prepared._pricing;
    pricing.stadiumLevelsByClub = _nextStadiumLevels!;
    pricing.fanStatesByClub = _nextFans!;
    pricing.presidentProfilesByClub = _nextProfiles!;
    pricing.tenureControl = _nextControl!;
    pricing._claimedRecording = null;
    pricing._preparedContexts = null;
    pricing._strictProvider = null;
    pricing._decisions.clear();
    _moved = true;
  }

  void validate() {
    advanced.world.validate();
    final opening = advanced.world.opening;
    final ids = opening.effectiveClubs.map((c) => c.id).toSet();
    if (ids.length != 48 ||
        promiseContexts.length != 48 ||
        acceptedPromises.length != 48 ||
        promiseContexts.map((c) => c.clubId).toSet().length != 48) {
      throw StateError('Incomplete owned annual promise coverage.');
    }
    for (var i = 0; i < promiseContexts.length; i++) {
      final context = promiseContexts[i];
      final promise = acceptedPromises[i];
      if (!ids.contains(context.clubId) ||
          context.clubId != promise.clubId ||
          context.seasonIndex != opening.seasonIndex ||
          promise.seasonIndex != opening.seasonIndex ||
          promise.id.isEmpty) {
        throw StateError('Foreign owned annual promise lineage.');
      }
    }
    receipt.verify(
      expectedOwner: owner,
      expectedRevision: revision,
      expectedProvenance: provenance,
      expectedSeason: advanced.world.opening.seasonIndex,
      expectedResults: advanced.world.finances,
      expectedEffectiveClubSource: advanced.managerOpening,
    );
  }

  void claim(
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance,
      required Object transition}) {
    validate();
    if (_claim != null) throw StateError('Annual-closing owner already moved.');
    advanced.claim(
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance,
        transition: transition);
    _claim = transition;
  }
}

final class PreparedTicketRuntimeSeason {
  static FutureTicketPreparationBinding stageFirstFuture(
      FutureRuntimeClaim claim) {
    if (claim.source.origin !=
        PostoffseasonRuntimeOrigin.firstFutureBootstrap) {
      throw StateError('First ticket activation requires genuine bootstrap.');
    }
    return _stageFuture(
        claim,
        const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(),
        null);
  }

  static FutureTicketPreparationBinding _stageFuture(
      FutureRuntimeClaim claim,
      PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine producer,
      _TicketPricingEconomyEngine? pricing) {
    claim.validateChild(claim.facilityRecipient);
    final graph = claim.source;
    final presidents = claim.presidentClubs;
    final context = _PricingRuntimeContext(
        clubs: graph.worldSuccessor.baseClubs,
        stadiumLevelsByClub: Map.unmodifiable({
          for (final state in graph.facilities.stadiumFacilities)
            state.clubId: state.level
        }),
        fanStatesByClub: Map.unmodifiable({
          for (final state in presidents) state.clubId: state.fanReputation
        }),
        presidentProfilesByClub: Map.unmodifiable({
          for (final state in presidents) state.clubId: state.managementProfile
        }),
        tenureControl: graph.control,
        presidentStates: presidents,
        electionInterval: claim.electionInterval,
        completedElectionTerms: claim.completedElectionTerms,
        seasonsIntoCurrentTerm: claim.seasonsIntoCurrentTerm,
        termPromiseScores: claim.termPromiseScores);
    return FutureTicketPreparationBinding._(claim, producer, context, pricing);
  }

  PreparedTicketRuntimeSeason._(this._producer, this._context, this._pricing,
      this._runtime, this._facility);
  final PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine _producer;
  final _PricingRuntimeContext _context;
  final _TicketPricingEconomyEngine _pricing;
  final FacilitySponsorCrisisRuntimeCareerEngine _runtime;
  final PreparedFacilitySponsorSeason _facility;
  bool _annualCaptureAttempted = false;
  Object get owner => _facility.owner;
  Object get revision => _facility.revision;
  Object get provenance => _facility.provenance;
  Object get executionIdentity => _facility.executionIdentity;
  Object get managerLineage => _facility.managerLineage;
  Object get transferLineage => _facility.transferLineage;
  PreparedWorldOpening get opening => _facility.opening;
  ManagerSeasonAuthority? get managerAuthority => _facility.managerAuthority;
  PreparedRuntimeOrigin get origin => _facility.origin;
  PreparedExecutionState get state => _facility.state;
  PlayerPresidentTenureControlState get tenureControl => _context.tenureControl;
  FacilityPortfolioRuntimeState get facilities => _facility.facilities;
  SponsorRuntimeCheckpoint get openingSponsor => _facility.openingSponsor;
  Map<String, FanState> get sponsorFanStates => _facility.fanStates;
  Map<String, FanState> get pricingFanStates =>
      Map.unmodifiable(_context.fanStatesByClub);
  Map<String, PresidentManagementProfile> get pricingProfiles =>
      Map.unmodifiable(_context.presidentProfilesByClub);
  int get openingContractCount => _facility.openingContractCount;
  AdvancedTransferRuntimeState get transferEvidence =>
      _facility.transferEvidence;
  int get sponsorProcessedClubCount => _facility.sponsorProcessedClubCount;
  Money get sponsorSeasonRevenue => _facility.sponsorSeasonRevenue;
  int get ticketDecisionCount => _pricing._decisions.length;

  PreparedTicketRuntimeSeason move(
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    if (_annualCaptureAttempted)
      throw StateError('Annual capture lease cannot move.');
    return PreparedTicketRuntimeSeason._(
        _producer,
        _context,
        _pricing,
        _runtime,
        _facility.move(
            expectedOwner: expectedOwner,
            expectedRevision: expectedRevision,
            expectedProvenance: expectedProvenance));
  }
}

/// Private-minted target binding; the pricing graph itself never escapes.
final class FutureTicketPreparationBinding {
  FutureTicketPreparationBinding._(
      this._claim, this._producer, this._context, this._pricing);
  final FutureRuntimeClaim _claim;
  final PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine _producer;
  final _PricingRuntimeContext _context;
  _TicketPricingEconomyEngine? _pricing;
  bool _bound = false;
  PreparedTicketRuntimeSeason prepare() {
    _claim.requirePreparationCommit();
    return _claim.facilityRecipient.prepareFuture(_claim, this);
  }

  bool _completed = false;
  PreparedTicketRuntimeSeason complete(PreparedFacilitySponsorSeason facility,
      FacilitySponsorCrisisRuntimeCareerEngine producer) {
    _claim.requirePreparationCommit();
    if (!_bound ||
        _completed ||
        !identical(facility.owner, _claim.owner) ||
        !identical(facility.revision, _claim.revision) ||
        !identical(facility.provenance, _claim.provenance) ||
        facility.opening.seasonIndex != _claim.source.targetSeasonIndex) {
      throw StateError('Foreign or repeated target preparation publication.');
    }
    _completed = true;
    return PreparedTicketRuntimeSeason._(
        _producer, _context, _pricing!, producer, facility);
  }

  void validate(FutureRuntimeClaim claim) {
    if (!identical(claim, _claim) || _bound) {
      throw StateError('Foreign or consumed future ticket binding.');
    }
    claim.validateChild(claim.facilityRecipient);
  }

  BasicEconomyEngine bindDelegate(BasicEconomyEngine delegate) {
    validate(_claim);
    validateDelegate(delegate);
    final pricing = _pricing;
    if (pricing != null) {
      if (!identical(delegate, pricing)) {
        throw StateError('Later ticket delegate lost its original lineage.');
      }
      _bound = true;
      return pricing;
    }
    _pricing = _TicketPricingEconomyEngine(
        delegate: delegate,
        expectedClubIds: _context.clubs.map((club) => club.id),
        stadiumLevelsByClub: _context.stadiumLevelsByClub,
        fanStatesByClub: _context.fanStatesByClub,
        presidentProfilesByClub: _context.presidentProfilesByClub,
        tenureControl: _context.tenureControl,
        playerProvider: _producer.playerProvider,
        aiPolicy: _producer.aiPolicy,
        pricingPolicy: _producer.pricingPolicy,
        stadiumPolicy: _producer.stadiumPolicy);
    _bound = true;
    return _pricing!;
  }

  void validateDelegate(BasicEconomyEngine delegate) {
    validate(_claim);
    if (_pricing != null && !identical(delegate, _pricing)) {
      throw StateError(
          'Later pricing lineage does not match its facility child.');
    }
  }
}

class PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine({
    this.financeRecording,
    this.playerProvider,
    this.aiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
    this.sponsorSystem = const SponsorSystemEngine(),
    this.crisisIntegration = const CrisisRuntimeIntegrationEngine(),
    this.sourceEngine = const PromiseMediaCareerEngine(),
  });

  final PlayerMatchdayTicketPricingDecisionProvider? playerProvider;
  final FullM65SeasonFinancePipeline? financeRecording;
  final PresidentMatchdayTicketPricingPolicy aiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;
  final PlayerPresidentTenureControlGate tenureGate;
  final WorldCareerEngine baseWorldEngine;
  final PresidentFacilityInvestmentRuntimeEngine investment;
  final SponsorSystemEngine sponsorSystem;
  final CrisisRuntimeIntegrationEngine crisisIntegration;
  final PromiseMediaCareerEngine sourceEngine;

  PreparedTicketRuntimeSeason prepareInitial(
      {required List<Club> clubs,
      required List<WorldLeague> leagues,
      required SimulationConfig config,
      required String controlledClubId,
      Object? owner,
      Object? revision,
      Object? provenance,
      bool captureManagerAuthority = false}) {
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }
    final context = _initialContext(
        clubs: clubs, config: config, controlledClubId: controlledClubId);
    final pricing = _preparePricing(context, context.tenureControl);
    final runtime = _runtimeFor(pricing).runtime;
    final facility = runtime.prepareInitial(
        clubs: clubs,
        leagues: leagues,
        config: config,
        owner: owner,
        revision: revision,
        provenance: provenance,
        captureManagerAuthority: captureManagerAuthority);
    return PreparedTicketRuntimeSeason._(
        this, context, pricing, runtime, facility);
  }

  PreparedTicketRuntimeSeason prepareResume(
      {required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
      Object? owner,
      Object? revision,
      Object? provenance,
      bool captureManagerAuthority = false}) {
    checkpoint.validate();
    final context =
        _contextFromCheckpoint(checkpoint.runtime, checkpoint.tenureControl);
    final pricing = _preparePricing(context, checkpoint.tenureControl);
    final runtime = _runtimeFor(pricing).runtime;
    final facility = runtime.prepareResume(
        checkpoint: checkpoint.runtime,
        owner: owner,
        revision: revision,
        provenance: provenance,
        captureManagerAuthority: captureManagerAuthority);
    return PreparedTicketRuntimeSeason._(
        this, context, pricing, runtime, facility);
  }

  AdvancedRuntimeSimulationResult executePrepared(PreparedTicketRuntimeSeason p,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    if (!identical(p._producer, this) || p._annualCaptureAttempted) {
      throw StateError('Foreign ticket prepared producer.');
    }
    return p._runtime.executePrepared(p._facility,
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance);
  }

  /// A new observation/admission seam over the existing annual production
  /// call, not a completed career replay or an arbitrary report constructor.
  OwnedAnnualClosingBoundary captureAnnualClosing(PreparedTicketRuntimeSeason p,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance,
      required bool hasNextSeason}) {
    if (!identical(p._producer, this) ||
        p._annualCaptureAttempted ||
        p.state != PreparedExecutionState.prepared ||
        p.managerAuthority == null ||
        !identical(p.owner, expectedOwner) ||
        !identical(p.revision, expectedRevision) ||
        !identical(p.provenance, expectedProvenance) ||
        p._pricing.financeRecording != null ||
        p._pricing._claimedRecording != null) {
      throw StateError('Foreign, consumed or unowned annual-closing graph.');
    }
    p._facility.validateEconomyHandoff();
    p._annualCaptureAttempted = true;
    final contexts = const PromiseOpeningContextBuilder().build(
        seasonIndex: p.opening.seasonIndex,
        effectiveClubs: p.opening.effectiveClubs,
        leagues: p.opening.leagues,
        openingFinanceStates: p.opening.financeStates);
    final promises = List<PresidentPromise>.unmodifiable(contexts.map(
        (context) => sourceEngine.promiseEngine.generator.generate(
            context: context,
            careerSeed: p.opening.config.careerSeed,
            simulationVersion: p.opening.config.simulationVersion)));
    final recording = FullM65SeasonFinancePipeline(
        owner: p.owner,
        sourceRevision: p.revision,
        provenance: p.provenance,
        seasonIndex: p.opening.seasonIndex,
        effectiveClubSource: p.managerAuthority);
    p._pricing._claimedRecording = recording;
    final closing = recording.record(() => p._runtime.captureAnnualClosing(
        p._facility,
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance,
        recording: recording));
    return OwnedAnnualClosingBoundary._(
        p, closing, recording.receipt!, contexts, promises, hasNextSeason);
  }

  _TicketPricingEconomyEngine _preparePricing(_PricingRuntimeContext context,
          PlayerPresidentTenureControlState tenure) =>
      _TicketPricingEconomyEngine(
          financeRecording: financeRecording,
          delegate: baseWorldEngine.economyEngine,
          expectedClubIds: context.clubs.map((club) => club.id),
          stadiumLevelsByClub: context.stadiumLevelsByClub,
          fanStatesByClub: context.fanStatesByClub,
          presidentProfilesByClub: context.presidentProfilesByClub,
          tenureControl: tenure,
          playerProvider: playerProvider,
          aiPolicy: aiPolicy,
          pricingPolicy: pricingPolicy,
          stadiumPolicy: stadiumPolicy);

  PlayerPresidentTicketPricingRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }

    final initialContext = _initialContext(
      clubs: clubs,
      config: config,
      controlledClubId: controlledClubId,
    );
    var tenure = initialContext.tenureControl;
    FacilitySponsorCrisisRuntimeCheckpoint? current;
    final boundaries = <PlayerPresidentTicketPricingRuntimeSeasonBoundary>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final context = current == null
          ? initialContext
          : _contextFromCheckpoint(current, tenure);
      final pricingEconomy = _preparePricing(context, tenure);
      final runtime = _runtimeFor(pricingEconomy);
      final PresidentFacilityInvestmentRuntimeCareerResult segment;
      if (current == null) {
        segment = runtime.simulateWithCheckpoint(
          clubs: clubs,
          leagues: leagues,
          config: config,
          seasonCount: 1,
          electionInterval: electionInterval,
          hasFutureSeasonAfterReport: hasFuture,
        );
      } else {
        segment = runtime.resume(
          checkpoint: current,
          seasonCount: 1,
          hasFutureSeasonAfterReport: hasFuture,
        );
      }
      current = segment.checkpoint;
      tenure = tenureGate.refresh(
        state: tenure,
        presidentRuntime: current.runtime.domain.presidentRuntime,
      );
      final checkpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
        runtime: current,
        tenureControl: tenure,
      );
      boundaries.add(
        PlayerPresidentTicketPricingRuntimeSeasonBoundary(
          source: segment.boundaries.single,
          pricingDecisions: pricingEconomy.decisions,
          checkpoint: checkpoint,
        ),
      );
    }

    return PlayerPresidentTicketPricingRuntimeCareerResult(
      checkpoint: PlayerPresidentTicketPricingRuntimeCheckpoint(
        runtime: current!,
        tenureControl: tenure,
      ),
      boundaries: boundaries,
    );
  }

  PlayerPresidentTicketPricingRuntimeCareerResult resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint.runtime;
    var tenure = checkpoint.tenureControl;
    final boundaries = <PlayerPresidentTicketPricingRuntimeSeasonBoundary>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final context = _contextFromCheckpoint(current, tenure);
      final pricingEconomy = _preparePricing(context, tenure);
      final segment = _runtimeFor(pricingEconomy).resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      current = segment.checkpoint;
      tenure = tenureGate.refresh(
        state: tenure,
        presidentRuntime: current.runtime.domain.presidentRuntime,
      );
      final nextCheckpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
        runtime: current,
        tenureControl: tenure,
      );
      boundaries.add(
        PlayerPresidentTicketPricingRuntimeSeasonBoundary(
          source: segment.boundaries.single,
          pricingDecisions: pricingEconomy.decisions,
          checkpoint: nextCheckpoint,
        ),
      );
    }
    return PlayerPresidentTicketPricingRuntimeCareerResult(
      checkpoint: PlayerPresidentTicketPricingRuntimeCheckpoint(
        runtime: current,
        tenureControl: tenure,
      ),
      boundaries: boundaries,
    );
  }

  _PricingRuntimeContext _initialContext({
    required List<Club> clubs,
    required SimulationConfig config,
    required String controlledClubId,
  }) {
    const opening = PresidentOpeningStateInitializer();
    final profiles = <String, PresidentManagementProfile>{};
    final fans = <String, FanState>{};
    final stadiums = <String, int>{};
    final presidentStates = <PresidentClubRuntimeState>[];
    String? playerPresidentId;
    for (final club in clubs) {
      final state = opening.prepareClub(clubId: club.id, config: config);
      profiles[club.id] = state.managementProfile;
      fans[club.id] = state.fan;
      stadiums[club.id] = 0;
      presidentStates.add(PresidentClubRuntimeState(
          tenure: state.tenure,
          managementProfile: state.managementProfile,
          fanReputation: state.fan,
          mediaReputation: state.media));
      if (club.id == controlledClubId) {
        playerPresidentId = state.president.id;
      }
    }
    return _PricingRuntimeContext(
      clubs: clubs,
      stadiumLevelsByClub: stadiums,
      fanStatesByClub: fans,
      presidentProfilesByClub: profiles,
      presidentStates: List.unmodifiable(presidentStates),
      electionInterval: 4,
      completedElectionTerms: 0,
      seasonsIntoCurrentTerm: 0,
      termPromiseScores: const {},
      tenureControl: PlayerPresidentTenureControlState.initial(
        controlledClubId: controlledClubId,
        playerPresidentId: playerPresidentId!,
      ),
    );
  }

  _PricingRuntimeContext _contextFromCheckpoint(
    FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
    PlayerPresidentTenureControlState tenure,
  ) {
    checkpoint.validate();
    final domain = checkpoint.runtime.domain;
    final clubs = domain.presidentRuntime.runtime.runtime.world.baseClubs;
    return _PricingRuntimeContext(
      clubs: clubs,
      stadiumLevelsByClub: {
        for (final state in checkpoint.facilities.stadiumFacilities)
          state.clubId: state.level,
      },
      fanStatesByClub: {
        for (final state in domain.presidentRuntime.clubs)
          state.clubId: state.fanReputation,
      },
      presidentProfilesByClub: {
        for (final state in domain.presidentRuntime.clubs)
          state.clubId: state.managementProfile,
      },
      tenureControl: tenure,
      presidentStates: domain.presidentRuntime.clubs,
      electionInterval: domain.presidentRuntime.electionInterval,
      completedElectionTerms: domain.presidentRuntime.completedElectionTerms,
      seasonsIntoCurrentTerm: domain.presidentRuntime.seasonsIntoCurrentTerm,
      termPromiseScores: Map.unmodifiable({
        for (final club in clubs)
          club.id: List<int>.unmodifiable(domain.currentTermPromises
              .where((p) => p.clubId == club.id)
              .map((p) => p.score))
      }),
    );
  }

  PresidentFacilityInvestmentRuntimeCareerEngine _runtimeFor(
    _TicketPricingEconomyEngine pricingEconomy,
  ) {
    final pricedWorld = WorldCareerEngine(
      seasonEngine: baseWorldEngine.seasonEngine,
      poolGenerator: baseWorldEngine.poolGenerator,
      lifecycleEngine: baseWorldEngine.lifecycleEngine,
      strengthCalculator: baseWorldEngine.strengthCalculator,
      economyEngine: pricingEconomy,
      transferMarketEngine: baseWorldEngine.transferMarketEngine,
    );
    return PresidentFacilityInvestmentRuntimeCareerEngine(
      runtime: FacilitySponsorCrisisRuntimeCareerEngine(
        financeRecording: financeRecording,
        sponsorSystem: sponsorSystem,
        baseWorldEngine: pricedWorld,
        crisisIntegration: crisisIntegration,
        sourceEngine: sourceEngine,
      ),
      investment: investment,
    );
  }
}

class _PricingRuntimeContext {
  const _PricingRuntimeContext({
    required this.clubs,
    required this.stadiumLevelsByClub,
    required this.fanStatesByClub,
    required this.presidentProfilesByClub,
    required this.tenureControl,
    required this.presidentStates,
    required this.electionInterval,
    required this.completedElectionTerms,
    required this.seasonsIntoCurrentTerm,
    required this.termPromiseScores,
  });

  final List<Club> clubs;
  final Map<String, int> stadiumLevelsByClub;
  final Map<String, FanState> fanStatesByClub;
  final Map<String, PresidentManagementProfile> presidentProfilesByClub;
  final PlayerPresidentTenureControlState tenureControl;
  final List<PresidentClubRuntimeState> presidentStates;
  final int electionInterval, completedElectionTerms, seasonsIntoCurrentTerm;
  final Map<String, List<int>> termPromiseScores;
}

class _TicketPricingEconomyEngine extends BasicEconomyEngine {
  _TicketPricingEconomyEngine({
    this.financeRecording,
    required this.delegate,
    required Iterable<String> expectedClubIds,
    required this.stadiumLevelsByClub,
    required this.fanStatesByClub,
    required this.presidentProfilesByClub,
    required this.tenureControl,
    required this.playerProvider,
    required this.aiPolicy,
    required this.pricingPolicy,
    required this.stadiumPolicy,
  })  : expectedClubIds = Set.unmodifiable(expectedClubIds),
        super(wageModel: delegate.wageModel);

  final BasicEconomyEngine delegate;
  final FullM65SeasonFinancePipeline? financeRecording;
  final Set<String> expectedClubIds;
  FullM65SeasonFinancePipeline? _claimedRecording;
  Map<String, PlayerPresidentTicketPricingDecisionContext>? _preparedContexts;
  PlayerMatchdayTicketPricingDecisionProvider? _strictProvider;
  Map<String, int> stadiumLevelsByClub;
  Map<String, FanState> fanStatesByClub;
  Map<String, PresidentManagementProfile> presidentProfilesByClub;
  PlayerPresidentTenureControlState tenureControl;
  final PlayerMatchdayTicketPricingDecisionProvider? playerProvider;
  final PresidentMatchdayTicketPricingPolicy aiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;

  final Map<String, PlayerPresidentTicketPricingDecision> _decisions = {};

  PlayerPresidentTicketPricingDecisionContext _prepareContext(
      Club club, int season, int position,
      {int? incomingMultiplier}) {
    final level = stadiumLevelsByClub[club.id] ??
        (throw StateError('Missing stadium level for ${club.id}.'));
    final fan = fanStatesByClub[club.id] ??
        (throw StateError('Missing fan state for ${club.id}.'));
    final president = presidentProfilesByClub[club.id] ??
        (throw StateError('Missing president profile for ${club.id}.'));
    final base = stadiumPolicy.attendanceProfile(
        level: level,
        clubStrength: club.strength,
        leaguePosition: position,
        fanTrust: fan.overallTrust);
    // Preserve legacy failure/callback timing: check the incoming attendance
    // before consulting the AI policy, not after context construction.
    if (incomingMultiplier != null &&
        incomingMultiplier != base.revenueMultiplierBps) {
      throw StateError(
          'M65 pricing seam mismatch for ${club.id}: $incomingMultiplier != ${base.revenueMultiplierBps}.');
    }
    return PlayerPresidentTicketPricingDecisionContext(
        seasonIndex: season,
        club: club,
        president: president,
        stadiumLevel: level,
        leaguePosition: position,
        fanTrust: fan.overallTrust,
        baseAttendance: base,
        aiChoice: aiPolicy.choose(
            profile: president, fanTrust: fan.overallTrust, base: base));
  }

  List<PlayerPresidentTicketPricingDecision> get decisions {
    if (_decisions.length != expectedClubIds.length ||
        !_decisions.keys.toSet().containsAll(expectedClubIds)) {
      throw StateError(
        'Ticket-pricing economy processed ${_decisions.length}/'
        '${expectedClubIds.length} clubs.',
      );
    }
    final values = _decisions.values.toList(growable: false)
      ..sort((a, b) => a.context.clubId.compareTo(b.context.clubId));
    return List.unmodifiable(values);
  }

  @override
  List<ClubFinanceSeason> simulateSeason({
    required List<Club> clubs,
    required List<Player> players,
    required SeasonReport seasonReport,
    required List<ClubFinanceState> openingStates,
    int economicScaleBps = 10000,
    int costScaleBps = 10000,
    Map<String, Money>? annualWagesByClub,
    Map<String, Money>? transferInstallmentIncomeByClub,
    Map<String, Money>? transferInstallmentExpenseByClub,
    Map<String, int> matchdayRevenueMultiplierBpsByClub = const {},
    Map<String, Money>? sponsorRevenueByClub,
  }) {
    final positions = <String, int>{};
    for (var index = 0; index < seasonReport.table.length; index++) {
      positions[seasonReport.table[index].clubId] = index + 1;
    }
    final pricedMultipliers = <String, int>{};
    for (final club in clubs) {
      if (!expectedClubIds.contains(club.id)) {
        throw StateError(
            'Ticket-pricing economy received unknown club ${club.id}.');
      }
      if (_decisions.containsKey(club.id)) {
        throw StateError('Ticket-pricing economy processed ${club.id} twice.');
      }
      final position = positions[club.id] ??
          (throw StateError('Missing league position for ${club.id}.'));
      final context = _preparedContexts?[club.id] ??
          _prepareContext(club, seasonReport.seasonIndex, position,
              incomingMultiplier:
                  matchdayRevenueMultiplierBpsByClub[club.id] ?? 10000);
      if (!identical(context.club, club) ||
          context.seasonIndex != seasonReport.seasonIndex ||
          context.leaguePosition != position)
        throw StateError('Changed pricing source.');
      final base = context.baseAttendance;
      final incomingMultiplier =
          matchdayRevenueMultiplierBpsByClub[club.id] ?? 10000;
      if (incomingMultiplier != base.revenueMultiplierBps) {
        throw StateError(
          'M65 pricing seam mismatch for ${club.id}: '
          '$incomingMultiplier != ${base.revenueMultiplierBps}.',
        );
      }
      final provider = _strictProvider ?? playerProvider;
      final canDelegate = club.id == tenureControl.controlledClubId &&
          provider != null &&
          tenureControl.active &&
          context.president.presidentId == tenureControl.playerPresidentId;
      final choice = canDelegate ? provider.choose(context) : context.aiChoice;
      final outcome = pricingPolicy.apply(base: base, tier: choice.tier);
      final decision = PlayerPresidentTicketPricingDecision(
        context: context,
        choice: choice,
        providerCalled: canDelegate,
        outcome: outcome,
      );
      _decisions[club.id] = decision;
      if (canDelegate) {
        provider.onApplied(decision);
      }
      pricedMultipliers[club.id] = outcome.revenueMultiplierBps;
    }

    final results = delegate.simulateSeason(
      clubs: clubs,
      players: players,
      seasonReport: seasonReport,
      openingStates: openingStates,
      economicScaleBps: economicScaleBps,
      costScaleBps: costScaleBps,
      annualWagesByClub: annualWagesByClub,
      transferInstallmentIncomeByClub: transferInstallmentIncomeByClub,
      transferInstallmentExpenseByClub: transferInstallmentExpenseByClub,
      matchdayRevenueMultiplierBpsByClub: pricedMultipliers,
      sponsorRevenueByClub: sponsorRevenueByClub,
    );
    (_claimedRecording ?? financeRecording)
        ?.forSeason(seasonReport.seasonIndex)
        ?.observeSettlement(
          actualSeason: seasonReport.seasonIndex,
          clubs: clubs,
          openingStates: openingStates,
          wages: annualWagesByClub,
          installmentIncome: transferInstallmentIncomeByClub,
          installmentExpense: transferInstallmentExpenseByClub,
          sponsorRevenue: sponsorRevenueByClub,
          incomingMultipliers: matchdayRevenueMultiplierBpsByClub,
          finalMultipliers: pricedMultipliers,
          tickets: _decisions,
          economicScaleBps: economicScaleBps,
          costScaleBps: costScaleBps,
          results: results,
        );
    return results;
  }
}
