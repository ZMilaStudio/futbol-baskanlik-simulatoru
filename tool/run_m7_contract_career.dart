import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const ContractWorldCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const ContractCareerValidator().validate(report);

  print('M7 20-season player contract career');
  print('Seed: $seed');
  print('Seasons: ${report.worldReport.seasonCount}');
  print('Matches: ${report.worldReport.totalMatches}');
  print('Initial contracts: ${report.initialContracts}');
  print('Active final contracts: ${report.activeContracts.length}');
  print('Renewals: ${report.renewals}');
  print('Releases: ${report.releases}');
  print('Free-agent signings: ${report.freeAgentSignings}');
  print('Final free agents: ${report.finalFreeAgents}');
  print('Youth contracts: ${report.youthContracts}');
  print('Transfer contracts: ${report.transferContracts}');
  print('Final annual wage bill: ${report.finalAnnualWageBill}');
  print(
    'Average final annual wage: '
    '${report.averageFinalAnnualWage.toStringAsFixed(0)}',
  );
  print('Transfers: ${report.worldReport.totalTransfers}');
  print('Transfer volume: ${report.worldReport.totalTransferVolume}');
  print('Final cash: ${report.worldReport.finalTotalCash}');
  print('Final debt: ${report.worldReport.finalTotalDebt}');
  print('Emergency borrowing: ${report.worldReport.totalEmergencyBorrowing}');
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M7 validation failed: $issues');
  }
}
