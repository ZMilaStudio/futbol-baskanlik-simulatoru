import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/election/president_financial_discipline_feedback_engine.dart';
import 'package:futbol_baskanlik_m0/src/election/president_financial_discipline_feedback_validator.dart';
import 'package:futbol_baskanlik_m0/src/election/president_financial_discipline_transfer_policy.dart';
import 'package:futbol_baskanlik_m0/src/transfer/transfer_budget_policy.dart';
import 'package:test/test.dart';

void main() {
  test('M20 financial discipline produces monotonic transfer budget limits', () {
    const policy = PresidentFinancialDisciplineTransferPolicy();
    final loose = policy.forDiscipline(20);
    final neutral = policy.forDiscipline(60);
    final strict = policy.forDiscipline(90);

    expect(neutral.reserveCash, TransferBudgetPolicy.neutral.reserveCash);
    expect(
      neutral.windowSpendCapBps,
      TransferBudgetPolicy.neutral.windowSpendCapBps,
    );
    expect(
      neutral.totalCommitmentCapBps,
      TransferBudgetPolicy.neutral.totalCommitmentCapBps,
    );

    expect(loose.reserveCash.minorUnits, lessThan(neutral.reserveCash.minorUnits));
    expect(strict.reserveCash.minorUnits, greaterThan(neutral.reserveCash.minorUnits));
    expect(loose.windowSpendCapBps, greaterThan(neutral.windowSpendCapBps));
    expect(strict.windowSpendCapBps, lessThan(neutral.windowSpendCapBps));
    expect(
      loose.totalCommitmentCapBps,
      greaterThan(neutral.totalCommitmentCapBps),
    );
    expect(
      strict.totalCommitmentCapBps,
      lessThan(neutral.totalCommitmentCapBps),
    );
  });

  test('M20 neutral budget provider preserves the old advanced world', () {
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
          budgetPolicyProvider: (_, __) => TransferBudgetPolicy.neutral,
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

  test('M20 closes financial discipline into the M19 feedback world', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentFinancialDisciplineFeedbackEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      maxIterations: 8,
    );
    final issues =
        const PresidentFinancialDisciplineFeedbackValidator().validate(report);

    print(
      'M20_BALANCE iterations=${report.iterationCount} '
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
    print('M20_ITERATIONS $iterationSummary');

    expect(issues, isEmpty);
    expect(report.converged, isTrue);
    expect(report.cycleDetected, isFalse);
    expect(report.iterationCount, inInclusiveRange(3, 7));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 160);
    expect(report.baselineLosses, 80);
    expect(report.baselineManagerChanges, 84);
    expect(report.baselineTransfers, 168);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);
    expect(report.electionOutcomeDifferences, inInclusiveRange(25, 90));
    expect(report.finalReelections, inInclusiveRange(140, 175));
    expect(report.finalLosses, inInclusiveRange(65, 100));
    expect(report.finalManagerChanges, inInclusiveRange(70, 105));
    expect(report.managerChangeDelta.abs(), lessThanOrEqualTo(25));
    expect(report.finalTransfers, inInclusiveRange(130, 190));
    expect(report.transferDelta.abs(), lessThanOrEqualTo(50));
    expect(
      report.finalTransferVolume,
      inInclusiveRange(
        const Money.fromUnits(1100000000),
        const Money.fromUnits(1700000000),
      ),
    );
    expect(report.transferVolumeDelta.minorUnits.abs(), lessThanOrEqualTo(
      const Money.fromUnits(400000000).minorUnits,
    ));
    expect(report.finalInstallmentDeals, inInclusiveRange(60, 100));
    expect(
      report.finalInstallmentCommitment,
      inInclusiveRange(
        const Money.fromUnits(200000000),
        const Money.fromUnits(360000000),
      ),
    );
    expect(
      report.finalCash,
      inInclusiveRange(
        const Money.fromUnits(900000000),
        const Money.fromUnits(1500000000),
      ),
    );
    expect(
      report.finalDebt,
      inInclusiveRange(
        const Money.fromUnits(250000000),
        const Money.fromUnits(500000000),
      ),
    );
    expect(
      report.finalEmergencyBorrowing,
      inInclusiveRange(
        const Money.fromUnits(80000000),
        const Money.fromUnits(250000000),
      ),
    );
    expect(report.uniqueFinalPresidents, inInclusiveRange(110, 145));
    expect(report.worldChanged, isTrue);
  });
}
