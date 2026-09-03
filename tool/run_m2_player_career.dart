import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final report = const PlayerCareerEngine().simulate(
    clubs: m0Clubs,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PlayerCareerValidator().validate(report);
  final averageAge =
      report.finalPlayers.fold<int>(0, (sum, player) => sum + player.age) /
          report.finalPlayers.length;
  final academyCount =
      report.finalPlayers.where((player) => player.isAcademyGraduate).length;

  print('M2 20-season player career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Matches: ${report.totalMatches}');
  print('Initial players: ${report.initialPlayerCount}');
  print('Final players: ${report.finalPlayers.length}');
  print('Retirements: ${report.totalRetirements}');
  print('Youth intakes: ${report.totalYouthIntakes}');
  print('Academy graduates active: $academyCount');
  print('Final average age: ${averageAge.toStringAsFixed(2)}');
  print('Championships: ${report.championships}');
  print('Final club strengths:');
  for (final club in report.finalClubs) {
    print('  ${club.name}: ${club.strength.toStringAsFixed(2)}');
  }
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M2 validation failed: $issues');
  }
}
