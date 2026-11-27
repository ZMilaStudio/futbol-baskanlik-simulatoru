part of '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';

final class _HistoricalOpeningCodec {
  const _HistoricalOpeningCodec();

  String encode(M65OwnedHistoricalOpeningState state) {
    state.validate();
    final c = state.config;
    final payload = <String, Object?>{
      'careerInstanceId': state.careerInstanceId,
      'origin': state.origin,
      'phase': state.phase,
      'runtimeProfile': state.runtimeProfile,
      'sourceClubs': [
        for (final club in state.sourceClubs)
          {'id': club.id, 'name': club.name, 'strength': club.strength}
      ],
      'sourceLeagues': [
        for (final league in state.sourceLeagues)
          {'tierLevel': league.tier.level, 'clubIds': league.clubIds}
      ],
      'config': {
        'careerSeed': c.careerSeed,
        'simulationVersion': c.simulationVersion,
        'seasonIndex': c.seasonIndex,
        'homeAdvantageRating': c.homeAdvantageRating,
        'baseHomeGoals': c.baseHomeGoals,
        'baseAwayGoals': c.baseAwayGoals,
        'ratingScale': c.ratingScale,
        'minExpectedGoals': c.minExpectedGoals,
        'maxExpectedGoals': c.maxExpectedGoals,
      },
      'controlledClubId': state.controlledClubId,
      'expectedPlayerPresidentId': state.expectedPlayerPresidentId,
      'electionInterval': state.electionInterval,
      'pending': {
        'kind': 'promise',
        'decisionId': state.decisionId,
        'contextSignature': state.contextSignature
      },
      'preparedOpeningDigest': state.preparedOpeningDigest,
    };
    return SaveChecksum.canonicalJson({
      'format': PlayerPresidentTicketPricingRuntimeSaveCodec.format,
      'saveVersion': PlayerPresidentTicketPricingRuntimeSaveCodec
          .historicalOpeningSaveVersion,
      'payload': payload,
      'checksum': SaveChecksum.forPayload(saveVersion: 3, payload: payload),
    });
  }

  M65OwnedHistoricalOpeningState decode(String encoded) {
    final Object? decoded;
    try {
      decoded = _ownedStrictJson(encoded);
    } on SaveLoadException {
      rethrow;
    } on FormatException catch (e) {
      throw SaveLoadException(SaveLoadFailure.malformedJson,
          'Invalid historical JSON: ${e.message}');
    }
    if (decoded is! Map ||
        decoded['format'] !=
            PlayerPresidentTicketPricingRuntimeSaveCodec.format) {
      throw const SaveLoadException(
          SaveLoadFailure.invalidEnvelope, 'Invalid historical save envelope.');
    }
    if (decoded['saveVersion'] is! int || decoded['saveVersion'] != 3) {
      throw const SaveLoadException(SaveLoadFailure.unsupportedVersion,
          'Unsupported historical save version.');
    }
    try {
      final envelope =
          _strict(decoded, ['format', 'saveVersion', 'payload', 'checksum']);
      final p = _strict(envelope['payload'], [
        'careerInstanceId',
        'origin',
        'phase',
        'runtimeProfile',
        'sourceClubs',
        'sourceLeagues',
        'config',
        'controlledClubId',
        'expectedPlayerPresidentId',
        'electionInterval',
        'pending',
        'preparedOpeningDigest',
      ]);
      if (envelope['checksum'] is! String ||
          envelope['checksum'] !=
              SaveChecksum.forPayload(saveVersion: 3, payload: p)) {
        throw const SaveLoadException(SaveLoadFailure.checksumMismatch,
            'Historical save checksum mismatch.');
      }
      final c = _strict(p['config'], [
        'careerSeed',
        'simulationVersion',
        'seasonIndex',
        'homeAdvantageRating',
        'baseHomeGoals',
        'baseAwayGoals',
        'ratingScale',
        'minExpectedGoals',
        'maxExpectedGoals',
      ]);
      final pending =
          _strict(p['pending'], ['kind', 'decisionId', 'contextSignature']);
      if (pending['kind'] != 'promise') _invalid('Unsupported pending kind.');
      return M65OwnedHistoricalOpeningState._(
        sourceClubs: _list(p['sourceClubs'], 'sourceClubs').map((raw) {
          final club = _strict(raw, ['id', 'name', 'strength']);
          return Club(
              id: _string(club['id'], 'id'),
              name: _string(club['name'], 'name'),
              strength: _number(club['strength'], 'strength'));
        }),
        sourceLeagues: _list(p['sourceLeagues'], 'sourceLeagues').map((raw) {
          final league = _strict(raw, ['tierLevel', 'clubIds']);
          final level = _integer(league['tierLevel'], 'tierLevel');
          final tier = LeagueTier.values.where((tier) => tier.level == level);
          if (tier.length != 1) _invalid('Unsupported league tier.');
          return WorldLeague(
              tier: tier.single,
              clubIds: _list(league['clubIds'], 'clubIds')
                  .map((id) => _string(id, 'clubId')));
        }),
        config: SimulationConfig(
          careerSeed: _integer(c['careerSeed'], 'careerSeed'),
          simulationVersion:
              _integer(c['simulationVersion'], 'simulationVersion'),
          seasonIndex: _integer(c['seasonIndex'], 'seasonIndex'),
          homeAdvantageRating:
              _number(c['homeAdvantageRating'], 'homeAdvantageRating'),
          baseHomeGoals: _number(c['baseHomeGoals'], 'baseHomeGoals'),
          baseAwayGoals: _number(c['baseAwayGoals'], 'baseAwayGoals'),
          ratingScale: _number(c['ratingScale'], 'ratingScale'),
          minExpectedGoals: _number(c['minExpectedGoals'], 'minExpectedGoals'),
          maxExpectedGoals: _number(c['maxExpectedGoals'], 'maxExpectedGoals'),
        ),
        controlledClubId: _string(p['controlledClubId'], 'controlledClubId'),
        expectedPlayerPresidentId: _string(
            p['expectedPlayerPresidentId'], 'expectedPlayerPresidentId'),
        electionInterval: _integer(p['electionInterval'], 'electionInterval'),
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
    } on JsonUnsupportedObjectError catch (e) {
      throw SaveLoadException(SaveLoadFailure.invalidPayload,
          'Historical payload cannot be canonicalized: $e');
    } on ArgumentError catch (e) {
      throw SaveLoadException(SaveLoadFailure.invalidPayload,
          'Invalid historical opening payload: $e');
    }
  }

  static Never _invalid(String message) =>
      throw SaveLoadException(SaveLoadFailure.invalidPayload, message);
  static Map<String, Object?> _strict(Object? value, List<String> keys) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      _invalid('Historical save field must be an object.');
    }
    if (value.length != keys.length ||
        keys.any((key) => !value.containsKey(key))) {
      _invalid('Unexpected or missing historical save fields.');
    }
    return Map<String, Object?>.from(value);
  }

  static String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) _invalid('$field must be nonempty.');
    return value;
  }

  static int _integer(Object? value, String field) {
    if (value is! int) _invalid('$field must be an integer.');
    return value;
  }

  static double _number(Object? value, String field) {
    if (value is! num || !value.isFinite) _invalid('$field must be finite.');
    return value.toDouble();
  }

  static List<Object?> _list(Object? value, String field) {
    if (value is! List) _invalid('$field must be a list.');
    return List<Object?>.from(value);
  }
}
