import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const engine = AdvancedRuntimeCareerEngine();
  const codec = AdvancedWorldSaveCodec();

  test('M27 advanced save encoding is deterministic and round-trips state', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(
      careerSeed: 27001,
      simulationVersion: 3,
      seasonIndex: 4,
    );
    final run = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
    );

    final encoded = codec.encode(run.checkpoint);
    final decoded = codec.decode(encoded);

    expect(codec.encode(decoded), encoded);
    expect(decoded.completedSeasons, 3);
    expect(decoded.nextSeasonIndex, 7);
    expect(decoded.transfer.activeContracts, isNotEmpty);
    expect(decoded.manager.assignments.length, 48);
    expect(decoded.manager.seasons.length, 3);
  });

  test('M27 8 save load 12 matches uninterrupted 20-season advanced world', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20260903);

    final uninterrupted = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 20,
    );
    final firstSegment = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final loaded = codec.decode(codec.encode(firstSegment.checkpoint));
    final resumed = engine.resume(checkpoint: loaded, seasonCount: 12);

    expect(
      _seasonSignatures(firstSegment.report),
      _seasonSignatures(uninterrupted.report).take(8).toList(),
    );
    expect(
      _seasonSignatures(resumed.report),
      _seasonSignatures(uninterrupted.report).skip(8).toList(),
    );
    expect(codec.encode(resumed.checkpoint), codec.encode(uninterrupted.checkpoint));
    expect(resumed.checkpoint.completedSeasons, 20);
    expect(resumed.checkpoint.nextSeasonIndex, 20);
  });

  test('M27 restored runtime preserves every owned state stream', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 27002);
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));

    expect(
      loaded.transfer.activeContracts.map((item) => item.signature).toList(),
      first.checkpoint.transfer.activeContracts
          .map((item) => item.signature)
          .toList(),
    );
    expect(
      loaded.transfer.contractEvents.map((item) => item.signature).toList(),
      first.checkpoint.transfer.contractEvents
          .map((item) => item.signature)
          .toList(),
    );
    expect(
      loaded.transfer.activeLoans.map((item) => item.signature).toList(),
      first.checkpoint.transfer.activeLoans.map((item) => item.signature).toList(),
    );
    expect(
      loaded.transfer.loanHistory.map((item) => item.signature).toList(),
      first.checkpoint.transfer.loanHistory.map((item) => item.signature).toList(),
    );
    expect(
      loaded.transfer.installmentObligations
          .map((item) => item.signature)
          .toList(),
      first.checkpoint.transfer.installmentObligations
          .map((item) => item.signature)
          .toList(),
    );
    expect(
      loaded.manager.managers.map((item) => item.signature).toList(),
      first.checkpoint.manager.managers.map((item) => item.signature).toList(),
    );
    expect(
      loaded.manager.assignments.map((item) => item.signature).toList(),
      first.checkpoint.manager.assignments.map((item) => item.signature).toList(),
    );
    expect(
      loaded.manager.seasons.map((item) => item.signature).toList(),
      first.checkpoint.manager.seasons.map((item) => item.signature).toList(),
    );
  });

  test('M27 rejects checksum corruption before loading runtime payload', () {
    final checkpoint = _checkpointFor(27003);
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    final manager = payload['manager'] as Map<String, dynamic>;
    (manager['assignments'] as List<dynamic>).removeLast();

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

  test('M27 rejects checksum-valid future advanced save version safely', () {
    final checkpoint = _checkpointFor(27004);
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    const futureVersion = AdvancedWorldSaveCodec.currentSaveVersion + 1;
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

  test('M27 rejects checksum-valid invalid manager assignment state', () {
    final checkpoint = _checkpointFor(27005);
    final envelope = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    final manager = payload['manager'] as Map<String, dynamic>;
    final assignments = manager['assignments'] as List<dynamic>;
    assignments[1] = Map<String, dynamic>.from(assignments.first as Map)
      ..['managerId'] =
          (assignments[1] as Map<String, dynamic>)['managerId'];
    envelope['checksum'] = SaveChecksum.forPayload(
      saveVersion: envelope['saveVersion'] as int,
      payload: payload,
    );

    expect(
      () => codec.decode(SaveChecksum.canonicalJson(envelope)),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.invalidPayload,
        ),
      ),
    );
  });

  test('M27 migrates synthetic v0 advanced fixture into v1 checkpoint', () {
    final checkpoint = _checkpointFor(27006);
    final current = jsonDecode(codec.encode(checkpoint)) as Map<String, dynamic>;
    final payload = current['payload'] as Map<String, dynamic>;
    final transfer = payload['transfer'] as Map<String, dynamic>;
    final manager = payload['manager'] as Map<String, dynamic>;
    final legacyPayload = <String, Object?>{
      'coreWorldSave': payload['worldSave'],
      'contracts': transfer['activeContracts'],
      'events': transfer['contractEvents'],
      'activeLoans': transfer['activeLoans'],
      'loanHistory': transfer['loanHistory'],
      'installments': transfer['installmentObligations'],
      'managers': manager['managers'],
      'assignments': manager['assignments'],
      'managerSeasons': manager['seasons'],
    };
    final legacyEnvelope = <String, Object?>{
      'format': AdvancedWorldSaveCodec.format,
      'saveVersion': 0,
      'payload': legacyPayload,
      'checksum': SaveChecksum.forPayload(
        saveVersion: 0,
        payload: legacyPayload,
      ),
    };

    final migrated = codec.decode(SaveChecksum.canonicalJson(legacyEnvelope));

    expect(codec.encode(migrated), codec.encode(checkpoint));
  });

  test('M27 rejects malformed JSON with an explicit failure code', () {
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

AdvancedRuntimeCheckpoint _checkpointFor(int seed) {
  final world = const FictionalWorldFactory().build();
  return const AdvancedRuntimeCareerEngine()
      .simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: SimulationConfig(careerSeed: seed),
        seasonCount: 3,
      )
      .checkpoint;
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
