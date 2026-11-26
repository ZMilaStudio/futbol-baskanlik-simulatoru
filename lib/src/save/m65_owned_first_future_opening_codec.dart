part of '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';

final class _OwnedOpeningCodec {
  const _OwnedOpeningCodec();
  String encode(M65OwnedFirstFutureOpeningState state) {
    state.validate();
    final payload = <String, Object?>{
      'careerInstanceId': state.careerInstanceId,
      'origin': state.origin,
      'phase': state.phase,
      'runtimeProfile': state.runtimeProfile,
      'worldSave': const WorldSaveCodec().encode(state.world),
      'tenureControlSave': const PlayerPresidentTenureControlSaveCodec()
          .encode(state.tenureControl),
      'manager': {
        'managers': state.managers.map(_encodeManager).toList(),
        'assignments': state.assignments.map(_encodeAssignment).toList(),
        'completedSeasons': <Object?>[]
      },
      'transfer': {
        'activeContracts':
            state.transfers.activeContracts.map(_encodeContract).toList(),
        'contractEvents':
            state.transfers.contractEvents.map(_encodeContractEvent).toList(),
        'activeLoans': state.transfers.activeLoans.map(_encodeLoan).toList(),
        'loanHistory': state.transfers.loanHistory.map(_encodeLoan).toList(),
        'installmentObligations': state.transfers.installmentObligations
            .map(_encodeObligation)
            .toList(),
      },
      'facilities': {
        'academyFacilities': state.facilities.academyFacilities
            .map((e) => {'clubId': e.clubId, 'level': e.level})
            .toList(),
        'stadiumFacilities': state.facilities.stadiumFacilities
            .map((e) => {'clubId': e.clubId, 'level': e.level})
            .toList(),
        'trainingGroundFacilities': state.facilities.trainingGroundFacilities
            .map((e) => {'clubId': e.clubId, 'level': e.level})
            .toList(),
        'totalInvestmentSpentMinorUnits':
            state.facilities.totalInvestmentSpent.minorUnits,
      },
      'presidency': {
        'clubs': state.presidentClubs.map(_encodeClub).toList(),
        'electionInterval': state.electionInterval,
        'termPromiseScores': state.termPromiseScores
      },
      'pending': {
        'kind': 'promise',
        'decisionId': state.decisionId,
        'contextSignature': state.contextSignature
      },
      'preparedOpeningDigest': state.preparedOpeningDigest,
    };
    return SaveChecksum.canonicalJson({
      'format': PlayerPresidentTicketPricingRuntimeSaveCodec.format,
      'saveVersion':
          PlayerPresidentTicketPricingRuntimeSaveCodec.ownedOpeningSaveVersion,
      'payload': payload,
      'checksum': SaveChecksum.forPayload(saveVersion: 2, payload: payload),
    });
  }

  M65OwnedFirstFutureOpeningState decode(String encoded) {
    final Object? decoded;
    try {
      decoded = _ownedStrictJson(encoded);
    } on SaveLoadException {
      rethrow;
    } on FormatException catch (e) {
      throw SaveLoadException(
          SaveLoadFailure.malformedJson, 'Invalid owned JSON: ${e.message}');
    }
    if (decoded is! Map ||
        decoded['format'] !=
            PlayerPresidentTicketPricingRuntimeSaveCodec.format) {
      throw const SaveLoadException(
          SaveLoadFailure.invalidEnvelope, 'Invalid owned save envelope.');
    }
    if (decoded['saveVersion'] is! int || decoded['saveVersion'] != 2) {
      throw const SaveLoadException(SaveLoadFailure.unsupportedVersion,
          'Unsupported owned save version.');
    }
    try {
      final envelope =
          _strict(decoded, ['format', 'saveVersion', 'payload', 'checksum']);
      final p = _strict(envelope['payload'], [
        'careerInstanceId',
        'origin',
        'phase',
        'runtimeProfile',
        'worldSave',
        'tenureControlSave',
        'manager',
        'transfer',
        'facilities',
        'presidency',
        'pending',
        'preparedOpeningDigest'
      ]);
      if (envelope['checksum'] is! String ||
          envelope['checksum'] !=
              SaveChecksum.forPayload(saveVersion: 2, payload: p)) {
        throw const SaveLoadException(
            SaveLoadFailure.checksumMismatch, 'Owned save checksum mismatch.');
      }
      final worldSave = _string(p['worldSave'], 'worldSave');
      final tenureSave = _string(p['tenureControlSave'], 'tenureControlSave');
      // Preserve existing nested legacy decoder member semantics. Only the
      // new envelope and inline owned maps have duplicate-member rejection.
      for (final nested in [worldSave, tenureSave]) {
        final n = jsonDecode(nested);
        if (n is! Map || n['saveVersion'] is! int || n['saveVersion'] != 1) {
          throw const SaveLoadException(SaveLoadFailure.unsupportedVersion,
              'Owned opening requires nested version one.');
        }
      }
      final m = _strict(
          p['manager'], ['managers', 'assignments', 'completedSeasons']);
      if (m['completedSeasons'] is! List ||
          (m['completedSeasons'] as List).isNotEmpty) {
        _invalid('Historical manager history must remain unavailable.');
      }
      final t = _strict(p['transfer'], [
        'activeContracts',
        'contractEvents',
        'activeLoans',
        'loanHistory',
        'installmentObligations'
      ]);
      final f = _strict(p['facilities'], [
        'academyFacilities',
        'stadiumFacilities',
        'trainingGroundFacilities',
        'totalInvestmentSpentMinorUnits'
      ]);
      final presidency = _strict(
          p['presidency'], ['clubs', 'electionInterval', 'termPromiseScores']);
      final pending =
          _strict(p['pending'], ['kind', 'decisionId', 'contextSignature']);
      if (pending['kind'] != 'promise') _invalid('Unsupported pending kind.');
      final scores = _map(presidency['termPromiseScores'], 'termPromiseScores');
      return M65OwnedFirstFutureOpeningState._(
        world: const WorldSaveCodec().decode(worldSave),
        tenureControl:
            const PlayerPresidentTenureControlSaveCodec().decode(tenureSave),
        managers: _decodeList(m['managers'], 'managers', _decodeManager),
        assignments:
            _decodeList(m['assignments'], 'assignments', _decodeAssignment),
        transfers: AdvancedTransferRuntimeState(
            activeContracts:
                _decodeList(t['activeContracts'], 'contracts', _decodeContract),
            contractEvents: _decodeList(
                t['contractEvents'], 'events', _decodeContractEvent),
            activeLoans:
                _decodeList(t['activeLoans'], 'activeLoans', _decodeLoan),
            loanHistory:
                _decodeList(t['loanHistory'], 'loanHistory', _decodeLoan),
            installmentObligations: _decodeList(
                t['installmentObligations'], 'obligations', _decodeObligation)),
        facilities: FacilityPortfolioRuntimeState(
            academyFacilities: _decodeList(
                f['academyFacilities'],
                'academyFacilities',
                (e) => AcademyFacilityState(
                    clubId: _string(e['clubId'], 'clubId'),
                    level: _integer(e['level'], 'level'))),
            stadiumFacilities: _decodeList(
                f['stadiumFacilities'],
                'stadiumFacilities',
                (e) => StadiumFacilityState(
                    clubId: _string(e['clubId'], 'clubId'),
                    level: _integer(e['level'], 'level'))),
            trainingGroundFacilities: _decodeList(
                f['trainingGroundFacilities'],
                'trainingGroundFacilities',
                (e) => TrainingGroundFacilityState(
                    clubId: _string(e['clubId'], 'clubId'),
                    level: _integer(e['level'], 'level'))),
            totalInvestmentSpent: Money.fromMinorUnits(
                _integer(f['totalInvestmentSpentMinorUnits'], 'spent'))),
        presidentClubs: _decodeList(presidency['clubs'], 'clubs', _decodeClub),
        electionInterval:
            _integer(presidency['electionInterval'], 'electionInterval'),
        termPromiseScores: {
          for (final e in scores.entries) e.key: _scoreList(e.value)
        },
        careerInstanceId: _string(p['careerInstanceId'], 'careerInstanceId'),
        origin: _string(p['origin'], 'origin'),
        phase: _string(p['phase'], 'phase'),
        runtimeProfile: _string(p['runtimeProfile'], 'runtimeProfile'),
        decisionId: _string(pending['decisionId'], 'decisionId'),
        contextSignature:
            _string(pending['contextSignature'], 'contextSignature'),
        preparedOpeningDigest:
            _string(p['preparedOpeningDigest'], 'preparedOpeningDigest'),
      );
    } on SaveLoadException {
      rethrow;
    } catch (e) {
      throw SaveLoadException(
          SaveLoadFailure.invalidPayload, 'Invalid owned opening: $e');
    }
  }

  static Never _invalid(String message) =>
      throw SaveLoadException(SaveLoadFailure.invalidPayload, message);
  static Map<String, Object?> _map(Object? value, String field) {
    if (value is! Map || value.keys.any((k) => k is! String))
      _invalid('$field must be an object.');
    return Map<String, Object?>.from(value);
  }

  static Map<String, Object?> _strict(Object? value, List<String> keys) {
    final m = _map(value, 'owned value');
    if (m.length != keys.length || keys.any((k) => !m.containsKey(k)))
      _invalid('Unexpected or missing owned fields.');
    return m;
  }

  static String _string(Object? v, String field) {
    if (v is! String || v.isEmpty)
      _invalid('$field must be a nonempty string.');
    return v;
  }

  static String? _nullableString(Object? v, String field) =>
      v == null ? null : _string(v, field);
  static int _integer(Object? v, String field) {
    if (v is! int) _invalid('$field must be an integer.');
    return v;
  }

  static int _int(Object? v, String field) => _integer(v, field);
  static int? _nullableInteger(Object? v, String field) =>
      v == null ? null : _integer(v, field);
  static double _finiteDouble(Object? v, String field) {
    if (v is! num || !v.isFinite) _invalid('$field must be finite.');
    return v.toDouble();
  }

  static List<int> _scoreList(Object? v) {
    if (v is! List) _invalid('scores must be a list.');
    return v.map((e) => _integer(e, 'score')).toList(growable: false);
  }

  static T _enum<T extends Enum>(Iterable<T> values, String name) =>
      values.firstWhere((e) => e.name == name,
          orElse: () => _invalid('Unknown enum $name.'));
  static ContractEventType _contractEventType(String name) =>
      _enum(ContractEventType.values, name);
  static ManagerProfile _managerProfile(String name) =>
      _enum(ManagerProfile.values, name);
  static List<T> _decodeList<T>(
      Object? value, String field, T Function(Map<String, Object?>) fn) {
    if (value is! List) _invalid('$field must be a list.');
    final keys = switch (field) {
      'contracts' => [
          'playerId',
          'clubId',
          'startSeasonIndex',
          'endSeasonIndex',
          'annualWageMinorUnits'
        ],
      'events' => [
          'seasonIndex',
          'playerId',
          'type',
          'fromClubId',
          'toClubId',
          'annualWageMinorUnits',
          'endSeasonIndex'
        ],
      'activeLoans' || 'loanHistory' => [
          'playerId',
          'parentClubId',
          'loanClubId',
          'startSeasonIndex',
          'endSeasonIndex',
          'loanFeeMinorUnits',
          'loanClubWageShareBps'
        ],
      'obligations' => [
          'playerId',
          'fromClubId',
          'toClubId',
          'createdSeasonIndex',
          'installments'
        ],
      'obligation.installments' => ['dueSeasonIndex', 'amountMinorUnits'],
      'managers' => [
          'id',
          'name',
          'profile',
          'startAge',
          'retirementAge',
          'reputation',
          'coaching',
          'youthDevelopment',
          'manManagement',
          'boardCooperation',
          'budgetDemand'
        ],
      'assignments' => [
          'clubId',
          'managerId',
          'appointedSeasonIndex',
          'completedSeasons',
          'boardRelationship'
        ],
      'academyFacilities' ||
      'stadiumFacilities' ||
      'trainingGroundFacilities' =>
        ['clubId', 'level'],
      'clubs' => [
          'clubId',
          'presidentId',
          'presidentName',
          'tenureNumber',
          'startedSeasonIndex',
          'reelectionsWon',
          'archetype',
          'financialDiscipline',
          'riskAppetite',
          'transferAmbition',
          'youthOrientation',
          'managerPatience',
          'fanSporting',
          'fanFinancial',
          'fanTransfer',
          'fanIdentity',
          'mediaCredibility'
        ],
      _ => throw StateError('Unknown owned leaf $field'),
    };
    return value.map((e) => fn(_strict(e, keys))).toList(growable: false);
  }

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
          _integer(
              json['annualWageMinorUnits'], 'contract.annualWageMinorUnits'),
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

  ContractEvent _decodeContractEvent(Map<String, Object?> json) =>
      ContractEvent(
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
        endSeasonIndex: _integer(json['endSeasonIndex'], 'loan.endSeasonIndex'),
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
              _integer(
                  item['amountMinorUnits'], 'installment.amountMinorUnits'),
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
        manManagement: _integer(json['manManagement'], 'manager.manManagement'),
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
}

// Inspect member names before whole-document decoding can discard duplicates.
// Nested legacy JSON strings remain strings and retain their existing semantics.
Object? _ownedStrictJson(String encoded) {
  _OwnedJsonMembers(encoded).document();
  return jsonDecode(encoded);
}

final class _OwnedJsonMembers {
  _OwnedJsonMembers(this.source);
  final String source;
  static final _number =
      RegExp(r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?');
  int at = 0;
  bool _duplicateMember = false;

  Never _malformed() =>
      throw FormatException('Invalid owned JSON syntax.', source, at);

  void ws() {
    while (at < source.length) {
      final code = source.codeUnitAt(at);
      if (code != 32 && code != 9 && code != 10 && code != 13) break;
      at++;
    }
  }

  bool take(String character) {
    if (at < source.length && source[at] == character) {
      at++;
      return true;
    }
    return false;
  }

  void require(String character) {
    if (!take(character)) _malformed();
  }

  void document() {
    value();
    ws();
    if (at != source.length) _malformed();
    if (_duplicateMember) {
      throw const SaveLoadException(SaveLoadFailure.invalidPayload,
          'Duplicate JSON member in owned save.');
    }
  }

  String string() {
    final start = at;
    require('"');
    while (at < source.length) {
      final code = source.codeUnitAt(at++);
      if (code == 34) {
        // This decodes only one validated string token, not the JSON object.
        return jsonDecode(source.substring(start, at)) as String;
      }
      if (code < 32) _malformed();
      if (code != 92) continue;
      if (at >= source.length) _malformed();
      final escaped = source[at++];
      if (escaped == 'u') {
        for (var index = 0; index < 4; index++) {
          if (at >= source.length) _malformed();
          final hex = source.codeUnitAt(at++);
          if (!((hex >= 48 && hex <= 57) ||
              (hex >= 65 && hex <= 70) ||
              (hex >= 97 && hex <= 102))) {
            _malformed();
          }
        }
      } else if (!const ['"', r'\', '/', 'b', 'f', 'n', 'r', 't']
          .contains(escaped)) {
        _malformed();
      }
    }
    _malformed();
  }

  void value() {
    ws();
    if (at >= source.length) _malformed();
    if (take('{')) {
      ws();
      final keys = <String>{};
      if (take('}')) return;
      while (true) {
        ws();
        final key = string();
        if (!keys.add(key)) _duplicateMember = true;
        ws();
        require(':');
        value();
        ws();
        if (take('}')) return;
        require(',');
      }
    }
    if (take('[')) {
      ws();
      if (take(']')) return;
      while (true) {
        value();
        ws();
        if (take(']')) return;
        require(',');
      }
    }
    if (source[at] == '"') {
      string();
      return;
    }
    for (final literal in const ['true', 'false', 'null']) {
      if (source.startsWith(literal, at)) {
        at += literal.length;
        return;
      }
    }
    final number = _number.matchAsPrefix(source, at);
    if (number == null) _malformed();
    at = number.end;
  }
}
