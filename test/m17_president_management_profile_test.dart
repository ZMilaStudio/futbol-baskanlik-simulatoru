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
    expect(report.archetypesUsed, PresidentManagementArchetype.values.length);
    expect(
      report.archetypeDistribution.values.every(
        (count) => count >= 10 && count <= 30,
      ),
      isTrue,
    );
    expect(report.archetypeChangedTurnovers, inInclusiveRange(55, 75));
    expect(report.meaningfulTurnovers, inInclusiveRange(45, 65));
    expect(report.averageTurnoverDistance, inInclusiveRange(18, 27));
    expect(report.averageFinancialDiscipline, inInclusiveRange(54, 66));
    expect(report.averageRiskAppetite, inInclusiveRange(49, 61));
    expect(report.averageTransferAmbition, inInclusiveRange(50, 63));
    expect(report.averageYouthOrientation, inInclusiveRange(54, 66));
    expect(report.averageManagerPatience, inInclusiveRange(52, 64));
    expect(report.minimumFinancialDiscipline, inInclusiveRange(20, 35));
    expect(report.maximumFinancialDiscipline, inInclusiveRange(85, 90));
    expect(report.minimumRiskAppetite, inInclusiveRange(20, 30));
    expect(report.maximumRiskAppetite, inInclusiveRange(85, 90));
    expect(report.minimumTransferAmbition, inInclusiveRange(20, 35));
    expect(report.maximumTransferAmbition, inInclusiveRange(85, 90));
    expect(report.minimumYouthOrientation, inInclusiveRange(20, 35));
    expect(report.maximumYouthOrientation, inInclusiveRange(85, 90));
    expect(report.minimumManagerPatience, inInclusiveRange(20, 30));
    expect(report.maximumManagerPatience, inInclusiveRange(85, 90));
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
