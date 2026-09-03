import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M5 fictional world contains 48 unique clubs across 3x16 leagues', () {
    final world = const FictionalWorldFactory().build();

    expect(world.clubs.length, 48);
    expect(world.clubs.map((club) => club.id).toSet().length, 48);
    expect(world.leagues.length, 3);
    expect(
      world.leagues.map((league) => league.tier).toSet(),
      containsAll(LeagueTier.values),
    );
    for (final league in world.leagues) {
      expect(league.clubIds.length, 16);
    }
    final memberships = world.leagues.expand((league) => league.clubIds).toList();
    expect(memberships.length, 48);
    expect(memberships.toSet().length, 48);
  });

  test('tiered economy scale preserves the full-scale default', () {
    final club = const Club(id: 'scale_test', name: 'Scale Test', strength: 65);
    const economy = BasicEconomyEngine();
    final full = economy.initialStates(
      clubs: [club],
      careerSeed: 20260903,
      simulationVersion: 1,
    ).single;
    final thirdTier = economy.initialStates(
      clubs: [club],
      careerSeed: 20260903,
      simulationVersion: 1,
      economicScaleBps: LeagueTier.third.economicScaleBps,
    ).single;

    expect(
      thirdTier.cash,
      full.cash.scaleBasisPoints(LeagueTier.third.economicScaleBps),
    );
    expect(
      thirdTier.debt,
      full.debt.scaleBasisPoints(LeagueTier.third.economicScaleBps),
    );
  });

  test('M5 simulates a valid 20-season 48-club world', () {
    final world = const FictionalWorldFactory().build();
    const engine = WorldCareerEngine();
    const validator = WorldCareerValidator();
    const config = SimulationConfig(careerSeed: 20260903);

    final report = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );

    expect(report.seasonCount, 20);
    expect(report.initialClubCount, 48);
    expect(report.initialPlayerCount, 864);
    expect(report.totalMatches, 14400);
    expect(report.totalMovements, 228);
    expect(report.finalPlayers.length, greaterThanOrEqualTo(600));
    expect(report.finalPlayers.length, lessThanOrEqualTo(1150));
    expect(report.finalLeagues.length, 3);
    expect(validator.validate(report), isEmpty);

    for (final season in report.seasons) {
      expect(season.matchCount, 720);
      expect(season.leagueResults.length, 3);
      for (final result in season.leagueResults) {
        expect(result.report.table.length, 16);
        expect(result.report.matchCount, 240);
        expect(
          result.report.table.every((row) => row.played == 30),
          isTrue,
        );
      }
    }
  });

  test('M5 is deterministic and different seeds diverge', () {
    final world = const FictionalWorldFactory().build();
    const engine = WorldCareerEngine();

    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 5101),
      seasonCount: 3,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 5101),
      seasonCount: 3,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 5102),
      seasonCount: 3,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
  });
}
