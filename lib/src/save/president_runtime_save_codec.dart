import 'dart:convert';

import '../election/president_management_profile.dart';
import '../election/president_tenure.dart';
import '../fan/fan_state.dart';
import '../media/media_state.dart';
import 'compact_advanced_world_save_codec.dart';
import 'president_runtime_checkpoint.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';

class PresidentRuntimeSaveCodec {
  const PresidentRuntimeSaveCodec({
    this.runtimeCodec = const CompactAdvancedWorldSaveCodec(),
  });

  final CompactAdvancedWorldSaveCodec runtimeCodec;

  static const String format = 'zmila-fbs-president-runtime';
  static const int currentSaveVersion = 1;

  String encode(PresidentRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      // Keep the nested M28 save as a JSON object rather than an encoded JSON
      // string. String nesting escapes every quote and materially inflates the
      // payload without adding any state.
      'runtimeSave': jsonDecode(runtimeCodec.encode(checkpoint.runtime)),
      'electionInterval': checkpoint.electionInterval,
      'completedElectionTerms': checkpoint.completedElectionTerms,
      'seasonsIntoCurrentTerm': checkpoint.seasonsIntoCurrentTerm,
      'clubs': checkpoint.clubs.map(_encodeClub).toList(),
    };
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

  PresidentRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'President runtime save is not valid JSON: ${error.message}',
      );
    }
    final envelope = _map(decoded, 'envelope');
    if (_string(envelope['format'], 'format') != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown president runtime save format.',
      );
    }
    final saveVersion = _int(envelope['saveVersion'], 'saveVersion');
    if (saveVersion < 0 || saveVersion > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported president runtime save version $saveVersion.',
      );
    }
    final payloadObject = envelope['payload'];
    final checksum = _string(envelope['checksum'], 'checksum');
    final expected = SaveChecksum.forPayload(
      saveVersion: saveVersion,
      payload: payloadObject,
    );
    if (checksum != expected) {
      throw SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'President runtime save checksum mismatch: expected $expected, found $checksum.',
      );
    }

    var version = saveVersion;
    var payload = _map(payloadObject, 'payload');
    while (version < currentSaveVersion) {
      switch (version) {
        case 0:
          payload = _migrateV0ToV1(payload);
          version = 1;
        default:
          throw SaveLoadException(
            SaveLoadFailure.unsupportedVersion,
            'No president runtime migration path from version $version.',
          );
      }
    }

    try {
      final clubList = payload['clubs'];
      if (clubList is! List) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'clubs must be a list.',
        );
      }
      return PresidentRuntimeCheckpoint(
        runtime: runtimeCodec.decode(_nestedRuntimeJson(payload['runtimeSave'])),
        electionInterval: _int(payload['electionInterval'], 'electionInterval'),
        completedElectionTerms:
            _int(payload['completedElectionTerms'], 'completedElectionTerms'),
        seasonsIntoCurrentTerm:
            _int(payload['seasonsIntoCurrentTerm'], 'seasonsIntoCurrentTerm'),
        clubs: clubList.map((item) => _decodeClub(_map(item, 'club'))),
      );
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
        'Invalid president runtime save payload: $error',
      );
    }
  }

  Map<String, Object?> _encodeClub(PresidentClubRuntimeState state) => {
        'clubId': state.clubId,
        'presidentId': state.tenure.president.id,
        'presidentName': state.tenure.president.name,
        'tenureNumber': state.tenure.tenureNumber,
        'startedSeasonIndex': state.tenure.startedSeasonIndex,
        'reelectionsWon': state.tenure.reelectionsWon,
        'archetype': state.managementProfile.archetype.name,
        'financialDiscipline': state.managementProfile.financialDiscipline,
        'riskAppetite': state.managementProfile.riskAppetite,
        'transferAmbition': state.managementProfile.transferAmbition,
        'youthOrientation': state.managementProfile.youthOrientation,
        'managerPatience': state.managementProfile.managerPatience,
        'fanSporting': state.fanReputation.sportingTrust,
        'fanFinancial': state.fanReputation.financialTrust,
        'fanTransfer': state.fanReputation.transferTrust,
        'fanIdentity': state.fanReputation.identityTrust,
        'mediaCredibility': state.mediaReputation.credibility,
      };

  PresidentClubRuntimeState _decodeClub(Map<String, Object?> json) {
    final clubId = _string(json['clubId'], 'club.clubId');
    final president = PresidentProfile(
      id: _string(json['presidentId'], 'club.presidentId'),
      name: _string(json['presidentName'], 'club.presidentName'),
    );
    final archetypeName = _string(json['archetype'], 'club.archetype');
    PresidentManagementArchetype? archetype;
    for (final candidate in PresidentManagementArchetype.values) {
      if (candidate.name == archetypeName) {
        archetype = candidate;
        break;
      }
    }
    if (archetype == null) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Unknown president archetype $archetypeName.',
      );
    }
    return PresidentClubRuntimeState(
      tenure: PresidentTenureState(
        clubId: clubId,
        president: president,
        tenureNumber: _int(json['tenureNumber'], 'club.tenureNumber'),
        startedSeasonIndex:
            _int(json['startedSeasonIndex'], 'club.startedSeasonIndex'),
        reelectionsWon: _int(json['reelectionsWon'], 'club.reelectionsWon'),
      ),
      managementProfile: PresidentManagementProfile(
        presidentId: president.id,
        archetype: archetype,
        financialDiscipline:
            _int(json['financialDiscipline'], 'club.financialDiscipline'),
        riskAppetite: _int(json['riskAppetite'], 'club.riskAppetite'),
        transferAmbition:
            _int(json['transferAmbition'], 'club.transferAmbition'),
        youthOrientation:
            _int(json['youthOrientation'], 'club.youthOrientation'),
        managerPatience: _int(json['managerPatience'], 'club.managerPatience'),
      ),
      fanReputation: FanState(
        clubId: clubId,
        sportingTrust: _int(json['fanSporting'], 'club.fanSporting'),
        financialTrust: _int(json['fanFinancial'], 'club.fanFinancial'),
        transferTrust: _int(json['fanTransfer'], 'club.fanTransfer'),
        identityTrust: _int(json['fanIdentity'], 'club.fanIdentity'),
      ),
      mediaReputation: MediaState(
        clubId: clubId,
        credibility: _int(json['mediaCredibility'], 'club.mediaCredibility'),
      ),
    );
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) => {
        'runtimeSave': legacy['compactRuntimeSave'],
        'electionInterval': legacy['termLength'],
        'completedElectionTerms': legacy['completedTerms'],
        'seasonsIntoCurrentTerm': legacy['termOffset'],
        'clubs': legacy['presidents'],
      };

  static String _nestedRuntimeJson(Object? value) {
    if (value is String && value.isNotEmpty) {
      // Accept the original draft representation so synthetic migration and
      // any pre-release development save remain loadable.
      return value;
    }
    if (value is Map) {
      return SaveChecksum.canonicalJson(_map(value, 'runtimeSave'));
    }
    throw const SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'runtimeSave must be a JSON object or encoded JSON string.',
    );
  }

  static Map<String, Object?> _map(Object? value, String field) {
    if (value is! Map) {
      throw SaveLoadException(
        field == 'envelope'
            ? SaveLoadFailure.invalidEnvelope
            : SaveLoadFailure.invalidPayload,
        '$field must be an object.',
      );
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw SaveLoadException(
          SaveLoadFailure.invalidPayload,
          '$field must use string keys.',
        );
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

  static int _int(Object? value, String field) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field must be an integer.',
    );
  }
}
