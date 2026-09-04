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

    expect(impatient.boardBreakdownRelationship, greaterThan(neutral.boardBreakdownRelationship));
    expect(patient.boardBreakdownRelationship, lessThan(neutral.boardBreakdownRelationship));
    expect(impatient.underperformanceGap, 4);
    expect(patient.underperformanceGap, 6);
    expect(impatient.underperformanceRelationship, greaterThan(neutral.underperformanceRelationship));
    expect(patient.underperformanceRelationship, lessThan(neutral.underperformanceRelationship));
    expect(impatient.relegationRelationship, greaterThan(neutral.relegationRelationship));
    expect(patient.relegationRelationship, lessThan(neutral.relegationRelationship));
  });

  test('M18 applies president patience to real manager decisions and world state', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentManagerPatienceCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PresidentManagerPatienceCareerValidator().validate(report);

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
      'baselineTransfers=${report.baselineAdvancedReport.worldReport.totalTransfers} '
      'influencedTransfers=${report.influencedAdvancedReport.worldReport.totalTransfers}',
    );

    expect(issues, isEmpty);
    expect(report.sourceReport.sourceReport.totalElections, 240);
    expect(report.sourceReport.sourceReport.reelections, 161);
    expect(report.sourceReport.sourceReport.losses, 79);
    expect(report.sourceReport.totalProfiles, 127);
    expect(report.decisions.length, 960);
    expect(report.influencedManagerReport.seasonCount, 20);
    expect(report.influencedManagerReport.worldReport.totalMatches, 14400);
    expect(report.decisionDifferences, inInclusiveRange(1, 300));
    expect(report.managerIdentityDifferences, inInclusiveRange(1, 900));
    expect(report.finalAssignmentDifferences, inInclusiveRange(1, 48));
    expect(report.lowPatienceClubSeasons, greaterThan(50));
    expect(report.highPatienceClubSeasons, greaterThan(50));
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
