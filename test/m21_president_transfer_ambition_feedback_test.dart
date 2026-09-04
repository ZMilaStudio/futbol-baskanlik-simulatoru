import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M21 transfer ambition maps monotonically to activity slots', () {
    const policy = PresidentTransferAmbitionActivityPolicy();
    final low = policy.forAmbition(20);
    final neutral = policy.forAmbition(60);
    final high = policy.forAmbition(90);

    expect(low.maxDealsPerWindow, 1);
    expect(neutral.maxDealsPerWindow, 2);
    expect(high.maxDealsPerWindow, 3);
    expect(
      neutral.maxDealsPerWindow,
      TransferActivityPolicy.neutral.maxDealsPerWindow,
    );
    expect(low.maxDealsPerWindow, lessThan(neutral.maxDealsPerWindow));
    expect(high.maxDealsPerWindow, greaterThan(neutral.maxDealsPerWindow));
  });

  test('M21 neutral activity provider preserves the old advanced world', () {
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
          activityPolicyProvider: (_, __) => TransferActivityPolicy.neutral,
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

  test('M21 closes transfer ambition into the M20 feedback world', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentTransferAmbitionFeedbackEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      maxIterations: 8,
    );
    final issues =
        const PresidentTransferAmbitionFeedbackValidator().validate(report);

    print(
      'M21_BALANCE iterations=${report.iterationCount} '
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
    final iterationSummary = report.iterations
        .map(
          (item) => 'i${item.iteration}['
              'changed=${item.timelineChanged},manager=${item.managerChanges},'
              'transfers=${item.transfers},volume=${item.transferVolume},'
              'installments=${item.installmentDeals},'
              'cash=${item.finalCash},debt=${item.finalDebt},'
              'reelected=${item.reelections},lost=${item.losses},'
              'electionDiff=${item.electionOutcomeDifferences}]',
        )
        .join(' ');
    print('M21_ITERATIONS $iterationSummary');

    expect(issues, isEmpty);
    expect(report.converged, isTrue);
    expect(report.cycleDetected, isFalse);
    expect(report.iterationCount, inInclusiveRange(3, 6));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 158);
    expect(report.baselineLosses, 82);
    expect(report.baselineManagerChanges, 83);
    expect(report.baselineTransfers, 153);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);

    expect(report.electionOutcomeDifferences, inInclusiveRange(25, 80));
    expect(report.finalReelections, inInclusiveRange(135, 165));
    expect(report.finalLosses, inInclusiveRange(75, 105));
    expect(report.finalManagerChanges, inInclusiveRange(70, 95));
    expect(report.managerChangeDelta.abs(), lessThanOrEqualTo(20));

    expect(report.finalTransfers, inInclusiveRange(140, 185));
    expect(report.transferDelta.abs(), inInclusiveRange(5, 35));
    expect(
      report.finalTransferVolume,
      greaterThanOrEqualTo(const Money.fromUnits(1200000000)),
    );
    expect(
      report.finalTransferVolume,
      lessThanOrEqualTo(const Money.fromUnits(1700000000)),
    );
    expect(
      report.transferVolumeDelta.minorUnits.abs(),
      lessThanOrEqualTo(const Money.fromUnits(300000000).minorUnits),
    );

    expect(report.finalInstallmentDeals, inInclusiveRange(55, 95));
    expect(
      report.finalInstallmentCommitment,
      greaterThanOrEqualTo(const Money.fromUnits(180000000)),
    );
    expect(
      report.finalInstallmentCommitment,
      lessThanOrEqualTo(const Money.fromUnits(330000000)),
    );
    expect(
      report.finalCash,
      greaterThanOrEqualTo(const Money.fromUnits(1000000000)),
    );
    expect(
      report.finalCash,
      lessThanOrEqualTo(const Money.fromUnits(1400000000)),
    );
    expect(
      report.finalDebt,
      greaterThanOrEqualTo(const Money.fromUnits(250000000)),
    );
    expect(
      report.finalDebt,
      lessThanOrEqualTo(const Money.fromUnits(430000000)),
    );
    expect(
      report.finalEmergencyBorrowing,
      greaterThanOrEqualTo(const Money.fromUnits(80000000)),
    );
    expect(
      report.finalEmergencyBorrowing,
      lessThanOrEqualTo(const Money.fromUnits(200000000)),
    );
    expect(report.uniqueFinalPresidents, inInclusiveRange(120, 150));
    expect(report.worldChanged, isTrue);
  });
}
