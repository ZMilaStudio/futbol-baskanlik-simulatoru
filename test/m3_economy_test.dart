import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

import '../tool/m0_data.dart';

void main() {
  test('Money arithmetic stays exact in minor units', () {
    const ten = Money.fromUnits(10);
    const half = Money.fromMinorUnits(50);

    expect(ten + half, const Money.fromMinorUnits(1050));
    expect(ten - half, const Money.fromMinorUnits(950));
    expect(ten.scaleBasisPoints(500), const Money.fromMinorUnits(50));
  });

  test('M3 simulates a valid deterministic 20-season economy career', () {
    const engine = EconomyCareerEngine();
    const validator = EconomyCareerValidator();
    const config = SimulationConfig(careerSeed: 20260903);

    final first = engine.simulate(clubs: m0Clubs, config: config);
    final second = engine.simulate(clubs: m0Clubs, config: config);

    expect(first.seasonCount, 20);
    expect(first.totalMatches, 1120);
    expect(first.initialStates.length, m0Clubs.length);
    expect(first.finalStates.length, m0Clubs.length);
    expect(validator.validate(first), isEmpty);
    expect(first.signature, second.signature);

    for (final season in first.seasons) {
      expect(season.clubs.length, m0Clubs.length);
      for (final club in season.clubs) {
        expect(club.totalRevenue, greaterThan(Money.zero));
        expect(club.wageExpense, greaterThan(Money.zero));
        expect(club.closingCash, greaterThanOrEqualTo(Money.zero));
        expect(club.closingDebt, greaterThanOrEqualTo(Money.zero));
        expect(club.principalRepaid, lessThanOrEqualTo(club.openingDebt));
      }
    }
  });

  test('M3 20-season baseline avoids universal prosperity or collapse', () {
    final report = const EconomyCareerEngine().simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 20260903),
    );

    expect(report.finalTotalCash, greaterThan(const Money.fromUnits(20000000)));
    expect(report.finalTotalCash, lessThan(const Money.fromUnits(500000000)));
    expect(report.finalTotalDebt, greaterThan(Money.zero));
    expect(report.finalTotalDebt, lessThan(const Money.fromUnits(400000000)));
    expect(
      report.totalEmergencyBorrowing,
      lessThan(const Money.fromUnits(250000000)),
    );

    final health = report.finalHealthDistribution;
    expect(health.length, greaterThanOrEqualTo(2));
    expect(health[FinancialHealth.debtCrisis] ?? 0, lessThanOrEqualTo(4));
    expect(health[FinancialHealth.veryStrong] ?? 0, lessThanOrEqualTo(4));
  });

  test('different career seeds produce different finance evolution', () {
    const engine = EconomyCareerEngine();
    final a = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 3001),
    );
    final b = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 3002),
    );

    expect(a.signature, isNot(equals(b.signature)));
  });

  test('M3 carries finance balances across season boundaries exactly', () {
    final report = const EconomyCareerEngine().simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 77),
      seasonCount: 5,
    );

    for (var i = 1; i < report.seasons.length; i++) {
      final previous = {
        for (final club in report.seasons[i - 1].clubs) club.clubId: club,
      };
      for (final club in report.seasons[i].clubs) {
        final prior = previous[club.clubId]!;
        expect(club.openingCash, prior.closingCash);
        expect(club.openingDebt, prior.closingDebt);
      }
    }
  });
}
