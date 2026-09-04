import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_position.dart';
import '../world/league_tier.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';

class WorldSaveCodec {
  const WorldSaveCodec();

  static const String format = 'zmila-fbs-world';
  static const int currentSaveVersion = 1;

  String encode(WorldCheckpoint checkpoint) {
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

  WorldCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'World save is not valid JSON: ${error.message}',
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
        'Unknown world save format.',
      );
    }

    final saveVersion = _integer(envelope['saveVersion'], 'saveVersion');
    if (saveVersion < 0) {
      throw const SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'World save version cannot be negative.',
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
        'World save checksum mismatch: expected $expectedChecksum, '
        'found $checksum.',
      );
    }
    if (saveVersion > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'World save version $saveVersion is newer than supported version '
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
              'No world migration path from save version $migratedVersion.',
            );
        }
      } on SaveLoadException {
        rethrow;
      } catch (error) {
        throw SaveLoadException(
          SaveLoadFailure.migrationFailed,
          'World save migration failed at version $migratedVersion: $error',
        );
      }
    }

    try {
      return _decodeV1Payload(migratedPayload);
    } on SaveLoadException {
      rethrow;
    } on ArgumentError catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        error.message?.toString() ?? error.toString(),
      );
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid world save payload: $error',
      );
    }
  }

  Map<String, Object?> _encodeV1Payload(WorldCheckpoint checkpoint) => {
        'config': _encodeConfig(checkpoint.config),
        'completedSeasons': checkpoint.completedSeasons,
        'baseClubs': checkpoint.baseClubs
            .map(
              (club) => {
                'id': club.id,
                'name': club.name,
                'strength': club.strength,
              },
            )
            .toList(growable: false),
        'nextSeasonLeagues': checkpoint.nextSeasonLeagues
            .map(
              (league) => {
                'tier': league.tier.name,
                'clubIds': league.clubIds,
              },
            )
            .toList(growable: false),
        'nextSeasonPlayers': checkpoint.nextSeasonPlayers
            .map(
              (player) => {
                'id': player.id,
                'name': player.name,
                'clubId': player.clubId,
                'position': player.position.name,
                'age': player.age,
                'ability': player.ability,
                'potential': player.potential,
                'retirementAge': player.retirementAge,
                'isAcademyGraduate': player.isAcademyGraduate,
              },
            )
            .toList(growable: false),
        'nextSeasonFinanceStates': checkpoint.nextSeasonFinanceStates
            .map(
              (state) => {
                'clubId': state.clubId,
                'cashMinorUnits': state.cash.minorUnits,
                'debtMinorUnits': state.debt.minorUnits,
              },
            )
            .toList(growable: false),
      };

  WorldCheckpoint _decodeV1Payload(Map<String, Object?> payload) {
    final config = _decodeConfig(
      _stringMap(
        payload['config'],
        failure: SaveLoadFailure.invalidPayload,
        field: 'config',
      ),
    );

    final clubsJson = _list(payload['baseClubs'], 'baseClubs');
    final clubs = <Club>[];
    for (var i = 0; i < clubsJson.length; i++) {
      final item = _stringMap(
        clubsJson[i],
        failure: SaveLoadFailure.invalidPayload,
        field: 'baseClubs[$i]',
      );
      clubs.add(
        Club(
          id: _string(item['id'], 'baseClubs[$i].id'),
          name: _string(item['name'], 'baseClubs[$i].name'),
          strength: _finiteDouble(
            item['strength'],
            'baseClubs[$i].strength',
          ),
        ),
      );
    }

    final leaguesJson = _list(
      payload['nextSeasonLeagues'],
      'nextSeasonLeagues',
    );
    final leagues = <WorldLeague>[];
    for (var i = 0; i < leaguesJson.length; i++) {
      final item = _stringMap(
        leaguesJson[i],
        failure: SaveLoadFailure.invalidPayload,
        field: 'nextSeasonLeagues[$i]',
      );
      leagues.add(
        WorldLeague(
          tier: _leagueTier(
            _string(item['tier'], 'nextSeasonLeagues[$i].tier'),
            'nextSeasonLeagues[$i].tier',
          ),
          clubIds: _stringList(
            item['clubIds'],
            'nextSeasonLeagues[$i].clubIds',
          ),
        ),
      );
    }

    final playersJson = _list(
      payload['nextSeasonPlayers'],
      'nextSeasonPlayers',
    );
    final players = <Player>[];
    for (var i = 0; i < playersJson.length; i++) {
      final item = _stringMap(
        playersJson[i],
        failure: SaveLoadFailure.invalidPayload,
        field: 'nextSeasonPlayers[$i]',
      );
      players.add(
        Player(
          id: _string(item['id'], 'nextSeasonPlayers[$i].id'),
          name: _string(item['name'], 'nextSeasonPlayers[$i].name'),
          clubId: _string(item['clubId'], 'nextSeasonPlayers[$i].clubId'),
          position: _playerPosition(
            _string(item['position'], 'nextSeasonPlayers[$i].position'),
            'nextSeasonPlayers[$i].position',
          ),
          age: _integer(item['age'], 'nextSeasonPlayers[$i].age'),
          ability: _finiteDouble(
            item['ability'],
            'nextSeasonPlayers[$i].ability',
          ),
          potential: _finiteDouble(
            item['potential'],
            'nextSeasonPlayers[$i].potential',
          ),
          retirementAge: _integer(
            item['retirementAge'],
            'nextSeasonPlayers[$i].retirementAge',
          ),
          isAcademyGraduate: _boolean(
            item['isAcademyGraduate'],
            'nextSeasonPlayers[$i].isAcademyGraduate',
          ),
        ),
      );
    }

    final financesJson = _list(
      payload['nextSeasonFinanceStates'],
      'nextSeasonFinanceStates',
    );
    final finances = <ClubFinanceState>[];
    for (var i = 0; i < financesJson.length; i++) {
      final item = _stringMap(
        financesJson[i],
        failure: SaveLoadFailure.invalidPayload,
        field: 'nextSeasonFinanceStates[$i]',
      );
      finances.add(
        ClubFinanceState(
          clubId: _string(
            item['clubId'],
            'nextSeasonFinanceStates[$i].clubId',
          ),
          cash: Money.fromMinorUnits(
            _integer(
              item['cashMinorUnits'],
              'nextSeasonFinanceStates[$i].cashMinorUnits',
            ),
          ),
          debt: Money.fromMinorUnits(
            _integer(
              item['debtMinorUnits'],
              'nextSeasonFinanceStates[$i].debtMinorUnits',
            ),
          ),
        ),
      );
    }

    return WorldCheckpoint(
      config: config,
      completedSeasons: _integer(
        payload['completedSeasons'],
        'completedSeasons',
      ),
      baseClubs: clubs,
      nextSeasonLeagues: leagues,
      nextSeasonPlayers: players,
      nextSeasonFinanceStates: finances,
    );
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) {
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
      'completedSeasons': _integer(legacy['completed'], 'completed'),
      'baseClubs': _list(legacy['clubs'], 'clubs'),
      'nextSeasonLeagues': _list(legacy['leagues'], 'leagues'),
      'nextSeasonPlayers': _list(legacy['players'], 'players'),
      'nextSeasonFinanceStates': _list(legacy['finances'], 'finances'),
    };
  }

  Map<String, Object?> _encodeConfig(SimulationConfig config) => {
        'careerSeed': config.careerSeed,
        'simulationVersion': config.simulationVersion,
        'initialSeasonIndex': config.seasonIndex,
        'homeAdvantageRating': config.homeAdvantageRating,
        'baseHomeGoals': config.baseHomeGoals,
        'baseAwayGoals': config.baseAwayGoals,
        'ratingScale': config.ratingScale,
        'minExpectedGoals': config.minExpectedGoals,
        'maxExpectedGoals': config.maxExpectedGoals,
      };

  SimulationConfig _decodeConfig(Map<String, Object?> json) => SimulationConfig(
        careerSeed: _integer(json['careerSeed'], 'config.careerSeed'),
        simulationVersion: _integer(
          json['simulationVersion'],
          'config.simulationVersion',
        ),
        seasonIndex: _integer(
          json['initialSeasonIndex'],
          'config.initialSeasonIndex',
        ),
        homeAdvantageRating: _finiteDouble(
          json['homeAdvantageRating'],
          'config.homeAdvantageRating',
        ),
        baseHomeGoals: _finiteDouble(
          json['baseHomeGoals'],
          'config.baseHomeGoals',
        ),
        baseAwayGoals: _finiteDouble(
          json['baseAwayGoals'],
          'config.baseAwayGoals',
        ),
        ratingScale: _finiteDouble(
          json['ratingScale'],
          'config.ratingScale',
        ),
        minExpectedGoals: _finiteDouble(
          json['minExpectedGoals'],
          'config.minExpectedGoals',
        ),
        maxExpectedGoals: _finiteDouble(
          json['maxExpectedGoals'],
          'config.maxExpectedGoals',
        ),
      );

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

  static List<Object?> _list(Object? value, String field) {
    if (value is! List) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be a list.',
      );
    }
    return List<Object?>.from(value);
  }

  static List<String> _stringList(Object? value, String field) {
    final values = _list(value, field);
    final result = <String>[];
    for (var i = 0; i < values.length; i++) {
      result.add(_string(values[i], '$field[$i]'));
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

  static bool _boolean(Object? value, String field) {
    if (value is bool) return value;
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field must be a boolean.',
    );
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

  static LeagueTier _leagueTier(String value, String field) {
    for (final tier in LeagueTier.values) {
      if (tier.name == value) return tier;
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field contains unknown league tier $value.',
    );
  }

  static PlayerPosition _playerPosition(String value, String field) {
    for (final position in PlayerPosition.values) {
      if (position.name == value) return position;
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field contains unknown player position $value.',
    );
  }
}
