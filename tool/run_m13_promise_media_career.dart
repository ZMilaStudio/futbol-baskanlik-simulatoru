import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PromiseMediaCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PromiseMediaCareerValidator().validate(report);

  print('M13 20-season promise-driven media credibility career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Promises: ${report.promiseChanges}');
  print('Positive promise changes: ${report.positivePromiseChanges}');
  print('Neutral promise changes: ${report.neutralPromiseChanges}');
  print('Negative promise changes: ${report.negativePromiseChanges}');
  print('Media statements: ${report.baselineMediaReport.totalStatements}');
  print('Contradictions: ${report.baselineMediaReport.totalContradictions}');
  print('Manager changes: ${report.managerReport.totalManagerChanges}');
  print(
    'Baseline media credibility: '
    '${report.baselineMediaReport.averageFinalCredibility.toStringAsFixed(2)}',
  );
  print('Final media credibility: ${report.averageFinalCredibility.toStringAsFixed(2)}');
  print('Average credibility delta: ${report.averageCredibilityDelta.toStringAsFixed(2)}');
  print('Final credibility range: ${report.minimumFinalCredibility}..${report.maximumFinalCredibility}');
  print('Boundary clubs: ${report.boundaryClubs}');
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    for (final issue in issues) {
      print('  - $issue');
    }
    throw StateError('M13 validation failed.');
  }
}
