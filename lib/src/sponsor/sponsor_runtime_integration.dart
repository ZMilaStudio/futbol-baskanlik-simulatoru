import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../election/president_reputation_career_report.dart';
import '../election/president_tenure.dart';
import '../fan/fan_state.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../media/media_state.dart';
import '../player/player.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_domain_memory_save_codec.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../save/sponsor_runtime_save_codec.dart';
import '../season/season_report.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'sponsor_system.dart';

class SponsorPresidentRuntimeCheckpoint {
  SponsorPresidentRuntimeCheckpoint({
    required this.domain,
    required this.sponsor,
  }) {
    validate();
  }

  final PresidentDomainMemoryCheckpoint domain;
  final SponsorRuntimeCheckpoint sponsor;

  int get nextSeasonIndex => domain.nextSeasonIndex;
  int get completedSeasons => domain.completedSeasons;

  void validate() {
    domain.validate();
    sponsor.validate();
    if (sponsor.nextSeasonIndex != domain.nextSeasonIndex) {
      throw StateError(
        'Sponsor and president-domain season cursors must match: '
        '${sponsor.nextSeasonIndex} != ${domain.nextSeasonIndex}.',
      );
    }
    final worldIds = domain.presidentRuntime.runtime.runtime.world.baseClubs
        .map((club) => club.id)
        .toSet();
    for (final contract in sponsor.activeContracts) {
      if (!worldIds.contains(contract.offer.clubId)) {
        throw StateError(
          'Sponsor contract references unknown club ${contract.offer.clubId}.',
        );
      }
    }
  }

  String get signature => '${domain.signature}||sponsor=${sponsor.signature}';
}

class SponsorPresidentRuntimeSaveCodec {
  const SponsorPresidentRuntimeSaveCodec({
    this.domainCodec = const PresidentDomainMemorySaveCodec(),
    this.sponsorCodec = const SponsorRuntimeSaveCodec(),
  });

  static const String format = 'zmila-fbs-sponsor-president-runtime';
  static const int currentSaveVersion = 1;

  final PresidentDomainMemorySaveCodec domainCodec;
  final SponsorRuntimeSaveCodec sponsorCodec;

  String encode(SponsorPresidentRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'domain': jsonDecode(domainCodec.encode(checkpoint.domain)),
      'sponsor': jsonDecode(sponsorCodec.encode(checkpoint.sponsor)),
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

  SponsorPresidentRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Sponsor-president save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Sponsor-president save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown sponsor-president save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0) {
      throw const SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Invalid sponsor-president save version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Sponsor-president save checksum mismatch.',
      );
    }
    if (version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Sponsor-president save version $version is newer than supported '
        'version $currentSaveVersion.',
      );
    }
    if (version != 1 || payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Sponsor-president save payload is invalid.',
      );
    }
    final map = Map<String, Object?>.from(payload);
    final domainJson = map['domain'];
    final sponsorJson = map['sponsor'];
    if (domainJson is! Map || sponsorJson is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Sponsor-president component payloads are invalid.',
      );
    }
    try {
      return SponsorPresidentRuntimeCheckpoint(
        domain: domainCodec.decode(SaveChecksum.canonicalJson(domainJson)),
        sponsor: sponsorCodec.decode(SaveChecksum.canonicalJson(sponsorJson)),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid sponsor-president runtime payload: $error',
      );
    }
  }
}

class SponsorRuntimeSeasonBoundary {
  SponsorRuntimeSeasonBoundary({
    required this.seasonIndex,
    required this.report,
    required Iterable<SponsorContract> contracts,
    required Map<String, Money> revenueByClub,
    required this.checkpoint,
  })  : contracts = List.unmodifiable(contracts),
        revenueByClub = Map.unmodifiable(revenueByClub);

  final int seasonIndex;
  final PresidentReputationCareerReport report;
  final List<SponsorContract> contracts;
  final Map<String, Money> revenueByClub;
  final SponsorPresidentRuntimeCheckpoint checkpoint;

  Money get totalRevenue => revenueByClub.values.fold(
        Money.zero,
        (sum, value) => sum + value,
      );

  String get signature {
    final sortedContracts = [...contracts]
      ..sort((a, b) => a.offer.clubId.compareTo(b.offer.clubId));
    final ids = revenueByClub.keys.toList()..sort();
    return 's$seasonIndex:'
        'contracts=${sortedContracts.map((item) => item.signature).join(';')}:'
        'revenue=${ids.map((id) => '$id:${revenueByClub[id]!.minorUnits}').join(';')}:'
        'checkpoint=${checkpoint.signature}';
  }
}

class SponsorRuntimeCareerResult {
  SponsorRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<SponsorRuntimeSeasonBoundary> boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final SponsorPresidentRuntimeCheckpoint checkpoint;
  final List<SponsorRuntimeSeasonBoundary> boundaries;

  Money get totalRuntimeRevenue => boundaries.fold(
        Money.zero,
        (sum, boundary) => sum + boundary.totalRevenue,
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

class SponsorRuntimeCareerEngine {
  const SponsorRuntimeCareerEngine({
    this.sponsorSystem = const SponsorSystemEngine(),
    this.baseEconomyEngine = const BasicEconomyEngine(),
    this.presidentGenerator = const PresidentProfileGenerator(),
    this.managementProfileGenerator = const PresidentManagementProfileGenerator(),
  });

  final SponsorSystemEngine sponsorSystem;
  final BasicEconomyEngine baseEconomyEngine;
  final PresidentProfileGenerator presidentGenerator;
  final PresidentManagementProfileGenerator managementProfileGenerator;

  SponsorRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }

    final openingSponsor = SponsorRuntimeCheckpoint(
      nextSeasonIndex: config.seasonIndex,
      activeContracts: const [],
      totalRevenuePaid: Money.zero,
    );
    final initialProfiles = <String, PresidentManagementProfile>{};
    final initialFan = <String, FanState>{};
    final initialMedia = <String, MediaState>{};
    for (final club in clubs) {
      final president = presidentGenerator.generateInitial(
        clubId: club.id,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      initialProfiles[club.id] = managementProfileGenerator.generate(
        president: president,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      initialFan[club.id] = FanState.initial(club.id);
      initialMedia[club.id] = MediaState(clubId: club.id, credibility: 65);
    }

    final firstCoordinator = _SponsorSeasonEconomyEngine(
      delegate: baseEconomyEngine,
      sponsorSystem: sponsorSystem,
      openingSponsor: openingSponsor,
      expectedClubIds: clubs.map((club) => club.id),
      presidentProfilesByClub: initialProfiles,
      fanStatesByClub: initialFan,
      mediaStatesByClub: initialMedia,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final firstEngine = _domainEngine(firstCoordinator);
    final first = firstEngine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport:
          seasonCount > 1 || hasFutureSeasonAfterReport,
    );
    var checkpoint = SponsorPresidentRuntimeCheckpoint(
      domain: first.checkpoint,
      sponsor: firstCoordinator.finalCheckpoint,
    );
    final boundaries = <SponsorRuntimeSeasonBoundary>[
      SponsorRuntimeSeasonBoundary(
        seasonIndex: config.seasonIndex,
        report: first.report,
        contracts: firstCoordinator.contracts,
        revenueByClub: firstCoordinator.revenueByClub,
        checkpoint: checkpoint,
      ),
    ];

    for (var offset = 1; offset < seasonCount; offset++) {
      final next = _resumeOneSeason(
        checkpoint: checkpoint,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      boundaries.add(next);
      checkpoint = next.checkpoint;
    }

    return SponsorRuntimeCareerResult(
      checkpoint: checkpoint,
      boundaries: boundaries,
    );
  }

  SponsorRuntimeCareerResult resume({
    required SponsorPresidentRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint;
    final boundaries = <SponsorRuntimeSeasonBoundary>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final next = _resumeOneSeason(
        checkpoint: current,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      boundaries.add(next);
      current = next.checkpoint;
    }
    return SponsorRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  SponsorRuntimeSeasonBoundary _resumeOneSeason({
    required SponsorPresidentRuntimeCheckpoint checkpoint,
    required bool hasFutureSeasonAfterReport,
  }) {
    checkpoint.validate();
    final domain = checkpoint.domain;
    final config = domain.presidentRuntime.runtime.runtime.world.config;
    final clubIds = domain.presidentRuntime.runtime.runtime.world.baseClubs
        .map((club) => club.id)
        .toList(growable: false);
    final profiles = <String, PresidentManagementProfile>{};
    final fans = <String, FanState>{};
    final media = <String, MediaState>{};
    for (final state in domain.presidentRuntime.clubs) {
      profiles[state.clubId] = state.managementProfile;
      fans[state.clubId] = state.fanReputation;
      media[state.clubId] = state.mediaReputation;
    }

    final coordinator = _SponsorSeasonEconomyEngine(
      delegate: baseEconomyEngine,
      sponsorSystem: sponsorSystem,
      openingSponsor: checkpoint.sponsor,
      expectedClubIds: clubIds,
      presidentProfilesByClub: profiles,
      fanStatesByClub: fans,
      mediaStatesByClub: media,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final engine = _domainEngine(coordinator);
    final result = engine.resume(
      checkpoint: domain,
      seasonCount: 1,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    final nextCheckpoint = SponsorPresidentRuntimeCheckpoint(
      domain: result.checkpoint,
      sponsor: coordinator.finalCheckpoint,
    );
    return SponsorRuntimeSeasonBoundary(
      seasonIndex: checkpoint.nextSeasonIndex,
      report: result.report,
      contracts: coordinator.contracts,
      revenueByClub: coordinator.revenueByClub,
      checkpoint: nextCheckpoint,
    );
  }

  PresidentDomainCareerEngine _domainEngine(
    _SponsorSeasonEconomyEngine economyEngine,
  ) {
    final advanced = AdvancedRuntimeCareerEngine(
      worldEngine: WorldCareerEngine(economyEngine: economyEngine),
    );
    return PresidentDomainCareerEngine(
      runtimeEngine: advanced,
      resumeEngine: PresidentDomainResumeEngine(runtimeEngine: advanced),
    );
  }
}

class _SponsorSeasonEconomyEngine extends BasicEconomyEngine {
  _SponsorSeasonEconomyEngine({
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
        super(wageModel: delegate.wageModel) {
    if (openingSponsor.nextSeasonIndex < 0) {
      throw ArgumentError('Sponsor season cursor cannot be negative.');
    }
    if (this.expectedClubIds.isEmpty) {
      throw ArgumentError('Sponsor runtime requires at least one club.');
    }
  }

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
        'M45 sponsor runtime cannot be combined with another sponsor revenue override.',
      );
    }
    if (seasonReport.seasonIndex != openingSponsor.nextSeasonIndex) {
      throw StateError(
        'Sponsor economy season ${seasonReport.seasonIndex} does not match '
        'checkpoint cursor ${openingSponsor.nextSeasonIndex}.',
      );
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
