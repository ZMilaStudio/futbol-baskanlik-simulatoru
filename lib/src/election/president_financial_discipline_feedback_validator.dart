import 'president_financial_discipline_feedback_report.dart';
import 'president_manager_election_feedback_validator.dart';
import 'president_reputation_career_validator.dart';

class PresidentFinancialDisciplineFeedbackValidator {
  const PresidentFinancialDisciplineFeedbackValidator();

  List<String> validate(PresidentFinancialDisciplineFeedbackReport report) {
    final issues = <String>[
      ...const PresidentManagerElectionFeedbackValidator()
          .validate(report.m19Baseline),
      ...const PresidentReputationCareerValidator().validate(report.finalReport),
    ];

    if (report.maxIterations <= 0) {
      issues.add('M20 maxIterations must be positive.');
    }
    if (report.iterations.isEmpty) {
      issues.add('M20 feedback produced no iterations.');
      return issues;
    }
    if (report.iterationCount > report.maxIterations) {
      issues.add('M20 feedback exceeded maxIterations.');
    }
    if (report.converged && report.cycleDetected) {
      issues.add('M20 cannot be both converged and cyclic.');
    }
    if (!report.converged) {
      issues.add('M20 financial feedback did not converge.');
    }
    if (report.cycleDetected) {
      issues.add('M20 financial feedback entered a president-timeline cycle.');
    }

    if (report.baselineReport.careerSeed != report.finalReport.careerSeed ||
        report.baselineReport.simulationVersion !=
            report.finalReport.simulationVersion ||
        report.baselineReport.electionInterval !=
            report.finalReport.electionInterval ||
        report.baselineReport.seasonCount != report.finalReport.seasonCount) {
      issues.add('M20 baseline/final simulation identity mismatch.');
    }
    if (report.baselineReport.totalElections != report.finalReport.totalElections) {
      issues.add('M20 election count changed during feedback.');
    }

    for (var i = 0; i < report.iterations.length; i++) {
      final item = report.iterations[i];
      if (item.iteration != i + 1) {
        issues.add('M20 iteration numbering mismatch at ${item.iteration}.');
      }
      if (i > 0 &&
          report.iterations[i - 1].outputTimelineSignature !=
              item.inputTimelineSignature) {
        issues.add('M20 feedback chain is discontinuous at iteration ${item.iteration}.');
      }
      if (item.managerChanges < 0 || item.managerChanges > 300) {
        issues.add('M20 manager-change count out of bounds at iteration ${item.iteration}.');
      }
      if (item.transfers < 0 || item.transfers > 1000) {
        issues.add('M20 transfer count out of bounds at iteration ${item.iteration}.');
      }
      if (item.transferVolume.minorUnits < 0 ||
          item.installmentDeals < 0 ||
          item.installmentCommitment.minorUnits < 0 ||
          item.finalCash.minorUnits < 0 ||
          item.finalDebt.minorUnits < 0) {
        issues.add('M20 financial metric became negative at iteration ${item.iteration}.');
      }
      if (item.reelections < 0 ||
          item.losses < 0 ||
          item.reelections + item.losses != report.baselineReport.totalElections) {
        issues.add('M20 election totals invalid at iteration ${item.iteration}.');
      }
      if (item.electionOutcomeDifferences < 0 ||
          item.electionOutcomeDifferences > report.baselineReport.totalElections) {
        issues.add('M20 election-difference count invalid at iteration ${item.iteration}.');
      }
    }

    final last = report.iterations.last;
    if (last.outputTimelineSignature != report.finalTimelineSignature) {
      issues.add('M20 final report does not match the last feedback output.');
    }
    if (report.converged && last.timelineChanged) {
      issues.add('M20 converged flag requires a stable final timeline.');
    }

    return issues;
  }
}
