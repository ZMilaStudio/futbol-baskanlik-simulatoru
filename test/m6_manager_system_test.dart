import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M6 manager pool is deterministic and profile-diverse', () {
    const generator = ManagerPoolGenerator();
    final first = generator.generate(
      careerSeed: 20260903,
      simulationVersion: 1,
    );
    final repeat = generator.generate(
      careerSeed: 20260903,
      simulationVersion: 1,
    );
    final different = generator.generate(
      careerSeed: 20260904,
      simulationVersion: 1,
    );

    expect(first.length, 96);
    expect(first.map((manager) => manager.id).toSet().length, 96);
    expect(
      first.map((manager) => manager.signature).toList(),
      repeat.map((manager) => manager.signature).toList(),
    );
    expect(
      first.map((manager) => manager.signature).join('|'),
      isNot(equals(different.map((manager) => manager.signature).join('|'))),
    );
    expect(
      first.map((manager) => manager.profile).toSet().length,
      greaterThanOrEqualTo(4),
    );
  });

  test('M6 simulates a valid 20-season manager career', () {
    final world = const FictionalWorldFactory().build();
    final report = const ManagerWorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const ManagerCareerValidator().validate(report);

    print(
      'M6_BALANCE changes=${report.totalManagerChanges} '
      'dismissals=${report.totalDismissals} '
      'retirements=${report.totalRetirements} '
      'unique=${report.uniqueManagersUsed} '
      'impact=${report.averageStrengthImpact.toStringAsFixed(3)} '
      'relationship=${report.averageFinalRelationship.toStringAsFixed(2)} '
      'transfers=${report.worldReport.totalTransfers} '
      'cash=${report.worldReport.finalTotalCash} '
      'debt=${report.worldReport.finalTotalDebt}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.worldReport.totalMatches, 14400);
    expect(report.managers.length, 96);
    expect(report.finalAssignments.length, 48);
    expect(report.seasons.every((season) => season.clubs.length == 48), isTrue);
    expect(report.totalManagerChanges, greaterThanOrEqualTo(1));
    expect(report.totalManagerChanges, lessThanOrEqualTo(300));
    expect(report.uniqueManagersUsed, greaterThanOrEqualTo(49));
    expect(report.uniqueManagersUsed, lessThanOrEqualTo(96));
    expect(report.averageStrengthImpact, greaterThan(-1.5));
    expect(report.averageStrengthImpact, lessThan(1.8));
    expect(report.averageFinalRelationship, greaterThan(15));
    expect(report.averageFinalRelationship, lessThan(95));
    expect(report.worldReport.totalTransfers, greaterThanOrEqualTo(30));
    expect(report.worldReport.totalTransfers, lessThanOrEqualTo(700));
    expect(
      report.worldReport.finalTotalCash,
      greaterThanOrEqualTo(const Money.fromUnits(100000000)),
    );
    expect(
      report.worldReport.finalTotalCash,
      lessThan(const Money.fromUnits(2000000000)),
    );
    expect(report.worldReport.finalTotalDebt, greaterThan(Money.zero));
    expect(
      report.worldReport.finalTotalDebt,
      lessThan(const Money.fromUnits(2000000000)),
    );
  });

  test('M6 is deterministic and manager effects alter the world', () {
    final world = const FictionalWorldFactory().build();
    const managerEngine = ManagerWorldCareerEngine();
    final first = managerEngine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 6101),
      seasonCount: 3,
    );
    final repeat = managerEngine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 6101),
      seasonCount: 3,
    );
    final different = managerEngine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 6102),
      seasonCount: 3,
    );
    final withoutManagers = const WorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 6101),
      seasonCount: 3,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(first.worldReport.signature, isNot(equals(withoutManagers.signature)));
  });
}
