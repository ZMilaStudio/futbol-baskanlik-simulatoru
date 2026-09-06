import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const engine = PresidentDomainCareerEngine();
  const codec = PresidentDomainMemorySaveCodec();

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
  final checkpoints = <int>[6];
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
    checkpoints.add(chained.checkpoint.completedSeasons);
  }
  final finalEncoded = codec.encode(chained.checkpoint);
  saveSizes.add(finalEncoded.length);

  final fullEncoded = codec.encode(full.checkpoint);
  final finalMatch = finalEncoded == fullEncoded;
  final bounded = saveSizes.every((bytes) => bytes < 1300000);
  final growth = saveSizes.last - saveSizes.first;
  final growthBounded = growth < 300000;

  if (!finalMatch || !bounded || !growthBounded) {
    throw StateError(
      'M32 stress mismatch: final=$finalMatch bounded=$bounded '
      'growthBounded=$growthBounded sizes=$saveSizes',
    );
  }

  print('M32 Long-Career Save Growth / Resume Stress I');
  print('Seed: $seed');
  print('Segments: 6 + 7 + 9 + 8');
  print('Checkpoint seasons: ${checkpoints.join(', ')}');
  print('Save bytes: ${saveSizes.join(', ')}');
  print('First -> final growth: $growth');
  print('Max save bytes: ${saveSizes.reduce((a, b) => a > b ? a : b)}');
  print('Completed seasons: ${chained.checkpoint.completedSeasons}');
  print('President states: ${chained.checkpoint.presidentRuntime.clubs.length}');
  print('Recent fan records: ${chained.checkpoint.recentFan.length}');
  print('Recent media records: ${chained.checkpoint.recentMedia.length}');
  print('Final checkpoint match: $finalMatch');
  print('Bounded save size: $bounded');
  print('30-season multi-checkpoint stress: PASS');
}
