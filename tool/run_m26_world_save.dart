import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  const engine = WorldCareerEngine();
  const codec = WorldSaveCodec();
  final config = SimulationConfig(careerSeed: seed);

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
  final encoded = codec.encode(firstSegment.checkpoint);
  final envelope = jsonDecode(encoded) as Map<String, dynamic>;
  final loaded = codec.decode(encoded);
  final resumed = engine.resume(checkpoint: loaded, seasonCount: 12);

  final seasonMatch = _seasonSignatures(resumed.report) ==
      _seasonSignatures(uninterrupted.report, skip: 8);
  final playerMatch = _playerSignature(resumed.report.finalPlayers) ==
      _playerSignature(uninterrupted.report.finalPlayers);
  final financeMatch = _financeSignature(resumed.report.finalFinanceStates) ==
      _financeSignature(uninterrupted.report.finalFinanceStates);
  final leagueMatch = _leagueSignature(resumed.report.finalLeagues) ==
      _leagueSignature(uninterrupted.report.finalLeagues);
  final checkpointMatch = _checkpointSignature(resumed.checkpoint) ==
      _checkpointSignature(uninterrupted.checkpoint);

  final currentPayload = envelope['payload'] as Map<String, dynamic>;
  final currentConfig = currentPayload['config'] as Map<String, dynamic>;
  final legacyPayload = <String, Object?>{
    'seed': currentConfig['careerSeed'],
    'simVersion': currentConfig['simulationVersion'],
    'initialSeason': currentConfig['initialSeasonIndex'],
    'completed': currentPayload['completedSeasons'],
    'clubs': currentPayload['baseClubs'],
    'leagues': currentPayload['nextSeasonLeagues'],
    'players': currentPayload['nextSeasonPlayers'],
    'finances': currentPayload['nextSeasonFinanceStates'],
  };
  final legacyEncoding = SaveChecksum.canonicalJson({
    'format': WorldSaveCodec.format,
    'saveVersion': 0,
    'payload': legacyPayload,
    'checksum': SaveChecksum.forPayload(
      saveVersion: 0,
      payload: legacyPayload,
    ),
  });
  final migrated = codec.decode(legacyEncoding);
  final migratedVersion = (jsonDecode(codec.encode(migrated))
      as Map<String, dynamic>)['saveVersion'];

  print('M26 World Save Snapshot I');
  print('Seed: $seed');
  print('Save version: ${envelope['saveVersion']}');
  print('Checksum: ${envelope['checksum']}');
  print('Save bytes: ${utf8.encode(encoded).length}');
  print('Split: 8 + 12 seasons');
  print('Loaded next season index: ${loaded.nextSeasonIndex}');
  print('Season replay match: $seasonMatch');
  print('Final players match: $playerMatch');
  print('Final finance match: $financeMatch');
  print('Final leagues match: $leagueMatch');
  print('Next checkpoint match: $checkpointMatch');
  print('Legacy fixture migrated to: v$migratedVersion');

  if (envelope['saveVersion'] != WorldSaveCodec.currentSaveVersion ||
      loaded.nextSeasonIndex != 8 ||
      !seasonMatch ||
      !playerMatch ||
      !financeMatch ||
      !leagueMatch ||
      !checkpointMatch ||
      migratedVersion != WorldSaveCodec.currentSaveVersion) {
    throw StateError('M26 world save continuation validation failed.');
  }
}

String _seasonSignatures(WorldCareerReport report, {int skip = 0}) => report
    .seasons
    .skip(skip)
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
          '${_financeSignature(season.financeStatesAfterWindow)}::'
          '${season.movementsAfterSeason.map((item) => item.signature).join('|')}::'
          '${_leagueSignature(season.leaguesAfterTransition)}';
    })
    .join('\n');

String _playerSignature(List<Player> players) =>
    players.map((player) => player.signature).join('|');

String _financeSignature(List<ClubFinanceState> states) =>
    states.map((state) => state.signature).join('|');

String _leagueSignature(List<WorldLeague> leagues) =>
    leagues.map((league) => league.signature).join('|');

String _checkpointSignature(WorldCheckpoint checkpoint) => [
      checkpoint.config.careerSeed,
      checkpoint.config.simulationVersion,
      checkpoint.config.seasonIndex,
      checkpoint.completedSeasons,
      checkpoint.baseClubs
          .map((club) => '${club.id}:${club.name}:${club.strength}')
          .join('|'),
      _leagueSignature(checkpoint.nextSeasonLeagues),
      _playerSignature(checkpoint.nextSeasonPlayers),
      _financeSignature(checkpoint.nextSeasonFinanceStates),
    ].join('||');
