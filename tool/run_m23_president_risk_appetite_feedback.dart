import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'profile_feedback_canonical_guard.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentRiskAppetiteFeedbackEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );

  final issues = seed == 20260903
      ? <String>[
          ...ProfileFeedbackCanonicalGuard.m19Issues(
            report.m21Baseline.m20Baseline.m19Baseline,
          ),
          ...ProfileFeedbackCanonicalGuard.m20Issues(
            report.m21Baseline.m20Baseline,
          ),
          ...ProfileFeedbackCanonicalGuard.m21Issues(report.m21Baseline),
          ...const PresidentRiskAppetiteFeedbackValidator().validate(report),
        ]
      : const PresidentRiskAppetiteFeedbackValidator().validate(report);

  print('M23 20-season president risk appetite feedback career');
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
  if (seed == 20260903) {
    print(
      'Nested canonical baselines: '
      'M19=${report.m21Baseline.m20Baseline.m19Baseline.finalReelections}/'
      '${report.m21Baseline.m20Baseline.m19Baseline.finalLosses}, '
      'M20=${report.m21Baseline.m20Baseline.finalReelections}/'
      '${report.m21Baseline.m20Baseline.finalLosses}, '
      'M21=${report.m21Baseline.finalReelections}/'
      '${report.m21Baseline.finalLosses}',
    );
  }
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
    throw StateError('M19-M23 canonical validation failed.');
  }
}
