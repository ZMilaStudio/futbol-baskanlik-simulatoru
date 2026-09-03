import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  final clubs = <Club>[
    const Club(id: 'a', name: 'A', strength: 80),
    const Club(id: 'b', name: 'B', strength: 76),
    const Club(id: 'c', name: 'C', strength: 73),
    const Club(id: 'd', name: 'D', strength: 70),
    const Club(id: 'e', name: 'E', strength: 67),
    const Club(id: 'f', name: 'F', strength: 64),
    const Club(id: 'g', name: 'G', strength: 61),
    const Club(id: 'h', name: 'H', strength: 58),
  ];

  test('100 seasons complete with zero invariant failures', () {
    const engine = SeasonEngine();
    const validator = SeasonValidator();
    var totalGoals = 0;
    var matches = 0;
    var homeWins = 0;
    var draws = 0;
    var awayWins = 0;

    for (var i = 0; i < 100; i++) {
      final report = engine.simulate(
        clubs: clubs,
        config: SimulationConfig(careerSeed: 900000 + i),
      );
      expect(validator.validate(report), isEmpty);
      totalGoals += report.totalGoals;
      matches += report.matchCount;
      homeWins += report.homeWins;
      draws += report.draws;
      awayWins += report.awayWins;
    }

    final averageGoals = totalGoals / matches;
    final homeRate = homeWins / matches;
    final drawRate = draws / matches;
    final awayRate = awayWins / matches;
    expect(averageGoals, inInclusiveRange(1.8, 3.5));
    expect(homeRate, inInclusiveRange(0.35, 0.55));
    expect(drawRate, inInclusiveRange(0.18, 0.35));
    expect(awayRate, inInclusiveRange(0.20, 0.40));
  });
}
