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
    expect(report.iterationCount, inInclusiveRange(1, 8));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 160);
    expect(report.baselineLosses, 80);
    expect(report.baselineManagerChanges, 84);
    expect(report.baselineTransfers, 168);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);
  });
}
