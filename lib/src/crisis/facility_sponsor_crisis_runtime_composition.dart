import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../election/president_reputation_career_report.dart';
import '../election/president_tenure.dart';
import '../facility/academy_facility.dart';
import '../facility/stadium_facility.dart';
import '../facility/training_ground_facility.dart';
import '../fan/fan_state.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../media/media_state.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../season/season_report.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../sponsor/sponsor_system.dart';
import '../world/world_career_engine.dart';
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
        academyFacilities.map((state) => '${state.clubId}:${state.level}').join('|'),
        stadiumFacilities.map((state) => '${state.clubId}:${state.level}').join('|'),
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

  String get signature => '${runtime.signature}||facilities=${facilities.signature}';
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
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
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
              return TrainingGroundFacilityState(clubId: entry.$1, level: entry.$2);
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
      throw StateError('Combined checkpoint cursor must match sponsor boundary.');
    }
    if (checkpoint.runtime.sponsor.signature != sponsor.checkpoint.sponsor.signature) {
      throw StateError('Crisis composition must not mutate sponsor state.');
    }
    if (checkpoint.runtime.domain.signature != crisis.checkpoint.signature) {
      throw StateError('Combined checkpoint must carry crisis-adjusted domain.');
    }
  }

  String get signature =>
      'season=$seasonIndex:sponsor=${sponsor.signature}:'
      'crisis=${crisis.signature}:final=${checkpoint.signature}';
}

class FacilitySponsorCrisisRuntimeCareerResult {
  FacilitySponsorCrisisRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<FacilitySponsorCrisisRuntimeSeasonBoundary> boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;
  final List<FacilitySponsorCrisisRuntimeSeasonBoundary> boundaries;

  int get crisisCount => boundaries.fold(0, (sum, item) => sum + item.crisisCount);

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
class FacilitySponsorCrisisRuntimeCareerEngine {
  const FacilitySponsorCrisisRuntimeCareerEngine({
    this.sponsorSystem = const SponsorSystemEngine(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.presidentGenerator = const PresidentProfileGenerator(),
    this.managementProfileGenerator = const PresidentManagementProfileGenerator(),
    this.crisisIntegration = const CrisisRuntimeIntegrationEngine(),
  });

  final SponsorSystemEngine sponsorSystem;
  final WorldCareerEngine baseWorldEngine;
  final PresidentProfileGenerator presidentGenerator;
  final PresidentManagementProfileGenerator managementProfileGenerator;
  final CrisisRuntimeIntegrationEngine crisisIntegration;

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
    final facilities = FacilityPortfolioRuntimeState.forClubs(
      clubs: clubs,
      academyFacilities: academyFacilities,
      stadiumFacilities: stadiumFacilities,
      trainingGroundFacilities: trainingGroundFacilities,
      totalInvestmentSpent: totalInvestmentSpent,
    );
    final openingSponsor = SponsorRuntimeCheckpoint(
      nextSeasonIndex: config.seasonIndex,
      activeContracts: const [],
      totalRevenuePaid: Money.zero,
    );
    final profiles = <String, PresidentManagementProfile>{};
    final fans = <String, FanState>{};
    final media = <String, MediaState>{};
    for (final club in clubs) {
      final president = presidentGenerator.generateInitial(
        clubId: club.id,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      profiles[club.id] = managementProfileGenerator.generate(
        president: president,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      fans[club.id] = FanState.initial(club.id);
      media[club.id] = MediaState(clubId: club.id, credibility: 65);
    }

    final first = _simulateInitialSeason(
      clubs: clubs,
      leagues: leagues,
      config: config,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport:
          seasonCount > 1 || hasFutureSeasonAfterReport,
      facilities: facilities,
      openingSponsor: openingSponsor,
      profiles: profiles,
      fans: fans,
      media: media,
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
    final coordinator = _FacilitySponsorSeasonEconomyEngine(
      delegate: baseWorldEngine.economyEngine,
      sponsorSystem: sponsorSystem,
      openingSponsor: openingSponsor,
      expectedClubIds: clubs.map((club) => club.id),
      presidentProfilesByClub: profiles,
      fanStatesByClub: fans,
      mediaStatesByClub: media,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final engine = _domainEngine(
      coordinator: coordinator,
      facilities: facilities,
      fanStatesByClub: fans,
    );
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
    checkpoint.validate();
    final domain = checkpoint.runtime.domain;
    final config = domain.presidentRuntime.runtime.runtime.world.config;
    final clubs = domain.presidentRuntime.runtime.runtime.world.baseClubs;
    final profiles = <String, PresidentManagementProfile>{};
    final fans = <String, FanState>{};
    final media = <String, MediaState>{};
    for (final state in domain.presidentRuntime.clubs) {
      profiles[state.clubId] = state.managementProfile;
      fans[state.clubId] = state.fanReputation;
      media[state.clubId] = state.mediaReputation;
    }
    final coordinator = _FacilitySponsorSeasonEconomyEngine(
      delegate: baseWorldEngine.economyEngine,
      sponsorSystem: sponsorSystem,
      openingSponsor: checkpoint.runtime.sponsor,
      expectedClubIds: clubs.map((club) => club.id),
      presidentProfilesByClub: profiles,
      fanStatesByClub: fans,
      mediaStatesByClub: media,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final engine = _domainEngine(
      coordinator: coordinator,
      facilities: checkpoint.facilities,
      fanStatesByClub: fans,
    );
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
      for (final state in facilities.trainingGroundFacilities) state.clubId: state,
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
        delegate: coordinator,
        stadiumFacilities: stadiums,
        fanStatesByClub: fanStatesByClub,
      ),
      transferMarketEngine: baseWorldEngine.transferMarketEngine,
    );
    final advanced = AdvancedRuntimeCareerEngine(worldEngine: world);
    return PresidentDomainCareerEngine(
      runtimeEngine: advanced,
      resumeEngine: PresidentDomainResumeEngine(runtimeEngine: advanced),
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
    Map<String, TrainingGroundFacilityState> trainingGroundFacilities = const {},
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
    required this.delegate,
    required this.stadiumFacilities,
    required this.fanStatesByClub,
  });

  final BasicEconomyEngine delegate;
  final Map<String, StadiumFacilityState> stadiumFacilities;
  final Map<String, FanState> fanStatesByClub;
  final StadiumInvestmentPolicy stadiumPolicy = const StadiumInvestmentPolicy();

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
      final stadium = stadiumFacilities[club.id];
      if (stadium == null) {
        throw StateError('Missing stadium facility state for ${club.id}.');
      }
      final position = positions[club.id];
      if (position == null) {
        throw StateError('Missing league position for ${club.id}.');
      }
      final fanTrust = fanStatesByClub[club.id]?.overallTrust ??
          StadiumInvestmentPolicy.neutralFanTrust;
      multipliers[club.id] = stadiumPolicy
          .attendanceProfile(
            level: stadium.level,
            clubStrength: club.strength,
            leaguePosition: position,
            fanTrust: fanTrust,
          )
          .revenueMultiplierBps;
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
  final SponsorRuntimeCheckpoint openingSponsor;
  final Set<String> expectedClubIds;
  final Map<String, PresidentManagementProfile> presidentProfilesByClub;
  final Map<String, FanState> fanStatesByClub;
  final Map<String, MediaState> mediaStatesByClub;
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
      throw StateError('Sponsor economy season does not match checkpoint cursor.');
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
