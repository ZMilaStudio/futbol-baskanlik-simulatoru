import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import 'm0_data.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  const engine = CareerEngine();
  const codec = CareerSaveCodec();
  final config = SimulationConfig(careerSeed: seed);

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
  final encoded = codec.encode(firstSegment.checkpoint);
  final envelope = jsonDecode(encoded) as Map<String, dynamic>;
  final loaded = codec.decode(encoded);
  final resumed = engine.resume(checkpoint: loaded, seasonCount: 12);

  final seasonMatch = _seasonSignatures(resumed.report) ==
      _seasonSignatures(uninterrupted.report, skip: 8);
  final finalClubMatch = _clubSignature(resumed.report.finalClubs) ==
      _clubSignature(uninterrupted.report.finalClubs);
  final nextCheckpointMatch =
      _clubSignature(resumed.checkpoint.nextSeasonClubs) ==
          _clubSignature(uninterrupted.checkpoint.nextSeasonClubs);

  final legacy = File('test/fixtures/m25_save_v0.json').readAsStringSync();
  final migrated = codec.decode(legacy);
  final migratedEncoding = codec.encode(migrated);
  final migratedEnvelope = jsonDecode(migratedEncoding) as Map<String, dynamic>;

  print('M25 save/load + versioning career');
  print('Seed: $seed');
  print('Save version: ${envelope['saveVersion']}');
  print('Checksum: ${envelope['checksum']}');
  print('Save bytes: ${utf8.encode(encoded).length}');
  print('Split: 8 + 12 seasons');
  print('Loaded next season index: ${loaded.nextSeasonIndex}');
  print('Loaded next season date: ${loaded.nextSeasonStartDate}');
  print('Season replay match: $seasonMatch');
  print('Final report clubs match: $finalClubMatch');
  print('Next checkpoint clubs match: $nextCheckpointMatch');
  print('Legacy fixture migrated to: v${migratedEnvelope['saveVersion']}');

  if (envelope['saveVersion'] != CareerSaveCodec.currentSaveVersion ||
      !seasonMatch ||
      !finalClubMatch ||
      !nextCheckpointMatch ||
      migratedEnvelope['saveVersion'] != CareerSaveCodec.currentSaveVersion) {
    throw StateError('M25 save/load continuation validation failed.');
  }
}

String _seasonSignatures(CareerReport report, {int skip = 0}) => report.seasons
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
    .join('\n');

String _clubSignature(List<Club> clubs) =>
    clubs.map((club) => '${club.id}:${club.name}:${club.strength}').join('|');
