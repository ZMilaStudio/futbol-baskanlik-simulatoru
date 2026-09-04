import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const expectationEngine = FanExpectationEngine();
  const trustEngine = FanTrustEngine();

  test('fan expectations understand financial and sporting context', () {
    final stressed = _context(
      health: FinancialHealth.debtCrisis,
      position: 14,
      cash: 3000000,
      debt: 25000000,
      emergency: 2000000,
    );
    final promoted = _context(
      health: FinancialHealth.solid,
      position: 2,
      promoted: true,
      cash: 18000000,
      debt: 5000000,
    );
    final ambitious = _context(
      health: FinancialHealth.veryStrong,
      position: 2,
      cash: 30000000,
      debt: 2000000,
    );

    expect(
      expectationEngine.generate(stressed).type,
      FanExpectationType.smartLoanReinforcement,
    );
    expect(
      expectationEngine.generate(promoted).type,
      FanExpectationType.prepareForHigherTier,
    );
    expect(
      expectationEngine.generate(ambitious).type,
      FanExpectationType.ambitiousReinforcement,
    );
  });

  test('fans reward smart loans and punish overspending in the same crisis', () {
    final smartLoan = _context(
      health: FinancialHealth.debtCrisis,
      position: 14,
      cash: 3000000,
      debt: 25000000,
      emergency: 2000000,
      loanIns: 1,
    );
    final aggressive = _context(
      health: FinancialHealth.debtCrisis,
      position: 14,
      cash: 3000000,
      debt: 25000000,
      emergency: 2000000,
      permanentBuys: 1,
      installmentBuys: 2,
      transferSpend: 8000000,
    );

    final smartExpectation = expectationEngine.generate(smartLoan);
    final aggressiveExpectation = expectationEngine.generate(aggressive);
    expect(smartExpectation.type, FanExpectationType.smartLoanReinforcement);
    expect(
      aggressiveExpectation.type,
      FanExpectationType.smartLoanReinforcement,
    );

    final smartReasons = trustEngine.evaluate(
      context: smartLoan,
      expectation: smartExpectation,
    );
    final aggressiveReasons = trustEngine.evaluate(
      context: aggressive,
      expectation: aggressiveExpectation,
    );

    final smartTransfer = smartReasons.firstWhere(
      (reason) => reason.dimension == FanTrustDimension.transfer,
    );
    final aggressiveTransfer = aggressiveReasons.firstWhere(
      (reason) => reason.dimension == FanTrustDimension.transfer,
    );

    expect(smartTransfer.code, 'used_smart_loan');
    expect(smartTransfer.delta, 4);
    expect(aggressiveTransfer.code, 'overspent_in_financial_stress');
    expect(aggressiveTransfer.delta, -4);
  });

  test('M9 simulates deterministic context-aware fan trust for 20 seasons', () {
    final world = const FictionalWorldFactory().build();
    const engine = FanCareerEngine();
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
    final issues = const FanCareerValidator().validate(report);

    print(
      'M9_BALANCE snapshots=${report.snapshots.length} '
      'avgTrust=${report.averageFinalTrust.toStringAsFixed(2)} '
      'minTrust=${report.minFinalTrust} maxTrust=${report.maxFinalTrust} '
      'boundary=${report.boundaryFinalStates} reasons=${report.reasonCount} '
      'smartLoan=${report.smartLoanExpectations} '
      'financialDiscipline=${report.financialDisciplineExpectations} '
      'expectations=${report.expectationCounts}',
    );

    expect(issues, isEmpty);
    expect(report.signature, repeat.signature);
    expect(report.snapshots.length, 960);
    expect(report.finalStates.length, 48);

    // Geniş denge guard'ları: nihai taraftar ekonomisi değildir. Amaç güvenin
    // 60 çevresine çökmesini veya 0/100 uçlarına yığılmasını engellemek.
    expect(report.averageFinalTrust, inInclusiveRange(50.0, 75.0));
    expect(report.minFinalTrust, inInclusiveRange(25, 60));
    expect(report.maxFinalTrust, inInclusiveRange(65, 90));
    expect(report.maxFinalTrust - report.minFinalTrust, greaterThanOrEqualTo(25));
    expect(report.boundaryFinalStates, lessThanOrEqualTo(2));
    expect(report.reasonCount, inInclusiveRange(1500, 3000));

    expect(report.smartLoanExpectations, inInclusiveRange(5, 100));
    expect(report.financialDisciplineExpectations, inInclusiveRange(20, 180));
    expect(report.expectationCounts.length, greaterThanOrEqualTo(7));
    expect(report.expectationCounts[FanExpectationType.none], 48);
    expect(
      report.expectationCounts[FanExpectationType.measuredImprovement] ?? 0,
      inInclusiveRange(250, 650),
    );
  });

  test('M9 different seeds diverge', () {
    final world = const FictionalWorldFactory().build();
    const engine = FanCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 9101),
      seasonCount: 3,
    );
    final second = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 9102),
      seasonCount: 3,
    );
    expect(first.signature, isNot(equals(second.signature)));
  });
}

FanSeasonContext _context({
  required FinancialHealth health,
  required int position,
  required int cash,
  required int debt,
  int emergency = 0,
  bool promoted = false,
  bool relegated = false,
  int permanentBuys = 0,
  int permanentSales = 0,
  int installmentBuys = 0,
  int loanIns = 0,
  int loanOuts = 0,
  int transferSpend = 0,
  int transferIncome = 0,
  double strength = 60,
}) =>
    FanSeasonContext(
      clubId: 'test_club',
      seasonIndex: 1,
      tier: LeagueTier.first,
      leaguePosition: position,
      leagueSize: 16,
      clubStrength: strength,
      financialHealth: health,
      closingCash: Money.fromUnits(cash),
      closingDebt: Money.fromUnits(debt),
      emergencyBorrowing: Money.fromUnits(emergency),
      permanentBuys: permanentBuys,
      permanentSales: permanentSales,
      installmentBuys: installmentBuys,
      loanIns: loanIns,
      loanOuts: loanOuts,
      transferSpend: Money.fromUnits(transferSpend),
      transferIncome: Money.fromUnits(transferIncome),
      promoted: promoted,
      relegated: relegated,
      hasTransferWindow: true,
    );
