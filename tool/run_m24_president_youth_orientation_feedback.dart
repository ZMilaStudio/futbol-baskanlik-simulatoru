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
          if (report.iterationCount < 3 || report.iterationCount > 6)
            'M24 canonical: iteration count outside 3..6.',
          if (report.finalReport.totalElections != 240)
            'M24 canonical: election count changed.',
          if (report.electionOutcomeDifferences < 25 ||
              report.electionOutcomeDifferences > 75)
            'M24 canonical: election difference outside 25..75.',
          if (report.finalReelections < 145 || report.finalReelections > 170)
            'M24 canonical: final reelections outside 145..170.',
          if (report.finalLosses < 70 || report.finalLosses > 95)
            'M24 canonical: final losses outside 70..95.',
          if (report.finalTransfers < 135 || report.finalTransfers > 175)
            'M24 canonical: final transfer count outside 135..175.',
          if (report.transferDelta.abs() < 10 || report.transferDelta.abs() > 40)
            'M24 canonical: transfer delta magnitude outside 10..40.',
          if (report.finalManagerChanges < 75 || report.finalManagerChanges > 100)
            'M24 canonical: manager changes outside 75..100.',
          if (!_moneyBetween(report.finalTransferVolume, 1200000000, 1650000000))
            'M24 canonical: transfer volume outside 1.20B..1.65B.',
          if (report.finalInstallmentDeals < 65 || report.finalInstallmentDeals > 90)
            'M24 canonical: installment deals outside 65..90.',
          if (!_moneyBetween(
              report.finalInstallmentCommitment, 200000000, 320000000))
            'M24 canonical: installment commitment outside 200M..320M.',
          if (!_moneyBetween(report.finalCash, 1000000000, 1400000000))
            'M24 canonical: final cash outside 1.00B..1.40B.',
          if (!_moneyBetween(report.finalDebt, 280000000, 430000000))
            'M24 canonical: final debt outside 280M..430M.',
          if (!_moneyBetween(report.finalEmergencyBorrowing, 100000000, 220000000))
            'M24 canonical: emergency borrowing outside 100M..220M.',
          if (report.uniqueFinalPresidents < 115 ||
              report.uniqueFinalPresidents > 145)
            'M24 canonical: unique presidents outside 115..145.',
          if (report.iterations.last.timelineChanged)
            'M24 canonical: final timeline must be stable.',
          if (report.iterations.last.electionOutcomeDifferences != 0)
            'M24 canonical: final election difference must be zero.',
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

bool _moneyBetween(Money value, int minUnits, int maxUnits) {
  final min = Money.fromUnits(minUnits).minorUnits;
  final max = Money.fromUnits(maxUnits).minorUnits;
  return value.minorUnits >= min && value.minorUnits <= max;
}
