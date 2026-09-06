import '../world/world_career_engine.dart';
import 'facility_runtime_checkpoint.dart';

class FacilityRuntimeCareerEngine {
  const FacilityRuntimeCareerEngine({this.worldEngine = const WorldCareerEngine()});

  final WorldCareerEngine worldEngine;

  FacilityRuntimeCheckpoint resume({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) {
    checkpoint.validate();
    final resumed = worldEngine.resume(
      checkpoint: checkpoint.world,
      seasonCount: seasonCount,
    );
    return FacilityRuntimeCheckpoint(
      world: resumed.checkpoint,
      academyFacilities: checkpoint.academyFacilities,
      totalInvestmentSpent: checkpoint.totalInvestmentSpent,
    );
  }
}
