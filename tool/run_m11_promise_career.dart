import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PromiseCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PromiseCareerValidator().validate(report);

  print('M11 20-season president-promise career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Promises: ${report.totalPromises}');
  print('Fulfilled: ${report.fulfilledPromises}');
  print('Partial: ${report.partialPromises}');
  print('Broken: ${report.brokenPromises}');
  print('Average score: ${report.averageScore.toStringAsFixed(2)}');
  print('Financial promises: ${report.financialPromises}');
  print('Sporting promises: ${report.sportingPromises}');
  print('Types: ${report.typeDistribution}');
  print('Statuses: ${report.statusDistribution}');
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M11 validation failed: $issues');
  }
}
