import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const runtimeEngine = AdvancedRuntimeCareerEngine();
  const compactEngine = CompactAdvancedRuntimeCareerEngine();
  const compactor = AdvancedRuntimeHistoryCompactor();
  const fullCodec = AdvancedWorldSaveCodec();
  const compactCodec = CompactAdvancedWorldSaveCodec();

  test('M28 compact save encoding is deterministic and round-trips state', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(
      careerSeed: 28001,
      simulationVersion: 3,
      seasonIndex: 4,
    );
    final full = runtimeEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 5,
    );
    final compact = compactor.compactFull(full.checkpoint);

    final encoded = compactCodec.encode(compact);
    final decoded = compactCodec.decode(encoded);

    expect(compactCodec.encode(decoded), encoded);
    expect(decoded.completedSeasons, 5);
    expect(decoded.nextSeasonIndex, 9);
    expect(decoded.recentHistoryStartSeasonIndex, 7);
    expect(decoded.runtime.manager.seasons.length, 2);
    expect(decoded.history.contractEventCount,
        full.checkpoint.transfer.contractEvents.length);
    expect(decoded.history.loanCount, full.checkpoint.transfer.loanHistory.length);
    expect(decoded.history.managerSeasonCount, 5);
  });

  test('M28 8 save load 12 matches uninterrupted 20-season advanced world', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20260903);

    final uninterrupted = runtimeEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 20,
    );
    final first = runtimeEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final compactFirst = compactor.compactFull(first.checkpoint);
    final loaded = compactCodec.decode(compactCodec.encode(compactFirst));
    final resumed = compactEngine.resume(checkpoint: loaded, seasonCount: 12);
    final compactUninterrupted = compactor.compactFull(uninterrupted.checkpoint);

    expect(
      _seasonSignatures(first.report),
      _seasonSignatures(uninterrupted.report).take(8).toList(),
    );
    expect(
      _seasonSignatures(resumed.report),
      _seasonSignatures(uninterrupted.report).skip(8).toList(),
    );
    expect(
      compactCodec.encode(resumed.checkpoint),
      compactCodec.encode(compactUninterrupted),
    );
    expect(resumed.checkpoint.history.signature,
        compactUninterrupted.history.signature);
  });

  test('M28 keeps current state and bounds raw history to recent seasons', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 28002);
    final full = runtimeEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final compact = compactor.compactFull(full.checkpoint);

    expect(compact.recentHistoryStartSeasonIndex, 6);
    expect(compact.runtime.manager.seasons.map((item) => item.seasonIndex), [6, 7]);
    expect(
      compact.runtime.transfer.contractEvents
          .every((event) => event.seasonIndex >= 6),
      isTrue,
    );
    expect(
      compact.runtime.transfer.activeContracts
          .map((item) => item.signature)
          .toList(),
      full.checkpoint.transfer.activeContracts
          .map((item) => item.signature)
          .toList(),
    );
    expect(
      compact.runtime.transfer.installmentObligations
          .map((item) => item.signature)
          .toList(),
      full.checkpoint.transfer.installmentObligations
          .map((item) => item.signature)
          .toList(),
    );
    expect(
      compact.runtime.manager.assignments.map((item) => item.signature).toList(),
      full.checkpoint.manager.assignments.map((item) => item.signature).toList(),
    );
    expect(compact.history.contractEventCount,
        full.checkpoint.transfer.contractEvents.length);
    expect(compact.history.loanCount, full.checkpoint.transfer.loanHistory.length);
    expect(compact.history.managerSeasonCount, 8);
  });

  test('M28 compact save materially reduces M27 history payload size', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20260903);
    final full8 = runtimeEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final compact8 = compactor.compactFull(full8.checkpoint);
    final fullBytes = utf8.encode(fullCodec.encode(full8.checkpoint)).length;
    final compactBytes = utf8.encode(compactCodec.encode(compact8)).length;

    expect(compactBytes, lessThan(fullBytes));
    expect(compactBytes * 100, lessThan(fullBytes * 75));
    expect(compactBytes, lessThan(750000));
  });

  test('M28 rejects checksum corruption before loading compact payload', () {
    final checkpoint = _compactCheckpointFor(28003);
    final envelope = jsonDecode(compactCodec.encode(checkpoint))
        as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    payload['recentHistoryStartSeasonIndex'] = 999;

    expect(
      () => compactCodec.decode(jsonEncode(envelope)),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.checksumMismatch,
        ),
      ),
    );
  });

  test('M28 rejects checksum-valid future compact save version safely', () {
    final checkpoint = _compactCheckpointFor(28004);
    final envelope = jsonDecode(compactCodec.encode(checkpoint))
        as Map<String, dynamic>;
    const futureVersion = CompactAdvancedWorldSaveCodec.currentSaveVersion + 1;
    envelope['saveVersion'] = futureVersion;
    envelope['checksum'] = SaveChecksum.forPayload(
      saveVersion: futureVersion,
      payload: envelope['payload'],
    );

    expect(
      () => compactCodec.decode(SaveChecksum.canonicalJson(envelope)),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.unsupportedVersion,
        ),
      ),
    );
  });

  test('M28 migrates synthetic compact v0 fixture into v1', () {
    final checkpoint = _compactCheckpointFor(28005);
    final current = jsonDecode(compactCodec.encode(checkpoint))
        as Map<String, dynamic>;
    final payload = current['payload'] as Map<String, dynamic>;
    final legacyPayload = <String, Object?>{
      'advancedRuntimeSave': payload['runtimeSave'],
      'historyStartSeasonIndex': payload['recentHistoryStartSeasonIndex'],
      'historySummary': payload['history'],
    };
    final legacyEnvelope = <String, Object?>{
      'format': CompactAdvancedWorldSaveCodec.format,
      'saveVersion': 0,
      'payload': legacyPayload,
      'checksum': SaveChecksum.forPayload(
        saveVersion: 0,
        payload: legacyPayload,
      ),
    };

    final migrated = compactCodec.decode(
      SaveChecksum.canonicalJson(legacyEnvelope),
    );

    expect(compactCodec.encode(migrated), compactCodec.encode(checkpoint));
  });

  test('M28 rejects malformed JSON with an explicit failure code', () {
    expect(
      () => compactCodec.decode('{not-json'),
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

CompactAdvancedRuntimeCheckpoint _compactCheckpointFor(int seed) {
  final world = const FictionalWorldFactory().build();
  final full = const AdvancedRuntimeCareerEngine().simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    seasonCount: 4,
  );
  return const AdvancedRuntimeHistoryCompactor().compactFull(full.checkpoint);
}

List<String> _seasonSignatures(WorldCareerReport report) => report.seasons
    .map((season) {
      final leagues = season.leagueResults.map((league) {
        final fixtures = league.report.fixtures.map((fixture) {
          final result = fixture.result!;
          return '${fixture.id}:${result.homeGoals}-${result.awayGoals}:'
              '${result.homeExpectedGoals}:${result.awayExpectedGoals}:'
              '${result.matchSeed}';
        }).join();
        return '${league.tier.name}:${league.report.seasonIndex}:'
            '${league.report.seed}:${league.report.championClubId}:$fixtures';
      }).join('|');
      return '${season.seasonIndex}::$leagues::'
          '${season.transfersAfterSeason.map((deal) => deal.signature).join('|')}::'
          '${season.retiredAfterSeason.map((player) => player.signature).join('|')}::'
          '${season.youthIntakeAfterSeason.map((player) => player.signature).join('|')}::'
          '${season.financeStatesAfterWindow.map((state) => state.signature).join('|')}::'
          '${season.movementsAfterSeason.map((item) => item.signature).join('|')}::'
          '${season.leaguesAfterTransition.map((item) => item.signature).join('|')}';
    })
    .toList(growable: false);
