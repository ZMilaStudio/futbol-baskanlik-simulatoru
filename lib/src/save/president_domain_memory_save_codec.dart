import 'dart:convert';

import 'president_domain_memory_checkpoint.dart';
import 'president_runtime_save_codec.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';

class PresidentDomainMemorySaveCodec {
  const PresidentDomainMemorySaveCodec({
    this.presidentCodec = const PresidentRuntimeSaveCodec(),
  });

  final PresidentRuntimeSaveCodec presidentCodec;

  static const String format = 'zmila-fbs-president-domain-memory';
  static const int currentSaveVersion = 1;

  String encode(PresidentDomainMemoryCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'presidentRuntimeSave': jsonDecode(
        presidentCodec.encode(checkpoint.presidentRuntime),
      ),
      'rawHistorySeasons': checkpoint.rawHistorySeasons,
      'summary': _encodeSummary(checkpoint.summary),
      'recentFan': checkpoint.recentFan.map(_encodeFan).toList(),
      'recentMedia': checkpoint.recentMedia.map(_encodeMedia).toList(),
      'currentTermPromises':
          checkpoint.currentTermPromises.map(_encodePromise).toList(),
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

  PresidentDomainMemoryCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'President domain memory save is not valid JSON: ${error.message}',
      );
    }

    final envelope = _map(decoded, 'envelope');
    if (_string(envelope['format'], 'format') != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown president domain memory save format.',
      );
    }
    final saveVersion = _int(envelope['saveVersion'], 'saveVersion');
    if (saveVersion < 0 || saveVersion > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported president domain memory save version $saveVersion.',
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
        'President domain memory save checksum mismatch: expected $expected, found $checksum.',
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
            'No president domain memory migration path from version $version.',
          );
      }
    }

    try {
      return PresidentDomainMemoryCheckpoint(
        presidentRuntime: presidentCodec.decode(
          _nestedPresidentJson(payload['presidentRuntimeSave']),
        ),
        rawHistorySeasons:
            _int(payload['rawHistorySeasons'], 'rawHistorySeasons'),
        summary: _decodeSummary(_map(payload['summary'], 'summary')),
        recentFan: _list(payload['recentFan'], 'recentFan')
            .map((item) => _decodeFan(_map(item, 'recentFan item'))),
        recentMedia: _list(payload['recentMedia'], 'recentMedia')
            .map((item) => _decodeMedia(_map(item, 'recentMedia item'))),
        currentTermPromises:
            _list(payload['currentTermPromises'], 'currentTermPromises').map(
          (item) => _decodePromise(_map(item, 'currentTermPromises item')),
        ),
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
        'Invalid president domain memory save payload: $error',
      );
    }
  }

  Map<String, Object?> _encodeSummary(PresidentDomainHistorySummary item) => {
        'fanSnapshots': item.fanSnapshots,
        'fanReasons': item.fanReasons,
        'mediaStatements': item.mediaStatements,
        'mediaContradictions': item.mediaContradictions,
        'promisesFulfilled': item.promisesFulfilled,
        'promisesPartial': item.promisesPartial,
        'promisesBroken': item.promisesBroken,
      };

  PresidentDomainHistorySummary _decodeSummary(Map<String, Object?> json) =>
      PresidentDomainHistorySummary(
        fanSnapshots: _int(json['fanSnapshots'], 'summary.fanSnapshots'),
        fanReasons: _int(json['fanReasons'], 'summary.fanReasons'),
        mediaStatements:
            _int(json['mediaStatements'], 'summary.mediaStatements'),
        mediaContradictions:
            _int(json['mediaContradictions'], 'summary.mediaContradictions'),
        promisesFulfilled:
            _int(json['promisesFulfilled'], 'summary.promisesFulfilled'),
        promisesPartial:
            _int(json['promisesPartial'], 'summary.promisesPartial'),
        promisesBroken:
            _int(json['promisesBroken'], 'summary.promisesBroken'),
      );

  Map<String, Object?> _encodeFan(RecentFanMemory item) => {
        'clubId': item.clubId,
        'seasonIndex': item.seasonIndex,
        'expectationSignature': item.expectationSignature,
        'stateSignature': item.stateSignature,
        'reasonSignatures': item.reasonSignatures,
      };

  RecentFanMemory _decodeFan(Map<String, Object?> json) => RecentFanMemory(
        clubId: _string(json['clubId'], 'recentFan.clubId'),
        seasonIndex: _int(json['seasonIndex'], 'recentFan.seasonIndex'),
        expectationSignature:
            _string(json['expectationSignature'], 'recentFan.expectationSignature'),
        stateSignature:
            _string(json['stateSignature'], 'recentFan.stateSignature'),
        reasonSignatures: _list(
          json['reasonSignatures'],
          'recentFan.reasonSignatures',
        ).map((item) => _string(item, 'recentFan.reasonSignature')),
      );

  Map<String, Object?> _encodeMedia(RecentMediaMemory item) => {
        'clubId': item.clubId,
        'seasonIndex': item.seasonIndex,
        'managerId': item.managerId,
        'managerChanged': item.managerChanged,
        'credibilityBefore': item.credibilityBefore,
        'credibilityAfter': item.credibilityAfter,
        'statementSignature': item.statementSignature,
        'changeSignature': item.changeSignature,
      };

  RecentMediaMemory _decodeMedia(Map<String, Object?> json) =>
      RecentMediaMemory(
        clubId: _string(json['clubId'], 'recentMedia.clubId'),
        seasonIndex: _int(json['seasonIndex'], 'recentMedia.seasonIndex'),
        managerId: _string(json['managerId'], 'recentMedia.managerId'),
        managerChanged: _bool(json['managerChanged'], 'recentMedia.managerChanged'),
        credibilityBefore:
            _int(json['credibilityBefore'], 'recentMedia.credibilityBefore'),
        credibilityAfter:
            _int(json['credibilityAfter'], 'recentMedia.credibilityAfter'),
        statementSignature: _nullableString(
          json['statementSignature'],
          'recentMedia.statementSignature',
        ),
        changeSignature:
            _nullableString(json['changeSignature'], 'recentMedia.changeSignature'),
      );

  Map<String, Object?> _encodePromise(CurrentTermPromiseMemory item) => {
        'clubId': item.clubId,
        'seasonIndex': item.seasonIndex,
        'promiseType': item.promiseType,
        'status': item.status,
        'score': item.score,
      };

  CurrentTermPromiseMemory _decodePromise(Map<String, Object?> json) =>
      CurrentTermPromiseMemory(
        clubId: _string(json['clubId'], 'currentTermPromise.clubId'),
        seasonIndex:
            _int(json['seasonIndex'], 'currentTermPromise.seasonIndex'),
        promiseType:
            _string(json['promiseType'], 'currentTermPromise.promiseType'),
        status: _string(json['status'], 'currentTermPromise.status'),
        score: _int(json['score'], 'currentTermPromise.score'),
      );

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) => {
        'presidentRuntimeSave': legacy['presidentSave'],
        'rawHistorySeasons': legacy['historyWindow'],
        'summary': legacy['historySummary'],
        'recentFan': legacy['fanMemory'],
        'recentMedia': legacy['mediaMemory'],
        'currentTermPromises': legacy['termPromises'],
      };

  String _nestedPresidentJson(Object? value) {
    if (value is String) {
      if (value.isEmpty) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'presidentRuntimeSave cannot be empty.',
        );
      }
      return value;
    }
    if (value is Map) {
      return SaveChecksum.canonicalJson(_map(value, 'presidentRuntimeSave'));
    }
    throw const SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'presidentRuntimeSave must be a JSON object.',
    );
  }

  Map<String, Object?> _map(Object? value, String field) {
    if (value is! Map) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be an object.',
      );
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<Object?> _list(Object? value, String field) {
    if (value is! List) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be a list.',
      );
    }
    return value.cast<Object?>();
  }

  int _int(Object? value, String field) {
    if (value is! int) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be an integer.',
      );
    }
    return value;
  }

  String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be a non-empty string.',
      );
    }
    return value;
  }

  String? _nullableString(Object? value, String field) {
    if (value == null) return null;
    return _string(value, field);
  }

  bool _bool(Object? value, String field) {
    if (value is! bool) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be a boolean.',
      );
    }
    return value;
  }
}
