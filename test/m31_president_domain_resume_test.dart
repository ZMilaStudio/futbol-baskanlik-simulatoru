import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M31 president domain 8 save + 12 resume matches uninterrupted 20', () {
    const seed = 20260903;
    const config = SimulationConfig(careerSeed: seed);
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
    final fullPresidentRuntime = PresidentRuntimeCheckpoint.capture(
      runtime: fullRuntime.checkpoint,
      report: fullReputation,
    );
    final fullDomain = PresidentDomainMemoryCheckpoint.capture(
      presidentRuntime: fullPresidentRuntime,
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
    final firstPresidentRuntime = PresidentRuntimeCheckpoint.capture(
      runtime: firstRuntime.checkpoint,
      report: firstReputation,
    );
    final firstDomain = PresidentDomainMemoryCheckpoint.capture(
      presidentRuntime: firstPresidentRuntime,
      report: firstReputation,
    );

    final resumed = const PresidentDomainResumeEngine().resume(
      checkpoint: firstDomain,
      seasonCount: 12,
    );

    expect(resumed.checkpoint.completedSeasons, 20);
    expect(resumed.checkpoint.nextSeasonIndex, 20);
    expect(
      const CompactAdvancedWorldSaveCodec().encode(
        resumed.checkpoint.presidentRuntime.runtime,
      ),
      const CompactAdvancedWorldSaveCodec().encode(fullRuntime.checkpoint),
    );
    expect(
      resumed.checkpoint.presidentRuntime.clubs
          .map((item) => item.signature)
          .toList(),
      fullDomain.presidentRuntime.clubs.map((item) => item.signature).toList(),
    );
    expect(resumed.checkpoint.summary.signature, fullDomain.summary.signature);
    expect(
      resumed.checkpoint.recentFan.map((item) => item.signature).toList(),
      fullDomain.recentFan.map((item) => item.signature).toList(),
    );
    expect(
      resumed.checkpoint.recentMedia.map((item) => item.signature).toList(),
      fullDomain.recentMedia.map((item) => item.signature).toList(),
    );
    expect(
      resumed.checkpoint.currentTermPromises
          .map((item) => item.signature)
          .toList(),
      fullDomain.currentTermPromises.map((item) => item.signature).toList(),
    );

    final expectedElections = fullReputation.elections
        .where((item) => item.seasonIndex >= 8)
        .map((item) => item.signature)
        .toList();
    expect(
      resumed.report.elections.map((item) => item.signature).toList(),
      expectedElections,
    );
    expect(
      resumed.report.finalTenureStates.map((item) => item.signature).toList(),
      fullReputation.finalTenureStates.map((item) => item.signature).toList(),
    );
    expect(
      resumed.report.finalFanStates.map((item) => item.signature).toList(),
      fullReputation.finalFanStates.map((item) => item.signature).toList(),
    );
    expect(
      resumed.report.finalMediaStates.map((item) => item.signature).toList(),
      fullReputation.finalMediaStates.map((item) => item.signature).toList(),
    );
  });

  test('M31 resumes inside an election term using saved promise scores', () {
    const config = SimulationConfig(careerSeed: 31002);
    final world = const FictionalWorldFactory().build();
    final runtime = const CompactAdvancedRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 5,
    );
    final reputation = const PresidentReputationCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 5,
      hasFutureSeasonAfterReport: true,
    );
    final domain = PresidentDomainMemoryCheckpoint.capture(
      presidentRuntime: PresidentRuntimeCheckpoint.capture(
        runtime: runtime.checkpoint,
        report: reputation,
      ),
      report: reputation,
    );

    expect(domain.currentTermPromises, hasLength(48));
    final resumed = const PresidentDomainResumeEngine().resume(
      checkpoint: domain,
      seasonCount: 3,
      hasFutureSeasonAfterReport: true,
    );

    expect(resumed.checkpoint.completedSeasons, 8);
    expect(resumed.checkpoint.currentTermPromises, isEmpty);
    expect(resumed.report.elections, hasLength(48));
    expect(resumed.report.elections.every((item) => item.termNumber == 2), isTrue);
  });
}
