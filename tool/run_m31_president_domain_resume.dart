import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();

  final fullRuntime = const CompactAdvancedRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 20,
  );
  final fullReputation = const PresidentReputationCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 20,
  );
  final fullDomain = PresidentDomainMemoryCheckpoint.capture(
    presidentRuntime: PresidentRuntimeCheckpoint.capture(
      runtime: fullRuntime.checkpoint,
      report: fullReputation,
    ),
    report: fullReputation,
  );

  final firstRuntime = const CompactAdvancedRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 8,
  );
  final firstReputation = const PresidentReputationCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 8,
    hasFutureSeasonAfterReport: true,
  );
  final firstDomain = PresidentDomainMemoryCheckpoint.capture(
    presidentRuntime: PresidentRuntimeCheckpoint.capture(
      runtime: firstRuntime.checkpoint,
      report: firstReputation,
    ),
    report: firstReputation,
  );
  final resumed = const PresidentDomainResumeEngine().resume(
    checkpoint: firstDomain,
    seasonCount: 12,
  );

  final presidentMatch = resumed.checkpoint.presidentRuntime.clubs
          .map((item) => item.signature)
          .join('|') ==
      fullDomain.presidentRuntime.clubs
          .map((item) => item.signature)
          .join('|');
  final memoryMatch = resumed.checkpoint.summary.signature ==
          fullDomain.summary.signature &&
      resumed.checkpoint.recentFan.map((item) => item.signature).join('|') ==
          fullDomain.recentFan.map((item) => item.signature).join('|') &&
      resumed.checkpoint.recentMedia.map((item) => item.signature).join('|') ==
          fullDomain.recentMedia.map((item) => item.signature).join('|') &&
      resumed.checkpoint.currentTermPromises
              .map((item) => item.signature)
              .join('|') ==
          fullDomain.currentTermPromises
              .map((item) => item.signature)
              .join('|');
  final runtimeMatch = const CompactAdvancedWorldSaveCodec().encode(
        resumed.checkpoint.presidentRuntime.runtime,
      ) ==
      const CompactAdvancedWorldSaveCodec().encode(fullRuntime.checkpoint);

  if (!presidentMatch || !memoryMatch || !runtimeMatch) {
    throw StateError(
      'M31 continuation mismatch: runtime=$runtimeMatch '
      'president=$presidentMatch memory=$memoryMatch',
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
  print('8 + 12 == 20: PASS');
}
