import '../core/simulation_config.dart';
import '../finance/wage_model.dart';
import '../league/club.dart';
import '../world/world_career_engine.dart';
import '../world/world_career_hooks.dart';
import '../world/world_league.dart';
import 'contract_career_report.dart';
import 'player_contract_controller.dart';

class ContractWorldCareerEngine {
  const ContractWorldCareerEngine({
    this.worldEngine = const WorldCareerEngine(),
    this.wageModel = const WageModel(),
  });

  final WorldCareerEngine worldEngine;
  final WageModel wageModel;

  ContractCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
  }) {
    final controller = PlayerContractController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      wageModel: wageModel,
    );
    final worldReport = worldEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: hooks,
      rosterHooks: controller,
    );
    return ContractCareerReport(
      worldReport: worldReport,
      activeContracts: controller.activeContracts,
      events: controller.events,
    );
  }
}
