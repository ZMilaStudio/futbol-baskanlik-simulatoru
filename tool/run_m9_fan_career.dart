import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const FanCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const FanCareerValidator().validate(report);

  print('M9 20-season context-aware fan career');
  print('Seed: $seed');
  print('Seasons: ${report.advancedTransferReport.worldReport.seasonCount}');
  print('Snapshots: ${report.snapshots.length}');
  print('Average final trust: ${report.averageFinalTrust.toStringAsFixed(2)}');
  print('Final trust range: ${report.minFinalTrust}..${report.maxFinalTrust}');
  print('Boundary final states: ${report.boundaryFinalStates}');
  print('Trust reasons: ${report.reasonCount}');
  print('Smart-loan expectations: ${report.smartLoanExpectations}');
  print(
    'Financial-discipline expectations: '
    '${report.financialDisciplineExpectations}',
  );
  print('Expectation distribution: ${report.expectationCounts}');
  print('Validation issues: ${issues.length}');
  if (issues.isNotEmpty) {
    for (final issue in issues) {
      print('  - $issue');
    }
    throw StateError('M9 validation failed.');
  }
}
