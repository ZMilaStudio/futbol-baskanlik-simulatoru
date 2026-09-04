import '../core/simulation_config.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_career_report.dart';
import '../manager/manager_patience_policy.dart';
import '../promise/promise_media_career_engine.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../transfer/transfer_market_engine.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'president_financial_discipline_feedback_report.dart';
import 'president_financial_discipline_transfer_policy.dart';
import 'president_management_profile.dart';
import 'president_manager_election_feedback_engine.dart';
import 'president_manager_election_feedback_report.dart';
import 'president_manager_patience_timeline.dart';
import 'president_reputation_career_engine.dart';

class PresidentFinancialDisciplineFeedbackEngine {
  const PresidentFinancialDisciplineFeedbackEngine({
    this.m19Engine = const PresidentManagerElectionFeedbackEngine(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.promiseMediaEngine = const PromiseMediaCareerEngine(),
    this.dismissalPolicy = const ManagerDismissalPolicy(),
    this.financialPolicy = const PresidentFinancialDisciplineTransferPolicy(),
    this.profileGenerator = const PresidentManagementProfileGenerator(),
  });

  final PresidentManagerElectionFeedbackEngine m19Engine;
  final PresidentReputationCareerEngine reputationEngine;
  final PromiseMediaCareerEngine promiseMediaEngine;
  final ManagerDismissalPolicy dismissalPolicy;
  final PresidentFinancialDisciplineTransferPolicy financialPolicy;
  final PresidentManagementProfileGenerator profileGenerator;

  PresidentFinancialDisciplineFeedbackReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    int maxIterations = 8,
  }) {
    if (maxIterations <= 0) {
      throw ArgumentError.value(maxIterations, 'maxIterations');
    }

    final m19Baseline = m19Engine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      maxIterations: maxIterations,
    );
    if (!m19Baseline.converged || m19Baseline.cycleDetected) {
      throw StateError('M20 requires a converged M19 baseline.');
    }

    var inputReport = m19Baseline.finalReport;
    var finalReport = inputReport;
    var converged = false;
    var cycleDetected = false;
    final iterations = <PresidentFinancialDisciplineFeedbackIteration>[];
    final seenTimelineSignatures = <String>{
      presidentTimelineSignature(inputReport),
    };

    for (var iteration = 1; iteration <= maxIterations; iteration++) {
      final inputTimelineSignature = presidentTimelineSignature(inputReport);
      final timeline = PresidentManagerPatienceTimeline.fromReputationReport(
        inputReport,
        profileGenerator: profileGenerator,
      );

      final managerController = ManagerCareerController(
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
        initialSeasonIndex: config.seasonIndex,
        patienceProvider: timeline.patienceFor,
        dismissalPolicy: dismissalPolicy,
      );
      final advancedEngine = AdvancedTransferWorldCareerEngine(
        worldEngine: WorldCareerEngine(
          transferMarketEngine: TransferMarketEngine(
            budgetPolicyProvider: (clubId, decisionSeasonIndex) {
              final discipline = timeline.financialDisciplineFor(
                clubId,
                decisionSeasonIndex,
              );
              return financialPolicy.forDiscipline(discipline);
            },
          ),
        ),
      );
      final advancedReport = advancedEngine.simulate(
        clubs: clubs,
        leagues: leagues,
        config: config,
        seasonCount: seasonCount,
        hooks: managerController,
      );
      final managerReport = ManagerCareerReport(
        worldReport: advancedReport.worldReport,
        managers: managerController.managers,
        seasons: managerController.seasons,
        finalAssignments: managerController.finalAssignments,
      );
      final sourceReport = promiseMediaEngine.simulateFromAdvancedReport(
        advancedReport: advancedReport,
        managerReport: managerReport,
        config: config,
      );
      final outputReport = reputationEngine.simulateFromSourceReport(
        sourceReport: sourceReport,
        config: config,
        electionInterval: electionInterval,
      );
      final outputTimelineSignature = presidentTimelineSignature(outputReport);

      iterations.add(
        PresidentFinancialDisciplineFeedbackIteration(
          iteration: iteration,
          inputTimelineSignature: inputTimelineSignature,
          outputTimelineSignature: outputTimelineSignature,
          managerChanges: managerReport.totalManagerChanges,
          transfers: advancedReport.worldReport.totalTransfers,
          transferVolume: advancedReport.worldReport.totalTransferVolume,
          installmentDeals: advancedReport.installmentDeals,
          installmentCommitment: advancedReport.totalInstallmentCommitment,
          finalCash: advancedReport.worldReport.finalTotalCash,
          finalDebt: advancedReport.worldReport.finalTotalDebt,
          reelections: outputReport.reelections,
          losses: outputReport.losses,
          electionOutcomeDifferences:
              electionOutcomeDifferencesBetween(inputReport, outputReport),
        ),
      );
      finalReport = outputReport;

      if (outputTimelineSignature == inputTimelineSignature) {
        converged = true;
        break;
      }
      if (!seenTimelineSignatures.add(outputTimelineSignature)) {
        cycleDetected = true;
        break;
      }
      inputReport = outputReport;
    }

    return PresidentFinancialDisciplineFeedbackReport(
      m19Baseline: m19Baseline,
      finalReport: finalReport,
      iterations: iterations,
      maxIterations: maxIterations,
      converged: converged,
      cycleDetected: cycleDetected,
    );
  }
}
