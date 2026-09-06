import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const engine = PresidentDomainCareerEngine();
  const codec = PresidentDomainMemorySaveCodec();

  test('M32 6+7+9+8 multi-save chain matches uninterrupted 30 seasons', () {
    const config = SimulationConfig(careerSeed: 20260903);
    final world = const FictionalWorldFactory().build();

    final full = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 30,
    );

    var chained = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 6,
      hasFutureSeasonAfterReport: true,
    );
    final saveSizes = <int>[];

    for (final segment in const [7, 9, 8]) {
      final encoded = codec.encode(chained.checkpoint);
      saveSizes.add(encoded.length);
      final decoded = codec.decode(encoded);
      chained = engine.resume(
        checkpoint: decoded,
        seasonCount: segment,
        hasFutureSeasonAfterReport: chained.checkpoint.completedSeasons + segment < 30,
      );
    }
    saveSizes.add(codec.encode(chained.checkpoint).length);

    expect(chained.checkpoint.completedSeasons, 30);
    expect(chained.checkpoint.nextSeasonIndex, 30);
    expect(codec.encode(chained.checkpoint), codec.encode(full.checkpoint));
    expect(saveSizes.every((bytes) => bytes < 1300000), isTrue);
    expect(saveSizes.last - saveSizes.first, lessThan(300000));
  });

  test('M32 repeated encode decode cycles are idempotent at season 30', () {
    const config = SimulationConfig(careerSeed: 32002);
    final world = const FictionalWorldFactory().build();
    final result = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 30,
    );

    var encoded = codec.encode(result.checkpoint);
    for (var i = 0; i < 5; i++) {
      encoded = codec.encode(codec.decode(encoded));
    }

    expect(encoded, codec.encode(result.checkpoint));
  });
}
