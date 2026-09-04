import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentManagerPatienceCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PresidentManagerPatienceCareerValidator().validate(report);

  print('M18 20-season president patience -> manager decisions career');
  print('Seed: $seed');
  print('Decisions: ${report.decisions.length}');
  print('Baseline manager changes: ${report.baselineManagerChanges}');
  print('Patience-aware manager changes: ${report.influencedManagerChanges}');
  print('Manager change delta: ${report.managerChangeDelta}');
  print('Decision differences: ${report.decisionDifferences}');
  print('Manager identity differences: ${report.managerIdentityDifferences}');
  print('Final assignment differences: ${report.finalAssignmentDifferences}');
  print('Low-patience club seasons: ${report.lowPatienceClubSeasons}');
  print('High-patience club seasons: ${report.highPatienceClubSeasons}');
  print(
    'Low-patience dismissal rate: '
    '${(report.lowPatienceDismissalRate * 100).toStringAsFixed(1)}%',
  );
  print(
    'High-patience dismissal rate: '
    '${(report.highPatienceDismissalRate * 100).toStringAsFixed(1)}%',
  );
  print(
    'Average patience on dismissals: '
    '${report.averageDismissalPatience.toStringAsFixed(2)}',
  );
  print(
    'Average patience on retained seasons: '
    '${report.averageRetainedPatience.toStringAsFixed(2)}',
  );
  print('Change reasons: ${report.changeReasons}');
  print(
    'Transfers baseline -> influenced: '
    '${report.baselineAdvancedReport.worldReport.totalTransfers} -> '
    '${report.influencedAdvancedReport.worldReport.totalTransfers}',
  );
  print('World changed: ${report.worldChanged}');
  print('Validation issues: ${issues.length}');
  for (final issue in issues) {
    print('  - $issue');
  }

  if (issues.isNotEmpty) {
    throw StateError('M18 validation failed.');
  }
}
