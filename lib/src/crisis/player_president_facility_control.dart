import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../facility/academy_facility.dart';
import '../facility/facility_investment_orchestrator.dart';
import '../facility/facility_portfolio_investment_orchestrator.dart';
import '../facility/president_academy_investment_orchestrator.dart';
import '../facility/president_facility_portfolio_investment_orchestrator.dart';
import '../facility/stadium_facility.dart';
import '../facility/training_ground_facility.dart';
import '../league/club.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/facility_runtime_checkpoint.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_runtime_checkpoint.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import 'facility_sponsor_crisis_runtime_composition.dart';
import 'president_facility_investment_runtime_integration.dart';

enum PlayerFacilityDecisionSource { ai, player }

class PlayerFacilityInvestmentChoice {
  const PlayerFacilityInvestmentChoice({
    this.academyUpgrades = 0,
    this.trainingGroundUpgrades = 0,
    this.stadiumUpgrades = 0,
  })  : assert(academyUpgrades >= 0 && academyUpgrades <= 2),
        assert(trainingGroundUpgrades >= 0 && trainingGroundUpgrades <= 2),
        assert(stadiumUpgrades >= 0 && stadiumUpgrades <= 2);

  static const hold = PlayerFacilityInvestmentChoice();

  final int academyUpgrades;
  final int trainingGroundUpgrades;
  final int stadiumUpgrades;

  void validate() {
    _validateUpgradeCount(academyUpgrades, 'academyUpgrades');
    _validateUpgradeCount(trainingGroundUpgrades, 'trainingGroundUpgrades');
    _validateUpgradeCount(stadiumUpgrades, 'stadiumUpgrades');
  }

  String get signature =>
      'academy=$academyUpgrades:training=$trainingGroundUpgrades:'
      'stadium=$stadiumUpgrades';

  static void _validateUpgradeCount(int value, String name) {
    if (value < 0 || value > 2) {
      throw ArgumentError.value(value, name, 'Must be between 0 and 2.');
    }
  }
}

class PlayerFacilityInvestmentContext {
  const PlayerFacilityInvestmentContext({
    required this.seasonIndex,
    required this.clubId,
    required this.presidentId,
    required this.managementProfile,
    required this.cash,
    required this.debt,
    required this.academyLevel,
    required this.trainingGroundLevel,
    required this.stadiumLevel,
    required this.aiAcademyTargetLevel,
    required this.aiTrainingGroundTargetLevel,
    required this.aiStadiumTargetLevel,
    required this.academyCashReserveBasisPoints,
    required this.portfolioCashReserveBasisPoints,
  });

  final int seasonIndex;
  final String clubId;
  final String presidentId;
  final PresidentManagementProfile managementProfile;
  final Money cash;
  final Money debt;
  final int academyLevel;
  final int trainingGroundLevel;
  final int stadiumLevel;
  final int aiAcademyTargetLevel;
  final int aiTrainingGroundTargetLevel;
  final int aiStadiumTargetLevel;
  final int academyCashReserveBasisPoints;
  final int portfolioCashReserveBasisPoints;

  String get signature =>
      '$seasonIndex:$clubId:$presidentId:cash=${cash.minorUnits}:'
      'debt=${debt.minorUnits}:levels=$academyLevel/'
      '$trainingGroundLevel/$stadiumLevel:ai=$aiAcademyTargetLevel/'
      '$aiTrainingGroundTargetLevel/$aiStadiumTargetLevel:reserve='
      '$academyCashReserveBasisPoints/$portfolioCashReserveBasisPoints';
}

abstract class PlayerFacilityInvestmentDecisionProvider {
  const PlayerFacilityInvestmentDecisionProvider();

  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context);
}

class PlayerPresidentFacilityRuntimeDecision {
  const PlayerPresidentFacilityRuntimeDecision({
    required this.source,
    required this.decision,
    this.requestedChoice,
  });

  final PlayerFacilityDecisionSource source;
  final PresidentFacilityInvestmentRuntimeDecision decision;
  final PlayerFacilityInvestmentChoice? requestedChoice;

  bool get playerControlled => source == PlayerFacilityDecisionSource.player;
  bool get invested => decision.invested;
  Money get spend => decision.spend;
  String get clubId => decision.clubId;

  String get signature =>
      '${source.name}:${requestedChoice?.signature ?? 'ai'}:'
      '${decision.signature}';
}

class PlayerPresidentFacilityControlResult {
  PlayerPresidentFacilityControlResult({
    required this.checkpoint,
    required Iterable<PlayerPresidentFacilityRuntimeDecision> decisions,
  }) : decisions = List.unmodifiable(decisions);

  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;
  final List<PlayerPresidentFacilityRuntimeDecision> decisions;

  Money get totalSpend => decisions.fold(
        Money.zero,
        (sum, item) => sum + item.spend,
      );

  PlayerPresidentFacilityRuntimeDecision playerDecisionFor(String clubId) =>
      decisions.firstWhere(
        (item) => item.clubId == clubId && item.playerControlled,
      );

  String get signature =>
      '${decisions.map((item) => item.signature).join('|')}:'
      'final=${checkpoint.signature}';
}

class PlayerPresidentFacilityControlCheckpoint {
  PlayerPresidentFacilityControlCheckpoint({
    required this.runtime,
    required this.controlledClubId,
  }) {
    validate();
  }

  final FacilitySponsorCrisisRuntimeCheckpoint runtime;
  final String controlledClubId;

  int get nextSeasonIndex => runtime.nextSeasonIndex;
  int get completedSeasons => runtime.completedSeasons;

  void validate() {
    runtime.validate();
    if (controlledClubId.isEmpty) {
      throw ArgumentError('controlledClubId cannot be empty.');
    }
    final ids = runtime.runtime.domain.presidentRuntime.runtime.runtime.world
        .baseClubs
        .map((club) => club.id)
        .toSet();
    if (!ids.contains(controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }
  }

  String get signature =>
      'controlled=$controlledClubId:runtime=${runtime.signature}';
}

class PlayerPresidentFacilityControlSaveCodec {
  const PlayerPresidentFacilityControlSaveCodec({
    this.runtimeCodec = const FacilitySponsorCrisisRuntimeSaveCodec(),
  });

  static const String format = 'zmila-fbs-player-president-facility-control';
  static const int currentSaveVersion = 1;

  final FacilitySponsorCrisisRuntimeSaveCodec runtimeCodec;

  String encode(PlayerPresidentFacilityControlCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'controlledClubId': checkpoint.controlledClubId,
      'runtimeSave': runtimeCodec.encode(checkpoint.runtime),
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

  PlayerPresidentFacilityControlCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Player-president facility save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Player-president facility save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown player-president facility save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported player-president facility save version $version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Player-president facility save checksum mismatch.',
      );
    }
    if (version != 1 || payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president facility save payload is invalid.',
      );
    }
    final map = Map<String, Object?>.from(payload);
    final controlledClubId = map['controlledClubId'];
    final runtimeSave = map['runtimeSave'];
    if (controlledClubId is! String || runtimeSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president facility payload fields are invalid.',
      );
    }
    try {
      return PlayerPresidentFacilityControlCheckpoint(
        runtime: runtimeCodec.decode(runtimeSave),
        controlledClubId: controlledClubId,
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid player-president facility payload: $error',
      );
    }
  }
}

class PlayerPresidentFacilityControlRuntimeEngine {
  const PlayerPresidentFacilityControlRuntimeEngine({
    this.provider,
    this.aiAcademy = const PresidentAcademyInvestmentOrchestrator(),
    this.aiPortfolio = const PresidentFacilityPortfolioInvestmentOrchestrator(),
    this.academyInvestment = const FacilityInvestmentOrchestrator(),
    this.portfolioInvestment = const FacilityPortfolioInvestmentOrchestrator(),
  });

  final PlayerFacilityInvestmentDecisionProvider? provider;
  final PresidentAcademyInvestmentOrchestrator aiAcademy;
  final PresidentFacilityPortfolioInvestmentOrchestrator aiPortfolio;
  final FacilityInvestmentOrchestrator academyInvestment;
  final FacilityPortfolioInvestmentOrchestrator portfolioInvestment;

  PlayerPresidentFacilityControlResult apply({
    required FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
    required String controlledClubId,
  }) {
    checkpoint.validate();
    final domain = checkpoint.runtime.domain;
    final presidentRuntime = domain.presidentRuntime;
    final world = presidentRuntime.runtime.runtime.world;
    final states = [...presidentRuntime.clubs]
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    if (!states.any((state) => state.clubId == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }

    var facilityCheckpoint = FacilityRuntimeCheckpoint(
      world: world,
      academyFacilities: checkpoint.facilities.academyFacilities,
      stadiumFacilities: checkpoint.facilities.stadiumFacilities,
      trainingGroundFacilities: checkpoint.facilities.trainingGroundFacilities,
      totalInvestmentSpent: checkpoint.facilities.totalInvestmentSpent,
    );
    final decisions = <PlayerPresidentFacilityRuntimeDecision>[];

    for (final state in states) {
      if (state.clubId != controlledClubId || provider == null) {
        final applied = _applyAi(
          checkpoint: facilityCheckpoint,
          state: state,
          seasonIndex: checkpoint.nextSeasonIndex,
        );
        facilityCheckpoint = applied.$1;
        decisions.add(applied.$2);
        continue;
      }

      final applied = _applyPlayer(
        checkpoint: facilityCheckpoint,
        state: state,
        seasonIndex: checkpoint.nextSeasonIndex,
      );
      facilityCheckpoint = applied.$1;
      decisions.add(applied.$2);
    }

    final nextDomain = _replaceWorld(domain, facilityCheckpoint.world);
    final nextRuntime = SponsorPresidentRuntimeCheckpoint(
      domain: nextDomain,
      sponsor: checkpoint.runtime.sponsor,
    );
    final nextFacilities = FacilityPortfolioRuntimeState(
      academyFacilities: facilityCheckpoint.academyFacilities,
      stadiumFacilities: facilityCheckpoint.stadiumFacilities,
      trainingGroundFacilities: facilityCheckpoint.trainingGroundFacilities,
      totalInvestmentSpent: facilityCheckpoint.totalInvestmentSpent,
    );
    return PlayerPresidentFacilityControlResult(
      checkpoint: FacilitySponsorCrisisRuntimeCheckpoint(
        runtime: nextRuntime,
        facilities: nextFacilities,
      ),
      decisions: decisions,
    );
  }

  (FacilityRuntimeCheckpoint, PlayerPresidentFacilityRuntimeDecision) _applyAi({
    required FacilityRuntimeCheckpoint checkpoint,
    required PresidentRuntimeClubState state,
    required int seasonIndex,
  }) {
    final profile = state.managementProfile;
    final academy = aiAcademy.apply(
      checkpoint: checkpoint,
      clubId: state.clubId,
      profile: profile,
    );
    final portfolio = aiPortfolio.apply(
      checkpoint: academy.checkpoint,
      clubId: state.clubId,
      profile: profile,
    );
    return (
      portfolio.checkpoint,
      PlayerPresidentFacilityRuntimeDecision(
        source: PlayerFacilityDecisionSource.ai,
        decision: PresidentFacilityInvestmentRuntimeDecision(
          seasonIndex: seasonIndex,
          clubId: state.clubId,
          presidentId: profile.presidentId,
          academyTargetLevel: academy.plan.targetLevel,
          academyBeforeLevel: academy.beforeLevel,
          academyAfterLevel: academy.afterLevel,
          academyAppliedUpgrades: academy.appliedUpgrades,
          academyCashReserveBasisPoints: academy.plan.cashReserveBasisPoints,
          trainingGroundTargetLevel: portfolio.plan.trainingGroundTargetLevel,
          trainingGroundBeforeLevel: portfolio.beforeTrainingGroundLevel,
          trainingGroundAfterLevel: portfolio.afterTrainingGroundLevel,
          trainingGroundAppliedUpgrades: portfolio.appliedTrainingGroundUpgrades,
          stadiumTargetLevel: portfolio.plan.stadiumTargetLevel,
          stadiumBeforeLevel: portfolio.beforeStadiumLevel,
          stadiumAfterLevel: portfolio.afterStadiumLevel,
          stadiumAppliedUpgrades: portfolio.appliedStadiumUpgrades,
          portfolioCashReserveBasisPoints: portfolio.plan.cashReserveBasisPoints,
          spend: academy.spend + portfolio.spend,
        ),
      ),
    );
  }

  (FacilityRuntimeCheckpoint, PlayerPresidentFacilityRuntimeDecision) _applyPlayer({
    required FacilityRuntimeCheckpoint checkpoint,
    required PresidentRuntimeClubState state,
    required int seasonIndex,
  }) {
    final profile = state.managementProfile;
    final academyPlan = aiAcademy.planFor(profile);
    final portfolioPlan = aiPortfolio.planFor(profile);
    final finance = checkpoint.world.nextSeasonFinanceStates
        .firstWhere((item) => item.clubId == state.clubId);
    final beforeAcademy = checkpoint.facilityFor(state.clubId).level;
    final beforeTraining = checkpoint.trainingGroundFor(state.clubId).level;
    final beforeStadium = checkpoint.stadiumFor(state.clubId).level;
    final context = PlayerFacilityInvestmentContext(
      seasonIndex: seasonIndex,
      clubId: state.clubId,
      presidentId: profile.presidentId,
      managementProfile: profile,
      cash: finance.cash,
      debt: finance.debt,
      academyLevel: beforeAcademy,
      trainingGroundLevel: beforeTraining,
      stadiumLevel: beforeStadium,
      aiAcademyTargetLevel: academyPlan.targetLevel,
      aiTrainingGroundTargetLevel: portfolioPlan.trainingGroundTargetLevel,
      aiStadiumTargetLevel: portfolioPlan.stadiumTargetLevel,
      academyCashReserveBasisPoints: academyPlan.cashReserveBasisPoints,
      portfolioCashReserveBasisPoints: portfolioPlan.cashReserveBasisPoints,
    );
    final choice = provider!.choose(context)..validate();
    var current = checkpoint;
    var academyApplied = 0;
    var trainingApplied = 0;
    var stadiumApplied = 0;

    for (var i = 0; i < choice.academyUpgrades; i++) {
      final stateBefore = current.facilityFor(state.clubId);
      final decision = academyInvestment.policy.upgrade(stateBefore);
      if (!decision.upgraded ||
          !_preservesReserve(
            current,
            state.clubId,
            decision.cost,
            academyPlan.cashReserveBasisPoints,
          )) {
        break;
      }
      final result = academyInvestment.upgradeAcademy(
        checkpoint: current,
        clubId: state.clubId,
      );
      if (!result.applied) break;
      current = result.checkpoint;
      academyApplied++;
    }

    final rounds = choice.trainingGroundUpgrades >= choice.stadiumUpgrades
        ? choice.trainingGroundUpgrades
        : choice.stadiumUpgrades;
    for (var round = 0; round < rounds; round++) {
      if (trainingApplied < choice.trainingGroundUpgrades) {
        final before = current.trainingGroundFor(state.clubId);
        final decision = portfolioInvestment.trainingGroundPolicy.upgrade(before);
        if (decision.upgraded &&
            _preservesReserve(
              current,
              state.clubId,
              decision.cost,
              portfolioPlan.cashReserveBasisPoints,
            )) {
          final result = portfolioInvestment.upgradeTrainingGround(
            checkpoint: current,
            clubId: state.clubId,
          );
          if (result.applied) {
            current = result.checkpoint;
            trainingApplied++;
          }
        }
      }

      if (stadiumApplied < choice.stadiumUpgrades) {
        final before = current.stadiumFor(state.clubId);
        final decision = portfolioInvestment.stadiumPolicy.upgrade(before);
        if (decision.upgraded &&
            _preservesReserve(
              current,
              state.clubId,
              decision.cost,
              portfolioPlan.cashReserveBasisPoints,
            )) {
          final result = portfolioInvestment.upgradeStadium(
            checkpoint: current,
            clubId: state.clubId,
          );
          if (result.applied) {
            current = result.checkpoint;
            stadiumApplied++;
          }
        }
      }
    }

    final academyTarget =
        (beforeAcademy + choice.academyUpgrades).clamp(0, AcademyInvestmentPolicy.maxLevel).toInt();
    final trainingTarget =
        (beforeTraining + choice.trainingGroundUpgrades).clamp(0, TrainingGroundInvestmentPolicy.maxLevel).toInt();
    final stadiumTarget =
        (beforeStadium + choice.stadiumUpgrades).clamp(0, StadiumInvestmentPolicy.maxLevel).toInt();
    final spend = current.totalInvestmentSpent - checkpoint.totalInvestmentSpent;
    return (
      current,
      PlayerPresidentFacilityRuntimeDecision(
        source: PlayerFacilityDecisionSource.player,
        requestedChoice: choice,
        decision: PresidentFacilityInvestmentRuntimeDecision(
          seasonIndex: seasonIndex,
          clubId: state.clubId,
          presidentId: profile.presidentId,
          academyTargetLevel: academyTarget,
          academyBeforeLevel: beforeAcademy,
          academyAfterLevel: current.facilityFor(state.clubId).level,
          academyAppliedUpgrades: academyApplied,
          academyCashReserveBasisPoints: academyPlan.cashReserveBasisPoints,
          trainingGroundTargetLevel: trainingTarget,
          trainingGroundBeforeLevel: beforeTraining,
          trainingGroundAfterLevel: current.trainingGroundFor(state.clubId).level,
          trainingGroundAppliedUpgrades: trainingApplied,
          stadiumTargetLevel: stadiumTarget,
          stadiumBeforeLevel: beforeStadium,
          stadiumAfterLevel: current.stadiumFor(state.clubId).level,
          stadiumAppliedUpgrades: stadiumApplied,
          portfolioCashReserveBasisPoints: portfolioPlan.cashReserveBasisPoints,
          spend: spend,
        ),
      ),
    );
  }

  bool _preservesReserve(
    FacilityRuntimeCheckpoint checkpoint,
    String clubId,
    Money cost,
    int reserveBasisPoints,
  ) {
    final finance = checkpoint.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == clubId);
    final reserve = finance.cash.scaleBasisPoints(reserveBasisPoints);
    return finance.cash - cost >= reserve;
  }

  PresidentDomainMemoryCheckpoint _replaceWorld(
    PresidentDomainMemoryCheckpoint checkpoint,
    WorldCheckpoint world,
  ) {
    final presidentRuntime = checkpoint.presidentRuntime;
    final compact = presidentRuntime.runtime;
    final advanced = compact.runtime;
    final nextAdvanced = AdvancedRuntimeCheckpoint(
      world: world,
      transfer: advanced.transfer,
      manager: advanced.manager,
    );
    final nextCompact = CompactAdvancedRuntimeCheckpoint(
      runtime: nextAdvanced,
      history: compact.history,
      recentHistoryStartSeasonIndex: compact.recentHistoryStartSeasonIndex,
    );
    final nextPresidentRuntime = PresidentRuntimeCheckpoint(
      runtime: nextCompact,
      electionInterval: presidentRuntime.electionInterval,
      completedElectionTerms: presidentRuntime.completedElectionTerms,
      seasonsIntoCurrentTerm: presidentRuntime.seasonsIntoCurrentTerm,
      clubs: presidentRuntime.clubs,
    );
    return PresidentDomainMemoryCheckpoint(
      presidentRuntime: nextPresidentRuntime,
      summary: checkpoint.summary,
      rawHistorySeasons: checkpoint.rawHistorySeasons,
      recentFan: checkpoint.recentFan,
      recentMedia: checkpoint.recentMedia,
      currentTermPromises: checkpoint.currentTermPromises,
    );
  }
}

class PlayerPresidentFacilityControlSeasonBoundary {
  const PlayerPresidentFacilityControlSeasonBoundary({
    required this.source,
    required this.checkpoint,
    this.control,
  });

  final FacilitySponsorCrisisRuntimeSeasonBoundary source;
  final PlayerPresidentFacilityControlCheckpoint checkpoint;
  final PlayerPresidentFacilityControlResult? control;

  int get seasonIndex => source.seasonIndex;
  bool get preparedNextSeason => control != null;
  Money get facilityInvestmentSpend => control?.totalSpend ?? Money.zero;
  List<PlayerPresidentFacilityRuntimeDecision> get decisions =>
      control?.decisions ?? const [];

  String get signature =>
      'season=$seasonIndex:source=${source.signature}:'
      'control=${control?.signature ?? 'none'}:final=${checkpoint.signature}';
}

class PlayerPresidentFacilityControlCareerResult {
  PlayerPresidentFacilityControlCareerResult({
    required this.checkpoint,
    required Iterable<PlayerPresidentFacilityControlSeasonBoundary> boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final PlayerPresidentFacilityControlCheckpoint checkpoint;
  final List<PlayerPresidentFacilityControlSeasonBoundary> boundaries;

  Money get totalFacilityInvestmentSpend => boundaries.fold(
        Money.zero,
        (sum, item) => sum + item.facilityInvestmentSpend,
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M49 introduces the first explicit player-president decision override.
///
/// Only [controlledClubId] can be overridden. Every other club reuses the
/// exact M48/M39 AI facility policy. Player choices select up to two upgrade
/// attempts per facility; existing reserve guards, no-hidden-debt semantics,
/// academy-first order, and training->stadium round-robin ordering remain in
/// force.
class PlayerPresidentFacilityControlCareerEngine {
  const PlayerPresidentFacilityControlCareerEngine({
    this.runtime = const FacilitySponsorCrisisRuntimeCareerEngine(),
    this.control = const PlayerPresidentFacilityControlRuntimeEngine(),
  });

  final FacilitySponsorCrisisRuntimeCareerEngine runtime;
  final PlayerPresidentFacilityControlRuntimeEngine control;

  PlayerPresidentFacilityControlCareerResult simulateWithCheckpoint({
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
    final boundaries = <PlayerPresidentFacilityControlSeasonBoundary>[];
    final firstHasFuture = seasonCount > 1 || hasFutureSeasonAfterReport;
    final first = runtime.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: firstHasFuture,
    );
    var boundary = _finishBoundary(
      source: first.boundaries.single,
      controlledClubId: controlledClubId,
      prepareNextSeason: firstHasFuture,
    );
    boundaries.add(boundary);
    var current = boundary.checkpoint;

    for (var offset = 1; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final resumed = runtime.resume(
        checkpoint: current.runtime,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      boundary = _finishBoundary(
        source: resumed.boundaries.single,
        controlledClubId: controlledClubId,
        prepareNextSeason: hasFuture,
      );
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }
    return PlayerPresidentFacilityControlCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  PlayerPresidentFacilityControlCareerResult resume({
    required PlayerPresidentFacilityControlCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    final boundaries = <PlayerPresidentFacilityControlSeasonBoundary>[];
    var current = checkpoint;
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final resumed = runtime.resume(
        checkpoint: current.runtime,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      final boundary = _finishBoundary(
        source: resumed.boundaries.single,
        controlledClubId: current.controlledClubId,
        prepareNextSeason: hasFuture,
      );
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }
    return PlayerPresidentFacilityControlCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  PlayerPresidentFacilityControlSeasonBoundary _finishBoundary({
    required FacilitySponsorCrisisRuntimeSeasonBoundary source,
    required String controlledClubId,
    required bool prepareNextSeason,
  }) {
    if (!prepareNextSeason) {
      return PlayerPresidentFacilityControlSeasonBoundary(
        source: source,
        checkpoint: PlayerPresidentFacilityControlCheckpoint(
          runtime: source.checkpoint,
          controlledClubId: controlledClubId,
        ),
      );
    }
    final result = control.apply(
      checkpoint: source.checkpoint,
      controlledClubId: controlledClubId,
    );
    return PlayerPresidentFacilityControlSeasonBoundary(
      source: source,
      checkpoint: PlayerPresidentFacilityControlCheckpoint(
        runtime: result.checkpoint,
        controlledClubId: controlledClubId,
      ),
      control: result,
    );
  }
}
