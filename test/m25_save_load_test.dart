import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

import '../tool/m0_data.dart';

void main() {
  const engine = CareerEngine();
  const codec = CareerSaveCodec();

  test('M25 save encoding is deterministic and round-trips full config', () {
    const config = SimulationConfig(
      careerSeed: 25001,
      simulationVersion: 3,
      seasonIndex: 7,
      homeAdvantageRating: 1.75,
      baseHomeGoals: 1.40,
      baseAwayGoals: 1.10,
      ratingScale: 50.0,
      minExpectedGoals: 0.30,
      maxExpectedGoals: 3.25,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: m0Clubs,
      config: config,
      seasonCount: 3,
      startDate: const GameDate(2030, 7, 1),
    );

    final encoded = codec.encode(first.checkpoint);
    final decoded = codec.decode(encoded);
    final encodedAgain = codec.encode(decoded);

    expect(encodedAgain, encoded);
    expect(decoded.config.careerSeed, config.careerSeed);
    expect(decoded.config.simulationVersion, config.simulationVersion);
    expect(decoded.config.seasonIndex, config.seasonIndex);
    expect(decoded.config.homeAdvantageRating, config.homeAdvantageRating);
    expect(decoded.config.baseHomeGoals, config.baseHomeGoals);
    expect(decoded.config.baseAwayGoals, config.baseAwayGoals);
    expect(decoded.config.ratingScale, config.ratingScale);
    expect(decoded.config.minExpectedGoals, config.minExpectedGoals);
    expect(decoded.config.maxExpectedGoals, config.maxExpectedGoals);
    expect(decoded.careerStartDate, const GameDate(2030, 7, 1));
    expect(decoded.completedSeasons, 3);
    expect(decoded.nextSeasonIndex, 10);
    expect(decoded.nextSeasonStartDate, const GameDate(2033, 7, 1));
    expect(_clubSignature(decoded.nextSeasonClubs),
        _clubSignature(first.checkpoint.nextSeasonClubs));
  });

  test('M25 save load resume matches uninterrupted 20-season career', () {
    const config = SimulationConfig(careerSeed: 20260903);
    final uninterrupted = engine.simulateWithCheckpoint(
      clubs: m0Clubs,
      config: config,
      seasonCount: 20,
    );
    final firstSegment = engine.simulateWithCheckpoint(
      clubs: m0Clubs,
      config: config,
      seasonCount: 8,
    );

    final saved = codec.encode(firstSegment.checkpoint);
    final loaded = codec.decode(saved);
    final resumed = engine.resume(checkpoint: loaded, seasonCount: 12);

    expect(resumed.report.initialSeasonIndex, 8);
    expect(resumed.report.startDate, const GameDate(2034, 7, 1));
    expect(resumed.report.endDate, const GameDate(2046, 7, 1));
    expect(
      _seasonSignatures(resumed.report),
      _seasonSignatures(uninterrupted.report, skip: 8),
    );
    expect(
      _clubSignature(resumed.report.finalClubs),
      _clubSignature(uninterrupted.report.finalClubs),
    );
    expect(resumed.checkpoint.completedSeasons, 20);
    expect(
      _clubSignature(resumed.checkpoint.nextSeasonClubs),
      _clubSignature(uninterrupted.checkpoint.nextSeasonClubs),
    );
  });

  test('M25 rejects checksum corruption before loading payload', () {
    final run = engine.simulateWithCheckpoint(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 25),
      seasonCount: 2,
    );
    final envelope = jsonDecode(codec.encode(run.checkpoint)) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    payload['completedSeasons'] = 999;

    expect(
      () => codec.decode(jsonEncode(envelope)),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.checksumMismatch,
        ),
      ),
    );
  });

  test('M25 rejects a checksum-valid future save version safely', () {
    final run = engine.simulateWithCheckpoint(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 26),
      seasonCount: 2,
    );
    final envelope = jsonDecode(codec.encode(run.checkpoint)) as Map<String, dynamic>;
    const futureVersion = CareerSaveCodec.currentSaveVersion + 1;
    envelope['saveVersion'] = futureVersion;
    envelope['checksum'] = SaveChecksum.forPayload(
      saveVersion: futureVersion,
      payload: envelope['payload'],
    );

    expect(
      () => codec.decode(jsonEncode(envelope)),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.unsupportedVersion,
        ),
      ),
    );
  });

  test('M25 migrates the legacy v0 fixture into current checkpoint format', () {
    final legacy = File('test/fixtures/m25_save_v0.json').readAsStringSync();
    final migrated = codec.decode(legacy);

    expect(CareerSaveCodec.currentSaveVersion, 1);
    expect(migrated.config.careerSeed, 77);
    expect(migrated.config.simulationVersion, 1);
    expect(migrated.config.seasonIndex, 3);
    expect(migrated.completedSeasons, 2);
    expect(migrated.careerStartDate, const GameDate(2030, 7, 1));
    expect(migrated.nextSeasonIndex, 5);
    expect(migrated.config.homeAdvantageRating, 2.0);
    expect(migrated.config.baseHomeGoals, 1.35);
    expect(migrated.config.baseAwayGoals, 1.15);
    expect(migrated.nextSeasonClubs.length, 2);
    expect(migrated.baselineStrengths, {'alpha': 70.0, 'beta': 65.0});

    final currentEncoding = codec.encode(migrated);
    final currentEnvelope = jsonDecode(currentEncoding) as Map<String, dynamic>;
    expect(currentEnvelope['saveVersion'], CareerSaveCodec.currentSaveVersion);
  });

  test('M25 rejects malformed JSON with an explicit failure code', () {
    expect(
      () => codec.decode('{not-json'),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.malformedJson,
        ),
      ),
    );
  });
}

List<String> _seasonSignatures(CareerReport report, {int skip = 0}) => report
    .seasons
    .skip(skip)
    .map((season) {
      final fixtures = season.report.fixtures.map((fixture) {
        final result = fixture.result!;
        return '${fixture.id}:${result.homeGoals}-${result.awayGoals}:'
            '${result.homeExpectedGoals}:${result.awayExpectedGoals}:'
            '${result.matchSeed}';
      }).join();
      final strengths = season.clubStrengths.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join('|');
      return '${season.report.seasonIndex}:${season.report.seed}:'
          '${season.report.championClubId}:$strengths:$fixtures';
    })
    .toList(growable: false);

List<String> _clubSignature(List<Club> clubs) => clubs
    .map((club) => '${club.id}:${club.name}:${club.strength}')
    .toList(growable: false);
