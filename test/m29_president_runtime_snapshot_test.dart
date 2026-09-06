import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const compactEngine = CompactAdvancedRuntimeCareerEngine();
  const reputationEngine = PresidentReputationCareerEngine();
  const codec = PresidentRuntimeSaveCodec();
  const compactCodec = CompactAdvancedWorldSaveCodec();

  test('M29 captures 48 current president states and election cursor', () {
    final checkpoint = _checkpoint(29001, seasonCount: 8);

    expect(checkpoint.clubs, hasLength(48));
    expect(checkpoint.completedSeasons, 8);
    expect(checkpoint.completedElectionTerms, 2);
    expect(checkpoint.seasonsIntoCurrentTerm, 0);
    expect(checkpoint.nextSeasonIndex, 8);
    expect(checkpoint.clubs.map((item) => item.clubId).toSet(), hasLength(48));
    expect(
      checkpoint.clubs.every(
        (item) => item.managementProfile.presidentId == item.tenure.president.id,
      ),
      isTrue,
    );
  });

  test('M29 president runtime save is deterministic and round-trips', () {
    final checkpoint = _checkpoint(29002, seasonCount: 5);
    final encoded = codec.encode(checkpoint);
    final decoded = codec.decode(encoded);

    expect(codec.encode(decoded), encoded);
    expect(decoded.signature, checkpoint.signature);
    expect(
      compactCodec.encode(decoded.runtime),
      compactCodec.encode(checkpoint.runtime),
    );
    expect(decoded.completedElectionTerms, 1);
    expect(decoded.seasonsIntoCurrentTerm, 1);
  });

  test('M29 preserves canonical generated management profiles', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 29003);
    final runtime = compactEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final reputation = reputationEngine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final checkpoint = PresidentRuntimeCheckpoint.capture(
      runtime: runtime.checkpoint,
      report: reputation,
    );
    const generator = PresidentManagementProfileGenerator();

    for (final state in checkpoint.clubs) {
      final expected = generator.generate(
        president: state.tenure.president,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      expect(state.managementProfile.signature, expected.signature);
    }
  });

  test('M29 rejects checksum corruption', () {
    final checkpoint = _checkpoint(29004, seasonCount: 4);
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    payload['completedElectionTerms'] = 99;

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

  test('M29 rejects future save versions safely', () {
    final checkpoint = _checkpoint(29005, seasonCount: 4);
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    const futureVersion = PresidentRuntimeSaveCodec.currentSaveVersion + 1;
    envelope['saveVersion'] = futureVersion;
    envelope['checksum'] = SaveChecksum.forPayload(
      saveVersion: futureVersion,
      payload: envelope['payload'],
    );

    expect(
      () => codec.decode(SaveChecksum.canonicalJson(envelope)),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.unsupportedVersion,
        ),
      ),
    );
  });

  test('M29 migrates synthetic v0 president runtime save', () {
    final checkpoint = _checkpoint(29006, seasonCount: 4);
    final current = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = current['payload'] as Map<String, dynamic>;
    final legacyPayload = <String, Object?>{
      'compactRuntimeSave': payload['runtimeSave'],
      'termLength': payload['electionInterval'],
      'completedTerms': payload['completedElectionTerms'],
      'termOffset': payload['seasonsIntoCurrentTerm'],
      'presidents': payload['clubs'],
    };
    final legacyEnvelope = <String, Object?>{
      'format': PresidentRuntimeSaveCodec.format,
      'saveVersion': 0,
      'payload': legacyPayload,
      'checksum': SaveChecksum.forPayload(saveVersion: 0, payload: legacyPayload),
    };

    final migrated = codec.decode(SaveChecksum.canonicalJson(legacyEnvelope));
    expect(migrated.signature, checkpoint.signature);
  });

  test('M29 adds bounded president state overhead to M28 compact save', () {
    final checkpoint = _checkpoint(20260903, seasonCount: 8);
    final baseBytes = utf8.encode(compactCodec.encode(checkpoint.runtime)).length;
    final presidentBytes = utf8.encode(codec.encode(checkpoint)).length;

    expect(presidentBytes, greaterThan(baseBytes));
    expect(presidentBytes - baseBytes, lessThan(50000));
  });
}

PresidentRuntimeCheckpoint _checkpoint(int seed, {required int seasonCount}) {
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  final runtime = const CompactAdvancedRuntimeCareerEngine().simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: seasonCount,
  );
  final reputation = const PresidentReputationCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: seasonCount,
  );
  return PresidentRuntimeCheckpoint.capture(
    runtime: runtime.checkpoint,
    report: reputation,
  );
}
