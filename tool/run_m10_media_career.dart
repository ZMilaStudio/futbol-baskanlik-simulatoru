import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const MediaCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const MediaCareerValidator().validate(report);

  print('M10 20-season media-memory career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Statements: ${report.totalStatements}');
  print('Contradictions: ${report.totalContradictions}');
  print('Strong-support contradictions: ${report.strongSupportContradictions}');
  print('Consistent statements: ${report.totalConsistentStatements}');
  print('Stances: ${report.stanceDistribution}');
  print(
    'Final credibility avg: '
    '${report.averageFinalCredibility.toStringAsFixed(2)}',
  );
  print(
    'Final credibility range: '
    '${report.minimumFinalCredibility} to ${report.maximumFinalCredibility}',
  );
  print('Boundary clubs: ${report.boundaryClubs}');
  print('Manager changes: ${report.managerReport.totalManagerChanges}');
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M10 validation failed: $issues');
  }
}
