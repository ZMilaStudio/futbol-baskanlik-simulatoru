import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const engine = PresidentDomainCareerEngine();

  final full = engine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 20,
  );
  final first = engine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 8,
    hasFutureSeasonAfterReport: true,
  );
  final resumed = engine.resume(
    checkpoint: first.checkpoint,
    seasonCount: 12,
  );

  final presidentMatch = resumed.checkpoint.presidentRuntime.clubs
          .map((item) => item.signature)
          .join('|') ==
      full.checkpoint.presidentRuntime.clubs
          .map((item) => item.signature)
          .join('|');
  final memoryMatch = resumed.checkpoint.summary.signature ==
          full.checkpoint.summary.signature &&
      resumed.checkpoint.recentFan.map((item) => item.signature).join('|') ==
          full.checkpoint.recentFan.map((item) => item.signature).join('|') &&
      resumed.checkpoint.recentMedia.map((item) => item.signature).join('|') ==
          full.checkpoint.recentMedia.map((item) => item.signature).join('|') &&
      resumed.checkpoint.currentTermPromises
              .map((item) => item.signature)
              .join('|') ==
          full.checkpoint.currentTermPromises
              .map((item) => item.signature)
              .join('|');
  final runtimeMatch = const CompactAdvancedWorldSaveCodec().encode(
        resumed.checkpoint.presidentRuntime.runtime,
      ) ==
      const CompactAdvancedWorldSaveCodec().encode(
        full.checkpoint.presidentRuntime.runtime,
      );
  final electionMatch = resumed.report.elections
          .map((item) => item.signature)
          .join('|') ==
      full.report.elections
          .where((item) => item.seasonIndex >= 8)
          .map((item) => item.signature)
          .join('|');

  if (!presidentMatch || !memoryMatch || !runtimeMatch || !electionMatch) {
    throw StateError(
      'M31 continuation mismatch: runtime=$runtimeMatch '
      'president=$presidentMatch memory=$memoryMatch elections=$electionMatch',
    );
  }

  print('M31 President Domain Resume Orchestration I');
  print('Seed: $seed');
  print('Split: 8 + 12 seasons');
  print('Completed seasons: ${resumed.checkpoint.completedSeasons}');
  print('Final president states: ${resumed.checkpoint.presidentRuntime.clubs.length}');
  print('Final recent fan records: ${resumed.checkpoint.recentFan.length}');
  print('Final recent media records: ${resumed.checkpoint.recentMedia.length}');
  print('Final current-term promises: ${resumed.checkpoint.currentTermPromises.length}');
  print('Resumed elections: ${resumed.report.elections.length}');
  print('Advanced runtime match: $runtimeMatch');
  print('President state match: $presidentMatch');
  print('President memory match: $memoryMatch');
  print('Election match: $electionMatch');
  print('8 + 12 == 20: PASS');
}
