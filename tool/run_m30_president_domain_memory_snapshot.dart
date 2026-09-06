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
  final president = PresidentRuntimeCheckpoint.capture(
    runtime: runtime.checkpoint,
    report: reputation,
  );
  final checkpoint = PresidentDomainMemoryCheckpoint.capture(
    presidentRuntime: president,
    report: reputation,
  );

  const codec = PresidentDomainMemorySaveCodec();
  const presidentCodec = PresidentRuntimeSaveCodec();
  final encoded = codec.encode(checkpoint);
  final decoded = codec.decode(encoded);
  if (codec.encode(decoded) != encoded || decoded.signature != checkpoint.signature) {
    throw StateError('M30 deterministic codec round-trip mismatch.');
  }

  final presidentBytes = utf8.encode(presidentCodec.encode(president)).length;
  final memoryBytes = utf8.encode(encoded).length;
  final overhead = memoryBytes - presidentBytes;
  if (checkpoint.recentFan.length != 96 || checkpoint.recentMedia.length != 96) {
    throw StateError('M30 expected exactly two raw seasons for 48 clubs.');
  }
  if (checkpoint.currentTermPromises.isNotEmpty) {
    throw StateError('M30 season-8 checkpoint must start a fresh election term.');
  }
  if (checkpoint.summary.totalPromises != 384) {
    throw StateError('M30 expected 384 all-time promise resolutions at season 8.');
  }
  if (overhead >= 100000) {
    throw StateError('M30 president memory overhead is too large: $overhead bytes.');
  }

  print('M30 Fan / Media / Promise Runtime Memory Snapshot I');
  print('Seed: $seed');
  print('Completed seasons: ${checkpoint.completedSeasons}');
  print('Raw history seasons: ${checkpoint.rawHistorySeasons}');
  print('Recent fan records: ${checkpoint.recentFan.length}');
  print('Recent media records: ${checkpoint.recentMedia.length}');
  print('Current-term promises: ${checkpoint.currentTermPromises.length}');
  print('All-time fan reasons: ${checkpoint.summary.fanReasons}');
  print('All-time media statements: ${checkpoint.summary.mediaStatements}');
  print('All-time media contradictions: ${checkpoint.summary.mediaContradictions}');
  print('All-time promises: ${checkpoint.summary.totalPromises}');
  print('M29 president bytes: $presidentBytes');
  print('M30 memory bytes: $memoryBytes');
  print('Memory overhead: $overhead');
  print('Round-trip: PASS');
}
