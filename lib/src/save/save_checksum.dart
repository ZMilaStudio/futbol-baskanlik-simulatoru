import 'dart:convert';

import '../core/stable_hash.dart';
import 'save_load_exception.dart';

class SaveChecksum {
  const SaveChecksum._();

  static String forPayload({
    required int saveVersion,
    required Object? payload,
  }) {
    final canonical = canonicalJson({
      'saveVersion': saveVersion,
      'payload': payload,
    });
    return StableHash.string32(canonical)
        .toRadixString(16)
        .padLeft(8, '0');
  }

  static String canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

  static Object? _canonicalize(Object? value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value is Map) {
      final keys = value.keys.map((key) {
        if (key is! String) {
          throw const SaveLoadException(
            SaveLoadFailure.invalidPayload,
            'Save maps must use string keys.',
          );
        }
        return key;
      }).toList(growable: false)
        ..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'Unsupported save value type: ${value.runtimeType}.',
    );
  }
}
