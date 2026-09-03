import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

import '../tool/m0_data.dart';

void main() {
  test('M1 simulates a valid deterministic 20-season career', () {
    const engine = CareerEngine();
    const validator = CareerValidator();
    const config = SimulationConfig(careerSeed: 20260903);

    final first = engine.simulate(clubs: m0Clubs, config: config);
    final second = engine.simulate(clubs: m0Clubs, config: config);

    expect(first.seasonCount, 20);
    expect(first.totalMatches, 1120);
    expect(first.initialSeasonIndex, 0);
    expect(first.seasons.first.report.seasonIndex, 0);
    expect(first.seasons.last.report.seasonIndex, 19);
    expect(first.startDate, const GameDate(2026, 7, 1));
    expect(first.endDate, const GameDate(2046, 7, 1));
    expect(validator.validate(first), isEmpty);

    final firstChampions = first.seasons
        .map((season) => season.report.championClubId)
        .toList(growable: false);
    final secondChampions = second.seasons
        .map((season) => season.report.championClubId)
        .toList(growable: false);
    expect(firstChampions, secondChampions);

    final firstStrengths = first.finalClubs
        .map((club) => '${club.id}:${club.strength}')
        .toList(growable: false);
    final secondStrengths = second.finalClubs
        .map((club) => '${club.id}:${club.strength}')
        .toList(growable: false);
    expect(firstStrengths, secondStrengths);

    final baseline = {for (final club in m0Clubs) club.id: club.strength};
    for (final season in first.seasons) {
      for (final entry in season.clubStrengths.entries) {
        expect(
          (entry.value - baseline[entry.key]!).abs(),
          lessThanOrEqualTo(4.0001),
        );
      }
    }
  });

  test('different career seeds produce different career evolution', () {
    const engine = CareerEngine();
    final a = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 1001),
    );
    final b = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 1002),
    );

    final aSignature = [
      ...a.seasons.map((season) => season.report.championClubId),
      ...a.finalClubs.map((club) => '${club.id}:${club.strength}'),
    ];
    final bSignature = [
      ...b.seasons.map((season) => season.report.championClubId),
      ...b.finalClubs.map((club) => '${club.id}:${club.strength}'),
    ];

    expect(aSignature, isNot(equals(bSignature)));
  });

  test('career respects custom initial season index and start date', () {
    const engine = CareerEngine();
    const validator = CareerValidator();
    final report = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 77, seasonIndex: 7),
      seasonCount: 3,
      startDate: const GameDate(2030, 7, 1),
    );

    expect(report.initialSeasonIndex, 7);
    expect(report.seasons.map((s) => s.report.seasonIndex).toList(), [7, 8, 9]);
    expect(report.startDate, const GameDate(2030, 7, 1));
    expect(report.endDate, const GameDate(2033, 7, 1));
    expect(validator.validate(report), isEmpty);
  });
}
