import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final report = const SeasonEngine().simulate(
    clubs: m0Clubs,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const SeasonValidator().validate(report);
  final output = {...report.toJson(), 'validationIssues': issues};
  print(const JsonEncoder.withIndent('  ').convert(output));
  if (issues.isNotEmpty) {
    throw StateError('M0 validation failed: $issues');
  }
}
