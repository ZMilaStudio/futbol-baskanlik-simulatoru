import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PromiseFanCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PromiseFanCareerValidator().validate(report);

  print('M12 20-season promise-driven fan trust career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Promises: ${report.promiseReport.totalPromises}');
  print('Promise reasons: ${report.promiseReasonCount}');
  print('Identity reasons: ${report.promiseIdentityReasons}');
  print('Financial reasons: ${report.promiseFinancialReasons}');
  print('Positive promise reasons: ${report.positivePromiseReasons}');
  print('Negative promise reasons: ${report.negativePromiseReasons}');
  print(
    'Baseline fan trust: '
    '${report.baselineFanReport.averageFinalTrust.toStringAsFixed(2)}',
  );
  print('Final fan trust: ${report.fanReport.averageFinalTrust.toStringAsFixed(2)}');
  print(
    'Average overall delta: '
    '${report.averageFinalOverallTrustDelta.toStringAsFixed(2)}',
  );
  print(
    'Average identity trust: '
    '${report.averageFinalIdentityTrust.toStringAsFixed(2)}',
  );
  print(
    'Identity range: '
    '${report.minimumFinalIdentityTrust}..${report.maximumFinalIdentityTrust}',
  );
  print(
    'Average identity delta: '
    '${report.averageFinalIdentityTrustDelta.toStringAsFixed(2)}',
  );
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M12 validation failed: $issues');
  }
}
