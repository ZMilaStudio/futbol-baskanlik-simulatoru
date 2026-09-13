import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../crisis/facility_sponsor_crisis_runtime_composition.dart';
import '../crisis/president_facility_investment_runtime_integration.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_management_profile.dart';
import '../election/president_tenure.dart';
import '../fan/fan_state.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../promise/promise_media_career_engine.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../season/season_report.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'player_president_tenure_gated_ticket_pricing_control.dart';
import 'stadium_facility.dart';

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
    final clubIds = runtime.runtime.domain.presidentRuntime.runtime.runtime.world
        .baseClubs
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
        checksum != SaveChecksum.forPayload(
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

  String get signature =>
      'season=$seasonIndex:pricing='
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
class PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine({
    this.playerProvider,
    this.aiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
    this.sourceEngine = const PromiseMediaCareerEngine(),
  });

  final PlayerMatchdayTicketPricingDecisionProvider? playerProvider;
  final PresidentMatchdayTicketPricingPolicy aiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;
  final PlayerPresidentTenureControlGate tenureGate;
  final WorldCareerEngine baseWorldEngine;
  final PresidentFacilityInvestmentRuntimeEngine investment;
  final PromiseMediaCareerEngine sourceEngine;

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
      final pricingEconomy = _TicketPricingEconomyEngine(
        delegate: baseWorldEngine.economyEngine,
        expectedClubIds: context.clubs.map((club) => club.id),
        stadiumLevelsByClub: context.stadiumLevelsByClub,
        fanStatesByClub: context.fanStatesByClub,
        presidentProfilesByClub: context.presidentProfilesByClub,
        tenureControl: tenure,
        playerProvider: playerProvider,
        aiPolicy: aiPolicy,
        pricingPolicy: pricingPolicy,
        stadiumPolicy: stadiumPolicy,
      );
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
      final pricingEconomy = _TicketPricingEconomyEngine(
        delegate: baseWorldEngine.economyEngine,
        expectedClubIds: context.clubs.map((club) => club.id),
        stadiumLevelsByClub: context.stadiumLevelsByClub,
        fanStatesByClub: context.fanStatesByClub,
        presidentProfilesByClub: context.presidentProfilesByClub,
        tenureControl: tenure,
        playerProvider: playerProvider,
        aiPolicy: aiPolicy,
        pricingPolicy: pricingPolicy,
        stadiumPolicy: stadiumPolicy,
      );
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
    const presidentGenerator = PresidentProfileGenerator();
    const managementGenerator = PresidentManagementProfileGenerator();
    final profiles = <String, PresidentManagementProfile>{};
    final fans = <String, FanState>{};
    final stadiums = <String, int>{};
    String? playerPresidentId;
    for (final club in clubs) {
      final president = presidentGenerator.generateInitial(
        clubId: club.id,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      profiles[club.id] = managementGenerator.generate(
        president: president,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      fans[club.id] = FanState.initial(club.id);
      stadiums[club.id] = 0;
      if (club.id == controlledClubId) {
        playerPresidentId = president.id;
      }
    }
    return _PricingRuntimeContext(
      clubs: clubs,
      stadiumLevelsByClub: stadiums,
      fanStatesByClub: fans,
      presidentProfilesByClub: profiles,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: controlledClubId,
        playerPresidentId: playerPresidentId!,
        status: PlayerPresidentTenureControlStatus.active,
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
        baseWorldEngine: pricedWorld,
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
  });

  final List<Club> clubs;
  final Map<String, int> stadiumLevelsByClub;
  final Map<String, FanState> fanStatesByClub;
  final Map<String, PresidentManagementProfile> presidentProfilesByClub;
  final PlayerPresidentTenureControlState tenureControl;
}

class _TicketPricingEconomyEngine extends BasicEconomyEngine {
  _TicketPricingEconomyEngine({
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
  final Set<String> expectedClubIds;
  final Map<String, int> stadiumLevelsByClub;
  final Map<String, FanState> fanStatesByClub;
  final Map<String, PresidentManagementProfile> presidentProfilesByClub;
  final PlayerPresidentTenureControlState tenureControl;
  final PlayerMatchdayTicketPricingDecisionProvider? playerProvider;
  final PresidentMatchdayTicketPricingPolicy aiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;

  final Map<String, PlayerPresidentTicketPricingDecision> _decisions = {};

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
        throw StateError('Ticket-pricing economy received unknown club ${club.id}.');
      }
      if (_decisions.containsKey(club.id)) {
        throw StateError('Ticket-pricing economy processed ${club.id} twice.');
      }
      final level = stadiumLevelsByClub[club.id] ??
          (throw StateError('Missing stadium level for ${club.id}.'));
      final fan = fanStatesByClub[club.id] ??
          (throw StateError('Missing fan state for ${club.id}.'));
      final president = presidentProfilesByClub[club.id] ??
          (throw StateError('Missing president profile for ${club.id}.'));
      final position = positions[club.id] ??
          (throw StateError('Missing league position for ${club.id}.'));
      final base = stadiumPolicy.attendanceProfile(
        level: level,
        clubStrength: club.strength,
        leaguePosition: position,
        fanTrust: fan.overallTrust,
      );
      final incomingMultiplier =
          matchdayRevenueMultiplierBpsByClub[club.id] ?? 10000;
      if (incomingMultiplier != base.revenueMultiplierBps) {
        throw StateError(
          'M65 pricing seam mismatch for ${club.id}: '
          '$incomingMultiplier != ${base.revenueMultiplierBps}.',
        );
      }
      final aiChoice = aiPolicy.choose(
        profile: president,
        fanTrust: fan.overallTrust,
        base: base,
      );
      final context = PlayerPresidentTicketPricingDecisionContext(
        seasonIndex: seasonReport.seasonIndex,
        club: club,
        president: president,
        stadiumLevel: level,
        leaguePosition: position,
        fanTrust: fan.overallTrust,
        baseAttendance: base,
        aiChoice: aiChoice,
      );
      final canDelegate = club.id == tenureControl.controlledClubId &&
          playerProvider != null &&
          tenureControl.active &&
          president.presidentId == tenureControl.playerPresidentId;
      final choice = canDelegate ? playerProvider!.choose(context) : aiChoice;
      final outcome = pricingPolicy.apply(base: base, tier: choice.tier);
      final decision = PlayerPresidentTicketPricingDecision(
        context: context,
        choice: choice,
        providerCalled: canDelegate,
        outcome: outcome,
      );
      _decisions[club.id] = decision;
      pricedMultipliers[club.id] = outcome.revenueMultiplierBps;
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
      matchdayRevenueMultiplierBpsByClub: pricedMultipliers,
      sponsorRevenueByClub: sponsorRevenueByClub,
    );
  }
}
