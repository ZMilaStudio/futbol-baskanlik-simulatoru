import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'profile_feedback_canonical_guard.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentFinancialDisciplineFeedbackEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = seed == 20260903
      ? ProfileFeedbackCanonicalGuard.m20Issues(report)
      : const PresidentFinancialDisciplineFeedbackValidator().validate(report);

  print('M20 20-season president financial discipline feedback career');
  print('Seed: $seed');
  print('Iterations: ${report.iterationCount}');
  print('Converged: ${report.converged}');
  print('Cycle detected: ${report.cycleDetected}');
  print('Elections: ${report.finalReport.totalElections}');
  print(
    'Reelections baseline -> final: '
    '${report.baselineReelections} -> ${report.finalReelections}',
  );
  print(
    'Losses baseline -> final: '
    '${report.baselineLosses} -> ${report.finalLosses}',
  );
  print('Election outcome differences: ${report.electionOutcomeDifferences}');
  print(
    'Manager changes baseline -> final: '
    '${report.baselineManagerChanges} -> ${report.finalManagerChanges}',
  );
  print(
    'Transfers baseline -> final: '
    '${report.baselineTransfers} -> ${report.finalTransfers}',
  );
  print(
    'Transfer volume baseline -> final: '
    '${report.baselineTransferVolume} -> ${report.finalTransferVolume}',
  );
  print(
    'Installment deals baseline -> final: '
    '${report.baselineInstallmentDeals} -> ${report.finalInstallmentDeals}',
  );
  print(
    'Installment commitment baseline -> final: '
    '${report.baselineInstallmentCommitment} -> '
    '${report.finalInstallmentCommitment}',
  );
  print(
    'Final cash baseline -> final: '
    '${report.baselineFinalCash} -> ${report.finalCash}',
  );
  print(
    'Final debt baseline -> final: '
    '${report.baselineFinalDebt} -> ${report.finalDebt}',
  );
  print(
    'Emergency borrowing baseline -> final: '
    '${report.baselineEmergencyBorrowing} -> '
    '${report.finalEmergencyBorrowing}',
  );
  print('Unique final presidents: ${report.uniqueFinalPresidents}');
  print('World changed: ${report.worldChanged}');
  print('Iteration path:');
  for (final item in report.iterations) {
    print(
      '  i${item.iteration}: changed=${item.timelineChanged}, '
      'manager=${item.managerChanges}, transfers=${item.transfers}, '
      'volume=${item.transferVolume}, installments=${item.installmentDeals}, '
      'cash=${item.finalCash}, debt=${item.finalDebt}, '
      'reelected=${item.reelections}, lost=${item.losses}, '
      'electionDiff=${item.electionOutcomeDifferences}',
    );
  }
  print('Validation issues: ${issues.length}');
  for (final issue in issues) {
    print('  - $issue');
  }

  if (issues.isNotEmpty) {
    throw StateError('M20 validation failed.');
  }
}
