import 'career_checkpoint.dart';
import 'career_report.dart';

class CareerSimulationResult {
  const CareerSimulationResult({
    required this.report,
    required this.checkpoint,
  });

  final CareerReport report;
  final CareerCheckpoint checkpoint;
}
