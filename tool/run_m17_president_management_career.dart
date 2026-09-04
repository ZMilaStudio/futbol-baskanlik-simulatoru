import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentManagementCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PresidentManagementCareerValidator().validate(report);

  print('M17 20-season president management profile career');
  print('Seed: $seed');
  print('Profiles: ${report.totalProfiles}');
  print('Archetypes: ${report.archetypeDistribution}');
  print('Financial discipline avg: ${report.averageFinancialDiscipline.toStringAsFixed(2)}');
  print('Risk appetite avg: ${report.averageRiskAppetite.toStringAsFixed(2)}');
  print('Transfer ambition avg: ${report.averageTransferAmbition.toStringAsFixed(2)}');
  print('Youth orientation avg: ${report.averageYouthOrientation.toStringAsFixed(2)}');
  print('Manager patience avg: ${report.averageManagerPatience.toStringAsFixed(2)}');
  print('Average turnover profile distance: ${report.averageTurnoverDistance.toStringAsFixed(2)}');
  print('Archetype-changing turnovers: ${report.archetypeChangedTurnovers}');
  print('Meaningful management changes: ${report.meaningfulTurnovers}');
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    for (final issue in issues) {
      stderr.writeln(issue);
    }
    exitCode = 1;
  }
}
