import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const expectationEngine = FanExpectationEngine();

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
    expect(report.averageFinalTrust, inInclusiveRange(20.0, 90.0));
    expect(report.minFinalTrust, greaterThan(0));
    expect(report.maxFinalTrust, lessThan(100));
    expect(report.boundaryFinalStates, lessThanOrEqualTo(8));
    expect(report.reasonCount, greaterThan(500));
    expect(report.smartLoanExpectations, greaterThan(0));
    expect(report.expectationCounts.length, greaterThanOrEqualTo(5));
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
}) =>
    FanSeasonContext(
      clubId: 'test_club',
      seasonIndex: 1,
      tier: LeagueTier.first,
      leaguePosition: position,
      leagueSize: 16,
      clubStrength: 60,
      financialHealth: health,
      closingCash: Money.fromUnits(cash),
      closingDebt: Money.fromUnits(debt),
      emergencyBorrowing: Money.fromUnits(emergency),
      permanentBuys: 0,
      permanentSales: 0,
      installmentBuys: 0,
      loanIns: 0,
      loanOuts: 0,
      transferSpend: Money.zero,
      transferIncome: Money.zero,
      promoted: promoted,
      relegated: false,
      hasTransferWindow: true,
    );
