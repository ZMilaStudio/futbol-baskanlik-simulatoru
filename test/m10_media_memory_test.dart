import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M10 credibility punishes backing a manager immediately before dismissal', () {
    const engine = MediaCredibilityEngine();
    const state = MediaState(clubId: 'club', credibility: 60);
    const backing = MediaStatement(
      id: 's1',
      clubId: 'club',
      targetManagerId: 'manager',
      seasonIndex: 1,
      topic: MediaTopic.managerFuture,
      stance: MediaStance.strongSupport,
    );
    const pressure = MediaStatement(
      id: 's2',
      clubId: 'club',
      targetManagerId: 'manager',
      seasonIndex: 1,
      topic: MediaTopic.managerFuture,
      stance: MediaStance.pressure,
    );

    final contradiction = engine.evaluate(
      state: state,
      statement: backing,
      managerChanged: true,
    );
    final consistent = engine.evaluate(
      state: state,
      statement: pressure,
      managerChanged: true,
    );
    final honoredBacking = engine.evaluate(
      state: state,
      statement: backing,
      managerChanged: false,
    );

    expect(contradiction.reason, MediaCredibilityReason.supportBroken);
    expect(contradiction.resolution, MediaResolution.contradiction);
    expect(contradiction.delta, -10);
    expect(contradiction.after, 50);

    expect(consistent.reason, MediaCredibilityReason.pressureFollowedByChange);
    expect(consistent.resolution, MediaResolution.consistent);
    expect(consistent.delta, 3);
    expect(consistent.after, 63);

    expect(honoredBacking.reason, MediaCredibilityReason.supportHonored);
    expect(honoredBacking.resolution, MediaResolution.consistent);
    expect(honoredBacking.delta, 2);
    expect(honoredBacking.after, 62);
  });

  test('M10 simulates a valid 20-season media memory', () {
    final world = const FictionalWorldFactory().build();
    final report = const MediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const MediaCareerValidator().validate(report);

    print(
      'M10_BALANCE statements=${report.totalStatements} '
      'contradictions=${report.totalContradictions} '
      'strongBroken=${report.strongSupportContradictions} '
      'consistent=${report.totalConsistentStatements} '
      'stances=${report.stanceDistribution} '
      'avg=${report.averageFinalCredibility.toStringAsFixed(2)} '
      'min=${report.minimumFinalCredibility} '
      'max=${report.maximumFinalCredibility} '
      'boundary=${report.boundaryClubs}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.seasons.every((season) => season.clubs.length == 48), isTrue);
    expect(report.finalStates.length, 48);
    expect(report.totalStatements, greaterThanOrEqualTo(300));
    expect(report.totalStatements, lessThanOrEqualTo(700));
    expect(report.totalContradictions, greaterThanOrEqualTo(10));
    expect(report.totalContradictions, lessThanOrEqualTo(80));
    expect(report.strongSupportContradictions, greaterThanOrEqualTo(3));
    expect(report.strongSupportContradictions, lessThanOrEqualTo(50));
    expect(report.totalConsistentStatements, greaterThanOrEqualTo(200));
    expect(report.totalConsistentStatements, lessThanOrEqualTo(550));
    expect(report.stanceDistribution.length, 4);
    expect(report.averageFinalCredibility, greaterThan(55));
    expect(report.averageFinalCredibility, lessThan(82));
    expect(report.minimumFinalCredibility, greaterThanOrEqualTo(25));
    expect(report.minimumFinalCredibility, lessThanOrEqualTo(60));
    expect(report.maximumFinalCredibility, greaterThanOrEqualTo(75));
    expect(report.maximumFinalCredibility, lessThanOrEqualTo(92));
    expect(report.boundaryClubs, lessThanOrEqualTo(2));
  });

  test('M10 is deterministic and observational over manager simulation', () {
    final world = const FictionalWorldFactory().build();
    const engine = MediaCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 10101),
      seasonCount: 4,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 10101),
      seasonCount: 4,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 10102),
      seasonCount: 4,
    );
    final managerOnly = const ManagerWorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 10101),
      seasonCount: 4,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(first.managerReport.signature, managerOnly.signature);
  });
}
