import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M13 promise media impact is outcome and difficulty sensitive', () {
    const engine = PromiseMediaImpactEngine();
    const state = MediaState(clubId: 'club', credibility: 65);

    PromiseMediaCredibilityChange change(
      PresidentPromiseType type,
      PromiseStatus status,
    ) =>
        engine.evaluate(
          state: state,
          resolution: PromiseResolution(
            promise: PresidentPromise(
              id: '${type.name}-${status.name}',
              clubId: 'club',
              seasonIndex: 1,
              type: type,
            ),
            status: status,
            // The impact engine consumes promise type + status. Use existing
            // M11 resolution reasons instead of inventing generic enum values.
            reason: status == PromiseStatus.fulfilled
                ? PromiseResolutionReason.topHalfMet
                : status == PromiseStatus.partial
                    ? PromiseResolutionReason.nearTopHalf
                    : PromiseResolutionReason.missedTopHalf,
            score: status == PromiseStatus.fulfilled
                ? 100
                : status == PromiseStatus.partial
                    ? 50
                    : 0,
          ),
        );

    expect(
      change(PresidentPromiseType.challengeTitle, PromiseStatus.fulfilled).delta,
      2,
    );
    expect(
      change(PresidentPromiseType.finishTopHalf, PromiseStatus.fulfilled).delta,
      1,
    );
    expect(
      change(PresidentPromiseType.finishTopHalf, PromiseStatus.partial).delta,
      0,
    );
    expect(
      change(PresidentPromiseType.avoidRelegation, PromiseStatus.broken).delta,
      -3,
    );
    expect(
      change(PresidentPromiseType.reduceDebt, PromiseStatus.broken).delta,
      -2,
    );
  });

  test('M13 runs manager advanced-transfer promise and media on one world', () {
    final world = const FictionalWorldFactory().build();
    final report = const PromiseMediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PromiseMediaCareerValidator().validate(report);

    print(
      'M13_BALANCE promises=${report.promiseChanges} '
      'positive=${report.positivePromiseChanges} '
      'neutral=${report.neutralPromiseChanges} '
      'negative=${report.negativePromiseChanges} '
      'statements=${report.baselineMediaReport.totalStatements} '
      'contradictions=${report.baselineMediaReport.totalContradictions} '
      'managerChanges=${report.managerReport.totalManagerChanges} '
      'baseline=${report.baselineMediaReport.averageFinalCredibility.toStringAsFixed(2)} '
      'final=${report.averageFinalCredibility.toStringAsFixed(2)} '
      'delta=${report.averageCredibilityDelta.toStringAsFixed(2)} '
      'range=${report.minimumFinalCredibility}..${report.maximumFinalCredibility} '
      'boundary=${report.boundaryClubs}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.promiseChanges, 960);
    expect(report.positivePromiseChanges, greaterThan(250));
    expect(report.neutralPromiseChanges, greaterThan(50));
    expect(report.negativePromiseChanges, greaterThan(200));
    expect(report.baselineMediaReport.averageFinalCredibility, inInclusiveRange(40, 90));
    expect(report.averageFinalCredibility, inInclusiveRange(30, 90));
    expect(report.averageCredibilityDelta, inInclusiveRange(-20, 10));
    expect(report.minimumFinalCredibility, inInclusiveRange(0, 70));
    expect(report.maximumFinalCredibility, inInclusiveRange(60, 100));
    expect(report.boundaryClubs, lessThanOrEqualTo(10));
  });

  test('M13 is deterministic and all reputation layers share the same world', () {
    final world = const FictionalWorldFactory().build();
    const engine = PromiseMediaCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 13101),
      seasonCount: 4,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 13101),
      seasonCount: 4,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 13102),
      seasonCount: 4,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(
      first.managerReport.worldReport.signature,
      first.advancedTransferReport.worldReport.signature,
    );
    expect(
      first.promiseReport.advancedTransferReport.signature,
      first.advancedTransferReport.signature,
    );
    expect(
      first.baselineMediaReport.managerReport.signature,
      first.managerReport.signature,
    );
  });
}
