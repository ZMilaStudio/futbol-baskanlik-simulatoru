import 'dart:convert';

import '../career/career_checkpoint.dart';
import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';

class CareerSaveCodec {
  const CareerSaveCodec();

  static const String format = 'zmila-fbs-career';
  static const int currentSaveVersion = 1;

  String encode(CareerCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = _encodeV1Payload(checkpoint);
    final checksum = SaveChecksum.forPayload(
      saveVersion: currentSaveVersion,
      payload: payload,
    );
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': checksum,
    });
  }

  CareerCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Save is not valid JSON: ${error.message}',
      );
    }

    final envelope = _stringMap(
      decoded,
      failure: SaveLoadFailure.invalidEnvelope,
      field: 'envelope',
    );
    if (_string(envelope['format'], 'format') != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown save format.',
      );
    }

    final saveVersion = _integer(envelope['saveVersion'], 'saveVersion');
    if (saveVersion < 0) {
      throw const SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Save version cannot be negative.',
      );
    }
    final payload = envelope['payload'];
    final checksum = _string(envelope['checksum'], 'checksum');
    final expectedChecksum = SaveChecksum.forPayload(
      saveVersion: saveVersion,
      payload: payload,
    );
    if (checksum != expectedChecksum) {
      throw SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Save checksum mismatch: expected $expectedChecksum, found $checksum.',
      );
    }

    if (saveVersion > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Save version $saveVersion is newer than supported version '
        '$currentSaveVersion.',
      );
    }

    var migratedVersion = saveVersion;
    var migratedPayload = _stringMap(
      payload,
      failure: SaveLoadFailure.invalidPayload,
      field: 'payload',
    );
    while (migratedVersion < currentSaveVersion) {
      try {
        switch (migratedVersion) {
          case 0:
            migratedPayload = _migrateV0ToV1(migratedPayload);
            migratedVersion = 1;
          default:
            throw SaveLoadException(
              SaveLoadFailure.unsupportedVersion,
              'No migration path from save version $migratedVersion.',
            );
        }
      } on SaveLoadException {
        rethrow;
      } catch (error) {
        throw SaveLoadException(
          SaveLoadFailure.migrationFailed,
          'Save migration failed at version $migratedVersion: $error',
        );
      }
    }

    try {
      return _decodeV1Payload(migratedPayload);
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid save payload: $error',
      );
    }
  }

  Map<String, Object?> _encodeV1Payload(CareerCheckpoint checkpoint) => {
        'config': {
          'careerSeed': checkpoint.config.careerSeed,
          'simulationVersion': checkpoint.config.simulationVersion,
          'initialSeasonIndex': checkpoint.config.seasonIndex,
          'homeAdvantageRating': checkpoint.config.homeAdvantageRating,
          'baseHomeGoals': checkpoint.config.baseHomeGoals,
          'baseAwayGoals': checkpoint.config.baseAwayGoals,
          'ratingScale': checkpoint.config.ratingScale,
          'minExpectedGoals': checkpoint.config.minExpectedGoals,
          'maxExpectedGoals': checkpoint.config.maxExpectedGoals,
        },
        'careerStartDate': {
          'year': checkpoint.careerStartDate.year,
          'month': checkpoint.careerStartDate.month,
          'day': checkpoint.careerStartDate.day,
        },
        'completedSeasons': checkpoint.completedSeasons,
        'baselineStrengths': checkpoint.baselineStrengths,
        'nextSeasonClubs': checkpoint.nextSeasonClubs
            .map(
              (club) => {
                'id': club.id,
                'name': club.name,
                'strength': club.strength,
              },
            )
            .toList(growable: false),
      };

  CareerCheckpoint _decodeV1Payload(Map<String, Object?> payload) {
    final configJson = _stringMap(
      payload['config'],
      failure: SaveLoadFailure.invalidPayload,
      field: 'config',
    );
    final config = SimulationConfig(
      careerSeed: _integer(configJson['careerSeed'], 'config.careerSeed'),
      simulationVersion: _integer(
        configJson['simulationVersion'],
        'config.simulationVersion',
      ),
      seasonIndex: _integer(
        configJson['initialSeasonIndex'],
        'config.initialSeasonIndex',
      ),
      homeAdvantageRating: _finiteDouble(
        configJson['homeAdvantageRating'],
        'config.homeAdvantageRating',
      ),
      baseHomeGoals: _finiteDouble(
        configJson['baseHomeGoals'],
        'config.baseHomeGoals',
      ),
      baseAwayGoals: _finiteDouble(
        configJson['baseAwayGoals'],
        'config.baseAwayGoals',
      ),
      ratingScale: _finiteDouble(
        configJson['ratingScale'],
        'config.ratingScale',
      ),
      minExpectedGoals: _finiteDouble(
        configJson['minExpectedGoals'],
        'config.minExpectedGoals',
      ),
      maxExpectedGoals: _finiteDouble(
        configJson['maxExpectedGoals'],
        'config.maxExpectedGoals',
      ),
    );

    final dateJson = _stringMap(
      payload['careerStartDate'],
      failure: SaveLoadFailure.invalidPayload,
      field: 'careerStartDate',
    );
    final careerStartDate = _date(
      year: _integer(dateJson['year'], 'careerStartDate.year'),
      month: _integer(dateJson['month'], 'careerStartDate.month'),
      day: _integer(dateJson['day'], 'careerStartDate.day'),
      field: 'careerStartDate',
    );

    final baselineJson = _stringMap(
      payload['baselineStrengths'],
      failure: SaveLoadFailure.invalidPayload,
      field: 'baselineStrengths',
    );
    final baselineStrengths = <String, double>{
      for (final entry in baselineJson.entries)
        entry.key: _finiteDouble(
          entry.value,
          'baselineStrengths.${entry.key}',
        ),
    };

    final clubsJson = payload['nextSeasonClubs'];
    if (clubsJson is! List) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'nextSeasonClubs must be a list.',
      );
    }
    final clubs = <Club>[];
    for (var i = 0; i < clubsJson.length; i++) {
      final clubJson = _stringMap(
        clubsJson[i],
        failure: SaveLoadFailure.invalidPayload,
        field: 'nextSeasonClubs[$i]',
      );
      clubs.add(
        Club(
          id: _string(clubJson['id'], 'nextSeasonClubs[$i].id'),
          name: _string(clubJson['name'], 'nextSeasonClubs[$i].name'),
          strength: _finiteDouble(
            clubJson['strength'],
            'nextSeasonClubs[$i].strength',
          ),
        ),
      );
    }

    try {
      return CareerCheckpoint(
        config: config,
        careerStartDate: careerStartDate,
        completedSeasons: _integer(
          payload['completedSeasons'],
          'completedSeasons',
        ),
        baselineStrengths: baselineStrengths,
        nextSeasonClubs: clubs,
      );
    } on ArgumentError catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        error.message?.toString() ?? error.toString(),
      );
    }
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) {
    final start = _string(legacy['start'], 'start');
    final parts = start.split('-');
    if (parts.length != 3) {
      throw const SaveLoadException(
        SaveLoadFailure.migrationFailed,
        'Legacy start date must use YYYY-MM-DD.',
      );
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw const SaveLoadException(
        SaveLoadFailure.migrationFailed,
        'Legacy start date is invalid.',
      );
    }
    _date(year: year, month: month, day: day, field: 'start');

    final baseline = _stringMap(
      legacy['baseline'],
      failure: SaveLoadFailure.migrationFailed,
      field: 'baseline',
    );
    final clubs = legacy['clubs'];
    if (clubs is! List) {
      throw const SaveLoadException(
        SaveLoadFailure.migrationFailed,
        'Legacy clubs must be a list.',
      );
    }

    const defaults = SimulationConfig(careerSeed: 0);
    return {
      'config': {
        'careerSeed': _integer(legacy['seed'], 'seed'),
        'simulationVersion': _integer(legacy['simVersion'], 'simVersion'),
        'initialSeasonIndex': _integer(
          legacy['initialSeason'],
          'initialSeason',
        ),
        'homeAdvantageRating': defaults.homeAdvantageRating,
        'baseHomeGoals': defaults.baseHomeGoals,
        'baseAwayGoals': defaults.baseAwayGoals,
        'ratingScale': defaults.ratingScale,
        'minExpectedGoals': defaults.minExpectedGoals,
        'maxExpectedGoals': defaults.maxExpectedGoals,
      },
      'careerStartDate': {
        'year': year,
        'month': month,
        'day': day,
      },
      'completedSeasons': _integer(legacy['completed'], 'completed'),
      'baselineStrengths': baseline,
      'nextSeasonClubs': clubs,
    };
  }

  static Map<String, Object?> _stringMap(
    Object? value, {
    required SaveLoadFailure failure,
    required String field,
  }) {
    if (value is! Map) {
      throw SaveLoadException(failure, '$field must be an object.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw SaveLoadException(failure, '$field must use string keys.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be a non-empty string.',
      );
    }
    return value;
  }

  static int _integer(Object? value, String field) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field must be an integer.',
    );
  }

  static double _finiteDouble(Object? value, String field) {
    if (value is num && value.isFinite) return value.toDouble();
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field must be a finite number.',
    );
  }

  static GameDate _date({
    required int year,
    required int month,
    required int day,
    required String field,
  }) {
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field contains an invalid date.',
      );
    }
    return GameDate(year, month, day);
  }
}
