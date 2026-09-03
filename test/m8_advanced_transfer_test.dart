import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M8 simulates deterministic loans and installment transfers', () {
    final world = const FictionalWorldFactory().build();
    const engine = AdvancedTransferWorldCareerEngine();
    final report = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const AdvancedTransferCareerValidator().validate(report);

    print(
      'M8_BALANCE transfers=${report.worldReport.totalTransfers} '
      'installmentDeals=${report.installmentDeals} '
      'installmentCommitment=${report.totalInstallmentCommitment} '
      'installmentsPaid=${report.totalInstallmentsPaid} '
      'outstanding=${report.outstandingInstallments} '
      'loans=${report.totalLoans} activeLoans=${report.activeLoans.length} '
      'loanFees=${report.totalLoanFees} '
      'avgLoanWageShare=${report.averageLoanWageShareBps.toStringAsFixed(0)} '
      'cash=${report.worldReport.finalTotalCash} '
      'debt=${report.worldReport.finalTotalDebt}',
    );

    expect(issues, isEmpty);
    expect(report.signature, repeat.signature);
    expect(report.worldReport.seasonCount, 20);
    expect(report.worldReport.totalMatches, 14400);
    expect(report.installmentDeals, greaterThan(0));
    expect(report.totalInstallmentCommitment, greaterThan(Money.zero));
    expect(report.totalInstallmentsPaid, greaterThan(Money.zero));
    expect(
      report.totalInstallmentsPaid,
      lessThanOrEqualTo(report.totalInstallmentCommitment),
    );
    expect(report.totalLoans, greaterThan(0));
    expect(report.activeLoans, isNotEmpty);
    expect(report.totalLoanFees, greaterThan(Money.zero));
    expect(report.averageLoanWageShareBps, inInclusiveRange(4500, 8000));
  });

  test('M8 different seeds diverge', () {
    final world = const FictionalWorldFactory().build();
    const engine = AdvancedTransferWorldCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 8101),
      seasonCount: 3,
    );
    final second = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 8102),
      seasonCount: 3,
    );
    expect(first.signature, isNot(equals(second.signature)));
  });

  test('manager and M8 transfer systems coexist on the same world engine', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 8611);
    final managerController = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
    );
    const engine = AdvancedTransferWorldCareerEngine();
    final report = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
      hooks: managerController,
    );

    expect(managerController.seasons.length, 3);
    expect(const AdvancedTransferCareerValidator().validate(report), isEmpty);
  });
}
