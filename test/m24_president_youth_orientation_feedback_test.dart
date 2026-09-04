import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M24 youth orientation scales youth preference monotonically', () {
    const policy = PresidentYouthOrientationTransferPolicy();
    final low = policy.forYouthOrientation(20);
    final neutral = policy.forYouthOrientation(60);
    final high = policy.forYouthOrientation(90);

    expect(low.youthSignalScaleBps, 6000);
    expect(neutral.youthSignalScaleBps, 10000);
    expect(high.youthSignalScaleBps, 13000);
    expect(
      neutral.youthSignalScaleBps,
      TransferYouthPreferencePolicy.neutral.youthSignalScaleBps,
    );
    expect(low.applyYouthSignal(10), lessThan(neutral.applyYouthSignal(10)));
    expect(high.applyYouthSignal(10), greaterThan(neutral.applyYouthSignal(10)));
  });

  test('M24 neutral youth preference preserves the old advanced world', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20260903);
    final baseline = const AdvancedTransferWorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
    );
    final neutral = AdvancedTransferWorldCareerEngine(
      worldEngine: WorldCareerEngine(
        transferMarketEngine: TransferMarketEngine(
          youthPreferencePolicyProvider: (_, __) =>
              TransferYouthPreferencePolicy.neutral,
        ),
      ),
    ).simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
    );

    expect(neutral.signature, baseline.signature);
  });

  test('M24 closes youth orientation into the M23 feedback world', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentYouthOrientationFeedbackEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      maxIterations: 8,
    );
    final issues =
        const PresidentYouthOrientationFeedbackValidator().validate(report);

    print(
      'M24_BALANCE iterations=${report.iterationCount} '
      'converged=${report.converged} cycle=${report.cycleDetected} '
      'elections=${report.finalReport.totalElections} '
      'reelected=${report.baselineReelections}->${report.finalReelections} '
      'lost=${report.baselineLosses}->${report.finalLosses} '
      'electionDiff=${report.electionOutcomeDifferences} '
      'managers=${report.baselineManagerChanges}->${report.finalManagerChanges} '
      'transfers=${report.baselineTransfers}->${report.finalTransfers} '
      'volume=${report.baselineTransferVolume}->${report.finalTransferVolume} '
      'installmentDeals=${report.baselineInstallmentDeals}->${report.finalInstallmentDeals} '
      'commitment=${report.baselineInstallmentCommitment}->${report.finalInstallmentCommitment} '
      'cash=${report.baselineFinalCash}->${report.finalCash} '
      'debt=${report.baselineFinalDebt}->${report.finalDebt} '
      'emergency=${report.baselineEmergencyBorrowing}->${report.finalEmergencyBorrowing} '
      'uniquePresidents=${report.uniqueFinalPresidents} '
      'worldChanged=${report.worldChanged}',
    );
    print(
      'M24_ITERATIONS ${report.iterations.map((item) => 'i${item.iteration}['
          'changed=${item.timelineChanged},manager=${item.managerChanges},'
          'transfers=${item.transfers},volume=${item.transferVolume},'
          'reelected=${item.reelections},lost=${item.losses},'
          'electionDiff=${item.electionOutcomeDifferences}]').join(' ')}',
    );

    expect(issues, isEmpty);
    expect(report.converged, isTrue);
    expect(report.cycleDetected, isFalse);
    expect(report.iterationCount, inInclusiveRange(1, 8));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 156);
    expect(report.baselineLosses, 84);
    expect(report.baselineManagerChanges, 85);
    expect(report.baselineTransfers, 133);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);
    expect(report.finalTransfers, inInclusiveRange(100, 180));
    expect(report.finalManagerChanges, inInclusiveRange(60, 110));
    expect(report.finalTransferVolume.minorUnits, greaterThan(0));
    expect(report.finalCash.minorUnits, greaterThanOrEqualTo(0));
    expect(report.finalDebt.minorUnits, greaterThanOrEqualTo(0));
    expect(report.uniqueFinalPresidents, inInclusiveRange(100, 170));
    expect(report.worldChanged, isTrue);
  }, tags: 'canonical-feedback');
}
