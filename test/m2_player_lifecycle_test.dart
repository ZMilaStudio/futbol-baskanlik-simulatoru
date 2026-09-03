import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

import '../tool/m0_data.dart';

void main() {
  test('M2 simulates a valid deterministic 20-season player career', () {
    const engine = PlayerCareerEngine();
    const validator = PlayerCareerValidator();
    const config = SimulationConfig(careerSeed: 20260903);

    final first = engine.simulate(clubs: m0Clubs, config: config);
    final second = engine.simulate(clubs: m0Clubs, config: config);

    expect(first.seasonCount, 20);
    expect(first.totalMatches, 1120);
    expect(first.initialPlayerCount, 144);
    expect(first.totalYouthIntakes, 19 * m0Clubs.length);
    expect(first.totalRetirements, greaterThan(0));
    expect(validator.validate(first), isEmpty);

    final firstSignature = [
      ...first.seasons.map((season) => season.report.championClubId),
      ...first.finalPlayers.map((player) => player.signature),
    ];
    final secondSignature = [
      ...second.seasons.map((season) => season.report.championClubId),
      ...second.finalPlayers.map((player) => player.signature),
    ];
    expect(firstSignature, secondSignature);
  });

  test('M2 keeps every club viable through retirement and youth intake', () {
    const engine = PlayerCareerEngine();
    final report = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 880055),
    );

    for (final season in report.seasons) {
      for (final club in season.clubs) {
        final roster = season.players
            .where((player) => player.clubId == club.id)
            .toList();
        expect(roster.length, greaterThanOrEqualTo(11));
      }
    }

    expect(report.totalRetirements, greaterThan(20));
    expect(report.finalPlayers.length, greaterThanOrEqualTo(88));
  });

  test('different seeds produce different player populations', () {
    const engine = PlayerCareerEngine();
    final a = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 501),
      seasonCount: 5,
    );
    final b = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 502),
      seasonCount: 5,
    );

    final aSignature =
        a.finalPlayers.map((player) => player.signature).toList();
    final bSignature =
        b.finalPlayers.map((player) => player.signature).toList();
    expect(aSignature, isNot(equals(bSignature)));
  });
}
