import 'dart:convert';

import '../contract/contract_event.dart';
import '../contract/player_contract.dart';
import '../core/money.dart';
import '../manager/manager.dart';
import '../manager/manager_assignment.dart';
import '../manager/manager_career_season.dart';
import '../manager/manager_profile.dart';
import '../transfer/loan_agreement.dart';
import '../transfer/transfer_installment.dart';
import 'advanced_runtime_checkpoint.dart';
import 'save_checksum.dart';
import 'save_load_exception.dart';
import 'world_save_codec.dart';

class AdvancedWorldSaveCodec {
  const AdvancedWorldSaveCodec({
    this.worldCodec = const WorldSaveCodec(),
  });

  final WorldSaveCodec worldCodec;

  static const String format = 'zmila-fbs-advanced-world';
  static const int currentSaveVersion = 1;

  String encode(AdvancedRuntimeCheckpoint checkpoint) {
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

  AdvancedRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Advanced world save is not valid JSON: ${error.message}',
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
        'Unknown advanced world save format.',
      );
    }

    final saveVersion = _integer(envelope['saveVersion'], 'saveVersion');
    if (saveVersion < 0) {
      throw const SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Advanced world save version cannot be negative.',
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
        'Advanced world save checksum mismatch: expected $expectedChecksum, '
        'found $checksum.',
      );
    }
    if (saveVersion > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Advanced world save version $saveVersion is newer than supported '
        'version $currentSaveVersion.',
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
              'No advanced world migration path from version '
              '$migratedVersion.',
            );
        }
      } on SaveLoadException {
        rethrow;
      } catch (error) {
        throw SaveLoadException(
          SaveLoadFailure.migrationFailed,
          'Advanced world migration failed at version $migratedVersion: '
          '$error',
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
        'Invalid advanced world save payload: $error',
      );
    }
  }

  Map<String, Object?> _encodeV1Payload(AdvancedRuntimeCheckpoint checkpoint) => {
        'worldSave': worldCodec.encode(checkpoint.world),
        'transfer': {
          'activeContracts': checkpoint.transfer.activeContracts
              .map(_encodeContract)
              .toList(growable: false),
          'contractEvents': checkpoint.transfer.contractEvents
              .map(_encodeContractEvent)
              .toList(growable: false),
          'activeLoans': checkpoint.transfer.activeLoans
              .map(_encodeLoan)
              .toList(growable: false),
          'loanHistory': checkpoint.transfer.loanHistory
              .map(_encodeLoan)
              .toList(growable: false),
          'installmentObligations': checkpoint.transfer.installmentObligations
              .map(_encodeObligation)
              .toList(growable: false),
        },
        'manager': {
          'managers': checkpoint.manager.managers
              .map(_encodeManager)
              .toList(growable: false),
          'assignments': checkpoint.manager.assignments
              .map(_encodeAssignment)
              .toList(growable: false),
          'seasons': checkpoint.manager.seasons
              .map(_encodeManagerSeason)
              .toList(growable: false),
        },
      };

  AdvancedRuntimeCheckpoint _decodeV1Payload(Map<String, Object?> payload) {
    final world = worldCodec.decode(_string(payload['worldSave'], 'worldSave'));
    final transferJson = _stringMap(
      payload['transfer'],
      failure: SaveLoadFailure.invalidPayload,
      field: 'transfer',
    );
    final managerJson = _stringMap(
      payload['manager'],
      failure: SaveLoadFailure.invalidPayload,
      field: 'manager',
    );

    return AdvancedRuntimeCheckpoint(
      world: world,
      transfer: AdvancedTransferRuntimeState(
        activeContracts: _decodeList(
          transferJson['activeContracts'],
          'transfer.activeContracts',
          _decodeContract,
        ),
        contractEvents: _decodeList(
          transferJson['contractEvents'],
          'transfer.contractEvents',
          _decodeContractEvent,
        ),
        activeLoans: _decodeList(
          transferJson['activeLoans'],
          'transfer.activeLoans',
          _decodeLoan,
        ),
        loanHistory: _decodeList(
          transferJson['loanHistory'],
          'transfer.loanHistory',
          _decodeLoan,
        ),
        installmentObligations: _decodeList(
          transferJson['installmentObligations'],
          'transfer.installmentObligations',
          _decodeObligation,
        ),
      ),
      manager: ManagerRuntimeState(
        managers: _decodeList(
          managerJson['managers'],
          'manager.managers',
          _decodeManager,
        ),
        assignments: _decodeList(
          managerJson['assignments'],
          'manager.assignments',
          _decodeAssignment,
        ),
        seasons: _decodeList(
          managerJson['seasons'],
          'manager.seasons',
          _decodeManagerSeason,
        ),
      ),
    );
  }

  Map<String, Object?> _migrateV0ToV1(Map<String, Object?> legacy) => {
        'worldSave': _string(legacy['coreWorldSave'], 'coreWorldSave'),
        'transfer': {
          'activeContracts': _list(legacy['contracts'], 'contracts'),
          'contractEvents': _list(legacy['events'], 'events'),
          'activeLoans': _list(legacy['activeLoans'], 'activeLoans'),
          'loanHistory': _list(legacy['loanHistory'], 'loanHistory'),
          'installmentObligations':
              _list(legacy['installments'], 'installments'),
        },
        'manager': {
          'managers': _list(legacy['managers'], 'managers'),
          'assignments': _list(legacy['assignments'], 'assignments'),
          'seasons': _list(legacy['managerSeasons'], 'managerSeasons'),
        },
      };

  Map<String, Object?> _encodeContract(PlayerContract contract) => {
        'playerId': contract.playerId,
        'clubId': contract.clubId,
        'startSeasonIndex': contract.startSeasonIndex,
        'endSeasonIndex': contract.endSeasonIndex,
        'annualWageMinorUnits': contract.annualWage.minorUnits,
      };

  PlayerContract _decodeContract(Map<String, Object?> json) => PlayerContract(
        playerId: _string(json['playerId'], 'contract.playerId'),
        clubId: _string(json['clubId'], 'contract.clubId'),
        startSeasonIndex:
            _integer(json['startSeasonIndex'], 'contract.startSeasonIndex'),
        endSeasonIndex:
            _integer(json['endSeasonIndex'], 'contract.endSeasonIndex'),
        annualWage: Money.fromMinorUnits(
          _integer(json['annualWageMinorUnits'], 'contract.annualWageMinorUnits'),
        ),
      );

  Map<String, Object?> _encodeContractEvent(ContractEvent event) => {
        'seasonIndex': event.seasonIndex,
        'playerId': event.playerId,
        'type': event.type.name,
        'fromClubId': event.fromClubId,
        'toClubId': event.toClubId,
        'annualWageMinorUnits': event.annualWage?.minorUnits,
        'endSeasonIndex': event.endSeasonIndex,
      };

  ContractEvent _decodeContractEvent(Map<String, Object?> json) => ContractEvent(
        seasonIndex: _integer(json['seasonIndex'], 'event.seasonIndex'),
        playerId: _string(json['playerId'], 'event.playerId'),
        type: _contractEventType(_string(json['type'], 'event.type')),
        fromClubId: _nullableString(json['fromClubId'], 'event.fromClubId'),
        toClubId: _nullableString(json['toClubId'], 'event.toClubId'),
        annualWage: json['annualWageMinorUnits'] == null
            ? null
            : Money.fromMinorUnits(
                _integer(
                  json['annualWageMinorUnits'],
                  'event.annualWageMinorUnits',
                ),
              ),
        endSeasonIndex:
            _nullableInteger(json['endSeasonIndex'], 'event.endSeasonIndex'),
      );

  Map<String, Object?> _encodeLoan(LoanAgreement loan) => {
        'playerId': loan.playerId,
        'parentClubId': loan.parentClubId,
        'loanClubId': loan.loanClubId,
        'startSeasonIndex': loan.startSeasonIndex,
        'endSeasonIndex': loan.endSeasonIndex,
        'loanFeeMinorUnits': loan.loanFee.minorUnits,
        'loanClubWageShareBps': loan.loanClubWageShareBps,
      };

  LoanAgreement _decodeLoan(Map<String, Object?> json) => LoanAgreement(
        playerId: _string(json['playerId'], 'loan.playerId'),
        parentClubId: _string(json['parentClubId'], 'loan.parentClubId'),
        loanClubId: _string(json['loanClubId'], 'loan.loanClubId'),
        startSeasonIndex:
            _integer(json['startSeasonIndex'], 'loan.startSeasonIndex'),
        endSeasonIndex:
            _integer(json['endSeasonIndex'], 'loan.endSeasonIndex'),
        loanFee: Money.fromMinorUnits(
          _integer(json['loanFeeMinorUnits'], 'loan.loanFeeMinorUnits'),
        ),
        loanClubWageShareBps: _integer(
          json['loanClubWageShareBps'],
          'loan.loanClubWageShareBps',
        ),
      );

  Map<String, Object?> _encodeObligation(
    TransferInstallmentObligation obligation,
  ) =>
      {
        'playerId': obligation.playerId,
        'fromClubId': obligation.fromClubId,
        'toClubId': obligation.toClubId,
        'createdSeasonIndex': obligation.createdSeasonIndex,
        'installments': obligation.installments
            .map(
              (item) => {
                'dueSeasonIndex': item.dueSeasonIndex,
                'amountMinorUnits': item.amount.minorUnits,
              },
            )
            .toList(growable: false),
      };

  TransferInstallmentObligation _decodeObligation(
    Map<String, Object?> json,
  ) =>
      TransferInstallmentObligation(
        playerId: _string(json['playerId'], 'obligation.playerId'),
        fromClubId: _string(json['fromClubId'], 'obligation.fromClubId'),
        toClubId: _string(json['toClubId'], 'obligation.toClubId'),
        createdSeasonIndex: _integer(
          json['createdSeasonIndex'],
          'obligation.createdSeasonIndex',
        ),
        installments: _decodeList(
          json['installments'],
          'obligation.installments',
          (item) => TransferInstallment(
            dueSeasonIndex: _integer(
              item['dueSeasonIndex'],
              'installment.dueSeasonIndex',
            ),
            amount: Money.fromMinorUnits(
              _integer(item['amountMinorUnits'], 'installment.amountMinorUnits'),
            ),
          ),
        ),
      );

  Map<String, Object?> _encodeManager(Manager manager) => {
        'id': manager.id,
        'name': manager.name,
        'profile': manager.profile.name,
        'startAge': manager.startAge,
        'retirementAge': manager.retirementAge,
        'reputation': manager.reputation,
        'coaching': manager.coaching,
        'youthDevelopment': manager.youthDevelopment,
        'manManagement': manager.manManagement,
        'boardCooperation': manager.boardCooperation,
        'budgetDemand': manager.budgetDemand,
      };

  Manager _decodeManager(Map<String, Object?> json) => Manager(
        id: _string(json['id'], 'manager.id'),
        name: _string(json['name'], 'manager.name'),
        profile: _managerProfile(_string(json['profile'], 'manager.profile')),
        startAge: _integer(json['startAge'], 'manager.startAge'),
        retirementAge: _integer(json['retirementAge'], 'manager.retirementAge'),
        reputation: _integer(json['reputation'], 'manager.reputation'),
        coaching: _integer(json['coaching'], 'manager.coaching'),
        youthDevelopment:
            _integer(json['youthDevelopment'], 'manager.youthDevelopment'),
        manManagement:
            _integer(json['manManagement'], 'manager.manManagement'),
        boardCooperation:
            _integer(json['boardCooperation'], 'manager.boardCooperation'),
        budgetDemand: _integer(json['budgetDemand'], 'manager.budgetDemand'),
      );

  Map<String, Object?> _encodeAssignment(ManagerAssignment assignment) => {
        'clubId': assignment.clubId,
        'managerId': assignment.managerId,
        'appointedSeasonIndex': assignment.appointedSeasonIndex,
        'completedSeasons': assignment.completedSeasons,
        'boardRelationship': assignment.boardRelationship,
      };

  ManagerAssignment _decodeAssignment(Map<String, Object?> json) =>
      ManagerAssignment(
        clubId: _string(json['clubId'], 'assignment.clubId'),
        managerId: _string(json['managerId'], 'assignment.managerId'),
        appointedSeasonIndex: _integer(
          json['appointedSeasonIndex'],
          'assignment.appointedSeasonIndex',
        ),
        completedSeasons: _integer(
          json['completedSeasons'],
          'assignment.completedSeasons',
        ),
        boardRelationship: _finiteDouble(
          json['boardRelationship'],
          'assignment.boardRelationship',
        ),
      );

  Map<String, Object?> _encodeManagerSeason(ManagerCareerSeason season) => {
        'seasonIndex': season.seasonIndex,
        'clubs': season.clubs
            .map(
              (item) => {
                'clubId': item.clubId,
                'managerId': item.managerId,
                'managerAge': item.managerAge,
                'fitScore': item.fitScore,
                'strengthImpact': item.strengthImpact,
                'relationshipBefore': item.relationshipBefore,
                'relationshipAfter': item.relationshipAfter,
                'expectedPosition': item.expectedPosition,
                'actualPosition': item.actualPosition,
                'changedAfterSeason': item.changedAfterSeason,
              },
            )
            .toList(growable: false),
        'changesAfterSeason': season.changesAfterSeason
            .map(
              (item) => {
                'clubId': item.clubId,
                'fromManagerId': item.fromManagerId,
                'toManagerId': item.toManagerId,
                'reason': item.reason.name,
              },
            )
            .toList(growable: false),
      };

  ManagerCareerSeason _decodeManagerSeason(Map<String, Object?> json) =>
      ManagerCareerSeason(
        seasonIndex: _integer(json['seasonIndex'], 'managerSeason.seasonIndex'),
        clubs: _decodeList(
          json['clubs'],
          'managerSeason.clubs',
          (item) => ManagerClubSeason(
            clubId: _string(item['clubId'], 'managerClubSeason.clubId'),
            managerId:
                _string(item['managerId'], 'managerClubSeason.managerId'),
            managerAge:
                _integer(item['managerAge'], 'managerClubSeason.managerAge'),
            fitScore:
                _finiteDouble(item['fitScore'], 'managerClubSeason.fitScore'),
            strengthImpact: _finiteDouble(
              item['strengthImpact'],
              'managerClubSeason.strengthImpact',
            ),
            relationshipBefore: _finiteDouble(
              item['relationshipBefore'],
              'managerClubSeason.relationshipBefore',
            ),
            relationshipAfter: _finiteDouble(
              item['relationshipAfter'],
              'managerClubSeason.relationshipAfter',
            ),
            expectedPosition: _integer(
              item['expectedPosition'],
              'managerClubSeason.expectedPosition',
            ),
            actualPosition: _integer(
              item['actualPosition'],
              'managerClubSeason.actualPosition',
            ),
            changedAfterSeason: _boolean(
              item['changedAfterSeason'],
              'managerClubSeason.changedAfterSeason',
            ),
          ),
        ),
        changesAfterSeason: _decodeList(
          json['changesAfterSeason'],
          'managerSeason.changesAfterSeason',
          (item) => ManagerChange(
            clubId: _string(item['clubId'], 'managerChange.clubId'),
            fromManagerId: _string(
              item['fromManagerId'],
              'managerChange.fromManagerId',
            ),
            toManagerId:
                _string(item['toManagerId'], 'managerChange.toManagerId'),
            reason: _managerChangeReason(
              _string(item['reason'], 'managerChange.reason'),
            ),
          ),
        ),
      );

  static List<T> _decodeList<T>(
    Object? value,
    String field,
    T Function(Map<String, Object?> json) decode,
  ) {
    final list = _list(value, field);
    return List<T>.generate(
      list.length,
      (index) => decode(
        _stringMap(
          list[index],
          failure: SaveLoadFailure.invalidPayload,
          field: '$field[$index]',
        ),
      ),
      growable: false,
    );
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

  static List<Object?> _list(Object? value, String field) {
    if (value is! List) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$field must be a list.',
      );
    }
    return List<Object?>.from(value);
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

  static String? _nullableString(Object? value, String field) {
    if (value == null) return null;
    return _string(value, field);
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

  static int? _nullableInteger(Object? value, String field) {
    if (value == null) return null;
    return _integer(value, field);
  }

  static double _finiteDouble(Object? value, String field) {
    if (value is num && value.isFinite) return value.toDouble();
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field must be a finite number.',
    );
  }

  static bool _boolean(Object? value, String field) {
    if (value is bool) return value;
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$field must be a boolean.',
    );
  }

  static ContractEventType _contractEventType(String value) {
    for (final item in ContractEventType.values) {
      if (item.name == value) return item;
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'Unknown contract event type $value.',
    );
  }

  static ManagerProfile _managerProfile(String value) {
    for (final item in ManagerProfile.values) {
      if (item.name == value) return item;
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'Unknown manager profile $value.',
    );
  }

  static ManagerChangeReason _managerChangeReason(String value) {
    for (final item in ManagerChangeReason.values) {
      if (item.name == value) return item;
    }
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'Unknown manager change reason $value.',
    );
  }
}
