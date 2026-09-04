import '../manager/manager_career_report.dart';
import '../transfer/advanced_transfer_career_report.dart';
import 'president_election.dart';
import 'president_reputation_career_report.dart';

String presidentTimelineSignature(PresidentReputationCareerReport report) {
  final initial = List.of(report.initialTenureStates)
    ..sort((a, b) => a.clubId.compareTo(b.clubId));
  final turnovers = List.of(report.turnovers)
    ..sort((a, b) {
      final season = a.effectiveSeasonIndex.compareTo(b.effectiveSeasonIndex);
      return season != 0 ? season : a.clubId.compareTo(b.clubId);
    });
  return 'initial=${initial.map((item) => '${item.clubId}:${item.president.id}').join('|')}:'
      'turnovers=${turnovers.map((item) => '${item.clubId}:s${item.effectiveSeasonIndex}:${item.incoming.id}').join('|')}';
}

class PresidentManagerFeedbackIteration {
  const PresidentManagerFeedbackIteration({
    required this.iteration,
    required this.inputTimelineSignature,
    required this.outputTimelineSignature,
    required this.managerChanges,
    required this.transfers,
    required this.reelections,
    required this.losses,
    required this.electionOutcomeDifferences,
  });

  final int iteration;
  final String inputTimelineSignature;
  final String outputTimelineSignature;
  final int managerChanges;
  final int transfers;
  final int reelections;
  final int losses;
  final int electionOutcomeDifferences;

  bool get timelineChanged => inputTimelineSignature != outputTimelineSignature;

  String get signature =>
      'i=$iteration:timeline=${timelineChanged ? 'changed' : 'stable'}:'
      'manager=$managerChanges:transfers=$transfers:'
      'reelected=$reelections:lost=$losses:'
      'electionDiff=$electionOutcomeDifferences:'
      'in=$inputTimelineSignature:out=$outputTimelineSignature';
}

class PresidentManagerElectionFeedbackReport {
  PresidentManagerElectionFeedbackReport({
    required this.baselineReport,
    required this.finalReport,
    required Iterable<PresidentManagerFeedbackIteration> iterations,
    required this.maxIterations,
    required this.converged,
    required this.cycleDetected,
  }) : iterations = List.unmodifiable(iterations);

  final PresidentReputationCareerReport baselineReport;
  final PresidentReputationCareerReport finalReport;
  final List<PresidentManagerFeedbackIteration> iterations;
  final int maxIterations;
  final bool converged;
  final bool cycleDetected;

  int get iterationCount => iterations.length;
  ManagerCareerReport get finalManagerReport => finalReport.sourceReport.managerReport;
  AdvancedTransferCareerReport get finalAdvancedReport =>
      finalReport.sourceReport.advancedTransferReport;

  String get baselineTimelineSignature => presidentTimelineSignature(baselineReport);
  String get finalTimelineSignature => presidentTimelineSignature(finalReport);

  int get baselineReelections => baselineReport.reelections;
  int get baselineLosses => baselineReport.losses;
  int get finalReelections => finalReport.reelections;
  int get finalLosses => finalReport.losses;
  int get electionOutcomeDifferences =>
      _electionOutcomeDifferences(baselineReport, finalReport);
  int get turnoverDifferenceCount => _turnoverDifferenceCount(baselineReport, finalReport);

  int get baselineManagerChanges => baselineReport.sourceReport.managerReport.totalManagerChanges;
  int get finalManagerChanges => finalManagerReport.totalManagerChanges;
  int get managerChangeDelta => finalManagerChanges - baselineManagerChanges;

  int get baselineTransfers =>
      baselineReport.sourceReport.advancedTransferReport.worldReport.totalTransfers;
  int get finalTransfers => finalAdvancedReport.worldReport.totalTransfers;
  int get transferDelta => finalTransfers - baselineTransfers;

  bool get worldChanged =>
      baselineReport.sourceReport.advancedTransferReport.worldReport.signature !=
      finalAdvancedReport.worldReport.signature;

  int get uniqueFinalPresidents {
    final ids = <String>{
      for (final state in finalReport.initialTenureStates) state.president.id,
      for (final turnover in finalReport.turnovers) turnover.incoming.id,
    };
    return ids.length;
  }

  String get signature =>
      '${baselineReport.signature}|feedback='
      '${iterations.map((item) => item.signature).join('||')}|'
      'max=$maxIterations:converged=$converged:cycle=$cycleDetected|'
      'final=${finalReport.signature}';
}

int electionOutcomeDifferencesBetween(
  PresidentReputationCareerReport first,
  PresidentReputationCareerReport second,
) =>
    _electionOutcomeDifferences(first, second);

int _electionOutcomeDifferences(
  PresidentReputationCareerReport first,
  PresidentReputationCareerReport second,
) {
  final firstByKey = {
    for (final election in first.elections)
      '${election.seasonIndex}|${election.clubId}': election.outcome,
  };
  final secondByKey = {
    for (final election in second.elections)
      '${election.seasonIndex}|${election.clubId}': election.outcome,
  };
  final keys = <String>{...firstByKey.keys, ...secondByKey.keys};
  var count = 0;
  for (final key in keys) {
    final a = firstByKey[key];
    final b = secondByKey[key];
    if (a != b) count++;
  }
  return count;
}

int _turnoverDifferenceCount(
  PresidentReputationCareerReport first,
  PresidentReputationCareerReport second,
) {
  final firstKeys = <String>{
    for (final turnover in first.turnovers)
      '${turnover.effectiveSeasonIndex}|${turnover.clubId}|${turnover.incoming.id}',
  };
  final secondKeys = <String>{
    for (final turnover in second.turnovers)
      '${turnover.effectiveSeasonIndex}|${turnover.clubId}|${turnover.incoming.id}',
  };
  return firstKeys.difference(secondKeys).length +
      secondKeys.difference(firstKeys).length;
}
