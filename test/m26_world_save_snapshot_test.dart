import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const engine = WorldCareerEngine();
  const codec = WorldSaveCodec();

  test('M26 world save encoding is deterministic and round-trips state', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(
      careerSeed: 26001,
      simulationVersion: 3,
      seasonIndex: 4,
      homeAdvantageRating: 1.75,
      baseHomeGoals: 1.40,
      baseAwayGoals: 1.10,
      ratingScale: 50.0,
      minExpectedGoals: 0.30,
      maxExpectedGoals: 3.25,
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
    expect(decoded.config.careerSeed, config.careerSeed);
    expect(decoded.config.simulationVersion, config.simulationVersion);
    expect(decoded.config.seasonIndex, config.seasonIndex);
    expect(decoded.config.homeAdvantageRating, config.homeAdvantageRating);
    expect(decoded.config.baseHomeGoals, config.baseHomeGoals);
    expect(decoded.config.baseAwayGoals, config.baseAwayGoals);
    expect(decoded.config.ratingScale, config.ratingScale);
    expect(decoded.config.minExpectedGoals, config.minExpectedGoals);
    expect(decoded.config.maxExpectedGoals, config.maxExpectedGoals);
    expect(_checkpointSignature(decoded), _checkpointSignature(run.checkpoint));
  });

  test('M26 8 save load 12 matches uninterrupted 20-season world', () {
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
    expect(
      _playerSignatures(resumed.report.finalPlayers),
      _playerSignatures(uninterrupted.report.finalPlayers),
    );
    expect(
      _financeSignatures(resumed.report.finalFinanceStates),
      _financeSignatures(uninterrupted.report.finalFinanceStates),
    );
    expect(
      _leagueSignatures(resumed.report.finalLeagues),
      _leagueSignatures(uninterrupted.report.finalLeagues),
    );
    expect(
      _clubSignatures(resumed.report.finalClubs),
      _clubSignatures(uninterrupted.report.finalClubs),
    );
    expect(resumed.checkpoint.completedSeasons, 20);
    expect(resumed.checkpoint.nextSeasonIndex, 20);
    expect(
      _checkpointSignature(resumed.checkpoint),
      _checkpointSignature(uninterrupted.checkpoint),
    );
  });

  test('M26 preserves legacy WorldCareerEngine.simulate final-season semantics', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 26002);

    final legacy = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );
    final checkpointCapable = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );

    expect(legacy.seasons.last.movementsAfterSeason, isEmpty);
    expect(legacy.seasons.last.retiredAfterSeason, isEmpty);
    expect(legacy.seasons.last.youthIntakeAfterSeason, isEmpty);
    expect(legacy.seasons.last.transfersAfterSeason, isEmpty);
    expect(checkpointCapable.report.seasons.last.movementsAfterSeason.length, 12);
    expect(checkpointCapable.checkpoint.completedSeasons, 2);
    expect(checkpointCapable.checkpoint.nextSeasonIndex, 2);
  });

  test('M26 rejects checksum corruption before loading world payload', () {
    final world = const FictionalWorldFactory().build();
    final run = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 26003),
      seasonCount: 2,
    );
    final envelope = jsonDecode(codec.encode(run.checkpoint))
        as Map<String, dynamic>;
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

  test('M26 rejects checksum-valid future world save version safely', () {
    final world = const FictionalWorldFactory().build();
    final run = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 26004),
      seasonCount: 2,
    );
    final envelope = jsonDecode(codec.encode(run.checkpoint))
        as Map<String, dynamic>;
    const futureVersion = WorldSaveCodec.currentSaveVersion + 1;
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

  test('M26 migrates synthetic v0 world fixture into v1 checkpoint', () {
    final world = const FictionalWorldFactory().build();
    final run = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 26005, seasonIndex: 3),
      seasonCount: 2,
    );
    final current = jsonDecode(codec.encode(run.checkpoint))
        as Map<String, dynamic>;
    final payload = current['payload'] as Map<String, dynamic>;
    final config = payload['config'] as Map<String, dynamic>;
    final legacyPayload = <String, Object?>{
      'seed': config['careerSeed'],
      'simVersion': config['simulationVersion'],
      'initialSeason': config['initialSeasonIndex'],
      'completed': payload['completedSeasons'],
      'clubs': payload['baseClubs'],
      'leagues': payload['nextSeasonLeagues'],
      'players': payload['nextSeasonPlayers'],
      'finances': payload['nextSeasonFinanceStates'],
    };
    final legacyEnvelope = <String, Object?>{
      'format': WorldSaveCodec.format,
      'saveVersion': 0,
      'payload': legacyPayload,
      'checksum': SaveChecksum.forPayload(
        saveVersion: 0,
        payload: legacyPayload,
      ),
    };

    final migrated = codec.decode(SaveChecksum.canonicalJson(legacyEnvelope));

    expect(WorldSaveCodec.currentSaveVersion, 1);
    expect(migrated.config.careerSeed, 26005);
    expect(migrated.config.seasonIndex, 3);
    expect(migrated.completedSeasons, 2);
    expect(migrated.nextSeasonIndex, 5);
    expect(migrated.config.homeAdvantageRating, 2.0);
    expect(migrated.config.baseHomeGoals, 1.35);
    expect(migrated.config.baseAwayGoals, 1.15);
    expect(_checkpointSignature(migrated), _checkpointSignature(run.checkpoint));
  });

  test('M26 rejects malformed JSON with an explicit failure code', () {
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
      final transfers =
          season.transfersAfterSeason.map((deal) => deal.signature).join('|');
      final retired =
          season.retiredAfterSeason.map((player) => player.signature).join('|');
      final youth =
          season.youthIntakeAfterSeason.map((player) => player.signature).join('|');
      final finances = _financeSignatures(season.financeStatesAfterWindow).join('|');
      final movements =
          season.movementsAfterSeason.map((item) => item.signature).join('|');
      final nextLeagues = _leagueSignatures(season.leaguesAfterTransition).join('|');
      return '${season.seasonIndex}::$leagues::$transfers::$retired::$youth::'
          '$finances::$movements::$nextLeagues';
    })
    .toList(growable: false);

String _checkpointSignature(WorldCheckpoint checkpoint) => [
      checkpoint.config.careerSeed,
      checkpoint.config.simulationVersion,
      checkpoint.config.seasonIndex,
      checkpoint.completedSeasons,
      ..._clubSignatures(checkpoint.baseClubs),
      ..._leagueSignatures(checkpoint.nextSeasonLeagues),
      ..._playerSignatures(checkpoint.nextSeasonPlayers),
      ..._financeSignatures(checkpoint.nextSeasonFinanceStates),
    ].join('||');

List<String> _clubSignatures(List<Club> clubs) => clubs
    .map((club) => '${club.id}:${club.name}:${club.strength}')
    .toList(growable: false);

List<String> _playerSignatures(List<Player> players) =>
    players.map((player) => player.signature).toList(growable: false);

List<String> _financeSignatures(List<ClubFinanceState> states) =>
    states.map((state) => state.signature).toList(growable: false);

List<String> _leagueSignatures(List<WorldLeague> leagues) =>
    leagues.map((league) => league.signature).toList(growable: false);
