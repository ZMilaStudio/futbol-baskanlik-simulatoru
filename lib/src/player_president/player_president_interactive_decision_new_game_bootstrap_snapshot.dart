import 'dart:convert';

import '../core/simulation_config.dart';
import '../league/club.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_persistence_bundle.dart';
import 'player_president_interactive_decision_transcript_snapshot.dart';

/// Replay-only persistence for an M79 new-game session before an M65
/// checkpoint exists.
///
/// This snapshot intentionally does not persist partial game state. It stores
/// the immutable new-game bootstrap inputs needed by M73 plus the accepted M74
/// answer transcript. The caller must still supply the same immutable world on
/// restore; [worldFingerprint] fail-closes divergent input before replay.
class PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot {
  PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot({
    required this.worldFingerprint,
    required this.config,
    required this.controlledClubId,
    required this.electionInterval,
    required this.resumeConfig,
    required this.transcript,
  }) {
    validate();
  }

  final String worldFingerprint;
  final SimulationConfig config;
  final String controlledClubId;
  final int electionInterval;
  final PlayerPresidentInteractiveDecisionResumeConfig resumeConfig;
  final PlayerPresidentInteractiveDecisionTranscriptSnapshot transcript;

  int get answeredDecisionCount => transcript.decisionCount;

  void validate() {
    if (worldFingerprint.isEmpty) {
      throw ArgumentError('worldFingerprint cannot be empty.');
    }
    if (controlledClubId.isEmpty) {
      throw ArgumentError('controlledClubId cannot be empty.');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }
    resumeConfig.validate();
  }

  void validateWorld({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  }) {
    validate();
    final actual = worldFingerprintFor(clubs: clubs, leagues: leagues);
    if (actual != worldFingerprint) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'New-game bootstrap world fingerprint does not match supplied inputs.',
      );
    }
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'New-game bootstrap controlled club is missing from supplied world.',
      );
    }
  }

  String get signature =>
      'world=$worldFingerprint:club=$controlledClubId:'
      'seed=${config.careerSeed}:version=${config.simulationVersion}:'
      'season=${config.seasonIndex}:election=$electionInterval:'
      '${resumeConfig.signature}:answers=${transcript.decisionCount}:'
      'transcript=${transcript.signature}';

  static String worldFingerprintFor({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  }) {
    final payload = <String, Object?>{
      'clubs': clubs
          .map(
            (club) => <String, Object?>{
              'id': club.id,
              'name': club.name,
              'strength': club.strength,
            },
          )
          .toList(),
      'leagues': leagues
          .map(
            (league) => <String, Object?>{
              'tierLevel': league.tier.level,
              'leagueId': league.id,
              'clubIds': List<String>.of(league.clubIds),
            },
          )
          .toList(),
    };
    return SaveChecksum.forPayload(saveVersion: 1, payload: payload);
  }
}

/// Versioned/checksummed M80 envelope for replay-only pre-checkpoint progress.
///
/// This is not an M65 replacement and is deliberately not an M75 bundle.
/// No partial runtime/world state is encoded here.
class PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec {
  const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec({
    this.transcriptCodec =
        const PlayerPresidentInteractiveDecisionTranscriptSaveCodec(),
  });

  static const String format =
      'zmila-fbs-player-president-interactive-decision-new-game-bootstrap';
  static const int currentSaveVersion = 1;

  final PlayerPresidentInteractiveDecisionTranscriptSaveCodec transcriptCodec;

  String encode(
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot snapshot,
  ) {
    snapshot.validate();
    final payload = <String, Object?>{
      'worldFingerprint': snapshot.worldFingerprint,
      'config': _configPayload(snapshot.config),
      'controlledClubId': snapshot.controlledClubId,
      'electionInterval': snapshot.electionInterval,
      'resumeConfig': snapshot.resumeConfig.toPayload(),
      'transcript': transcriptCodec.encode(snapshot.transcript),
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

  PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot decode(
    String encoded,
  ) {
    final Object? root;
    try {
      root = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'New-game bootstrap snapshot is not valid JSON: $error',
      );
    }

    final envelope = _asStringMap(root, 'bootstrap envelope');
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unexpected new-game bootstrap format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Bootstrap saveVersion must be an integer.',
      );
    }
    if (version != currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported new-game bootstrap version: $version.',
      );
    }

    final payload = _asStringMap(envelope['payload'], 'bootstrap payload');
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum !=
            SaveChecksum.forPayload(
              saveVersion: version,
              payload: payload,
            )) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'New-game bootstrap checksum mismatch.',
      );
    }

    final worldFingerprint = _requiredString(payload, 'worldFingerprint');
    final controlledClubId = _requiredString(payload, 'controlledClubId');
    final electionInterval = _requiredInt(payload, 'electionInterval');
    final transcriptEncoded = _requiredString(payload, 'transcript');

    final snapshot = PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot(
      worldFingerprint: worldFingerprint,
      config: _configFromPayload(payload['config']),
      controlledClubId: controlledClubId,
      electionInterval: electionInterval,
      resumeConfig:
          PlayerPresidentInteractiveDecisionResumeConfig.fromPayload(
        payload['resumeConfig'],
      ),
      transcript: transcriptCodec.decode(transcriptEncoded),
    );
    snapshot.validate();
    return snapshot;
  }

  static Map<String, Object?> _configPayload(SimulationConfig config) =>
      <String, Object?>{
        'careerSeed': config.careerSeed,
        'simulationVersion': config.simulationVersion,
        'seasonIndex': config.seasonIndex,
        'homeAdvantageRating': config.homeAdvantageRating,
        'baseHomeGoals': config.baseHomeGoals,
        'baseAwayGoals': config.baseAwayGoals,
        'ratingScale': config.ratingScale,
        'minExpectedGoals': config.minExpectedGoals,
        'maxExpectedGoals': config.maxExpectedGoals,
      };

  static SimulationConfig _configFromPayload(Object? value) {
    final map = _asStringMap(value, 'simulation config');
    return SimulationConfig(
      careerSeed: _requiredInt(map, 'careerSeed'),
      simulationVersion: _requiredInt(map, 'simulationVersion'),
      seasonIndex: _requiredInt(map, 'seasonIndex'),
      homeAdvantageRating: _requiredDouble(map, 'homeAdvantageRating'),
      baseHomeGoals: _requiredDouble(map, 'baseHomeGoals'),
      baseAwayGoals: _requiredDouble(map, 'baseAwayGoals'),
      ratingScale: _requiredDouble(map, 'ratingScale'),
      minExpectedGoals: _requiredDouble(map, 'minExpectedGoals'),
      maxExpectedGoals: _requiredDouble(map, 'maxExpectedGoals'),
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
      '$key must be a non-empty string.',
    );
  }
  return value;
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$key must be an integer.',
    );
  }
  return value;
}

double _requiredDouble(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! num) {
    throw SaveLoadException(
      SaveLoadFailure.invalidPayload,
      '$key must be numeric.',
    );
  }
  return value.toDouble();
}
