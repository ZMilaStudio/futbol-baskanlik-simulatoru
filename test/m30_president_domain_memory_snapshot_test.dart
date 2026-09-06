import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const codec = PresidentDomainMemorySaveCodec();
  const presidentCodec = PresidentRuntimeSaveCodec();

  test('M30 keeps two raw seasons and current election-term promise memory', () {
    final data = _checkpoint(30001, seasonCount: 5);
    final checkpoint = data.checkpoint;

    expect(checkpoint.completedSeasons, 5);
    expect(checkpoint.rawHistorySeasons, 2);
    expect(checkpoint.recentFan, hasLength(96));
    expect(checkpoint.recentMedia, hasLength(96));
    expect(checkpoint.currentTermPromises, hasLength(48));
    expect(checkpoint.summary.fanSnapshots, 240);
    expect(checkpoint.summary.totalPromises, 240);
    expect(
      checkpoint.currentTermPromises.map((item) => item.seasonIndex).toSet(),
      {4},
    );
  });

  test('M30 clears current-term promise memory exactly on election boundary', () {
    final checkpoint = _checkpoint(30002, seasonCount: 8).checkpoint;

    expect(checkpoint.presidentRuntime.seasonsIntoCurrentTerm, 0);
    expect(checkpoint.currentTermPromises, isEmpty);
    expect(checkpoint.recentFan, hasLength(96));
    expect(checkpoint.recentMedia, hasLength(96));
  });

  test('M30 president domain memory save is deterministic and round-trips', () {
    final checkpoint = _checkpoint(30003, seasonCount: 7).checkpoint;
    final encoded = codec.encode(checkpoint);
    final decoded = codec.decode(encoded);

    expect(codec.encode(decoded), encoded);
    expect(decoded.signature, checkpoint.signature);
    expect(
      presidentCodec.encode(decoded.presidentRuntime),
      presidentCodec.encode(checkpoint.presidentRuntime),
    );
    expect(decoded.currentTermPromises, hasLength(144));
  });

  test('M30 rejects checksum corruption', () {
    final checkpoint = _checkpoint(30004, seasonCount: 5).checkpoint;
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    payload['rawHistorySeasons'] = 99;

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

  test('M30 rejects future save versions safely', () {
    final checkpoint = _checkpoint(30005, seasonCount: 5).checkpoint;
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    const futureVersion = PresidentDomainMemorySaveCodec.currentSaveVersion + 1;
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

  test('M30 migrates synthetic v0 domain-memory save', () {
    final checkpoint = _checkpoint(30006, seasonCount: 5).checkpoint;
    final current = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = current['payload'] as Map<String, dynamic>;
    final legacyPayload = <String, Object?>{
      'presidentSave': payload['presidentRuntimeSave'],
      'historyWindow': payload['rawHistorySeasons'],
      'historySummary': payload['summary'],
      'fanMemory': payload['recentFan'],
      'mediaMemory': payload['recentMedia'],
      'termPromises': payload['currentTermPromises'],
    };
    final legacyEnvelope = <String, Object?>{
      'format': PresidentDomainMemorySaveCodec.format,
      'saveVersion': 0,
      'payload': legacyPayload,
      'checksum': SaveChecksum.forPayload(saveVersion: 0, payload: legacyPayload),
    };

    final migrated = codec.decode(SaveChecksum.canonicalJson(legacyEnvelope));
    expect(migrated.signature, checkpoint.signature);
  });

  test('M30 adds bounded memory overhead to M29 president save', () {
    final checkpoint = _checkpoint(20260903, seasonCount: 8).checkpoint;
    final presidentBytes =
        utf8.encode(presidentCodec.encode(checkpoint.presidentRuntime)).length;
    final memoryBytes = utf8.encode(codec.encode(checkpoint)).length;

    expect(memoryBytes, greaterThan(presidentBytes));
    expect(memoryBytes - presidentBytes, lessThan(100000));
  });
}

class _M30Data {
  const _M30Data(this.checkpoint);

  final PresidentDomainMemoryCheckpoint checkpoint;
}

_M30Data _checkpoint(int seed, {required int seasonCount}) {
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
  final president = PresidentRuntimeCheckpoint.capture(
    runtime: runtime.checkpoint,
    report: reputation,
  );
  return _M30Data(
    PresidentDomainMemoryCheckpoint.capture(
      presidentRuntime: president,
      report: reputation,
    ),
  );
}
