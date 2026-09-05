import '../core/simulation_config.dart';
import '../league/club.dart';
import '../world/world_league.dart';
import 'advanced_history_compaction.dart';
import 'advanced_runtime_career_engine.dart';

class CompactAdvancedRuntimeCareerEngine {
  const CompactAdvancedRuntimeCareerEngine({
    this.runtimeEngine = const AdvancedRuntimeCareerEngine(),
    this.compactor = const AdvancedRuntimeHistoryCompactor(),
  });

  final AdvancedRuntimeCareerEngine runtimeEngine;
  final AdvancedRuntimeHistoryCompactor compactor;

  CompactAdvancedRuntimeSimulationResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    final full = runtimeEngine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
    );
    return CompactAdvancedRuntimeSimulationResult(
      report: full.report,
      checkpoint: compactor.compactFull(full.checkpoint),
    );
  }

  CompactAdvancedRuntimeSimulationResult resume({
    required CompactAdvancedRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) {
    checkpoint.validate();
    final resumeStartSeasonIndex = checkpoint.nextSeasonIndex;
    final full = runtimeEngine.resume(
      checkpoint: checkpoint.runtime,
      seasonCount: seasonCount,
    );
    return CompactAdvancedRuntimeSimulationResult(
      report: full.report,
      checkpoint: compactor.compactAfterResume(
        source: full.checkpoint,
        previousHistory: checkpoint.history,
        resumeStartSeasonIndex: resumeStartSeasonIndex,
      ),
    );
  }
}
