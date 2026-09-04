import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M18 manager patience produces monotonic dismissal thresholds', () {
    const policy = ManagerDismissalPolicy();
    final impatient = policy.thresholds(20);
    final neutral = policy.thresholds(60);
    final patient = policy.thresholds(90);

    expect(neutral.boardBreakdownRelationship, 28);
    expect(neutral.underperformanceGap, 5);
    expect(neutral.underperformanceRelationship, 46);
    expect(neutral.relegationRelationship, 52);

    expect(
      impatient.boardBreakdownRelationship,
      greaterThan(neutral.boardBreakdownRelationship),
    );
    expect(
      patient.boardBreakdownRelationship,
      lessThan(neutral.boardBreakdownRelationship),
    );
    expect(impatient.underperformanceGap, 4);
    expect(patient.underperformanceGap, 6);
    expect(
      impatient.underperformanceRelationship,
      greaterThan(neutral.underperformanceRelationship),
    );
    expect(
      patient.underperformanceRelationship,
      lessThan(neutral.underperformanceRelationship),
    );
    expect(
      impatient.relegationRelationship,
      greaterThan(neutral.relegationRelationship),
    );
    expect(
      patient.relegationRelationship,
      lessThan(neutral.relegationRelationship),
    );
  });

  test('M18 applies president patience to real manager decisions and world state', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentManagerPatienceCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PresidentManagerPatienceCareerValidator().validate(report);
    final baselineTransfers =
        report.baselineAdvancedReport.worldReport.totalTransfers;
    final influencedTransfers =
        report.influencedAdvancedReport.worldReport.totalTransfers;

    print(
      'M18_BALANCE baselineChanges=${report.baselineManagerChanges} '
      'influencedChanges=${report.influencedManagerChanges} '
      'delta=${report.managerChangeDelta} '
      'decisionDiff=${report.decisionDifferences} '
      'managerIdentityDiff=${report.managerIdentityDifferences} '
      'finalAssignmentDiff=${report.finalAssignmentDifferences} '
      'lowSeasons=${report.lowPatienceClubSeasons} '
      'highSeasons=${report.highPatienceClubSeasons} '
      'lowDismissalRate=${report.lowPatienceDismissalRate.toStringAsFixed(3)} '
      'highDismissalRate=${report.highPatienceDismissalRate.toStringAsFixed(3)} '
      'dismissalPatience=${report.averageDismissalPatience.toStringAsFixed(2)} '
      'retainedPatience=${report.averageRetainedPatience.toStringAsFixed(2)} '
      'reasons=${report.changeReasons} '
      'baselineTransfers=$baselineTransfers '
      'influencedTransfers=$influencedTransfers',
    );

    expect(issues, isEmpty);

    // M17 remains the canonical exogenous president timeline for M18.
    expect(report.sourceReport.sourceReport.totalElections, 240);
    expect(report.sourceReport.sourceReport.reelections, 161);
    expect(report.sourceReport.sourceReport.losses, 79);
    expect(report.sourceReport.totalProfiles, 127);

    expect(report.decisions.length, 960);
    expect(report.influencedManagerReport.seasonCount, 20);
    expect(report.influencedManagerReport.worldReport.totalMatches, 14400);

    // Canonical M13 advanced-world manager baseline remains untouched.
    expect(report.baselineManagerChanges, 81);
    expect(baselineTransfers, 173);

    // Accepted M18 V1 balance envelope: material, but not hyperactive.
    expect(report.influencedManagerChanges, inInclusiveRange(80, 100));
    expect(report.managerChangeDelta, inInclusiveRange(-5, 20));
    expect(report.decisionDifferences, inInclusiveRange(60, 130));
    expect(report.managerIdentityDifferences, inInclusiveRange(300, 600));
    expect(report.finalAssignmentDifferences, inInclusiveRange(25, 45));

    // Both patience regimes must have substantial samples.
    expect(report.lowPatienceClubSeasons, inInclusiveRange(180, 280));
    expect(report.highPatienceClubSeasons, inInclusiveRange(250, 360));

    // Patience must visibly change dismissal culture.
    expect(report.lowPatienceDismissalRate, inInclusiveRange(0.10, 0.22));
    expect(report.highPatienceDismissalRate, inInclusiveRange(0.03, 0.10));
    expect(
      report.lowPatienceDismissalRate - report.highPatienceDismissalRate,
      greaterThanOrEqualTo(0.05),
    );
    expect(report.averageDismissalPatience, inInclusiveRange(45, 56));
    expect(report.averageRetainedPatience, inInclusiveRange(57, 65));
    expect(
      report.averageDismissalPatience,
      lessThan(report.averageRetainedPatience),
    );

    expect(
      report.changeReasons[ManagerChangeReason.performance] ?? 0,
      inInclusiveRange(45, 75),
    );
    expect(
      report.changeReasons[ManagerChangeReason.boardBreakdown] ?? 0,
      inInclusiveRange(15, 35),
    );
    expect(
      report.changeReasons[ManagerChangeReason.retirement] ?? 0,
      inInclusiveRange(1, 6),
    );

    // Manager-path divergence may alter transfer activity, but not destroy it.
    expect(influencedTransfers, inInclusiveRange(120, 200));
    expect((influencedTransfers - baselineTransfers).abs(), lessThanOrEqualTo(50));
    expect(report.worldChanged, isTrue);
  });

  test('M18 is deterministic and different seeds diverge', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentManagerPatienceCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 18001),
      seasonCount: 3,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 18001),
      seasonCount: 3,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 18002),
      seasonCount: 3,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
  });
}
