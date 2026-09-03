import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final report = const TransferCareerEngine().simulate(
    clubs: m0Clubs,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const TransferCareerValidator().validate(report);

  final totalCash = report.finalFinanceStates.fold<Money>(
    Money.zero,
    (sum, state) => sum + state.cash,
  );
  final totalDebt = report.finalFinanceStates.fold<Money>(
    Money.zero,
    (sum, state) => sum + state.debt,
  );
  final averageFee = report.totalTransfers == 0
      ? Money.zero
      : Money.fromMinorUnits(
          report.totalTransferVolume.minorUnits ~/ report.totalTransfers,
        );

  print('M4 20-season transfer career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Transfers: ${report.totalTransfers}');
  print('Transfer volume: ${report.totalTransferVolume}');
  print('Average fee: $averageFee');
  print('Final total cash: $totalCash');
  print('Final total debt: $totalDebt');
  print('Final players: ${report.finalPlayers.length}');
  print('Final club strengths:');
  for (final club in report.finalClubs) {
    print('  ${club.name}: ${club.strength.toStringAsFixed(2)}');
  }
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M4 validation failed: $issues');
  }
}
