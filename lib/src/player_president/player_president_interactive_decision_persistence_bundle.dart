import 'dart:convert';

import '../crisis/crisis_decision_core.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_interactive_decision_transcript_snapshot.dart';

/// Deterministic runtime knobs needed to recreate an M73 resume session.
///
/// M75 intentionally supports checkpoint-backed interactive resume. The
/// authoritative game state still comes from M65; this config only records the
/// small runtime inputs that M73.resume() cannot derive from that checkpoint.
class PlayerPresidentInteractiveDecisionResumeConfig {
  const PlayerPresidentInteractiveDecisionResumeConfig({
    required this.seasonCount,
    this.hasFutureSeasonAfterReport = false,
    this.crisisActivationThreshold = 55,
    this.candidateLimit = 5,
  });

  final int seasonCount;
  final bool hasFutureSeasonAfterReport;
  final int crisisActivationThreshold;
  final int candidateLimit;

  void validate() {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (crisisActivationThreshold < 0 || crisisActivationThreshold > 100) {
      throw ArgumentError.value(
        crisisActivationThreshold,
        'crisisActivationThreshold',
        'Expected a value between 0 and 100.',
      );
    }
    if (candidateLimit <= 0) {
      throw ArgumentError.value(candidateLimit, 'candidateLimit');
    }
  }

  Map<String, Object?> toPayload() {
    validate();
    return <String, Object?>{
      'seasonCount': seasonCount,
      'hasFutureSeasonAfterReport': hasFutureSeasonAfterReport,
      'crisisActivationThreshold': crisisActivationThreshold,
      'candidateLimit': candidateLimit,
    };
  }

  static PlayerPresidentInteractiveDecisionResumeConfig fromPayload(
    Object? value,
  ) {
    final map = _asStringMap(value, 'resume config');
    final seasonCount = map['seasonCount'];
    final hasFutureSeasonAfterReport = map['hasFutureSeasonAfterReport'];
    final crisisActivationThreshold = map['crisisActivationThreshold'];
    final candidateLimit = map['candidateLimit'];
    if (seasonCount is! int ||
        hasFutureSeasonAfterReport is! bool ||
        crisisActivationThreshold is! int ||
        candidateLimit is! int) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Interactive resume config fields are invalid.',
      );
    }
    final config = PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      crisisActivationThreshold: crisisActivationThreshold,
      candidateLimit: candidateLimit,
    );
    try {
      config.validate();
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Interactive resume config is invalid: $error',
      );
    }
    return config;
  }

  String get signature =>
      'seasons=$seasonCount:future=$hasFutureSeasonAfterReport:'
      'crisis=$crisisActivationThreshold:candidates=$candidateLimit';
}

/// One application-save unit for an in-progress checkpoint-backed M73 session.
///
/// The bundle does not invent a new game-state model. It nests the canonical
/// M65 game-state save and the M74 answer-transcript sidecar in one checksummed
/// envelope so a save slot cannot accidentally persist or load them as an
/// unpaired set. M65 remains the only game-state authority.
class PlayerPresidentInteractiveDecisionPersistenceBundle {
  PlayerPresidentInteractiveDecisionPersistenceBundle({
    required this.checkpoint,
    required this.transcript,
    required this.resumeConfig,
  }) {
    validate();
  }

  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  final PlayerPresidentInteractiveDecisionTranscriptSnapshot transcript;
  final PlayerPresidentInteractiveDecisionResumeConfig resumeConfig;

  int get answeredDecisionCount => transcript.decisionCount;

  void validate() {
    checkpoint.validate();
    resumeConfig.validate();
  }

  /// Recreates the canonical M73+M74 interactive session without requiring the
  /// application to separately pair a checkpoint save and transcript sidecar.
  PlayerPresidentInteractiveDecisionTranscriptSession restoreSession() {
    validate();
    final base = PlayerPresidentInteractiveDecisionSession.resume(
      checkpoint: checkpoint,
      seasonCount: resumeConfig.seasonCount,
      hasFutureSeasonAfterReport:
          resumeConfig.hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold: resumeConfig.crisisActivationThreshold,
      ),
      candidateLimit: resumeConfig.candidateLimit,
    );
    return PlayerPresidentInteractiveDecisionTranscriptSession.restore(
      session: base,
      snapshot: transcript,
    );
  }

  String get signature =>
      '${resumeConfig.signature}:checkpoint=${checkpoint.signature}:'
      'transcript=${transcript.signature}';
}

/// Versioned/checksummed outer envelope for M65 + M74 persistence.
///
/// The nested saves are independently decoded by their existing codecs. This
/// keeps their versioning, checksums, and authority boundaries intact while
/// giving the application one atomic persistence blob.
class PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec {
  const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec({
    this.checkpointCodec = const PlayerPresidentTicketPricingRuntimeSaveCodec(),
    this.transcriptCodec =
        const PlayerPresidentInteractiveDecisionTranscriptSaveCodec(),
  });

  static const String format =
      'zmila-fbs-player-president-interactive-decision-persistence-bundle';
  static const int currentSaveVersion = 1;

  final PlayerPresidentTicketPricingRuntimeSaveCodec checkpointCodec;
  final PlayerPresidentInteractiveDecisionTranscriptSaveCodec transcriptCodec;

  String encode(PlayerPresidentInteractiveDecisionPersistenceBundle bundle) {
    bundle.validate();
    final payload = <String, Object?>{
      'resumeConfig': bundle.resumeConfig.toPayload(),
      'gameStateSave': checkpointCodec.encode(bundle.checkpoint),
      'transcriptSave': transcriptCodec.encode(bundle.transcript),
    };
    return SaveChecksum.canonicalJson(<String, Object?>{
      'format': format,
      'saveVersion': currentSaveVersion,
      'checksum': SaveChecksum.forPayload(
        saveVersion: currentSaveVersion,
        payload: payload,
      ),
      'payload': payload,
    });
  }

  PlayerPresidentInteractiveDecisionPersistenceBundle decode(String encoded) {
    final Object? root;
    try {
      root = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Interactive persistence bundle is not valid JSON: $error',
      );
    }

    final envelope = _asStringMap(root, 'persistence bundle envelope');
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unexpected interactive persistence bundle format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Persistence bundle saveVersion must be an integer.',
      );
    }
    if (version != currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported interactive persistence bundle version: $version.',
      );
    }

    final payload = _asStringMap(envelope['payload'], 'persistence payload');
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum !=
            SaveChecksum.forPayload(
              saveVersion: version,
              payload: payload,
            )) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Interactive persistence bundle checksum mismatch.',
      );
    }

    final gameStateSave = payload['gameStateSave'];
    final transcriptSave = payload['transcriptSave'];
    if (gameStateSave is! String || transcriptSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Persistence bundle requires nested game-state and transcript saves.',
      );
    }

    try {
      return PlayerPresidentInteractiveDecisionPersistenceBundle(
        checkpoint: checkpointCodec.decode(gameStateSave),
        transcript: transcriptCodec.decode(transcriptSave),
        resumeConfig:
            PlayerPresidentInteractiveDecisionResumeConfig.fromPayload(
          payload['resumeConfig'],
        ),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Interactive persistence bundle payload is invalid: $error',
      );
    }
  }
}

Map<String, Object?> _asStringMap(Object? value, String label) {
  if (value is! Map) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$label must be a map.',
    );
  }
  try {
    return Map<String, Object?>.from(value);
  } catch (error) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$label must use string keys: $error',
    );
  }
}
