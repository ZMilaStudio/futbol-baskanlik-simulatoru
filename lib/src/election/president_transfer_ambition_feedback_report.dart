import '../core/money.dart';
import '../manager/manager_career_report.dart';
import '../transfer/advanced_transfer_career_report.dart';
import 'president_financial_discipline_feedback_report.dart';
import 'president_manager_election_feedback_report.dart';
import 'president_reputation_career_report.dart';

class PresidentTransferAmbitionFeedbackIteration {
  const PresidentTransferAmbitionFeedbackIteration({
    required this.iteration,
    required this.inputTimelineSignature,
    required this.outputTimelineSignature,
    required this.managerChanges,
    required this.transfers,
    required this.transferVolume,
    required this.installmentDeals,
    required this.installmentCommitment,
    required this.finalCash,
    required this.finalDebt,
    required this.reelections,
    required this.losses,
    required this.electionOutcomeDifferences,
  });

  final int iteration;
  final String inputTimelineSignature;
  final String outputTimelineSignature;
  final int managerChanges;
  final int transfers;
  final Money transferVolume;
  final int installmentDeals;
  final Money installmentCommitment;
  final Money finalCash;
  final Money finalDebt;
  final int reelections;
  final int losses;
  final int electionOutcomeDifferences;

  bool get timelineChanged => inputTimelineSignature != outputTimelineSignature;

  String get signature =>
      'i=$iteration:timeline=${timelineChanged ? 'changed' : 'stable'}:'
      'manager=$managerChanges:transfers=$transfers:'
      'volume=${transferVolume.minorUnits}:installments=$installmentDeals:'
      'commitment=${installmentCommitment.minorUnits}:'
      'cash=${finalCash.minorUnits}:debt=${finalDebt.minorUnits}:'
      'reelected=$reelections:lost=$losses:'
      'electionDiff=$electionOutcomeDifferences:'
      'in=$inputTimelineSignature:out=$outputTimelineSignature';
}

class PresidentTransferAmbitionFeedbackReport {
  PresidentTransferAmbitionFeedbackReport({
    required this.m20Baseline,
    required this.finalReport,
    required Iterable<PresidentTransferAmbitionFeedbackIteration> iterations,
    required this.maxIterations,
    required this.converged,
    required this.cycleDetected,
  }) : iterations = List.unmodifiable(iterations);

  final PresidentFinancialDisciplineFeedbackReport m20Baseline;
  final PresidentReputationCareerReport finalReport;
  final List<PresidentTransferAmbitionFeedbackIteration> iterations;
  final int maxIterations;
  final bool converged;
  final bool cycleDetected;

  PresidentReputationCareerReport get baselineReport => m20Baseline.finalReport;
  int get iterationCount => iterations.length;

  ManagerCareerReport get baselineManagerReport => m20Baseline.finalManagerReport;
  ManagerCareerReport get finalManagerReport => finalReport.sourceReport.managerReport;
  AdvancedTransferCareerReport get baselineAdvancedReport =>
      m20Baseline.finalAdvancedReport;
  AdvancedTransferCareerReport get finalAdvancedReport =>
      finalReport.sourceReport.advancedTransferReport;

  String get baselineTimelineSignature => presidentTimelineSignature(baselineReport);
  String get finalTimelineSignature => presidentTimelineSignature(finalReport);

  int get baselineReelections => baselineReport.reelections;
  int get baselineLosses => baselineReport.losses;
  int get finalReelections => finalReport.reelections;
  int get finalLosses => finalReport.losses;
  int get electionOutcomeDifferences =>
      electionOutcomeDifferencesBetween(baselineReport, finalReport);

  int get baselineManagerChanges => baselineManagerReport.totalManagerChanges;
  int get finalManagerChanges => finalManagerReport.totalManagerChanges;
  int get managerChangeDelta => finalManagerChanges - baselineManagerChanges;

  int get baselineTransfers => baselineAdvancedReport.worldReport.totalTransfers;
  int get finalTransfers => finalAdvancedReport.worldReport.totalTransfers;
  int get transferDelta => finalTransfers - baselineTransfers;

  Money get baselineTransferVolume => baselineAdvancedReport.worldReport.totalTransferVolume;
  Money get finalTransferVolume => finalAdvancedReport.worldReport.totalTransferVolume;
  Money get transferVolumeDelta => finalTransferVolume - baselineTransferVolume;

  int get baselineInstallmentDeals => baselineAdvancedReport.installmentDeals;
  int get finalInstallmentDeals => finalAdvancedReport.installmentDeals;
  int get installmentDealDelta => finalInstallmentDeals - baselineInstallmentDeals;

  Money get baselineInstallmentCommitment =>
      baselineAdvancedReport.totalInstallmentCommitment;
  Money get finalInstallmentCommitment =>
      finalAdvancedReport.totalInstallmentCommitment;
  Money get installmentCommitmentDelta =>
      finalInstallmentCommitment - baselineInstallmentCommitment;

  Money get baselineFinalCash => baselineAdvancedReport.worldReport.finalTotalCash;
  Money get finalCash => finalAdvancedReport.worldReport.finalTotalCash;
  Money get finalCashDelta => finalCash - baselineFinalCash;

  Money get baselineFinalDebt => baselineAdvancedReport.worldReport.finalTotalDebt;
  Money get finalDebt => finalAdvancedReport.worldReport.finalTotalDebt;
  Money get finalDebtDelta => finalDebt - baselineFinalDebt;

  Money get baselineEmergencyBorrowing =>
      baselineAdvancedReport.worldReport.totalEmergencyBorrowing;
  Money get finalEmergencyBorrowing =>
      finalAdvancedReport.worldReport.totalEmergencyBorrowing;
  Money get emergencyBorrowingDelta =>
      finalEmergencyBorrowing - baselineEmergencyBorrowing;

  bool get worldChanged =>
      baselineAdvancedReport.worldReport.signature !=
      finalAdvancedReport.worldReport.signature;

  int get uniqueFinalPresidents {
    final ids = <String>{
      for (final state in finalReport.initialTenureStates) state.president.id,
      for (final turnover in finalReport.turnovers) turnover.incoming.id,
    };
    return ids.length;
  }

  String get signature =>
      '${m20Baseline.signature}|m21='
      '${iterations.map((item) => item.signature).join('||')}|'
      'max=$maxIterations:converged=$converged:cycle=$cycleDetected|'
      'final=${finalReport.signature}';
}
