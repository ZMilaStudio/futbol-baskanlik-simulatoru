import 'dart:convert';

import '../core/money.dart';
import '../facility/academy_facility.dart';
import 'facility_runtime_checkpoint.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';
import 'world_save_codec.dart';

class FacilityRuntimeSaveCodec {
  const FacilityRuntimeSaveCodec({this.worldCodec = const WorldSaveCodec()});

  static const String format = 'zmila-fbs-facility-runtime';
  static const int currentSaveVersion = 1;

  final WorldSaveCodec worldCodec;

  String encode(FacilityRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'worldSave': worldCodec.encode(checkpoint.world),
      'academyFacilities': checkpoint.academyFacilities
          .map((state) => {'clubId': state.clubId, 'level': state.level})
          .toList(growable: false),
      'totalInvestmentSpentMinorUnits': checkpoint.totalInvestmentSpent.minorUnits,
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

  FacilityRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Facility save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Facility save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown facility save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0) {
      throw const SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Invalid facility save version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Facility save checksum mismatch.',
      );
    }
    if (version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Facility save version $version is newer than supported version $currentSaveVersion.',
      );
    }
    if (payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Facility save payload must be a map.',
      );
    }

    var map = Map<String, Object?>.from(payload);
    if (version == 0) {
      map = _migrateV0ToV1(map);
    }
    return _decodeV1(map);
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) => {
        'worldSave': legacy['world'],
        'academyFacilities': legacy['facilities'],
        'totalInvestmentSpentMinorUnits': legacy['spentMinorUnits'] ?? 0,
      };

  FacilityRuntimeCheckpoint _decodeV1(Map<String, Object?> map) {
    final worldSave = map['worldSave'];
    final facilitiesJson = map['academyFacilities'];
    final spent = map['totalInvestmentSpentMinorUnits'];
    if (worldSave is! String || facilitiesJson is! List || spent is! int) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Facility save payload fields are invalid.',
      );
    }
    final facilities = <AcademyFacilityState>[];
    for (final item in facilitiesJson) {
      if (item is! Map) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'Academy facility entry must be a map.',
        );
      }
      final entry = Map<String, Object?>.from(item);
      final clubId = entry['clubId'];
      final level = entry['level'];
      if (clubId is! String || level is! int) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'Academy facility fields are invalid.',
        );
      }
      facilities.add(AcademyFacilityState(clubId: clubId, level: level));
    }
    try {
      return FacilityRuntimeCheckpoint(
        world: worldCodec.decode(worldSave),
        academyFacilities: facilities,
        totalInvestmentSpent: Money.fromMinorUnits(spent),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid facility runtime payload: $error',
      );
    }
  }
}
