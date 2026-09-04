import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentManagerElectionFeedbackEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    maxIterations: 8,
  );
  final issues = const PresidentManagerElectionFeedbackValidator().validate(report);

  print('M19 20-season president manager election feedback career');
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
  print('Turnover membership differences: ${report.turnoverDifferenceCount}');
  print(
    'Manager changes baseline -> final: '
    '${report.baselineManagerChanges} -> ${report.finalManagerChanges}',
  );
  print(
    'Transfers baseline -> final: '
    '${report.baselineTransfers} -> ${report.finalTransfers}',
  );
  print('Unique final presidents: ${report.uniqueFinalPresidents}');
  print('World changed: ${report.worldChanged}');
  print('Iteration path:');
  for (final item in report.iterations) {
    print(
      '  i${item.iteration}: changed=${item.timelineChanged}, '
      'manager=${item.managerChanges}, transfers=${item.transfers}, '
      'reelected=${item.reelections}, lost=${item.losses}, '
      'electionDiff=${item.electionOutcomeDifferences}',
    );
  }
  print('Validation issues: ${issues.length}');
  for (final issue in issues) {
    print('  - $issue');
  }

  if (issues.isNotEmpty) {
    throw StateError('M19 validation failed.');
  }
}
