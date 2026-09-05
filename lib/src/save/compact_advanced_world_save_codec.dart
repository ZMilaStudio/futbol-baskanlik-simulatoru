import 'dart:convert';

import '../contract/contract_event.dart';
import '../manager/manager_career_season.dart';
import 'advanced_history_compaction.dart';
import 'advanced_world_save_codec.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';

class CompactAdvancedWorldSaveCodec {
  const CompactAdvancedWorldSaveCodec({
    this.runtimeCodec = const AdvancedWorldSaveCodec(),
  });

  final AdvancedWorldSaveCodec runtimeCodec;

  static const String format = 'zmila-fbs-advanced-world-compact';
  static const int currentSaveVersion = 1;

  String encode(CompactAdvancedRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'runtimeSave': runtimeCodec.encode(checkpoint.runtime),
      'recentHistoryStartSeasonIndex': checkpoint.recentHistoryStartSeasonIndex,
      'history': _encodeHistory(checkpoint.history),
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

  CompactAdvancedRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Compact advanced save is not valid JSON: ${error.message}',
      );
    }

    final envelope = _stringMap(decoded, 'envelope');
    if (_string(envelope['format'], 'format') != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown compact advanced save format.',
      );
    }
    final saveVersion = _integer(envelope['saveVersion'], 'saveVersion');
    if (saveVersion < 0 || saveVersion > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported compact advanced save version $saveVersion.',
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
        'Compact advanced save checksum mismatch: expected $expected, '
        'found $checksum.',
      );
    }

    var version = saveVersion;
    var payload = _stringMap(payloadObject, 'payload');
    while (version < currentSaveVersion) {
      switch (version) {
        case 0:
          payload = _migrateV0ToV1(payload);
          version = 1;
        default:
          throw SaveLoadException(
            SaveLoadFailure.unsupportedVersion,
            'No compact advanced migration path from version $version.',
          );
      }
    }

    try {
      final historyJson = _stringMap(payload['history'], 'history');
      return CompactAdvancedRuntimeCheckpoint(
        runtime: runtimeCodec.decode(
          _string(payload['runtimeSave'], 'runtimeSave'),
        ),
        recentHistoryStartSeasonIndex: _integer(
          payload['recentHistoryStartSeasonIndex'],
          'recentHistoryStartSeasonIndex',
        ),
        history: _decodeHistory(historyJson),
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
        'Invalid compact advanced save payload: $error',
      );
    }
  }

  Map<String, Object?> _encodeHistory(AdvancedHistorySummary history) => {
        'completedSeasons': history.completedSeasons,
        'contractEventCount': history.contractEventCount,
        'contractEventsByType': {
          for (final type in ContractEventType.values)
            type.name: history.contractEventsByType[type] ?? 0,
        },
        'loanCount': history.loanCount,
        'loanFeeMinorUnits': history.loanFeeMinorUnits,
        'managerSeasonCount': history.managerSeasonCount,
        'managerChangeCount': history.managerChangeCount,
        'managerChangesByReason': {
          for (final reason in ManagerChangeReason.values)
            reason.name: history.managerChangesByReason[reason] ?? 0,
        },
      };

  AdvancedHistorySummary _decodeHistory(Map<String, Object?> json) {
    final contractJson = _stringMap(
      json['contractEventsByType'],
      'history.contractEventsByType',
    );
    final managerJson = _stringMap(
      json['managerChangesByReason'],
      'history.managerChangesByReason',
    );
    return AdvancedHistorySummary(
      completedSeasons:
          _integer(json['completedSeasons'], 'history.completedSeasons'),
      contractEventCount:
          _integer(json['contractEventCount'], 'history.contractEventCount'),
      contractEventsByType: {
        for (final type in ContractEventType.values)
          type: _integer(
            contractJson[type.name],
            'history.contractEventsByType.${type.name}',
          ),
      },
      loanCount: _integer(json['loanCount'], 'history.loanCount'),
      loanFeeMinorUnits:
          _integer(json['loanFeeMinorUnits'], 'history.loanFeeMinorUnits'),
      managerSeasonCount:
          _integer(json['managerSeasonCount'], 'history.managerSeasonCount'),
      managerChangeCount:
          _integer(json['managerChangeCount'], 'history.managerChangeCount'),
      managerChangesByReason: {
        for (final reason in ManagerChangeReason.values)
          reason: _integer(
            managerJson[reason.name],
            'history.managerChangesByReason.${reason.name}',
          ),
      },
    );
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) => {
        'runtimeSave': _string(legacy['advancedRuntimeSave'], 'advancedRuntimeSave'),
        'recentHistoryStartSeasonIndex': _integer(
          legacy['historyStartSeasonIndex'],
          'historyStartSeasonIndex',
        ),
        'history': _stringMap(legacy['historySummary'], 'historySummary'),
      };

  static Map<String, Object?> _stringMap(Object? value, String field) {
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
}
