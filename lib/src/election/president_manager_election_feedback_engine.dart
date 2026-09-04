import '../core/simulation_config.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_career_report.dart';
import '../manager/manager_patience_policy.dart';
import '../promise/promise_media_career_engine.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../world/world_league.dart';
import 'president_management_profile.dart';
import 'president_manager_election_feedback_report.dart';
import 'president_manager_patience_timeline.dart';
import 'president_reputation_career_engine.dart';
import 'president_reputation_career_report.dart';

class PresidentManagerElectionFeedbackEngine {
  const PresidentManagerElectionFeedbackEngine({
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.advancedEngine = const AdvancedTransferWorldCareerEngine(),
    this.promiseMediaEngine = const PromiseMediaCareerEngine(),
    this.dismissalPolicy = const ManagerDismissalPolicy(),
    this.profileGenerator = const PresidentManagementProfileGenerator(),
  });

  final PresidentReputationCareerEngine reputationEngine;
  final AdvancedTransferWorldCareerEngine advancedEngine;
  final PromiseMediaCareerEngine promiseMediaEngine;
  final ManagerDismissalPolicy dismissalPolicy;
  final PresidentManagementProfileGenerator profileGenerator;

  PresidentManagerElectionFeedbackReport simulate({
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

    final baselineReport = reputationEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
    );

    var inputReport = baselineReport;
    var finalReport = baselineReport;
    var converged = false;
    var cycleDetected = false;
    final iterations = <PresidentManagerFeedbackIteration>[];
    final seenTimelineSignatures = <String>{
      presidentTimelineSignature(baselineReport),
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
        PresidentManagerFeedbackIteration(
          iteration: iteration,
          inputTimelineSignature: inputTimelineSignature,
          outputTimelineSignature: outputTimelineSignature,
          managerChanges: managerReport.totalManagerChanges,
          transfers: advancedReport.worldReport.totalTransfers,
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

    return PresidentManagerElectionFeedbackReport(
      baselineReport: baselineReport,
      finalReport: finalReport,
      iterations: iterations,
      maxIterations: maxIterations,
      converged: converged,
      cycleDetected: cycleDetected,
    );
  }
}
