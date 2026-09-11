import 'dart:convert';

import '../core/money.dart';
import '../sponsor/sponsor_system.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';

class SponsorRuntimeSaveCodec {
  const SponsorRuntimeSaveCodec();

  static const String format = 'zmila-fbs-sponsor-runtime';
  static const int currentSaveVersion = 1;

  String encode(SponsorRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'nextSeasonIndex': checkpoint.nextSeasonIndex,
      'totalRevenuePaidMinorUnits': checkpoint.totalRevenuePaid.minorUnits,
      'activeContracts': checkpoint.activeContracts
          .map(
            (contract) => <String, Object?>{
              'id': contract.offer.id,
              'sponsorName': contract.offer.sponsorName,
              'clubId': contract.offer.clubId,
              'annualGuaranteedMinorUnits':
                  contract.offer.annualGuaranteed.minorUnits,
              'performanceBonusMinorUnits':
                  contract.offer.performanceBonus.minorUnits,
              'termSeasons': contract.offer.termSeasons,
              'bonusTarget': contract.offer.bonusTarget.name,
              'startSeasonIndex': contract.startSeasonIndex,
              'acceptedByPresidentId': contract.acceptedByPresidentId,
            },
          )
          .toList(growable: false),
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

  SponsorRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Sponsor save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Sponsor save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown sponsor save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0) {
      throw const SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Invalid sponsor save version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Sponsor save checksum mismatch.',
      );
    }
    if (version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Sponsor save version $version is newer than supported version $currentSaveVersion.',
      );
    }
    if (payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Sponsor save payload must be a map.',
      );
    }

    var map = Map<String, Object?>.from(payload);
    if (version == 0) {
      map = _migrateV0ToV1(map);
    }
    return _decodeV1(map);
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) => {
        'nextSeasonIndex': legacy['season'],
        'totalRevenuePaidMinorUnits': legacy['totalPaid'] ?? 0,
        'activeContracts': legacy['contracts'] ?? const <Object?>[],
      };

  SponsorRuntimeCheckpoint _decodeV1(Map<String, Object?> map) {
    final nextSeasonIndex = map['nextSeasonIndex'];
    final totalRevenue = map['totalRevenuePaidMinorUnits'];
    final contractsJson = map['activeContracts'];
    if (nextSeasonIndex is! int || totalRevenue is! int || contractsJson is! List) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Sponsor save payload fields are invalid.',
      );
    }

    final contracts = <SponsorContract>[];
    for (final item in contractsJson) {
      if (item is! Map) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'Sponsor contract entry must be a map.',
        );
      }
      final entry = Map<String, Object?>.from(item);
      final id = entry['id'];
      final sponsorName = entry['sponsorName'];
      final clubId = entry['clubId'];
      final guaranteed = entry['annualGuaranteedMinorUnits'];
      final bonus = entry['performanceBonusMinorUnits'];
      final term = entry['termSeasons'];
      final targetName = entry['bonusTarget'];
      final start = entry['startSeasonIndex'];
      final presidentId = entry['acceptedByPresidentId'];
      if (id is! String ||
          sponsorName is! String ||
          clubId is! String ||
          guaranteed is! int ||
          bonus is! int ||
          term is! int ||
          targetName is! String ||
          start is! int ||
          presidentId is! String) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'Sponsor contract fields are invalid.',
        );
      }
      final target = SponsorBonusTarget.values
          .where((value) => value.name == targetName)
          .firstOrNull;
      if (target == null) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'Unknown sponsor bonus target.',
        );
      }
      contracts.add(
        SponsorContract(
          offer: SponsorOffer(
            id: id,
            sponsorName: sponsorName,
            clubId: clubId,
            annualGuaranteed: Money.fromMinorUnits(guaranteed),
            performanceBonus: Money.fromMinorUnits(bonus),
            termSeasons: term,
            bonusTarget: target,
          ),
          startSeasonIndex: start,
          acceptedByPresidentId: presidentId,
        ),
      );
    }

    try {
      return SponsorRuntimeCheckpoint(
        nextSeasonIndex: nextSeasonIndex,
        activeContracts: contracts,
        totalRevenuePaid: Money.fromMinorUnits(totalRevenue),
      );
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid sponsor runtime payload: $error',
      );
    }
  }
}
