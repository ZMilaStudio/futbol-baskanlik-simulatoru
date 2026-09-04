import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M23 risk appetite maps monotonically to negotiation bid ceiling', () {
    const policy = PresidentRiskAppetiteNegotiationPolicy();
    final low = policy.forRiskAppetite(20);
    final neutral = policy.forRiskAppetite(60);
    final high = policy.forRiskAppetite(90);

    expect(low.maxBidAdjustmentBps, -800);
    expect(neutral.maxBidAdjustmentBps, 0);
    expect(high.maxBidAdjustmentBps, 600);
    expect(
      neutral.maxBidAdjustmentBps,
      TransferNegotiationPolicy.neutral.maxBidAdjustmentBps,
    );
    expect(low.maxBidAdjustmentBps, lessThan(neutral.maxBidAdjustmentBps));
    expect(high.maxBidAdjustmentBps, greaterThan(neutral.maxBidAdjustmentBps));
  });

  test('M23 neutral negotiation provider preserves the old advanced world', () {
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
          negotiationPolicyProvider: (_, __) => TransferNegotiationPolicy.neutral,
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

  test('M23 closes risk appetite into the M21 feedback world', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentRiskAppetiteFeedbackEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      maxIterations: 8,
    );
    final issues = const PresidentRiskAppetiteFeedbackValidator().validate(report);

    print(
      'M23_BALANCE iterations=${report.iterationCount} '
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
    print('M23_ITERATIONS $iterationSummary');

    expect(issues, isEmpty);
    expect(report.converged, isTrue);
    expect(report.cycleDetected, isFalse);
    expect(report.iterationCount, inInclusiveRange(1, 8));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 150);
    expect(report.baselineLosses, 90);
    expect(report.baselineManagerChanges, 80);
    expect(report.baselineTransfers, 161);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);
    expect(report.finalTransfers, inInclusiveRange(120, 210));
    expect(report.finalManagerChanges, inInclusiveRange(60, 110));
    expect(report.finalTransferVolume.minorUnits, greaterThan(0));
    expect(report.finalInstallmentCommitment.minorUnits, greaterThanOrEqualTo(0));
    expect(report.finalCash.minorUnits, greaterThanOrEqualTo(0));
    expect(report.finalDebt.minorUnits, greaterThanOrEqualTo(0));
    expect(report.uniqueFinalPresidents, inInclusiveRange(100, 160));
    expect(report.worldChanged, isTrue);
  }, tags: 'canonical-feedback');
}
