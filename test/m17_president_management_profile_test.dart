import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M17 management profile is deterministic, bounded, and president-specific', () {
    const presidentA = PresidentProfile(id: 'president_a', name: 'A A');
    const presidentB = PresidentProfile(id: 'president_b', name: 'B B');
    const generator = PresidentManagementProfileGenerator();

    final first = generator.generate(
      president: presidentA,
      careerSeed: 1701,
      simulationVersion: 1,
    );
    final repeat = generator.generate(
      president: presidentA,
      careerSeed: 1701,
      simulationVersion: 1,
    );
    final other = generator.generate(
      president: presidentB,
      careerSeed: 1701,
      simulationVersion: 1,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(other.signature)));
    expect(first.traits.every((value) => value >= 20 && value <= 90), isTrue);
  });

  test('M17 observes diverse management philosophies without changing M16 career', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentManagementCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PresidentManagementCareerValidator().validate(report);

    print(
      'M17_BALANCE profiles=${report.totalProfiles} '
      'archetypes=${report.archetypeDistribution} '
      'finance=${report.averageFinancialDiscipline.toStringAsFixed(2)} '
      'financeRange=${report.minimumFinancialDiscipline}..${report.maximumFinancialDiscipline} '
      'risk=${report.averageRiskAppetite.toStringAsFixed(2)} '
      'riskRange=${report.minimumRiskAppetite}..${report.maximumRiskAppetite} '
      'transfer=${report.averageTransferAmbition.toStringAsFixed(2)} '
      'transferRange=${report.minimumTransferAmbition}..${report.maximumTransferAmbition} '
      'youth=${report.averageYouthOrientation.toStringAsFixed(2)} '
      'youthRange=${report.minimumYouthOrientation}..${report.maximumYouthOrientation} '
      'patience=${report.averageManagerPatience.toStringAsFixed(2)} '
      'patienceRange=${report.minimumManagerPatience}..${report.maximumManagerPatience} '
      'turnoverDistance=${report.averageTurnoverDistance.toStringAsFixed(2)} '
      'archetypeChanges=${report.archetypeChangedTurnovers} '
      'meaningful=${report.meaningfulTurnovers}',
    );

    expect(issues, isEmpty);
    expect(report.sourceReport.totalElections, 240);
    expect(report.sourceReport.reelections, 161);
    expect(report.sourceReport.losses, 79);
    expect(report.sourceReport.totalTurnovers, 79);
    expect(report.totalProfiles, 127);
    expect(report.archetypesUsed, greaterThanOrEqualTo(5));
    expect(report.archetypeChangedTurnovers, greaterThan(35));
    expect(report.meaningfulTurnovers, greaterThan(35));
    expect(report.averageTurnoverDistance, inInclusiveRange(8, 40));
    expect(
      report.maximumFinancialDiscipline - report.minimumFinancialDiscipline,
      greaterThanOrEqualTo(35),
    );
    expect(
      report.maximumTransferAmbition - report.minimumTransferAmbition,
      greaterThanOrEqualTo(35),
    );
    expect(
      report.maximumYouthOrientation - report.minimumYouthOrientation,
      greaterThanOrEqualTo(35),
    );
    expect(
      report.maximumManagerPatience - report.minimumManagerPatience,
      greaterThanOrEqualTo(35),
    );
  });

  test('M17 is deterministic and different seeds produce different philosophies', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentManagementCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 17101),
      seasonCount: 8,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 17101),
      seasonCount: 8,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 17102),
      seasonCount: 8,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
  });
}
