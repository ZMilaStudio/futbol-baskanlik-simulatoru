import 'world_career_report.dart';
import 'world_checkpoint.dart';

class WorldCareerSimulationResult {
  const WorldCareerSimulationResult({
    required this.report,
    required this.checkpoint,
  });

  final WorldCareerReport report;
  final WorldCheckpoint checkpoint;
}
