import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  const engine = CareerEngine();
  const validator = CareerValidator();
  final report = engine.simulate(
    clubs: m0Clubs,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = validator.validate(report);

  print('M1 20-season career');
  print('Seed: $seed');
  print('Window: ${report.startDate} -> ${report.endDate}');
  print('Seasons: ${report.seasonCount}');
  print('Matches: ${report.totalMatches}');
  print('Championships: ${report.championships}');
  print('Final strengths:');
  for (final club in report.finalClubs) {
    print('  ${club.name}: ${club.strength.toStringAsFixed(2)}');
  }
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    for (final issue in issues) {
      print('  - $issue');
    }
    throw StateError('M1 career validation failed.');
  }
}
