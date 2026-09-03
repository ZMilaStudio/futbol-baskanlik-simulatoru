import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const ManagerWorldCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const ManagerCareerValidator().validate(report);
  final reasonCounts = <ManagerChangeReason, int>{};
  for (final season in report.seasons) {
    for (final change in season.changesAfterSeason) {
      reasonCounts.update(
        change.reason,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
  }

  print('M6 20-season manager-aware world career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Matches: ${report.worldReport.totalMatches}');
  print('Managers in pool: ${report.managers.length}');
  print('Unique managers used: ${report.uniqueManagersUsed}');
  print('Manager changes: ${report.totalManagerChanges}');
  print('Dismissals: ${report.totalDismissals}');
  print('Retirements: ${report.totalRetirements}');
  print('Change reasons: $reasonCounts');
  print(
    'Average strength impact: '
    '${report.averageStrengthImpact.toStringAsFixed(3)}',
  );
  print(
    'Average final board relationship: '
    '${report.averageFinalRelationship.toStringAsFixed(2)}',
  );
  print('Transfers: ${report.worldReport.totalTransfers}');
  print('Transfer volume: ${report.worldReport.totalTransferVolume}');
  print('Final cash: ${report.worldReport.finalTotalCash}');
  print('Final debt: ${report.worldReport.finalTotalDebt}');
  print('Emergency borrowing: ${report.worldReport.totalEmergencyBorrowing}');
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M6 validation failed: $issues');
  }
}
