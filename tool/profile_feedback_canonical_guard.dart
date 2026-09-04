import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

class ProfileFeedbackCanonicalGuard {
  const ProfileFeedbackCanonicalGuard._();

  static List<String> m19Issues(
    PresidentManagerElectionFeedbackReport report,
  ) {
    final issues = <String>[
      ...const PresidentManagerElectionFeedbackValidator().validate(report),
    ];

    void require(bool condition, String message) {
      if (!condition) issues.add('M19 canonical: $message');
    }

    require(report.baselineReport.careerSeed == 20260903, 'seed changed.');
    require(report.iterationCount >= 2 && report.iterationCount <= 6,
        'iteration count outside 2..6.');
    require(report.finalReport.totalElections == 240, 'election count changed.');
    require(report.baselineReelections == 161, 'baseline reelections changed.');
    require(report.baselineLosses == 79, 'baseline losses changed.');
    require(report.baselineManagerChanges == 81, 'baseline manager count changed.');
    require(report.baselineTransfers == 173, 'baseline transfer count changed.');
    require(report.iterations.first.managerChanges == 88,
        'first feedback manager count changed.');
    require(report.iterations.first.transfers == 153,
        'first feedback transfer count changed.');
    require(!report.iterations.last.timelineChanged,
        'final timeline must be stable.');
    require(report.iterations.last.electionOutcomeDifferences == 0,
        'final election difference must be zero.');
    require(report.electionOutcomeDifferences >= 25 &&
        report.electionOutcomeDifferences <= 90,
        'election difference outside 25..90.');
    require(report.finalReelections >= 140 && report.finalReelections <= 175,
        'final reelections outside 140..175.');
    require(report.finalLosses >= 65 && report.finalLosses <= 100,
        'final losses outside 65..100.');
    require(report.finalManagerChanges >= 75 && report.finalManagerChanges <= 100,
        'final manager changes outside 75..100.');
    require(report.managerChangeDelta.abs() <= 25,
        'manager delta magnitude exceeds 25.');
    require(report.finalTransfers >= 130 && report.finalTransfers <= 210,
        'final transfers outside 130..210.');
    require(report.transferDelta.abs() <= 60,
        'transfer delta magnitude exceeds 60.');
    require(report.uniqueFinalPresidents >= 110 &&
        report.uniqueFinalPresidents <= 145,
        'unique presidents outside 110..145.');
    require(report.worldChanged, 'world must change.');

    return issues;
  }

  static List<String> m20Issues(
    PresidentFinancialDisciplineFeedbackReport report,
  ) {
    final issues = <String>[
      ...const PresidentFinancialDisciplineFeedbackValidator().validate(report),
    ];

    void require(bool condition, String message) {
      if (!condition) issues.add('M20 canonical: $message');
    }

    require(report.baselineReport.careerSeed == 20260903, 'seed changed.');
    require(report.iterationCount >= 3 && report.iterationCount <= 7,
        'iteration count outside 3..7.');
    require(report.finalReport.totalElections == 240, 'election count changed.');
    require(report.baselineReelections == 160, 'baseline reelections changed.');
    require(report.baselineLosses == 80, 'baseline losses changed.');
    require(report.baselineManagerChanges == 84, 'baseline manager count changed.');
    require(report.baselineTransfers == 168, 'baseline transfer count changed.');
    require(!report.iterations.last.timelineChanged,
        'final timeline must be stable.');
    require(report.iterations.last.electionOutcomeDifferences == 0,
        'final election difference must be zero.');
    require(report.electionOutcomeDifferences >= 25 &&
        report.electionOutcomeDifferences <= 90,
        'election difference outside 25..90.');
    require(report.finalReelections >= 140 && report.finalReelections <= 175,
        'final reelections outside 140..175.');
    require(report.finalLosses >= 65 && report.finalLosses <= 100,
        'final losses outside 65..100.');
    require(report.finalManagerChanges >= 70 && report.finalManagerChanges <= 105,
        'final manager changes outside 70..105.');
    require(report.managerChangeDelta.abs() <= 25,
        'manager delta magnitude exceeds 25.');
    require(report.finalTransfers >= 130 && report.finalTransfers <= 190,
        'final transfers outside 130..190.');
    require(report.transferDelta.abs() <= 50,
        'transfer delta magnitude exceeds 50.');
    require(_moneyBetween(report.finalTransferVolume, 1100000000, 1700000000),
        'transfer volume outside 1.10B..1.70B.');
    require(report.transferVolumeDelta.minorUnits.abs() <=
        const Money.fromUnits(400000000).minorUnits,
        'transfer volume delta exceeds 400M.');
    require(report.finalInstallmentDeals >= 60 && report.finalInstallmentDeals <= 100,
        'installment deals outside 60..100.');
    require(_moneyBetween(report.finalInstallmentCommitment, 200000000, 360000000),
        'installment commitment outside 200M..360M.');
    require(_moneyBetween(report.finalCash, 900000000, 1500000000),
        'final cash outside 900M..1.50B.');
    require(_moneyBetween(report.finalDebt, 250000000, 500000000),
        'final debt outside 250M..500M.');
    require(_moneyBetween(report.finalEmergencyBorrowing, 80000000, 250000000),
        'emergency borrowing outside 80M..250M.');
    require(report.uniqueFinalPresidents >= 110 &&
        report.uniqueFinalPresidents <= 145,
        'unique presidents outside 110..145.');
    require(report.worldChanged, 'world must change.');

    return issues;
  }

  static List<String> m21Issues(
    PresidentTransferAmbitionFeedbackReport report,
  ) {
    final issues = <String>[
      ...const PresidentTransferAmbitionFeedbackValidator().validate(report),
    ];

    void require(bool condition, String message) {
      if (!condition) issues.add('M21 canonical: $message');
    }

    require(report.baselineReport.careerSeed == 20260903, 'seed changed.');
    require(report.iterationCount >= 3 && report.iterationCount <= 6,
        'iteration count outside 3..6.');
    require(report.finalReport.totalElections == 240, 'election count changed.');
    require(report.baselineReelections == 158, 'baseline reelections changed.');
    require(report.baselineLosses == 82, 'baseline losses changed.');
    require(report.baselineManagerChanges == 83, 'baseline manager count changed.');
    require(report.baselineTransfers == 153, 'baseline transfer count changed.');
    require(!report.iterations.last.timelineChanged,
        'final timeline must be stable.');
    require(report.iterations.last.electionOutcomeDifferences == 0,
        'final election difference must be zero.');
    require(report.electionOutcomeDifferences >= 25 &&
        report.electionOutcomeDifferences <= 80,
        'election difference outside 25..80.');
    require(report.finalReelections >= 135 && report.finalReelections <= 165,
        'final reelections outside 135..165.');
    require(report.finalLosses >= 75 && report.finalLosses <= 105,
        'final losses outside 75..105.');
    require(report.finalManagerChanges >= 70 && report.finalManagerChanges <= 95,
        'final manager changes outside 70..95.');
    require(report.managerChangeDelta.abs() <= 20,
        'manager delta magnitude exceeds 20.');
    require(report.finalTransfers >= 140 && report.finalTransfers <= 185,
        'final transfers outside 140..185.');
    require(report.transferDelta.abs() >= 5 && report.transferDelta.abs() <= 35,
        'transfer delta magnitude outside 5..35.');
    require(_moneyBetween(report.finalTransferVolume, 1200000000, 1700000000),
        'transfer volume outside 1.20B..1.70B.');
    require(report.transferVolumeDelta.minorUnits.abs() <=
        const Money.fromUnits(300000000).minorUnits,
        'transfer volume delta exceeds 300M.');
    require(report.finalInstallmentDeals >= 55 && report.finalInstallmentDeals <= 95,
        'installment deals outside 55..95.');
    require(_moneyBetween(report.finalInstallmentCommitment, 180000000, 330000000),
        'installment commitment outside 180M..330M.');
    require(_moneyBetween(report.finalCash, 1000000000, 1400000000),
        'final cash outside 1.00B..1.40B.');
    require(_moneyBetween(report.finalDebt, 250000000, 430000000),
        'final debt outside 250M..430M.');
    require(_moneyBetween(report.finalEmergencyBorrowing, 80000000, 200000000),
        'emergency borrowing outside 80M..200M.');
    require(report.uniqueFinalPresidents >= 120 &&
        report.uniqueFinalPresidents <= 150,
        'unique presidents outside 120..150.');
    require(report.worldChanged, 'world must change.');

    return issues;
  }

  static bool _moneyBetween(Money value, int minUnits, int maxUnits) {
    final min = Money.fromUnits(minUnits).minorUnits;
    final max = Money.fromUnits(maxUnits).minorUnits;
    return value.minorUnits >= min && value.minorUnits <= max;
  }
}
