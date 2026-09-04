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
import 'president_financial_discipline_transfer_policy.dart';
import 'president_management_profile.dart';
import 'president_manager_election_feedback_report.dart';
import 'president_manager_patience_timeline.dart';
import 'president_reputation_career_engine.dart';
import 'president_risk_appetite_feedback_report.dart';
import 'president_risk_appetite_negotiation_policy.dart';
import 'president_transfer_ambition_activity_policy.dart';
import 'president_transfer_ambition_feedback_engine.dart';

class PresidentRiskAppetiteFeedbackEngine {
  const PresidentRiskAppetiteFeedbackEngine({
    this.m21Engine = const PresidentTransferAmbitionFeedbackEngine(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.promiseMediaEngine = const PromiseMediaCareerEngine(),
    this.dismissalPolicy = const ManagerDismissalPolicy(),
    this.financialPolicy = const PresidentFinancialDisciplineTransferPolicy(),
    this.ambitionPolicy = const PresidentTransferAmbitionActivityPolicy(),
    this.riskPolicy = const PresidentRiskAppetiteNegotiationPolicy(),
    this.profileGenerator = const PresidentManagementProfileGenerator(),
  });

  final PresidentTransferAmbitionFeedbackEngine m21Engine;
  final PresidentReputationCareerEngine reputationEngine;
  final PromiseMediaCareerEngine promiseMediaEngine;
  final ManagerDismissalPolicy dismissalPolicy;
  final PresidentFinancialDisciplineTransferPolicy financialPolicy;
  final PresidentTransferAmbitionActivityPolicy ambitionPolicy;
  final PresidentRiskAppetiteNegotiationPolicy riskPolicy;
  final PresidentManagementProfileGenerator profileGenerator;

  PresidentRiskAppetiteFeedbackReport simulate({
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

    final m21Baseline = m21Engine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      maxIterations: maxIterations,
    );
    if (!m21Baseline.converged || m21Baseline.cycleDetected) {
      throw StateError('M23 requires a converged M21 baseline.');
    }

    var inputReport = m21Baseline.finalReport;
    var finalReport = inputReport;
    var converged = false;
    var cycleDetected = false;
    final iterations = <PresidentRiskAppetiteFeedbackIteration>[];
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
            activityPolicyProvider: (clubId, decisionSeasonIndex) {
              final ambition = timeline.transferAmbitionFor(
                clubId,
                decisionSeasonIndex,
              );
              return ambitionPolicy.forAmbition(ambition);
            },
            negotiationPolicyProvider: (clubId, decisionSeasonIndex) {
              final risk = timeline.riskAppetiteFor(
                clubId,
                decisionSeasonIndex,
              );
              return riskPolicy.forRiskAppetite(risk);
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
        PresidentRiskAppetiteFeedbackIteration(
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

    return PresidentRiskAppetiteFeedbackReport(
      m21Baseline: m21Baseline,
      finalReport: finalReport,
      iterations: iterations,
      maxIterations: maxIterations,
      converged: converged,
      cycleDetected: cycleDetected,
    );
  }
}
