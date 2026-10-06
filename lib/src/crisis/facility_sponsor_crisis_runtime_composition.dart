import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../election/president_reputation_career_report.dart';
import '../election/president_tenure.dart';
import '../facility/academy_facility.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../facility/stadium_facility.dart';
import '../facility/training_ground_facility.dart';
import '../fan/fan_state.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../finance/season_finance_authority_receipt.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_career_season.dart';
import '../media/media_state.dart';
import '../player/player.dart';
import '../player_president/player_president_interactive_decision_application_session.dart';
import '../save/president_runtime_checkpoint.dart';
import '../world/world_checkpoint.dart';
import '../player/player_lifecycle_engine.dart';
import '../promise/promise_media_career_engine.dart';
import '../promise/promise_season_snapshot.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../season/season_report.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../sponsor/sponsor_system.dart';
import '../world/world_career_engine.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import 'crisis_runtime_integration.dart';

class FacilityPortfolioRuntimeState {
  FacilityPortfolioRuntimeState({
    required Iterable<AcademyFacilityState> academyFacilities,
    required Iterable<StadiumFacilityState> stadiumFacilities,
    required Iterable<TrainingGroundFacilityState> trainingGroundFacilities,
    this.totalInvestmentSpent = Money.zero,
  })  : academyFacilities = List.unmodifiable(
          academyFacilities.toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        ),
        stadiumFacilities = List.unmodifiable(
          stadiumFacilities.toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        ),
        trainingGroundFacilities = List.unmodifiable(
          trainingGroundFacilities.toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        ) {
    if (totalInvestmentSpent.isNegative) {
      throw ArgumentError('Facility investment total cannot be negative.');
    }
  }

  factory FacilityPortfolioRuntimeState.forClubs({
    required Iterable<Club> clubs,
    Iterable<AcademyFacilityState>? academyFacilities,
    Iterable<StadiumFacilityState>? stadiumFacilities,
    Iterable<TrainingGroundFacilityState>? trainingGroundFacilities,
    Money totalInvestmentSpent = Money.zero,
  }) {
    final clubList = clubs.toList(growable: false);
    final state = FacilityPortfolioRuntimeState(
      academyFacilities: academyFacilities ??
          clubList.map(
            (club) => AcademyFacilityState(clubId: club.id, level: 0),
          ),
      stadiumFacilities: stadiumFacilities ??
          clubList.map(
            (club) => StadiumFacilityState(clubId: club.id, level: 0),
          ),
      trainingGroundFacilities: trainingGroundFacilities ??
          clubList.map(
            (club) => TrainingGroundFacilityState(clubId: club.id, level: 0),
          ),
      totalInvestmentSpent: totalInvestmentSpent,
    );
    state.validateAgainst(clubList.map((club) => club.id).toSet());
    return state;
  }

  final List<AcademyFacilityState> academyFacilities;
  final List<StadiumFacilityState> stadiumFacilities;
  final List<TrainingGroundFacilityState> trainingGroundFacilities;
  final Money totalInvestmentSpent;

  AcademyFacilityState academyFor(String clubId) =>
      academyFacilities.firstWhere((state) => state.clubId == clubId);

  StadiumFacilityState stadiumFor(String clubId) =>
      stadiumFacilities.firstWhere((state) => state.clubId == clubId);

  TrainingGroundFacilityState trainingGroundFor(String clubId) =>
      trainingGroundFacilities.firstWhere((state) => state.clubId == clubId);

  void validateAgainst(Set<String> worldIds) {
    _validateCoverage(
      label: 'Academy',
      worldIds: worldIds,
      clubIds: academyFacilities.map((state) => state.clubId),
    );
    _validateCoverage(
      label: 'Stadium',
      worldIds: worldIds,
      clubIds: stadiumFacilities.map((state) => state.clubId),
    );
    _validateCoverage(
      label: 'Training ground',
      worldIds: worldIds,
      clubIds: trainingGroundFacilities.map((state) => state.clubId),
    );
  }

  void _validateCoverage({
    required String label,
    required Set<String> worldIds,
    required Iterable<String> clubIds,
  }) {
    final ids = <String>{};
    for (final clubId in clubIds) {
      if (!worldIds.contains(clubId) || !ids.add(clubId)) {
        throw ArgumentError('Invalid or duplicate $label facility $clubId.');
      }
    }
    if (ids.length != worldIds.length ||
        ids.difference(worldIds).isNotEmpty ||
        worldIds.difference(ids).isNotEmpty) {
      throw ArgumentError('$label facilities must cover every world club.');
    }
  }

  String get signature => [
        totalInvestmentSpent.minorUnits,
        academyFacilities
            .map((state) => '${state.clubId}:${state.level}')
            .join('|'),
        stadiumFacilities
            .map((state) => '${state.clubId}:${state.level}')
            .join('|'),
        trainingGroundFacilities
            .map((state) => '${state.clubId}:${state.level}')
            .join('|'),
      ].join('||');
}

class FacilitySponsorCrisisRuntimeCheckpoint {
  FacilitySponsorCrisisRuntimeCheckpoint({
    required this.runtime,
    required this.facilities,
  }) {
    validate();
  }

  final SponsorPresidentRuntimeCheckpoint runtime;
  final FacilityPortfolioRuntimeState facilities;

  int get nextSeasonIndex => runtime.nextSeasonIndex;
  int get completedSeasons => runtime.completedSeasons;

  void validate() {
    runtime.validate();
    final worldIds = runtime
        .domain.presidentRuntime.runtime.runtime.world.baseClubs
        .map((club) => club.id)
        .toSet();
    facilities.validateAgainst(worldIds);
  }

  String get signature =>
      '${runtime.signature}||facilities=${facilities.signature}';
}

class FacilitySponsorCrisisRuntimeSaveCodec {
  const FacilitySponsorCrisisRuntimeSaveCodec({
    this.runtimeCodec = const SponsorPresidentRuntimeSaveCodec(),
  });

  static const String format = 'zmila-fbs-facility-sponsor-crisis-runtime';
  static const int currentSaveVersion = 1;

  final SponsorPresidentRuntimeSaveCodec runtimeCodec;

  String encode(FacilitySponsorCrisisRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'runtimeSave': runtimeCodec.encode(checkpoint.runtime),
      'academyFacilities': checkpoint.facilities.academyFacilities
          .map((state) => {'clubId': state.clubId, 'level': state.level})
          .toList(growable: false),
      'stadiumFacilities': checkpoint.facilities.stadiumFacilities
          .map((state) => {'clubId': state.clubId, 'level': state.level})
          .toList(growable: false),
      'trainingGroundFacilities': checkpoint.facilities.trainingGroundFacilities
          .map((state) => {'clubId': state.clubId, 'level': state.level})
          .toList(growable: false),
      'totalInvestmentSpentMinorUnits':
          checkpoint.facilities.totalInvestmentSpent.minorUnits,
    };
    final checksum = SaveChecksum.forPayload(
      saveVersion: currentSaveVersion,
      payload: payload,
    );
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': checksum,
    });
  }

  FacilitySponsorCrisisRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Facility sponsor-crisis save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Facility sponsor-crisis save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown facility sponsor-crisis save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported facility sponsor-crisis save version $version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum !=
            SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Facility sponsor-crisis save checksum mismatch.',
      );
    }
    if (version != 1 || payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Facility sponsor-crisis save payload is invalid.',
      );
    }
    final map = Map<String, Object?>.from(payload);
    final runtimeSave = map['runtimeSave'];
    final academies = map['academyFacilities'];
    final stadiums = map['stadiumFacilities'];
    final training = map['trainingGroundFacilities'];
    final spent = map['totalInvestmentSpentMinorUnits'];
    if (runtimeSave is! String ||
        academies is! List ||
        stadiums is! List ||
        training is! List ||
        spent is! int) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Facility sponsor-crisis payload fields are invalid.',
      );
    }
    try {
      return FacilitySponsorCrisisRuntimeCheckpoint(
        runtime: runtimeCodec.decode(runtimeSave),
        facilities: FacilityPortfolioRuntimeState(
          academyFacilities: academies.map(
            (item) {
              final entry = _facilityEntry(item, 'Academy');
              return AcademyFacilityState(clubId: entry.$1, level: entry.$2);
            },
          ),
          stadiumFacilities: stadiums.map(
            (item) {
              final entry = _facilityEntry(item, 'Stadium');
              return StadiumFacilityState(clubId: entry.$1, level: entry.$2);
            },
          ),
          trainingGroundFacilities: training.map(
            (item) {
              final entry = _facilityEntry(item, 'Training ground');
              return TrainingGroundFacilityState(
                  clubId: entry.$1, level: entry.$2);
            },
          ),
          totalInvestmentSpent: Money.fromMinorUnits(spent),
        ),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid facility sponsor-crisis runtime payload: $error',
      );
    }
  }

  (String, int) _facilityEntry(Object? item, String label) {
    if (item is! Map) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$label facility entry must be a map.',
      );
    }
    final entry = Map<String, Object?>.from(item);
    final clubId = entry['clubId'];
    final level = entry['level'];
    if (clubId is! String || level is! int) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$label facility fields are invalid.',
      );
    }
    return (clubId, level);
  }
}

class FacilitySponsorCrisisRuntimeSeasonBoundary {
  FacilitySponsorCrisisRuntimeSeasonBoundary({
    required this.sponsor,
    required this.crisis,
    required this.checkpoint,
  }) {
    validate();
  }

  final SponsorRuntimeSeasonBoundary sponsor;
  final CrisisRuntimeBoundaryResult crisis;
  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;

  int get seasonIndex => sponsor.seasonIndex;
  int get crisisCount => crisis.crisisCount;
  Money get sponsorRevenue => sponsor.totalRevenue;

  void validate() {
    if (sponsor.seasonIndex != crisis.seasonIndex) {
      throw StateError('Sponsor and crisis boundaries must share a season.');
    }
    if (checkpoint.nextSeasonIndex != sponsor.checkpoint.nextSeasonIndex) {
      throw StateError(
          'Combined checkpoint cursor must match sponsor boundary.');
    }
    if (checkpoint.runtime.sponsor.signature !=
        sponsor.checkpoint.sponsor.signature) {
      throw StateError('Crisis composition must not mutate sponsor state.');
    }
    if (checkpoint.runtime.domain.signature != crisis.checkpoint.signature) {
      throw StateError(
          'Combined checkpoint must carry crisis-adjusted domain.');
    }
  }

  String get signature => 'season=$seasonIndex:sponsor=${sponsor.signature}:'
      'crisis=${crisis.signature}:final=${checkpoint.signature}';
}

class FacilitySponsorCrisisRuntimeCareerResult {
  FacilitySponsorCrisisRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<FacilitySponsorCrisisRuntimeSeasonBoundary> boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;
  final List<FacilitySponsorCrisisRuntimeSeasonBoundary> boundaries;

  int get crisisCount =>
      boundaries.fold(0, (sum, item) => sum + item.crisisCount);

  Money get totalSponsorRevenue => boundaries.fold(
        Money.zero,
        (sum, item) => sum + item.sponsorRevenue,
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M47 composes facility-aware world simulation with M45 sponsor economy and
/// M44 crisis continuation in one PresidentDomain season path.
///
/// Facility levels remain continuation-critical state but are intentionally
/// static in M47. President-driven facility investment remains the concern of
/// the existing M39 decision loop and can be composed in a later milestone.
final class _FacilitySeasonInputs {
  _FacilitySeasonInputs(this.clubs, this.config, this.facilities, this.sponsor,
      this.profiles, this.fans, this.media);
  final List<Club> clubs;
  final SimulationConfig config;
  final FacilityPortfolioRuntimeState facilities;
  final SponsorRuntimeCheckpoint sponsor;
  final Map<String, PresidentManagementProfile> profiles;
  final Map<String, FanState> fans;
  final Map<String, MediaState> media;
}

final class _FacilityPreparedGraph {
  _FacilityPreparedGraph(this.inputs, this.coordinator, this.domain);
  final _FacilitySeasonInputs inputs;
  final _FacilitySponsorSeasonEconomyEngine coordinator;
  final PresidentDomainCareerEngine domain;
}

/// First activation has no invented sponsor season/payment history. The real
/// coordinator/delegate graph remains private and unattempted for its recipient.
final class FacilitySponsorPostseasonContinuation {
  FacilitySponsorPostseasonContinuation._(
      this._graph, this.owner, this.revision, this.provenance, this.world);
  final _FacilityPreparedGraph _graph;
  final Object owner, revision, provenance;
  final WorldCheckpoint world;
  bool _successorCommitted = false;
  _FacilityEconomyEngine? _successorEconomy;
  Map<String, StadiumFacilityState>? _successorStadiums;
  void commitOwnedSuccessor() {
    if (_successorCommitted)
      throw StateError('Facility successor already moved.');
    final economy = _successorEconomy;
    if (economy != null) {
      final inputs = _graph.inputs;
      final coordinator = _graph.coordinator;
      coordinator.openingSponsor = inputs.sponsor;
      coordinator.presidentProfilesByClub = inputs.profiles;
      coordinator.fanStatesByClub = inputs.fans;
      coordinator.mediaStatesByClub = inputs.media;
      coordinator._processedClubIds.clear();
      coordinator._contracts.clear();
      coordinator._activeNext.clear();
      coordinator._revenueByClub.clear();
      coordinator._seasonRevenue = Money.zero;
      coordinator._claimedRecording = null;
      economy.stadiumFacilities = _successorStadiums!;
      economy.fanStatesByClub = inputs.fans;
      economy._preparedAttendance = null;
      economy._claimedRecording = null;
    }
    _successorCommitted = true;
  }

  FacilityPortfolioRuntimeState get facilities => _graph.inputs.facilities;
  SponsorRuntimeCheckpoint get sponsor => _graph.inputs.sponsor;
  int get processedSponsorClubs => _graph.coordinator._processedClubIds.length;
}

/// The original graph stays private; the advanced lease is its only executor.
final class PreparedFacilitySponsorSeason {
  PreparedFacilitySponsorSeason._(this._producer, this._graph, this._advanced);
  final FacilitySponsorCrisisRuntimeCareerEngine _producer;
  final _FacilityPreparedGraph _graph;
  final PreparedAdvancedRuntimeSeason _advanced;
  OwnedAdvancedAnnualClosing? _annualClosing;
  bool _domainProjected = false;

  /// Uses the original prepared domain/resume policies, never a rebuilt graph.
  PresidentDomainSeasonEffects projectOwnedDomainSeason({
    required OwnedAdvancedAnnualClosing closing,
    required Object transition,
    required WorldCareerSeason season,
    required Iterable<PresidentClubRuntimeState> priorClubs,
    required Iterable<PromiseSeasonSnapshot> acceptedPromises,
    required int electionInterval,
    required int completedElectionTerms,
    required int seasonsIntoCurrentTerm,
    required Map<String, List<int>> priorTermPromiseScores,
    required bool hasNextSeason,
    required ManagerCareerSeason managerSeason,
  }) {
    closing.validateTransition(transition);
    if (!identical(closing, _annualClosing) || _domainProjected) {
      throw StateError('Foreign or consumed owned domain projection.');
    }
    _domainProjected = true;
    return _graph.domain.resumeEngine.projectRuntimeSeason(
        season: season,
        config: closing.world.opening.config,
        priorClubs: priorClubs,
        acceptedPromises: acceptedPromises,
        loanHistory: closing.loanHistory,
        electionInterval: electionInterval,
        completedElectionTerms: completedElectionTerms,
        seasonsIntoCurrentTerm: seasonsIntoCurrentTerm,
        priorTermPromiseScores: priorTermPromiseScores,
        hasNextSeason: hasNextSeason,
        managerSeason: managerSeason);
  }

  Object get owner => _advanced.owner;
  Object get revision => _advanced.revision;
  Object get provenance => _advanced.provenance;
  Object get executionIdentity => _advanced.executionIdentity;
  Object get managerLineage => _advanced.managerLineage;
  Object get transferLineage => _advanced.transferLineage;
  PreparedWorldOpening get opening => _advanced.opening;
  ManagerSeasonAuthority? get managerAuthority => _advanced.managerAuthority;
  PreparedRuntimeOrigin get origin => _advanced.origin;
  PreparedExecutionState get state => _advanced.state;
  int get openingContractCount => _advanced.openingContractCount;
  FacilityPortfolioRuntimeState get facilities => _graph.inputs.facilities;
  SponsorRuntimeCheckpoint get openingSponsor => _graph.inputs.sponsor;
  Map<String, FanState> get fanStates => Map.unmodifiable(_graph.inputs.fans);
  Map<String, MediaState> get mediaStates =>
      Map.unmodifiable(_graph.inputs.media);
  Map<String, PresidentManagementProfile> get managementProfiles =>
      Map.unmodifiable(_graph.inputs.profiles);
  int get sponsorProcessedClubCount =>
      _graph.coordinator._processedClubIds.length;
  Money get sponsorSeasonRevenue => _graph.coordinator._seasonRevenue;

  PreparedFacilitySponsorSeason move(
          {required Object expectedOwner,
          required Object expectedRevision,
          required Object expectedProvenance}) =>
      PreparedFacilitySponsorSeason._(
          _producer,
          _graph,
          _advanced.move(
              expectedOwner: expectedOwner,
              expectedRevision: expectedRevision,
              expectedProvenance: expectedProvenance));

  void validateEconomyHandoff() {
    final economy = _graph.domain.runtimeEngine.worldEngine.economyEngine;
    if (state != PreparedExecutionState.prepared ||
        _graph.coordinator.financeRecording != null ||
        _graph.coordinator._processedClubIds.isNotEmpty ||
        economy is! _FacilityEconomyEngine ||
        economy.financeRecording != null) {
      throw StateError(
          'Facility graph is not an unattempted recording-free lease.');
    }
  }

  void bindReleasedAnnualClosing(
      OwnedAdvancedAnnualClosing closing,
      FullM65RuntimeEconomyContinuationAuthority authority,
      SeasonFinanceAuthorityReceipt receipt) {
    if (_annualClosing != null ||
        !identical(closing.world.opening, opening) ||
        !authority.permitsAnnualRelease(opening, executionIdentity, receipt)) {
      throw StateError('Foreign released facility graph.');
    }
    _annualClosing = closing;
  }

  FacilityEconomyRecipient moveToEconomy(
      {required FullM65RuntimeEconomyContinuationAuthority authority,
      required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance,
      required FullM65SeasonFinancePipeline recording}) {
    validateEconomyHandoff();
    final economy = _graph.domain.runtimeEngine.worldEngine.economyEngine
        as _FacilityEconomyEngine;
    final advanced = _advanced.moveToEconomy(
        authority: authority,
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance);
    economy._claimedRecording = recording;
    _graph.coordinator._claimedRecording = recording;
    return FacilityEconomyRecipient._(advanced, economy, _graph.coordinator);
  }
}

final class FacilityEconomyRecipient {
  FacilityEconomyRecipient._(this._advanced, this._economy, this._coordinator);
  final AdvancedEconomyRecipient _advanced;
  final _FacilityEconomyEngine _economy;
  final _FacilitySponsorSeasonEconomyEngine _coordinator;
  int get contractCount => _advanced.contractCount;
  int get processedSponsorClubCount => _coordinator._processedClubIds.length;
  OwnedAdvancedAnnualClosing releaseSettledAnnualClosing({
    required FullM65RuntimeEconomyContinuationAuthority authority,
    required CommittedSeasonSettlementCapability committed,
    required SeasonFinanceAuthorityReceipt receipt,
  }) =>
      _advanced.releaseSettledAnnualClosing(
          authority: authority, committed: committed, receipt: receipt);
  FinanceAttendanceEvidence prepareAttendance(Club club, int position) =>
      _economy._attendance(club, position);
  void cacheAttendance(Map<String, FinanceAttendanceEvidence> evidence) {
    if (_economy._preparedAttendance != null)
      throw StateError('Attendance already admitted.');
    _economy._preparedAttendance = Map.unmodifiable(evidence);
  }

  List<ClubFinanceSeason> executeCommittedFinance(
          {required Object expectedExecution,
          required CommittedSeasonSettlementCapability committed}) =>
      _advanced.executeCommittedFinance(
          expectedExecution: expectedExecution, committed: committed);
}

class FacilitySponsorCrisisRuntimeCareerEngine {
  FacilitySponsorPostseasonContinuation stageOwnedPostseason({
    required PreparedFacilitySponsorSeason prepared,
    required OwnedAdvancedAnnualClosing closing,
    required Object transition,
    required WorldCheckpoint world,
    required FacilityPortfolioRuntimeState facilities,
    required List<PresidentClubRuntimeState> domainClubs,
  }) {
    closing.validateTransition(transition);
    world.validate();
    final ids = world.baseClubs.map((c) => c.id).toSet();
    facilities.validateAgainst(ids);
    if (!identical(prepared._producer, this) ||
        !identical(prepared._annualClosing, closing) ||
        world.nextSeasonIndex != closing.world.opening.seasonIndex + 1 ||
        domainClubs.length != 48 ||
        domainClubs.map((c) => c.clubId).toSet().length != 48 ||
        !domainClubs.every((c) => ids.contains(c.clubId))) {
      throw StateError('Foreign facility annual-closing successor.');
    }
    for (final state in domainClubs) {
      state.validate();
    }
    final sponsor = prepared._graph.coordinator.finalCheckpoint;
    if (sponsor.nextSeasonIndex != world.nextSeasonIndex) {
      throw StateError('Sponsor annual successor season mismatch.');
    }
    final inputs = _FacilitySeasonInputs(
        world.baseClubs,
        world.config,
        facilities,
        sponsor,
        Map.unmodifiable(
            {for (final c in domainClubs) c.clubId: c.managementProfile}),
        Map.unmodifiable(
            {for (final c in domainClubs) c.clubId: c.fanReputation}),
        Map.unmodifiable(
            {for (final c in domainClubs) c.clubId: c.mediaReputation}));
    final graph = _FacilityPreparedGraph(
        inputs, prepared._graph.coordinator, prepared._graph.domain);
    return FacilitySponsorPostseasonContinuation._(
        graph, prepared.owner, prepared.revision, prepared.provenance, world)
      .._successorEconomy = prepared._graph.domain.runtimeEngine.worldEngine
          .economyEngine as _FacilityEconomyEngine
      .._successorStadiums = Map.unmodifiable({
        for (final state in facilities.stadiumFacilities) state.clubId: state
      });
  }

  /// Captures the real owned annual call, before movement/completion/offseason.
  /// Recording is bound to the original wrapper graph, never a rebuilt graph.
  OwnedAdvancedAnnualClosing captureAnnualClosing(
    PreparedFacilitySponsorSeason prepared, {
    required Object expectedOwner,
    required Object expectedRevision,
    required Object expectedProvenance,
    required FullM65SeasonFinancePipeline recording,
  }) {
    if (!identical(prepared._producer, this) ||
        !identical(prepared.owner, expectedOwner) ||
        !identical(prepared.revision, expectedRevision) ||
        !identical(prepared.provenance, expectedProvenance) ||
        !identical(recording.owner, expectedOwner) ||
        !identical(recording.sourceRevision, expectedRevision) ||
        !identical(recording.provenance, expectedProvenance) ||
        !identical(recording.effectiveClubSource, prepared.managerAuthority) ||
        recording.seasonIndex != prepared.opening.seasonIndex) {
      throw StateError('Foreign annual-closing recording/producer.');
    }
    prepared.validateEconomyHandoff();
    final economy = prepared._graph.domain.runtimeEngine.worldEngine
        .economyEngine as _FacilityEconomyEngine;
    economy._claimedRecording = recording;
    prepared._graph.coordinator._claimedRecording = recording;
    return prepared._annualClosing =
        prepared._graph.domain.runtimeEngine.captureAnnualClosing(
      prepared._advanced,
      expectedOwner: expectedOwner,
      expectedRevision: expectedRevision,
      expectedProvenance: expectedProvenance,
    );
  }

  FacilitySponsorPostseasonContinuation activateFirstPostseason({
    required ApplicationPostseasonTransitionToken token,
    required WorldCheckpoint world,
    required FacilityPortfolioRuntimeState facilities,
    required List<PresidentClubRuntimeState> domainClubs,
  }) {
    token.validate();
    world.validate();
    final ids = world.baseClubs.map((club) => club.id).toSet();
    facilities.validateAgainst(ids);
    if (world.nextSeasonIndex != token.source.seasonIndex + 1 ||
        domainClubs.length != ids.length ||
        domainClubs.map((club) => club.clubId).toSet().length != ids.length ||
        !domainClubs.every((club) => ids.contains(club.clubId))) {
      throw StateError('Invalid first facility/sponsor activation successor.');
    }
    for (final club in domainClubs) {
      club.validate();
    }
    token.claimFacilityActivation();
    final graph = _prepareGraph(_FacilitySeasonInputs(
      world.baseClubs,
      world.config,
      facilities,
      SponsorRuntimeCheckpoint.initial(seasonIndex: world.nextSeasonIndex),
      {for (final state in domainClubs) state.clubId: state.managementProfile},
      {for (final state in domainClubs) state.clubId: state.fanReputation},
      {for (final state in domainClubs) state.clubId: state.mediaReputation},
    ));
    return FacilitySponsorPostseasonContinuation._(
      graph,
      token.owner,
      token.revision,
      token.provenance,
      world,
    );
  }

  const FacilitySponsorCrisisRuntimeCareerEngine({
    this.financeRecording,
    this.sponsorSystem = const SponsorSystemEngine(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.presidentGenerator = const PresidentProfileGenerator(),
    this.managementProfileGenerator =
        const PresidentManagementProfileGenerator(),
    this.crisisIntegration = const CrisisRuntimeIntegrationEngine(),
    this.sourceEngine = const PromiseMediaCareerEngine(),
  });

  final SponsorSystemEngine sponsorSystem;
  final FullM65SeasonFinancePipeline? financeRecording;
  final WorldCareerEngine baseWorldEngine;
  final PresidentProfileGenerator presidentGenerator;
  final PresidentManagementProfileGenerator managementProfileGenerator;
  final CrisisRuntimeIntegrationEngine crisisIntegration;
  final PromiseMediaCareerEngine sourceEngine;

  PreparedFacilitySponsorSeason prepareInitial(
      {required List<Club> clubs,
      required List<WorldLeague> leagues,
      required SimulationConfig config,
      Object? owner,
      Object? revision,
      Object? provenance,
      bool captureManagerAuthority = false,
      Iterable<AcademyFacilityState>? academyFacilities,
      Iterable<StadiumFacilityState>? stadiumFacilities,
      Iterable<TrainingGroundFacilityState>? trainingGroundFacilities,
      Money totalInvestmentSpent = Money.zero}) {
    final inputs = _initialInputs(
        clubs: clubs,
        config: config,
        academyFacilities: academyFacilities,
        stadiumFacilities: stadiumFacilities,
        trainingGroundFacilities: trainingGroundFacilities,
        totalInvestmentSpent: totalInvestmentSpent);
    final graph = _prepareGraph(inputs);
    final prepared = graph.domain.runtimeEngine.prepareInitial(
        clubs: clubs,
        leagues: leagues,
        config: config,
        owner: owner,
        revision: revision,
        provenance: provenance,
        captureManagerAuthority: captureManagerAuthority);
    return PreparedFacilitySponsorSeason._(this, graph, prepared);
  }

  PreparedFacilitySponsorSeason prepareResume(
      {required FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
      Object? owner,
      Object? revision,
      Object? provenance,
      bool captureManagerAuthority = false}) {
    final graph = _prepareGraph(_resumeInputs(checkpoint));
    final prepared = graph.domain.runtimeEngine.prepareResume(
        checkpoint: checkpoint.runtime.domain.presidentRuntime.runtime.runtime,
        owner: owner,
        revision: revision,
        provenance: provenance,
        captureManagerAuthority: captureManagerAuthority);
    return PreparedFacilitySponsorSeason._(this, graph, prepared);
  }

  /// Executes the owned advanced graph, not a new domain/checkpoint simulation.
  /// Domain-memory publication remains the existing legacy facade's job.
  AdvancedRuntimeSimulationResult executePrepared(
      PreparedFacilitySponsorSeason p,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    if (!identical(p._producer, this)) {
      throw StateError('Foreign facility/sponsor prepared producer.');
    }
    return p._graph.domain.runtimeEngine.executePrepared(p._advanced,
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance);
  }

  _FacilitySeasonInputs _initialInputs(
      {required List<Club> clubs,
      required SimulationConfig config,
      Iterable<AcademyFacilityState>? academyFacilities,
      Iterable<StadiumFacilityState>? stadiumFacilities,
      Iterable<TrainingGroundFacilityState>? trainingGroundFacilities,
      Money totalInvestmentSpent = Money.zero}) {
    final facilities = FacilityPortfolioRuntimeState.forClubs(
        clubs: clubs,
        academyFacilities: academyFacilities,
        stadiumFacilities: stadiumFacilities,
        trainingGroundFacilities: trainingGroundFacilities,
        totalInvestmentSpent: totalInvestmentSpent);
    final sponsor =
        SponsorRuntimeCheckpoint.initial(seasonIndex: config.seasonIndex);
    final profiles = <String, PresidentManagementProfile>{};
    final fans = <String, FanState>{};
    final media = <String, MediaState>{};
    for (final club in clubs) {
      final president = presidentGenerator.generateInitial(
          clubId: club.id,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion);
      profiles[club.id] = managementProfileGenerator.generate(
          president: president,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion);
      fans[club.id] = FanState.initial(club.id);
      media[club.id] = MediaState(clubId: club.id, credibility: 65);
    }
    return _FacilitySeasonInputs(
        clubs,
        config,
        facilities,
        sponsor,
        Map.unmodifiable(profiles),
        Map.unmodifiable(fans),
        Map.unmodifiable(media));
  }

  _FacilitySeasonInputs _resumeInputs(
      FacilitySponsorCrisisRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final domain = checkpoint.runtime.domain;
    final world = domain.presidentRuntime.runtime.runtime.world;
    return _FacilitySeasonInputs(
        world.baseClubs,
        world.config,
        checkpoint.facilities,
        checkpoint.runtime.sponsor,
        Map.unmodifiable({
          for (final s in domain.presidentRuntime.clubs)
            s.clubId: s.managementProfile
        }),
        Map.unmodifiable({
          for (final s in domain.presidentRuntime.clubs)
            s.clubId: s.fanReputation
        }),
        Map.unmodifiable({
          for (final s in domain.presidentRuntime.clubs)
            s.clubId: s.mediaReputation
        }));
  }

  _FacilityPreparedGraph _prepareGraph(_FacilitySeasonInputs inputs) {
    final coordinator = _FacilitySponsorSeasonEconomyEngine(
        financeRecording: financeRecording,
        delegate: baseWorldEngine.economyEngine,
        sponsorSystem: sponsorSystem,
        openingSponsor: inputs.sponsor,
        expectedClubIds: inputs.clubs.map((c) => c.id),
        presidentProfilesByClub: inputs.profiles,
        fanStatesByClub: inputs.fans,
        mediaStatesByClub: inputs.media,
        careerSeed: inputs.config.careerSeed,
        simulationVersion: inputs.config.simulationVersion);
    return _FacilityPreparedGraph(
        inputs,
        coordinator,
        _domainEngine(
            coordinator: coordinator,
            facilities: inputs.facilities,
            fanStatesByClub: inputs.fans));
  }

  FacilitySponsorCrisisRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
    Iterable<AcademyFacilityState>? academyFacilities,
    Iterable<StadiumFacilityState>? stadiumFacilities,
    Iterable<TrainingGroundFacilityState>? trainingGroundFacilities,
    Money totalInvestmentSpent = Money.zero,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }
    final inputs = _initialInputs(
        clubs: clubs,
        config: config,
        academyFacilities: academyFacilities,
        stadiumFacilities: stadiumFacilities,
        trainingGroundFacilities: trainingGroundFacilities,
        totalInvestmentSpent: totalInvestmentSpent);

    final first = _simulateInitialSeason(
      clubs: clubs,
      leagues: leagues,
      config: config,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: seasonCount > 1 || hasFutureSeasonAfterReport,
      facilities: inputs.facilities,
      openingSponsor: inputs.sponsor,
      profiles: inputs.profiles,
      fans: inputs.fans,
      media: inputs.media,
    );
    var current = first.checkpoint;
    final boundaries = <FacilitySponsorCrisisRuntimeSeasonBoundary>[first];

    for (var offset = 1; offset < seasonCount; offset++) {
      final next = _resumeOneSeason(
        checkpoint: current,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      boundaries.add(next);
      current = next.checkpoint;
    }
    return FacilitySponsorCrisisRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  FacilitySponsorCrisisRuntimeCareerResult resume({
    required FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    var current = checkpoint;
    final boundaries = <FacilitySponsorCrisisRuntimeSeasonBoundary>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final next = _resumeOneSeason(
        checkpoint: current,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      boundaries.add(next);
      current = next.checkpoint;
    }
    return FacilitySponsorCrisisRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  FacilitySponsorCrisisRuntimeSeasonBoundary _simulateInitialSeason({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required int electionInterval,
    required bool hasFutureSeasonAfterReport,
    required FacilityPortfolioRuntimeState facilities,
    required SponsorRuntimeCheckpoint openingSponsor,
    required Map<String, PresidentManagementProfile> profiles,
    required Map<String, FanState> fans,
    required Map<String, MediaState> media,
  }) {
    final graph = _prepareGraph(_FacilitySeasonInputs(
        clubs, config, facilities, openingSponsor, profiles, fans, media));
    final coordinator = graph.coordinator;
    final engine = graph.domain;
    final result = engine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return _finishBoundary(
      seasonIndex: config.seasonIndex,
      report: result.report,
      domain: result.checkpoint,
      coordinator: coordinator,
      facilities: facilities,
    );
  }

  FacilitySponsorCrisisRuntimeSeasonBoundary _resumeOneSeason({
    required FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
    required bool hasFutureSeasonAfterReport,
  }) {
    final graph = _prepareGraph(_resumeInputs(checkpoint));
    final domain = checkpoint.runtime.domain;
    final coordinator = graph.coordinator;
    final engine = graph.domain;
    final result = engine.resume(
      checkpoint: domain,
      seasonCount: 1,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return _finishBoundary(
      seasonIndex: checkpoint.nextSeasonIndex,
      report: result.report,
      domain: result.checkpoint,
      coordinator: coordinator,
      facilities: checkpoint.facilities,
    );
  }

  FacilitySponsorCrisisRuntimeSeasonBoundary _finishBoundary({
    required int seasonIndex,
    required PresidentReputationCareerReport report,
    required dynamic domain,
    required _FacilitySponsorSeasonEconomyEngine coordinator,
    required FacilityPortfolioRuntimeState facilities,
  }) {
    final sponsorCheckpoint = SponsorPresidentRuntimeCheckpoint(
      domain: domain,
      sponsor: coordinator.finalCheckpoint,
    );
    final sponsorBoundary = SponsorRuntimeSeasonBoundary(
      seasonIndex: seasonIndex,
      report: report,
      contracts: coordinator.contracts,
      revenueByClub: coordinator.revenueByClub,
      checkpoint: sponsorCheckpoint,
    );
    final crisis = crisisIntegration.apply(sponsorCheckpoint.domain);
    final combinedRuntime = SponsorPresidentRuntimeCheckpoint(
      domain: crisis.checkpoint,
      sponsor: sponsorCheckpoint.sponsor,
    );
    return FacilitySponsorCrisisRuntimeSeasonBoundary(
      sponsor: sponsorBoundary,
      crisis: crisis,
      checkpoint: FacilitySponsorCrisisRuntimeCheckpoint(
        runtime: combinedRuntime,
        facilities: facilities,
      ),
    );
  }

  PresidentDomainCareerEngine _domainEngine({
    required _FacilitySponsorSeasonEconomyEngine coordinator,
    required FacilityPortfolioRuntimeState facilities,
    required Map<String, FanState> fanStatesByClub,
  }) {
    final academies = {
      for (final state in facilities.academyFacilities) state.clubId: state,
    };
    final stadiums = {
      for (final state in facilities.stadiumFacilities) state.clubId: state,
    };
    final trainingGrounds = {
      for (final state in facilities.trainingGroundFacilities)
        state.clubId: state,
    };
    final world = WorldCareerEngine(
      seasonEngine: baseWorldEngine.seasonEngine,
      poolGenerator: baseWorldEngine.poolGenerator,
      lifecycleEngine: _FacilityLifecycleEngine(
        delegate: baseWorldEngine.lifecycleEngine,
        academyFacilities: academies,
        trainingGroundFacilities: trainingGrounds,
      ),
      strengthCalculator: baseWorldEngine.strengthCalculator,
      economyEngine: _FacilityEconomyEngine(
        financeRecording: financeRecording,
        delegate: coordinator,
        stadiumFacilities: stadiums,
        fanStatesByClub: fanStatesByClub,
      ),
      transferMarketEngine: baseWorldEngine.transferMarketEngine,
    );
    final advanced = AdvancedRuntimeCareerEngine(worldEngine: world);
    return PresidentDomainCareerEngine(
      runtimeEngine: advanced,
      sourceEngine: sourceEngine,
      resumeEngine: PresidentDomainResumeEngine(
        runtimeEngine: advanced,
        sourceEngine: sourceEngine,
      ),
    );
  }
}

class _FacilityLifecycleEngine extends PlayerLifecycleEngine {
  _FacilityLifecycleEngine({
    required this.delegate,
    required this.academyFacilities,
    required this.trainingGroundFacilities,
  });

  final PlayerLifecycleEngine delegate;
  final Map<String, AcademyFacilityState> academyFacilities;
  final Map<String, TrainingGroundFacilityState> trainingGroundFacilities;

  @override
  PlayerLifecycleResult advance({
    required List<Player> currentPlayers,
    required List<Club> currentClubs,
    required List<Club> referenceClubs,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
    Map<String, AcademyFacilityState> academyFacilities = const {},
    Map<String, TrainingGroundFacilityState> trainingGroundFacilities =
        const {},
  }) =>
      delegate.advance(
        currentPlayers: currentPlayers,
        currentClubs: currentClubs,
        referenceClubs: referenceClubs,
        careerSeed: careerSeed,
        nextSeasonIndex: nextSeasonIndex,
        simulationVersion: simulationVersion,
        academyFacilities: this.academyFacilities,
        trainingGroundFacilities: this.trainingGroundFacilities,
      );
}

class _FacilityEconomyEngine extends BasicEconomyEngine {
  _FacilityEconomyEngine({
    this.financeRecording,
    required this.delegate,
    required this.stadiumFacilities,
    required this.fanStatesByClub,
  });

  final BasicEconomyEngine delegate;
  final FullM65SeasonFinancePipeline? financeRecording;
  FullM65SeasonFinancePipeline? _claimedRecording;
  Map<String, FinanceAttendanceEvidence>? _preparedAttendance;
  Map<String, StadiumFacilityState> stadiumFacilities;
  Map<String, FanState> fanStatesByClub;
  final StadiumInvestmentPolicy stadiumPolicy = const StadiumInvestmentPolicy();

  FinanceAttendanceEvidence _attendance(Club club, int position) {
    final stadium = stadiumFacilities[club.id] ??
        (throw StateError('Missing stadium for ${club.id}.'));
    final trust = fanStatesByClub[club.id]?.overallTrust ??
        StadiumInvestmentPolicy.neutralFanTrust;
    return FinanceAttendanceEvidence(
        club: club,
        stadiumLevel: stadium.level,
        fanTrust: trust,
        leaguePosition: position,
        multiplierBps: stadiumPolicy
            .attendanceProfile(
                level: stadium.level,
                clubStrength: club.strength,
                leaguePosition: position,
                fanTrust: trust)
            .revenueMultiplierBps);
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
    final multipliers = <String, int>{};
    for (final club in clubs) {
      final position = positions[club.id];
      if (position == null) {
        throw StateError('Missing league position for ${club.id}.');
      }
      final evidence =
          _preparedAttendance?[club.id] ?? _attendance(club, position);
      if (!identical(evidence.club, club) ||
          evidence.leaguePosition != position) {
        throw StateError('Changed attendance source.');
      }
      multipliers[club.id] = evidence.multiplierBps;
      (_claimedRecording ?? financeRecording)
          ?.forSeason(seasonReport.seasonIndex)
          ?.observeAttendance(evidence);
    }
    return delegate.simulateSeason(
      clubs: clubs,
      players: players,
      seasonReport: seasonReport,
      openingStates: openingStates,
      economicScaleBps: economicScaleBps,
      costScaleBps: costScaleBps,
      annualWagesByClub: annualWagesByClub,
      transferInstallmentIncomeByClub: transferInstallmentIncomeByClub,
      transferInstallmentExpenseByClub: transferInstallmentExpenseByClub,
      matchdayRevenueMultiplierBpsByClub: multipliers,
      sponsorRevenueByClub: sponsorRevenueByClub,
    );
  }
}

class _FacilitySponsorSeasonEconomyEngine extends BasicEconomyEngine {
  _FacilitySponsorSeasonEconomyEngine({
    this.financeRecording,
    required this.delegate,
    required this.sponsorSystem,
    required this.openingSponsor,
    required Iterable<String> expectedClubIds,
    required this.presidentProfilesByClub,
    required this.fanStatesByClub,
    required this.mediaStatesByClub,
    required this.careerSeed,
    required this.simulationVersion,
  })  : expectedClubIds = Set.unmodifiable(expectedClubIds),
        super(wageModel: delegate.wageModel);

  final BasicEconomyEngine delegate;
  final SponsorSystemEngine sponsorSystem;
  final FullM65SeasonFinancePipeline? financeRecording;
  FullM65SeasonFinancePipeline? _claimedRecording;
  SponsorRuntimeCheckpoint openingSponsor;
  final Set<String> expectedClubIds;
  Map<String, PresidentManagementProfile> presidentProfilesByClub;
  Map<String, FanState> fanStatesByClub;
  Map<String, MediaState> mediaStatesByClub;
  final int careerSeed;
  final int simulationVersion;

  final Set<String> _processedClubIds = <String>{};
  final List<SponsorContract> _contracts = <SponsorContract>[];
  final List<SponsorContract> _activeNext = <SponsorContract>[];
  final Map<String, Money> _revenueByClub = <String, Money>{};
  Money _seasonRevenue = Money.zero;

  List<SponsorContract> get contracts {
    _assertComplete();
    final result = [..._contracts]
      ..sort((a, b) => a.offer.clubId.compareTo(b.offer.clubId));
    return List.unmodifiable(result);
  }

  Map<String, Money> get revenueByClub {
    _assertComplete();
    return Map.unmodifiable(_revenueByClub);
  }

  SponsorRuntimeCheckpoint get finalCheckpoint {
    _assertComplete();
    final active = [..._activeNext]
      ..sort((a, b) => a.offer.clubId.compareTo(b.offer.clubId));
    return SponsorRuntimeCheckpoint(
      nextSeasonIndex: openingSponsor.nextSeasonIndex + 1,
      activeContracts: active,
      totalRevenuePaid: openingSponsor.totalRevenuePaid + _seasonRevenue,
    );
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
    if (sponsorRevenueByClub != null) {
      throw StateError(
        'M47 sponsor runtime cannot be combined with another sponsor override.',
      );
    }
    if (seasonReport.seasonIndex != openingSponsor.nextSeasonIndex) {
      throw StateError(
          'Sponsor economy season does not match checkpoint cursor.');
    }
    final ids = clubs.map((club) => club.id).toSet();
    if (!expectedClubIds.containsAll(ids)) {
      throw StateError('Sponsor economy received an unknown club.');
    }
    if (_processedClubIds.intersection(ids).isNotEmpty) {
      throw StateError('Sponsor economy processed a club twice in one season.');
    }
    final positions = <String, int>{};
    for (var index = 0; index < seasonReport.table.length; index++) {
      positions[seasonReport.table[index].clubId] = index + 1;
    }
    final existing = openingSponsor.activeContracts
        .where((contract) => ids.contains(contract.offer.clubId))
        .toList(growable: false);
    final resolution = sponsorSystem.resolveSeason(
      seasonIndex: seasonReport.seasonIndex,
      clubs: clubs,
      leaguePositions: positions,
      presidentProfilesByClub: {
        for (final id in ids)
          id: presidentProfilesByClub[id] ??
              (throw StateError('Missing sponsor president profile for $id.')),
      },
      fanStatesByClub: {
        for (final id in ids)
          id: fanStatesByClub[id] ??
              (throw StateError('Missing sponsor fan state for $id.')),
      },
      mediaStatesByClub: {
        for (final id in ids)
          id: mediaStatesByClub[id] ??
              (throw StateError('Missing sponsor media state for $id.')),
      },
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
      existingContracts: existing,
      totalRevenuePaid: Money.zero,
    );

    _processedClubIds.addAll(ids);
    _contracts.addAll(resolution.contracts);
    _activeNext.addAll(resolution.checkpoint.activeContracts);
    _revenueByClub.addAll(resolution.revenueByClub);
    _seasonRevenue += resolution.totalRevenue;
    (_claimedRecording ?? financeRecording)
        ?.forSeason(seasonReport.seasonIndex)
        ?.observeSponsor(ids, resolution);

    return delegate.simulateSeason(
      clubs: clubs,
      players: players,
      seasonReport: seasonReport,
      openingStates: openingStates,
      economicScaleBps: economicScaleBps,
      costScaleBps: costScaleBps,
      annualWagesByClub: annualWagesByClub,
      transferInstallmentIncomeByClub: transferInstallmentIncomeByClub,
      transferInstallmentExpenseByClub: transferInstallmentExpenseByClub,
      matchdayRevenueMultiplierBpsByClub: matchdayRevenueMultiplierBpsByClub,
      sponsorRevenueByClub: resolution.revenueByClub,
    );
  }

  void _assertComplete() {
    if (_processedClubIds.length != expectedClubIds.length ||
        !_processedClubIds.containsAll(expectedClubIds)) {
      throw StateError(
        'Sponsor runtime season is incomplete: processed '
        '${_processedClubIds.length}/${expectedClubIds.length} clubs.',
      );
    }
  }
}
