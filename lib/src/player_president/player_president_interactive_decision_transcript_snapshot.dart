import 'dart:convert';

import '../crisis/crisis_decision_core.dart';
import '../crisis/player_president_crisis_control.dart';
import '../crisis/player_president_facility_control.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../manager/player_president_manager_control.dart';
import '../media/media_statement.dart';
import '../promise/president_promise.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import 'player_president_interactive_decision_session.dart';

/// One replayable M73 answer. It contains no game-state snapshot: the request
/// context is intentionally re-derived from the authoritative starting inputs
/// or M65 checkpoint when the transcript is restored.
class PlayerPresidentInteractiveDecisionTranscriptEntry {
  PlayerPresidentInteractiveDecisionTranscriptEntry({
    required this.requestKey,
    required this.kind,
    required Map<String, Object?> choice,
  }) : choice = Map.unmodifiable(choice) {
    if (requestKey.isEmpty) {
      throw ArgumentError('requestKey cannot be empty.');
    }
  }

  factory PlayerPresidentInteractiveDecisionTranscriptEntry.fromDecision({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      PlayerPresidentInteractiveDecisionTranscriptEntry(
        requestKey: request.key,
        kind: request.kind,
        choice: _encodeChoice(request.kind, choice),
      );

  final String requestKey;
  final PlayerPresidentInteractiveDecisionKind kind;
  final Map<String, Object?> choice;

  String get signature =>
      '$requestKey:${kind.name}:${SaveChecksum.canonicalJson(choice)}';

  Object choiceFor(PlayerPresidentInteractiveDecisionRequest request) {
    if (request.key != requestKey || request.kind != kind) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Transcript entry does not match the current deterministic request.',
      );
    }
    return _decodeChoice(kind, choice);
  }

  Map<String, Object?> toPayload() => <String, Object?>{
        'requestKey': requestKey,
        'kind': kind.name,
        'choice': choice,
      };

  static PlayerPresidentInteractiveDecisionTranscriptEntry fromPayload(
    Object? value,
  ) {
    final map = _asStringMap(value, 'transcript entry');
    final requestKey = map['requestKey'];
    final kindName = map['kind'];
    if (requestKey is! String || requestKey.isEmpty || kindName is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Transcript entry requires requestKey and kind.',
      );
    }
    final kind = _enumByName(
      PlayerPresidentInteractiveDecisionKind.values,
      kindName,
      'decision kind',
    );
    return PlayerPresidentInteractiveDecisionTranscriptEntry(
      requestKey: requestKey,
      kind: kind,
      choice: _asStringMap(map['choice'], 'choice'),
    );
  }
}

class PlayerPresidentInteractiveDecisionTranscriptSnapshot {
  PlayerPresidentInteractiveDecisionTranscriptSnapshot({
    required Iterable<PlayerPresidentInteractiveDecisionTranscriptEntry>
        entries,
  }) : entries = List.unmodifiable(entries);

  final List<PlayerPresidentInteractiveDecisionTranscriptEntry> entries;

  int get decisionCount => entries.length;

  String get signature => entries.map((entry) => entry.signature).join('||');
}

/// Versioned sidecar codec for M73 answer transcripts.
///
/// This is deliberately not a second game-state save. The application must
/// still provide the same immutable new-game inputs or the authoritative M65
/// checkpoint when restoring. Pending request/context state is never stored;
/// it is deterministically re-derived and request-key checked during replay.
class PlayerPresidentInteractiveDecisionTranscriptSaveCodec {
  const PlayerPresidentInteractiveDecisionTranscriptSaveCodec();

  static const String format =
      'zmila-fbs-player-president-interactive-decision-transcript';
  static const int currentSaveVersion = 1;

  String encode(PlayerPresidentInteractiveDecisionTranscriptSnapshot snapshot) {
    final payload = <String, Object?>{
      'entries': snapshot.entries.map((entry) => entry.toPayload()).toList(),
    };
    final checksum = SaveChecksum.forPayload(
      saveVersion: currentSaveVersion,
      payload: payload,
    );
    return SaveChecksum.canonicalJson(<String, Object?>{
      'format': format,
      'saveVersion': currentSaveVersion,
      'checksum': checksum,
      'payload': payload,
    });
  }

  PlayerPresidentInteractiveDecisionTranscriptSnapshot decode(String encoded) {
    final Object? root;
    try {
      root = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Transcript snapshot is not valid JSON: $error',
      );
    }

    final envelope = _asStringMap(root, 'transcript envelope');
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unexpected interactive transcript format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Transcript saveVersion must be an integer.',
      );
    }
    if (version != currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported interactive transcript version: $version.',
      );
    }

    final payload = _asStringMap(envelope['payload'], 'transcript payload');
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum !=
            SaveChecksum.forPayload(
              saveVersion: version,
              payload: payload,
            )) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Interactive transcript checksum mismatch.',
      );
    }

    final rawEntries = payload['entries'];
    if (rawEntries is! List) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Transcript payload requires an entries list.',
      );
    }
    return PlayerPresidentInteractiveDecisionTranscriptSnapshot(
      entries: rawEntries.map(
        PlayerPresidentInteractiveDecisionTranscriptEntry.fromPayload,
      ),
    );
  }
}

/// Application-lifecycle wrapper around M73.
///
/// It records only accepted answers. On restore the caller supplies a freshly
/// constructed M73 session with the same immutable start inputs or M65
/// checkpoint. Every transcript entry must match the request re-derived by
/// M73 before it is submitted, so stale/divergent sidecars fail closed.
class PlayerPresidentInteractiveDecisionTranscriptSession {
  PlayerPresidentInteractiveDecisionTranscriptSession(
    PlayerPresidentInteractiveDecisionSession session, {
    this.codec = const PlayerPresidentInteractiveDecisionTranscriptSaveCodec(),
  })  : _session = session,
        _entries = [];

  PlayerPresidentInteractiveDecisionTranscriptSession._(
    this._session,
    this.codec,
    List<PlayerPresidentInteractiveDecisionTranscriptEntry> entries,
  ) : _entries = entries;

  factory PlayerPresidentInteractiveDecisionTranscriptSession.restore({
    required PlayerPresidentInteractiveDecisionSession session,
    required PlayerPresidentInteractiveDecisionTranscriptSnapshot snapshot,
    PlayerPresidentInteractiveDecisionTranscriptSaveCodec codec =
        const PlayerPresidentInteractiveDecisionTranscriptSaveCodec(),
  }) {
    final restoredEntries =
        <PlayerPresidentInteractiveDecisionTranscriptEntry>[];
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (final entry in snapshot.entries) {
      if (step is! PlayerPresidentInteractiveDecisionPending) {
        throw const SaveLoadException(
          SaveLoadFailure.invalidPayload,
          'Transcript contains answers after the session completed.',
        );
      }
      final request = step.request;
      final choice = entry.choiceFor(request);
      step = session.submit(request: request, choice: choice);
      restoredEntries.add(entry);
    }
    if (session.answeredDecisionCount != restoredEntries.length) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Restored transcript decision count diverged from M73.',
      );
    }
    return PlayerPresidentInteractiveDecisionTranscriptSession._(
      session,
      codec,
      restoredEntries,
    );
  }

  factory PlayerPresidentInteractiveDecisionTranscriptSession.restoreEncoded({
    required PlayerPresidentInteractiveDecisionSession session,
    required String encodedTranscript,
    PlayerPresidentInteractiveDecisionTranscriptSaveCodec codec =
        const PlayerPresidentInteractiveDecisionTranscriptSaveCodec(),
  }) =>
      PlayerPresidentInteractiveDecisionTranscriptSession.restore(
        session: session,
        snapshot: codec.decode(encodedTranscript),
        codec: codec,
      );

  final PlayerPresidentInteractiveDecisionSession _session;
  final List<PlayerPresidentInteractiveDecisionTranscriptEntry> _entries;
  final PlayerPresidentInteractiveDecisionTranscriptSaveCodec codec;

  int get answeredDecisionCount => _entries.length;
  PlayerPresidentInteractiveDecisionRequest? get pendingDecision =>
      _session.pendingDecision;
  PlayerPresidentInteractiveSessionCompleted? get completed =>
      _session.completed;

  PlayerPresidentInteractiveDecisionTranscriptSnapshot get snapshot =>
      PlayerPresidentInteractiveDecisionTranscriptSnapshot(entries: _entries);

  String encodeSnapshot() => codec.encode(snapshot);

  PlayerPresidentInteractiveSessionStep advance() => _session.advance();

  PlayerPresidentInteractiveSessionStep submit({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      submitWithResolution(request: request, choice: choice).nextStep;

  PlayerPresidentInteractiveDecisionSubmissionResult submitWithResolution({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) {
    final entry =
        PlayerPresidentInteractiveDecisionTranscriptEntry.fromDecision(
      request: request,
      choice: choice,
    );
    final result = _session.submitWithResolution(
      request: request,
      choice: choice,
    );
    _entries.add(entry);
    return result;
  }
}

Map<String, Object?> _encodeChoice(
  PlayerPresidentInteractiveDecisionKind kind,
  Object choice,
) {
  switch (kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      if (choice is! PlayerFacilityInvestmentChoice) {
        throw ArgumentError.value(choice, 'choice', 'Expected facility choice.');
      }
      choice.validate();
      return <String, Object?>{
        'academyUpgrades': choice.academyUpgrades,
        'trainingGroundUpgrades': choice.trainingGroundUpgrades,
        'stadiumUpgrades': choice.stadiumUpgrades,
      };
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      if (choice is! PlayerSponsorOfferChoice) {
        throw ArgumentError.value(choice, 'choice', 'Expected sponsor choice.');
      }
      choice.validate();
      return <String, Object?>{'offerId': choice.offerId};
    case PlayerPresidentInteractiveDecisionKind.crisis:
      if (choice is! PlayerCrisisActionChoice) {
        throw ArgumentError.value(choice, 'choice', 'Expected crisis choice.');
      }
      return <String, Object?>{'action': choice.action.name};
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      if (choice is! PlayerManagerReviewChoice) {
        throw ArgumentError.value(
          choice,
          'choice',
          'Expected manager review choice.',
        );
      }
      return <String, Object?>{'review': choice.name};
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      if (choice is! PlayerManagerReplacementChoice) {
        throw ArgumentError.value(
          choice,
          'choice',
          'Expected manager replacement choice.',
        );
      }
      choice.validate();
      return <String, Object?>{'managerId': choice.managerId};
    case PlayerPresidentInteractiveDecisionKind.promise:
      if (choice is! PresidentPromiseType) {
        throw ArgumentError.value(choice, 'choice', 'Expected promise type.');
      }
      return <String, Object?>{'promise': choice.name};
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      if (choice is! MediaStance) {
        throw ArgumentError.value(choice, 'choice', 'Expected media stance.');
      }
      return <String, Object?>{'stance': choice.name};
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      if (choice is! PlayerTransferStrategyChoice) {
        throw ArgumentError.value(
          choice,
          'choice',
          'Expected transfer strategy choice.',
        );
      }
      choice.validate();
      return <String, Object?>{
        'financialDiscipline': choice.financialDiscipline,
        'transferAmbition': choice.transferAmbition,
        'riskAppetite': choice.riskAppetite,
        'youthOrientation': choice.youthOrientation,
      };
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      if (choice is! MatchdayTicketPricingChoice) {
        throw ArgumentError.value(
          choice,
          'choice',
          'Expected ticket pricing choice.',
        );
      }
      return <String, Object?>{'tier': choice.tier.name};
  }
}

Object _decodeChoice(
  PlayerPresidentInteractiveDecisionKind kind,
  Map<String, Object?> choice,
) {
  switch (kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice(
        academyUpgrades: _requiredInt(choice, 'academyUpgrades'),
        trainingGroundUpgrades: _requiredInt(choice, 'trainingGroundUpgrades'),
        stadiumUpgrades: _requiredInt(choice, 'stadiumUpgrades'),
      );
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      return PlayerSponsorOfferChoice(
        offerId: _requiredString(choice, 'offerId'),
      );
    case PlayerPresidentInteractiveDecisionKind.crisis:
      return PlayerCrisisActionChoice(
        action: _enumByName(
          CrisisAction.values,
          _requiredString(choice, 'action'),
          'crisis action',
        ),
      );
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return _enumByName(
        PlayerManagerReviewChoice.values,
        _requiredString(choice, 'review'),
        'manager review',
      );
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      return PlayerManagerReplacementChoice(
        managerId: _requiredString(choice, 'managerId'),
      );
    case PlayerPresidentInteractiveDecisionKind.promise:
      return _enumByName(
        PresidentPromiseType.values,
        _requiredString(choice, 'promise'),
        'promise type',
      );
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      return _enumByName(
        MediaStance.values,
        _requiredString(choice, 'stance'),
        'media stance',
      );
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      return PlayerTransferStrategyChoice(
        financialDiscipline: _requiredInt(choice, 'financialDiscipline'),
        transferAmbition: _requiredInt(choice, 'transferAmbition'),
        riskAppetite: _requiredInt(choice, 'riskAppetite'),
        youthOrientation: _requiredInt(choice, 'youthOrientation'),
      );
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return MatchdayTicketPricingChoice(
        _enumByName(
          MatchdayTicketPriceTier.values,
          _requiredString(choice, 'tier'),
          'ticket tier',
        ),
      );
  }
}

Map<String, Object?> _asStringMap(Object? value, String label) {
  if (value is! Map) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$label must be a JSON object.',
    );
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        '$label contains a non-string key.',
      );
    }
    result[key] = entry.value;
  }
  return result;
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'Choice field $key must be a non-empty string.',
    );
  }
  return value;
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      'Choice field $key must be an integer.',
    );
  }
  return value;
}

T _enumByName<T extends Enum>(
  List<T> values,
  String name,
  String label,
) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw SaveLoadException(
    SaveLoadFailure.invalidPayload,
    'Unknown $label: $name.',
  );
}
