import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  const engine = AdvancedTransferWorldCareerEngine();
  final report = engine.simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const AdvancedTransferCareerValidator().validate(report);

  print('M8 20-season loans + installments career');
  print('Seed: $seed');
  print('Seasons: ${report.worldReport.seasonCount}');
  print('Matches: ${report.worldReport.totalMatches}');
  print('Permanent transfers: ${report.worldReport.totalTransfers}');
  print('Installment deals: ${report.installmentDeals}');
  print('Future installment commitment: ${report.totalInstallmentCommitment}');
  print('Installments paid: ${report.totalInstallmentsPaid}');
  print('Outstanding installments: ${report.outstandingInstallments}');
  print('Loans: ${report.totalLoans}');
  print('Active final loans: ${report.activeLoans.length}');
  print('Loan fees: ${report.totalLoanFees}');
  print(
    'Average loan-club wage share: '
    '${report.averageLoanWageShareBps.toStringAsFixed(0)} bps',
  );
  print('Final cash: ${report.worldReport.finalTotalCash}');
  print('Final debt: ${report.worldReport.finalTotalDebt}');
  print('Emergency borrowing: ${report.worldReport.totalEmergencyBorrowing}');
  print('Validation issues: ${issues.length}');
  for (final issue in issues.take(20)) {
    print('  - $issue');
  }
  if (issues.isNotEmpty) {
    throw StateError('M8 validation failed.');
  }
}
