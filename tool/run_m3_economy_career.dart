import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final report = const EconomyCareerEngine().simulate(
    clubs: m0Clubs,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const EconomyCareerValidator().validate(report);

  print('M3 20-season economy career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Matches: ${report.totalMatches}');
  print('Final total cash: ${report.finalTotalCash}');
  print('Final total debt: ${report.finalTotalDebt}');
  print('Emergency borrowing: ${report.totalEmergencyBorrowing}');
  print('Final health: ${report.finalHealthDistribution}');
  print('Final club finances:');

  final lastById = {
    for (final club in report.seasons.last.clubs) club.clubId: club,
  };
  final names = {for (final club in m0Clubs) club.id: club.name};
  for (final state in report.finalStates) {
    final season = lastById[state.clubId]!;
    print(
      '  ${names[state.clubId]}: cash=${state.cash}, debt=${state.debt}, '
      'health=${season.health.name}',
    );
  }
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M3 validation failed: $issues');
  }
}
