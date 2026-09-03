import '../core/simulation_config.dart';
import '../league/club.dart';
import '../world/world_career_engine.dart';
import '../world/world_career_hooks.dart';
import '../world/world_league.dart';
import 'advanced_transfer_career_report.dart';
import 'advanced_transfer_controller.dart';

class AdvancedTransferWorldCareerEngine {
  const AdvancedTransferWorldCareerEngine({
    this.worldEngine = const WorldCareerEngine(),
  });

  final WorldCareerEngine worldEngine;

  AdvancedTransferCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
  }) {
    final controller = AdvancedTransferController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
    );
    final worldReport = worldEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: hooks,
      rosterHooks: controller,
      financeHooks: controller,
      transferHooks: controller,
      enableTransferInstallments: true,
    );
    return AdvancedTransferCareerReport(
      worldReport: worldReport,
      activeContracts: controller.activeContracts,
      contractEvents: controller.contractEvents,
      loanHistory: controller.loanHistory,
      activeLoans: controller.activeLoans,
      installmentObligations: controller.installmentObligations,
    );
  }
}
