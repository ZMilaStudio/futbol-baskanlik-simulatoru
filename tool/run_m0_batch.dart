import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final count = args.isEmpty ? 100 : int.parse(args.first);
  var homeWins = 0;
  var draws = 0;
  var awayWins = 0;
  var totalGoals = 0;
  var matches = 0;
  final champions = <String, int>{};
  const validator = SeasonValidator();
  const engine = SeasonEngine();

  for (var i = 0; i < count; i++) {
    final report = engine.simulate(
      clubs: m0Clubs,
      config: SimulationConfig(careerSeed: 20260903 + i),
    );
    final issues = validator.validate(report);
    if (issues.isNotEmpty) {
      throw StateError('Seed ${report.seed} failed: $issues');
    }
    homeWins += report.homeWins;
    draws += report.draws;
    awayWins += report.awayWins;
    totalGoals += report.totalGoals;
    matches += report.matchCount;
    champions.update(
      report.championClubId,
      (v) => v + 1,
      ifAbsent: () => 1,
    );
  }

  final output = {
    'seasons': count,
    'matches': matches,
    'homeWinRate': homeWins / matches,
    'drawRate': draws / matches,
    'awayWinRate': awayWins / matches,
    'averageGoals': totalGoals / matches,
    'champions': champions,
  };
  print(const JsonEncoder.withIndent('  ').convert(output));
}
