import '../core/simulation_config.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_fit_model.dart';
import '../manager/manager_impact_model.dart';
import '../manager/manager_pool_generator.dart';
import '../transfer/advanced_transfer_controller.dart';
import '../transfer/loan_market_engine.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'advanced_runtime_checkpoint.dart';

class AdvancedRuntimeCareerEngine {
  const AdvancedRuntimeCareerEngine({
    this.worldEngine = const WorldCareerEngine(),
    this.managerPoolGenerator = const ManagerPoolGenerator(),
    this.managerFitModel = const ManagerFitModel(),
    this.managerImpactModel = const ManagerImpactModel(),
    this.loanMarketEngine = const LoanMarketEngine(),
  });

  final WorldCareerEngine worldEngine;
  final ManagerPoolGenerator managerPoolGenerator;
  final ManagerFitModel managerFitModel;
  final ManagerImpactModel managerImpactModel;
  final LoanMarketEngine loanMarketEngine;

  AdvancedRuntimeSimulationResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    final transferController = AdvancedTransferController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      loanMarketEngine: loanMarketEngine,
    );
    final managerController = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      poolGenerator: managerPoolGenerator,
      fitModel: managerFitModel,
      impactModel: managerImpactModel,
    );

    final world = worldEngine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: managerController,
      rosterHooks: transferController,
      financeHooks: transferController,
      transferHooks: transferController,
      enableTransferInstallments: true,
    );

    final checkpoint = _checkpoint(
      world: world.checkpoint,
      transferController: transferController,
      managerController: managerController,
    );
    return AdvancedRuntimeSimulationResult(
      report: world.report,
      checkpoint: checkpoint,
    );
  }

  AdvancedRuntimeSimulationResult resume({
    required AdvancedRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) {
    checkpoint.validate();
    final config = checkpoint.world.config;
    final transferController = AdvancedTransferController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      activeContracts: checkpoint.transfer.activeContracts,
      contractEvents: checkpoint.transfer.contractEvents,
      activeLoans: checkpoint.transfer.activeLoans,
      loanHistory: checkpoint.transfer.loanHistory,
      installmentObligations: checkpoint.transfer.installmentObligations,
      loanMarketEngine: loanMarketEngine,
    );
    final managerController = ManagerCareerController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      managers: checkpoint.manager.managers,
      assignments: checkpoint.manager.assignments,
      seasons: checkpoint.manager.seasons,
      poolGenerator: managerPoolGenerator,
      fitModel: managerFitModel,
      impactModel: managerImpactModel,
    );

    final world = worldEngine.resume(
      checkpoint: checkpoint.world,
      seasonCount: seasonCount,
      hooks: managerController,
      rosterHooks: transferController,
      financeHooks: transferController,
      transferHooks: transferController,
      enableTransferInstallments: true,
    );

    final nextCheckpoint = _checkpoint(
      world: world.checkpoint,
      transferController: transferController,
      managerController: managerController,
    );
    return AdvancedRuntimeSimulationResult(
      report: world.report,
      checkpoint: nextCheckpoint,
    );
  }

  AdvancedRuntimeCheckpoint _checkpoint({
    required dynamic world,
    required AdvancedTransferController transferController,
    required ManagerCareerController managerController,
  }) =>
      AdvancedRuntimeCheckpoint(
        world: world,
        transfer: AdvancedTransferRuntimeState(
          activeContracts: transferController.activeContracts,
          contractEvents: transferController.contractEvents,
          activeLoans: transferController.activeLoans,
          loanHistory: transferController.loanHistory,
          installmentObligations: transferController.installmentObligations,
        ),
        manager: ManagerRuntimeState(
          managers: managerController.managers,
          assignments: managerController.finalAssignments,
          seasons: managerController.seasons,
        ),
      );
}
