import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_runtime_checkpoint.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import 'crisis_decision_core.dart';

class CrisisRuntimeClubSnapshot {
  const CrisisRuntimeClubSnapshot({
    required this.context,
    required this.resolution,
  });

  final CrisisContext context;
  final CrisisResolution? resolution;

  String get clubId => context.clubId;
  int get seasonIndex => context.seasonIndex;
  String get presidentId => context.president.presidentId;
  bool get hadCrisis => resolution != null;

  String get signature =>
      '${context.signature}:${resolution?.signature ?? 'no-crisis'}';
}

class CrisisRuntimeBoundaryResult {
  CrisisRuntimeBoundaryResult({
    required this.seasonIndex,
    required this.checkpoint,
    required Iterable<CrisisRuntimeClubSnapshot> clubs,
  }) : clubs = List.unmodifiable(clubs);

  final int seasonIndex;
  final PresidentDomainMemoryCheckpoint checkpoint;
  final List<CrisisRuntimeClubSnapshot> clubs;

  int get crisisCount => clubs.where((item) => item.hadCrisis).length;

  String get signature {
    final finance = checkpoint
        .presidentRuntime.runtime.runtime.world.nextSeasonFinanceStates
        .map((item) => item.signature)
        .join('|');
    return 's$seasonIndex:crises=$crisisCount:'
        '${clubs.map((item) => item.signature).join('|')}:'
        'finance=$finance:checkpoint=${checkpoint.signature}';
  }
}

class CrisisRuntimeCareerResult {
  CrisisRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<CrisisRuntimeBoundaryResult> boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final PresidentDomainMemoryCheckpoint checkpoint;
  final List<CrisisRuntimeBoundaryResult> boundaries;

  int get crisisCount => boundaries.fold<int>(
        0,
        (sum, boundary) => sum + boundary.crisisCount,
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

class CrisisRuntimeIntegrationEngine {
  const CrisisRuntimeIntegrationEngine({
    this.decisionEngine = const CrisisDecisionEngine(activationThreshold: 55),
  });

  final CrisisDecisionEngine decisionEngine;

  CrisisRuntimeBoundaryResult apply(PresidentDomainMemoryCheckpoint checkpoint) {
    checkpoint.validate();
    if (checkpoint.completedSeasons <= 0) {
      throw ArgumentError(
        'Crisis runtime integration requires at least one completed season.',
      );
    }

    final presidentRuntime = checkpoint.presidentRuntime;
    final compact = presidentRuntime.runtime;
    final advanced = compact.runtime;
    final world = advanced.world;
    final seasonIndex = checkpoint.nextSeasonIndex - 1;
    final financeByClub = <String, ClubFinanceState>{
      for (final item in world.nextSeasonFinanceStates) item.clubId: item,
    };

    final snapshots = <CrisisRuntimeClubSnapshot>[];
    final nextFinanceByClub = <String, ClubFinanceState>{};
    final nextPresidentClubs = <PresidentClubRuntimeState>[];

    for (final state in presidentRuntime.clubs) {
      final finance = financeByClub[state.clubId];
      if (finance == null) {
        throw StateError('Missing finance state for ${state.clubId}.');
      }
      final context = CrisisContext(
        clubId: state.clubId,
        seasonIndex: seasonIndex,
        finance: finance,
        fan: state.fanReputation,
        media: state.mediaReputation,
        president: state.managementProfile,
      );
      final resolution = decisionEngine.evaluate(context);
      snapshots.add(
        CrisisRuntimeClubSnapshot(
          context: context,
          resolution: resolution,
        ),
      );

      nextFinanceByClub[state.clubId] = resolution?.finance ?? finance;
      nextPresidentClubs.add(
        PresidentClubRuntimeState(
          tenure: state.tenure,
          managementProfile: state.managementProfile,
          fanReputation: resolution?.fan ?? state.fanReputation,
          mediaReputation: resolution?.media ?? state.mediaReputation,
        ),
      );
    }

    final nextWorld = WorldCheckpoint(
      config: world.config,
      completedSeasons: world.completedSeasons,
      baseClubs: world.baseClubs,
      nextSeasonLeagues: world.nextSeasonLeagues,
      nextSeasonPlayers: world.nextSeasonPlayers,
      nextSeasonFinanceStates: world.nextSeasonFinanceStates
          .map((item) => nextFinanceByClub[item.clubId]!)
          .toList(),
    );
    final nextAdvanced = AdvancedRuntimeCheckpoint(
      world: nextWorld,
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
      clubs: nextPresidentClubs,
    );
    final nextCheckpoint = PresidentDomainMemoryCheckpoint(
      presidentRuntime: nextPresidentRuntime,
      summary: checkpoint.summary,
      rawHistorySeasons: checkpoint.rawHistorySeasons,
      recentFan: checkpoint.recentFan,
      recentMedia: checkpoint.recentMedia,
      currentTermPromises: checkpoint.currentTermPromises,
    );

    return CrisisRuntimeBoundaryResult(
      seasonIndex: seasonIndex,
      checkpoint: nextCheckpoint,
      clubs: snapshots,
    );
  }
}

class CrisisRuntimeCareerEngine {
  const CrisisRuntimeCareerEngine({
    this.domainEngine = const PresidentDomainCareerEngine(),
    this.integrationEngine = const CrisisRuntimeIntegrationEngine(),
  });

  final PresidentDomainCareerEngine domainEngine;
  final CrisisRuntimeIntegrationEngine integrationEngine;

  CrisisRuntimeCareerResult simulateWithCheckpoint({
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

    final boundaries = <CrisisRuntimeBoundaryResult>[];
    final first = domainEngine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport:
          seasonCount > 1 || hasFutureSeasonAfterReport,
    );
    var boundary = integrationEngine.apply(first.checkpoint);
    boundaries.add(boundary);

    for (var offset = 1; offset < seasonCount; offset++) {
      final resumed = domainEngine.resume(
        checkpoint: boundary.checkpoint,
        seasonCount: 1,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      boundary = integrationEngine.apply(resumed.checkpoint);
      boundaries.add(boundary);
    }

    return CrisisRuntimeCareerResult(
      checkpoint: boundary.checkpoint,
      boundaries: boundaries,
    );
  }

  CrisisRuntimeCareerResult resume({
    required PresidentDomainMemoryCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint;
    final boundaries = <CrisisRuntimeBoundaryResult>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final resumed = domainEngine.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      final boundary = integrationEngine.apply(resumed.checkpoint);
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }
    return CrisisRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }
}
