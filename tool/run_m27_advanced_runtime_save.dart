import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  const engine = AdvancedRuntimeCareerEngine();
  const codec = AdvancedWorldSaveCodec();
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
  final checkpointMatch =
      codec.encode(resumed.checkpoint) == codec.encode(uninterrupted.checkpoint);

  final payload = envelope['payload'] as Map<String, dynamic>;
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
  final legacyEncoding = SaveChecksum.canonicalJson({
    'format': AdvancedWorldSaveCodec.format,
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

  print('M27 Advanced World Runtime Snapshot I');
  print('Seed: $seed');
  print('Save version: ${envelope['saveVersion']}');
  print('Checksum: ${envelope['checksum']}');
  print('Save bytes: ${utf8.encode(encoded).length}');
  print('Split: 8 + 12 seasons');
  print('Loaded next season index: ${loaded.nextSeasonIndex}');
  print('Season replay match: $seasonMatch');
  print('Final runtime checkpoint match: $checkpointMatch');
  print('Contracts at checkpoint: ${loaded.transfer.activeContracts.length}');
  print('Contract events at checkpoint: ${loaded.transfer.contractEvents.length}');
  print('Active loans at checkpoint: ${loaded.transfer.activeLoans.length}');
  print('Loan history at checkpoint: ${loaded.transfer.loanHistory.length}');
  print('Installment obligations: ${loaded.transfer.installmentObligations.length}');
  print('Managers in pool: ${loaded.manager.managers.length}');
  print('Manager assignments: ${loaded.manager.assignments.length}');
  print('Manager seasons: ${loaded.manager.seasons.length}');
  print('Legacy fixture migrated to: v$migratedVersion');

  if (envelope['saveVersion'] != AdvancedWorldSaveCodec.currentSaveVersion ||
      loaded.nextSeasonIndex != 8 ||
      !seasonMatch ||
      !checkpointMatch ||
      loaded.manager.assignments.length != 48 ||
      loaded.manager.seasons.length != 8 ||
      migratedVersion != AdvancedWorldSaveCodec.currentSaveVersion) {
    throw StateError('M27 advanced runtime save continuation failed.');
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
          '${season.financeStatesAfterWindow.map((state) => state.signature).join('|')}::'
          '${season.movementsAfterSeason.map((item) => item.signature).join('|')}::'
          '${season.leaguesAfterTransition.map((item) => item.signature).join('|')}';
    })
    .join('\n');
