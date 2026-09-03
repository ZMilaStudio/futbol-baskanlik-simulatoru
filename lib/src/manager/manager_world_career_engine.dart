import '../core/simulation_config.dart';
import '../league/club.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'manager_career_controller.dart';
import 'manager_career_report.dart';
import 'manager_fit_model.dart';
import 'manager_impact_model.dart';
import 'manager_pool_generator.dart';

class ManagerWorldCareerEngine {
  const ManagerWorldCareerEngine({
    this.worldEngine = const WorldCareerEngine(),
    this.poolGenerator = const ManagerPoolGenerator(),
    this.fitModel = const ManagerFitModel(),
    this.impactModel = const ManagerImpactModel(),
  });

  final WorldCareerEngine worldEngine;
  final ManagerPoolGenerator poolGenerator;
  final ManagerFitModel fitModel;
  final ManagerImpactModel impactModel;

  ManagerCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    final controller = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      poolGenerator: poolGenerator,
      fitModel: fitModel,
      impactModel: impactModel,
    );
    final worldReport = worldEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: controller,
    );
    return ManagerCareerReport(
      worldReport: worldReport,
      managers: controller.managers,
      seasons: controller.seasons,
      finalAssignments: controller.finalAssignments,
    );
  }
}
