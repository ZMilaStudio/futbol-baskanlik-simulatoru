import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const engine = PresidentDomainCareerEngine();

  test('M31 president domain 8 save + 12 resume matches uninterrupted 20', () {
    const config = SimulationConfig(careerSeed: 20260903);
    final world = const FictionalWorldFactory().build();

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

    expect(resumed.checkpoint.completedSeasons, 20);
    expect(resumed.checkpoint.nextSeasonIndex, 20);
    expect(
      const CompactAdvancedWorldSaveCodec().encode(
        resumed.checkpoint.presidentRuntime.runtime,
      ),
      const CompactAdvancedWorldSaveCodec().encode(
        full.checkpoint.presidentRuntime.runtime,
      ),
    );
    expect(
      resumed.checkpoint.presidentRuntime.clubs
          .map((item) => item.signature)
          .toList(),
      full.checkpoint.presidentRuntime.clubs
          .map((item) => item.signature)
          .toList(),
    );
    expect(
      resumed.checkpoint.summary.signature,
      full.checkpoint.summary.signature,
    );
    expect(
      resumed.checkpoint.recentFan.map((item) => item.signature).toList(),
      full.checkpoint.recentFan.map((item) => item.signature).toList(),
    );
    expect(
      resumed.checkpoint.recentMedia.map((item) => item.signature).toList(),
      full.checkpoint.recentMedia.map((item) => item.signature).toList(),
    );
    expect(
      resumed.checkpoint.currentTermPromises
          .map((item) => item.signature)
          .toList(),
      full.checkpoint.currentTermPromises
          .map((item) => item.signature)
          .toList(),
    );

    final expectedElections = full.report.elections
        .where((item) => item.seasonIndex >= 8)
        .map((item) => item.signature)
        .toList();
    expect(
      resumed.report.elections.map((item) => item.signature).toList(),
      expectedElections,
    );
    expect(
      resumed.report.finalTenureStates.map((item) => item.signature).toList(),
      full.report.finalTenureStates.map((item) => item.signature).toList(),
    );
    expect(
      resumed.report.finalFanStates.map((item) => item.signature).toList(),
      full.report.finalFanStates.map((item) => item.signature).toList(),
    );
    expect(
      resumed.report.finalMediaStates.map((item) => item.signature).toList(),
      full.report.finalMediaStates.map((item) => item.signature).toList(),
    );
  });

  test('M31 resumes inside an election term using saved promise scores', () {
    const config = SimulationConfig(careerSeed: 31002);
    final world = const FictionalWorldFactory().build();
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 5,
      hasFutureSeasonAfterReport: true,
    );

    expect(first.checkpoint.currentTermPromises, hasLength(48));
    final resumed = engine.resume(
      checkpoint: first.checkpoint,
      seasonCount: 3,
      hasFutureSeasonAfterReport: true,
    );

    expect(resumed.checkpoint.completedSeasons, 8);
    expect(resumed.checkpoint.currentTermPromises, isEmpty);
    expect(resumed.report.elections, hasLength(48));
    expect(
      resumed.report.elections.every((item) => item.termNumber == 2),
      isTrue,
    );
  });
}
