import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M12 promise impact is type and outcome sensitive', () {
    const engine = PromiseFanImpactEngine();

    const titlePromise = PresidentPromise(
      id: 'title',
      clubId: 'club',
      seasonIndex: 1,
      type: PresidentPromiseType.challengeTitle,
      targetLeaguePosition: 1,
    );
    const survivalPromise = PresidentPromise(
      id: 'survival',
      clubId: 'club',
      seasonIndex: 1,
      type: PresidentPromiseType.avoidRelegation,
    );
    const debtPromise = PresidentPromise(
      id: 'debt',
      clubId: 'club',
      seasonIndex: 1,
      type: PresidentPromiseType.reduceDebt,
      targetDebtReductionBps: 800,
    );

    final titleKept = engine.evaluate(const PromiseResolution(
      promise: titlePromise,
      status: PromiseStatus.fulfilled,
      reason: PromiseResolutionReason.champion,
      score: 100,
    ));
    final relegated = engine.evaluate(const PromiseResolution(
      promise: survivalPromise,
      status: PromiseStatus.broken,
      reason: PromiseResolutionReason.relegated,
      score: 0,
    ));
    final debtPartial = engine.evaluate(const PromiseResolution(
      promise: debtPromise,
      status: PromiseStatus.partial,
      reason: PromiseResolutionReason.debtReduced,
      score: 50,
    ));

    expect(titleKept, hasLength(1));
    expect(titleKept.single.dimension, FanTrustDimension.identity);
    expect(titleKept.single.delta, 3);
    expect(titleKept.single.code, 'promise_fulfilled_challengeTitle');

    expect(relegated, hasLength(1));
    expect(relegated.single.dimension, FanTrustDimension.identity);
    expect(relegated.single.delta, -4);

    expect(debtPartial, hasLength(2));
    expect(
      debtPartial.where((reason) => reason.dimension == FanTrustDimension.identity).single.delta,
      1,
    );
    expect(
      debtPartial.where((reason) => reason.dimension == FanTrustDimension.financial).single.delta,
      1,
    );
  });

  test('M12 simulates one shared world with promise-driven fan identity trust', () {
    final world = const FictionalWorldFactory().build();
    final report = const PromiseFanCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PromiseFanCareerValidator().validate(report);

    print(
      'M12_BALANCE promises=${report.promiseReport.totalPromises} '
      'promiseReasons=${report.promiseReasonCount} '
      'identityReasons=${report.promiseIdentityReasons} '
      'financialReasons=${report.promiseFinancialReasons} '
      'positive=${report.positivePromiseReasons} '
      'negative=${report.negativePromiseReasons} '
      'baselineTrust=${report.baselineFanReport.averageFinalTrust.toStringAsFixed(2)} '
      'finalTrust=${report.fanReport.averageFinalTrust.toStringAsFixed(2)} '
      'overallDelta=${report.averageFinalOverallTrustDelta.toStringAsFixed(2)} '
      'identity=${report.averageFinalIdentityTrust.toStringAsFixed(2)} '
      'identityRange=${report.minimumFinalIdentityTrust}..${report.maximumFinalIdentityTrust} '
      'identityDelta=${report.averageFinalIdentityTrustDelta.toStringAsFixed(2)}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.promiseReport.totalPromises, 960);
    expect(report.promiseIdentityReasons, 960);
    expect(report.promiseFinancialReasons, report.promiseReport.financialPromises);
    expect(
      report.promiseReasonCount,
      report.promiseReport.totalPromises + report.promiseReport.financialPromises,
    );
    expect(report.positivePromiseReasons, greaterThan(300));
    expect(report.negativePromiseReasons, greaterThan(250));
    expect(report.baselineFanReport.averageFinalTrust, inInclusiveRange(50, 75));
    expect(report.fanReport.averageFinalTrust, inInclusiveRange(45, 80));
    expect(report.averageFinalOverallTrustDelta, inInclusiveRange(-5, 5));
    expect(report.averageFinalIdentityTrust, inInclusiveRange(40, 80));
    expect(report.minimumFinalIdentityTrust, inInclusiveRange(20, 65));
    expect(report.maximumFinalIdentityTrust, inInclusiveRange(60, 95));
    expect(report.averageFinalIdentityTrustDelta, inInclusiveRange(-10, 15));
  });

  test('M12 is deterministic and does not resimulate different worlds per layer', () {
    final world = const FictionalWorldFactory().build();
    const engine = PromiseFanCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 12101),
      seasonCount: 4,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 12101),
      seasonCount: 4,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 12102),
      seasonCount: 4,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(
      first.promiseReport.advancedTransferReport.signature,
      first.baselineFanReport.advancedTransferReport.signature,
    );
    expect(
      first.promiseReport.advancedTransferReport.signature,
      first.fanReport.advancedTransferReport.signature,
    );
    expect(first.baselineFanReport.signature, isNot(equals(first.fanReport.signature)));
  });
}
