import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);

  final runtime = const CompactAdvancedRuntimeCareerEngine().simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 8,
  );
  final reputation = const PresidentReputationCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 8,
  );
  final checkpoint = PresidentRuntimeCheckpoint.capture(
    runtime: runtime.checkpoint,
    report: reputation,
  );
  const codec = PresidentRuntimeSaveCodec();
  const compactCodec = CompactAdvancedWorldSaveCodec();
  final encoded = codec.encode(checkpoint);
  final decoded = codec.decode(encoded);
  final encodedAgain = codec.encode(decoded);
  if (encodedAgain != encoded) {
    throw StateError('M29 deterministic codec round-trip mismatch.');
  }

  final compactBytes = utf8.encode(compactCodec.encode(checkpoint.runtime)).length;
  final presidentBytes = utf8.encode(encoded).length;
  final overhead = presidentBytes - compactBytes;
  if (checkpoint.clubs.length != 48) {
    throw StateError('M29 expected 48 president club states.');
  }
  if (checkpoint.completedElectionTerms != 2 ||
      checkpoint.seasonsIntoCurrentTerm != 0) {
    throw StateError('M29 election cursor mismatch.');
  }
  if (overhead >= 50000) {
    throw StateError('M29 president runtime overhead is too large: $overhead bytes.');
  }

  print('M29 President Runtime Snapshot I');
  print('Seed: $seed');
  print('Completed seasons: ${checkpoint.completedSeasons}');
  print('Next season index: ${checkpoint.nextSeasonIndex}');
  print('President club states: ${checkpoint.clubs.length}');
  print('Completed election terms: ${checkpoint.completedElectionTerms}');
  print('Term offset: ${checkpoint.seasonsIntoCurrentTerm}');
  print('M28 compact bytes: $compactBytes');
  print('M29 president bytes: $presidentBytes');
  print('President state overhead: $overhead');
  print('Round-trip: PASS');
}
