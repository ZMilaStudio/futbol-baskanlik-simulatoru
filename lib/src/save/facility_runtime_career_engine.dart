import '../facility/academy_facility.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../world/world_career_engine.dart';
import '../world/world_career_report.dart';
import 'facility_runtime_checkpoint.dart';

class FacilityRuntimeCareerSimulationResult {
  const FacilityRuntimeCareerSimulationResult({
    required this.report,
    required this.checkpoint,
  });

  final WorldCareerReport report;
  final FacilityRuntimeCheckpoint checkpoint;
}

class FacilityRuntimeCareerEngine {
  const FacilityRuntimeCareerEngine({this.worldEngine = const WorldCareerEngine()});

  final WorldCareerEngine worldEngine;

  FacilityRuntimeCheckpoint resume({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) =>
      resumeWithReport(
        checkpoint: checkpoint,
        seasonCount: seasonCount,
      ).checkpoint;

  FacilityRuntimeCareerSimulationResult resumeWithReport({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) {
    checkpoint.validate();
    final facilitiesByClub = Map<String, AcademyFacilityState>.unmodifiable({
      for (final facility in checkpoint.academyFacilities)
        facility.clubId: facility,
    });
    final integratedWorldEngine = WorldCareerEngine(
      seasonEngine: worldEngine.seasonEngine,
      poolGenerator: worldEngine.poolGenerator,
      lifecycleEngine: _FacilityAwareLifecycleEngine(
        delegate: worldEngine.lifecycleEngine,
        academyFacilities: facilitiesByClub,
      ),
      strengthCalculator: worldEngine.strengthCalculator,
      economyEngine: worldEngine.economyEngine,
      transferMarketEngine: worldEngine.transferMarketEngine,
    );
    final resumed = integratedWorldEngine.resume(
      checkpoint: checkpoint.world,
      seasonCount: seasonCount,
    );
    return FacilityRuntimeCareerSimulationResult(
      report: resumed.report,
      checkpoint: FacilityRuntimeCheckpoint(
        world: resumed.checkpoint,
        academyFacilities: checkpoint.academyFacilities,
        totalInvestmentSpent: checkpoint.totalInvestmentSpent,
      ),
    );
  }
}

class _FacilityAwareLifecycleEngine extends PlayerLifecycleEngine {
  _FacilityAwareLifecycleEngine({
    required this.delegate,
    required this.academyFacilities,
  });

  final PlayerLifecycleEngine delegate;
  final Map<String, AcademyFacilityState> academyFacilities;

  @override
  PlayerLifecycleResult advance({
    required List<Player> currentPlayers,
    required List<Club> currentClubs,
    required List<Club> referenceClubs,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
    Map<String, AcademyFacilityState> academyFacilities = const {},
  }) =>
      delegate.advance(
        currentPlayers: currentPlayers,
        currentClubs: currentClubs,
        referenceClubs: referenceClubs,
        careerSeed: careerSeed,
        nextSeasonIndex: nextSeasonIndex,
        simulationVersion: simulationVersion,
        academyFacilities: this.academyFacilities,
      );
}
