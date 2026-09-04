import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M11 promise generator uses preseason context instead of impossible goals', () {
    const generator = PromiseGenerator();

    const titleContext = PresidentPromiseContext(
      clubId: 'elite',
      seasonIndex: 1,
      tier: LeagueTier.first,
      leagueSize: 16,
      expectedPosition: 2,
      openingCash: Money.fromUnits(50000000),
      openingDebt: Money.fromUnits(5000000),
    );
    const promotionContext = PresidentPromiseContext(
      clubId: 'contender',
      seasonIndex: 1,
      tier: LeagueTier.second,
      leagueSize: 16,
      expectedPosition: 3,
      openingCash: Money.fromUnits(25000000),
      openingDebt: Money.fromUnits(3000000),
    );
    const survivalContext = PresidentPromiseContext(
      clubId: 'survivor',
      seasonIndex: 1,
      tier: LeagueTier.first,
      leagueSize: 16,
      expectedPosition: 15,
      openingCash: Money.fromUnits(15000000),
      openingDebt: Money.fromUnits(2000000),
    );

    final title = generator.generate(
      context: titleContext,
      careerSeed: 20260903,
      simulationVersion: 1,
    );
    final titleRepeat = generator.generate(
      context: titleContext,
      careerSeed: 20260903,
      simulationVersion: 1,
    );
    final promotion = generator.generate(
      context: promotionContext,
      careerSeed: 20260903,
      simulationVersion: 1,
    );
    final survival = generator.generate(
      context: survivalContext,
      careerSeed: 20260903,
      simulationVersion: 1,
    );

    expect(title.type, PresidentPromiseType.challengeTitle);
    expect(title.signature, titleRepeat.signature);
    expect(promotion.type, PresidentPromiseType.earnPromotion);
    expect(survival.type, PresidentPromiseType.avoidRelegation);
  });

  test('M11 debt promise distinguishes fulfilled partial and broken outcomes', () {
    const resolver = PromiseResolver();
    const promise = PresidentPromise(
      id: 'debt',
      clubId: 'club',
      seasonIndex: 1,
      type: PresidentPromiseType.reduceDebt,
      targetDebtReductionBps: 1000,
    );

    PromiseResolution resolve(int closingDebtUnits) => resolver.resolve(
          promise: promise,
          outcome: PresidentPromiseOutcome(
            clubId: 'club',
            seasonIndex: 1,
            leaguePosition: 8,
            leagueSize: 16,
            openingDebt: const Money.fromUnits(100000000),
            closingDebt: Money.fromUnits(closingDebtUnits),
            emergencyBorrowing: Money.zero,
            promoted: false,
            relegated: false,
          ),
        );

    final fulfilled = resolve(85000000);
    final partial = resolve(95000000);
    final broken = resolve(110000000);

    expect(fulfilled.status, PromiseStatus.fulfilled);
    expect(fulfilled.reason, PromiseResolutionReason.debtTargetMet);
    expect(fulfilled.score, 100);
    expect(partial.status, PromiseStatus.partial);
    expect(partial.reason, PromiseResolutionReason.debtReduced);
    expect(partial.score, 50);
    expect(broken.status, PromiseStatus.broken);
    expect(broken.reason, PromiseResolutionReason.debtNotReduced);
    expect(broken.score, 0);
  });

  test('M11 sporting promises support meaningful partial outcomes', () {
    const resolver = PromiseResolver();
    const promotionPromise = PresidentPromise(
      id: 'promotion',
      clubId: 'club',
      seasonIndex: 1,
      type: PresidentPromiseType.earnPromotion,
      targetLeaguePosition: 3,
    );
    const titlePromise = PresidentPromise(
      id: 'title',
      clubId: 'club',
      seasonIndex: 1,
      type: PresidentPromiseType.challengeTitle,
      targetLeaguePosition: 1,
    );
    const nearOutcome = PresidentPromiseOutcome(
      clubId: 'club',
      seasonIndex: 1,
      leaguePosition: 4,
      leagueSize: 16,
      openingDebt: Money.zero,
      closingDebt: Money.zero,
      emergencyBorrowing: Money.zero,
      promoted: false,
      relegated: false,
    );
    const podiumOutcome = PresidentPromiseOutcome(
      clubId: 'club',
      seasonIndex: 1,
      leaguePosition: 2,
      leagueSize: 16,
      openingDebt: Money.zero,
      closingDebt: Money.zero,
      emergencyBorrowing: Money.zero,
      promoted: false,
      relegated: false,
    );

    expect(
      resolver.resolve(promise: promotionPromise, outcome: nearOutcome).status,
      PromiseStatus.partial,
    );
    expect(
      resolver.resolve(promise: titlePromise, outcome: podiumOutcome).status,
      PromiseStatus.partial,
    );
  });

  test('M11 simulates a valid 20-season measurable promise history', () {
    final world = const FictionalWorldFactory().build();
    final report = const PromiseCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PromiseCareerValidator().validate(report);
    final types = report.typeDistribution;

    print(
      'M11_BALANCE promises=${report.totalPromises} '
      'fulfilled=${report.fulfilledPromises} '
      'partial=${report.partialPromises} '
      'broken=${report.brokenPromises} '
      'avg=${report.averageScore.toStringAsFixed(2)} '
      'financial=${report.financialPromises} '
      'sporting=${report.sportingPromises} '
      'types=$types',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.totalPromises, 960);
    expect(types.length, PresidentPromiseType.values.length);
    expect(report.financialPromises, inInclusiveRange(60, 200));
    expect(report.sportingPromises, inInclusiveRange(760, 900));
    expect(report.fulfilledPromises, inInclusiveRange(300, 600));
    expect(report.partialPromises, inInclusiveRange(100, 300));
    expect(report.brokenPromises, inInclusiveRange(250, 500));
    expect(report.averageScore, inInclusiveRange(45, 65));
    expect(
      types[PresidentPromiseType.challengeTitle],
      inInclusiveRange(30, 100),
    );
    expect(
      types[PresidentPromiseType.finishTopHalf],
      inInclusiveRange(250, 500),
    );
    expect(
      types[PresidentPromiseType.avoidRelegation],
      inInclusiveRange(150, 300),
    );
    expect(
      types[PresidentPromiseType.earnPromotion],
      inInclusiveRange(120, 250),
    );
    expect(
      types[PresidentPromiseType.reduceDebt],
      inInclusiveRange(30, 120),
    );
    expect(
      types[PresidentPromiseType.stabilizeFinances],
      inInclusiveRange(20, 100),
    );
  });

  test('M11 is deterministic and observational over advanced transfer world', () {
    final world = const FictionalWorldFactory().build();
    const engine = PromiseCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 11101),
      seasonCount: 4,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 11101),
      seasonCount: 4,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 11102),
      seasonCount: 4,
    );
    final advancedOnly = const AdvancedTransferWorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 11101),
      seasonCount: 4,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(first.advancedTransferReport.signature, advancedOnly.signature);
  });
}
