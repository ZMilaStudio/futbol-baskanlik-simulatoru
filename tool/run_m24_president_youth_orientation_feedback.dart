import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'profile_feedback_canonical_guard.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentYouthOrientationFeedbackEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );

  final issues = seed == 20260903
      ? <String>[
          ...ProfileFeedbackCanonicalGuard.m19Issues(
            report.m23Baseline.m21Baseline.m20Baseline.m19Baseline,
          ),
          ...ProfileFeedbackCanonicalGuard.m20Issues(
            report.m23Baseline.m21Baseline.m20Baseline,
          ),
          ...ProfileFeedbackCanonicalGuard.m21Issues(
            report.m23Baseline.m21Baseline,
          ),
          ...ProfileFeedbackCanonicalGuard.m23Issues(report.m23Baseline),
          ...const PresidentYouthOrientationFeedbackValidator().validate(report),
          if (report.baselineReelections != 156)
            'M24 canonical: baseline reelections changed.',
          if (report.baselineLosses != 84)
            'M24 canonical: baseline losses changed.',
          if (report.baselineManagerChanges != 85)
            'M24 canonical: baseline manager count changed.',
          if (report.baselineTransfers != 133)
            'M24 canonical: baseline transfer count changed.',
          if (report.iterationCount < 1 || report.iterationCount > 8)
            'M24 canonical: iteration count outside 1..8.',
          if (report.finalReport.totalElections != 240)
            'M24 canonical: election count changed.',
          if (report.finalTransfers < 100 || report.finalTransfers > 180)
            'M24 canonical: final transfer count outside 100..180.',
          if (report.finalManagerChanges < 60 || report.finalManagerChanges > 110)
            'M24 canonical: manager changes outside 60..110.',
          if (report.uniqueFinalPresidents < 100 ||
              report.uniqueFinalPresidents > 170)
            'M24 canonical: unique presidents outside 100..170.',
          if (!report.worldChanged)
            'M24 canonical: youth orientation must change the world.',
        ]
      : const PresidentYouthOrientationFeedbackValidator().validate(report);

  print('M24 20-season president youth orientation feedback career');
  print('Seed: $seed');
  print('Iterations: ${report.iterationCount}');
  print('Converged: ${report.converged}');
  print('Cycle detected: ${report.cycleDetected}');
  print('Elections: ${report.finalReport.totalElections}');
  print('Reelections baseline -> final: ${report.baselineReelections} -> ${report.finalReelections}');
  print('Losses baseline -> final: ${report.baselineLosses} -> ${report.finalLosses}');
  print('Election outcome differences: ${report.electionOutcomeDifferences}');
  print('Manager changes baseline -> final: ${report.baselineManagerChanges} -> ${report.finalManagerChanges}');
  print('Transfers baseline -> final: ${report.baselineTransfers} -> ${report.finalTransfers}');
  print('Transfer volume baseline -> final: ${report.baselineTransferVolume} -> ${report.finalTransferVolume}');
  print('Installment deals baseline -> final: ${report.baselineInstallmentDeals} -> ${report.finalInstallmentDeals}');
  print('Installment commitment baseline -> final: ${report.baselineInstallmentCommitment} -> ${report.finalInstallmentCommitment}');
  print('Final cash baseline -> final: ${report.baselineFinalCash} -> ${report.finalCash}');
  print('Final debt baseline -> final: ${report.baselineFinalDebt} -> ${report.finalDebt}');
  print('Emergency borrowing baseline -> final: ${report.baselineEmergencyBorrowing} -> ${report.finalEmergencyBorrowing}');
  print('Unique final presidents: ${report.uniqueFinalPresidents}');
  print('World changed: ${report.worldChanged}');
  if (seed == 20260903) {
    print(
      'Nested canonical baselines: '
      'M19=${report.m23Baseline.m21Baseline.m20Baseline.m19Baseline.finalReelections}/'
      '${report.m23Baseline.m21Baseline.m20Baseline.m19Baseline.finalLosses}, '
      'M20=${report.m23Baseline.m21Baseline.m20Baseline.finalReelections}/'
      '${report.m23Baseline.m21Baseline.m20Baseline.finalLosses}, '
      'M21=${report.m23Baseline.m21Baseline.finalReelections}/'
      '${report.m23Baseline.m21Baseline.finalLosses}, '
      'M23=${report.m23Baseline.finalReelections}/'
      '${report.m23Baseline.finalLosses}',
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
    throw StateError('M19-M24 canonical validation failed.');
  }
}
