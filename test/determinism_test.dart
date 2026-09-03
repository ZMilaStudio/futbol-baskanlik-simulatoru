import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  final clubs = List.generate(
    8,
    (i) => Club(id: 'c$i', name: 'Club $i', strength: 58 + i * 3),
  );

  test('same seed produces same season', () {
    const engine = SeasonEngine();
    const config = SimulationConfig(careerSeed: 123456);
    final a = engine.simulate(clubs: clubs, config: config);
    final b = engine.simulate(clubs: clubs, config: config);

    final scoresA = a.fixtures
        .map((f) => '${f.result!.homeGoals}-${f.result!.awayGoals}')
        .toList();
    final scoresB = b.fixtures
        .map((f) => '${f.result!.homeGoals}-${f.result!.awayGoals}')
        .toList();
    expect(scoresA, scoresB);
    expect(a.championClubId, b.championClubId);
  });

  test('different seeds alter at least one score', () {
    const engine = SeasonEngine();
    final a = engine.simulate(
      clubs: clubs,
      config: const SimulationConfig(careerSeed: 111),
    );
    final b = engine.simulate(
      clubs: clubs,
      config: const SimulationConfig(careerSeed: 222),
    );
    final same = <bool>[];
    for (var i = 0; i < a.fixtures.length; i++) {
      final ar = a.fixtures[i].result!;
      final br = b.fixtures[i].result!;
      same.add(
        ar.homeGoals == br.homeGoals && ar.awayGoals == br.awayGoals,
      );
    }
    expect(same.every((v) => v), isFalse);
  });
}
