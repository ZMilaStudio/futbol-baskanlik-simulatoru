import 'dart:convert';

import '../save/president_runtime_checkpoint.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';

enum PlayerPresidentTenureControlStatus { active, lost }

class PlayerPresidentTenureControlState {
  const PlayerPresidentTenureControlState({
    required this.controlledClubId,
    required this.playerPresidentId,
    required this.status,
    this.lostAtCompletedSeason,
    this.successorPresidentId,
  });

  final String controlledClubId;
  final String playerPresidentId;
  final PlayerPresidentTenureControlStatus status;
  final int? lostAtCompletedSeason;
  final String? successorPresidentId;

  factory PlayerPresidentTenureControlState.initial({
    required String controlledClubId,
    required String playerPresidentId,
  }) =>
      PlayerPresidentTenureControlState(
        controlledClubId: controlledClubId,
        playerPresidentId: playerPresidentId,
        status: PlayerPresidentTenureControlStatus.active,
      );

  bool get active => status == PlayerPresidentTenureControlStatus.active;
  bool get lost => status == PlayerPresidentTenureControlStatus.lost;

  void validate() {
    if (controlledClubId.isEmpty) {
      throw ArgumentError('controlledClubId cannot be empty.');
    }
    if (playerPresidentId.isEmpty) {
      throw ArgumentError('playerPresidentId cannot be empty.');
    }
    if (active) {
      if (lostAtCompletedSeason != null || successorPresidentId != null) {
        throw ArgumentError('Active player-president control cannot contain loss metadata.');
      }
      return;
    }
    if (lostAtCompletedSeason == null || lostAtCompletedSeason! < 0) {
      throw ArgumentError('Lost player-president control requires a valid loss season.');
    }
    if (successorPresidentId == null || successorPresidentId!.isEmpty) {
      throw ArgumentError('Lost player-president control requires a successor president.');
    }
    if (successorPresidentId == playerPresidentId) {
      throw ArgumentError('Successor president must differ from the player president.');
    }
  }

  String get signature =>
      '$controlledClubId:$playerPresidentId:${status.name}:'
      'lostAt=${lostAtCompletedSeason ?? 'none'}:'
      'successor=${successorPresidentId ?? 'none'}';
}

/// M58 binds player control to the actual incumbent president identity rather
/// than to the club id alone.
///
/// Once a real election turnover replaces the captured player-president id,
/// control is permanently lost. The gate never mutates election outcomes and
/// never reactivates control if the same identity is observed later.
class PlayerPresidentTenureControlGate {
  const PlayerPresidentTenureControlGate();

  PlayerPresidentTenureControlState capture({
    required PresidentRuntimeCheckpoint presidentRuntime,
    required String controlledClubId,
  }) {
    presidentRuntime.validate();
    final incumbent = _stateFor(presidentRuntime, controlledClubId);
    final state = PlayerPresidentTenureControlState(
      controlledClubId: controlledClubId,
      playerPresidentId: incumbent.tenure.president.id,
      status: PlayerPresidentTenureControlStatus.active,
    );
    state.validate();
    return state;
  }

  PlayerPresidentTenureControlState refresh({
    required PlayerPresidentTenureControlState state,
    required PresidentRuntimeCheckpoint presidentRuntime,
  }) {
    state.validate();
    presidentRuntime.validate();
    final incumbent = _stateFor(presidentRuntime, state.controlledClubId);
    if (state.lost) return state;

    final currentPresidentId = incumbent.tenure.president.id;
    if (currentPresidentId == state.playerPresidentId) return state;

    final next = PlayerPresidentTenureControlState(
      controlledClubId: state.controlledClubId,
      playerPresidentId: state.playerPresidentId,
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: presidentRuntime.completedSeasons,
      successorPresidentId: currentPresidentId,
    );
    next.validate();
    return next;
  }

  bool canControl({
    required PlayerPresidentTenureControlState state,
    required PresidentRuntimeCheckpoint presidentRuntime,
  }) {
    final refreshed = refresh(state: state, presidentRuntime: presidentRuntime);
    return refreshed.active;
  }

  PresidentRuntimeClubState _stateFor(
    PresidentRuntimeCheckpoint presidentRuntime,
    String clubId,
  ) {
    if (clubId.isEmpty) {
      throw ArgumentError('controlledClubId cannot be empty.');
    }
    for (final item in presidentRuntime.clubs) {
      if (item.clubId == clubId) return item;
    }
    throw ArgumentError('Unknown controlled club $clubId.');
  }
}

class PlayerPresidentTenureControlSaveCodec {
  const PlayerPresidentTenureControlSaveCodec();

  static const String format = 'zmila-fbs-player-president-tenure-control';
  static const int currentSaveVersion = 1;

  String encode(PlayerPresidentTenureControlState state) {
    state.validate();
    final payload = <String, Object?>{
      'controlledClubId': state.controlledClubId,
      'playerPresidentId': state.playerPresidentId,
      'status': state.status.name,
      'lostAtCompletedSeason': state.lostAtCompletedSeason,
      'successorPresidentId': state.successorPresidentId,
    };
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': SaveChecksum.forPayload(
        saveVersion: currentSaveVersion,
        payload: payload,
      ),
    });
  }

  PlayerPresidentTenureControlState decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Player-president tenure control save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Player-president tenure control save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown player-president tenure control save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported player-president tenure control save version $version.',
      );
    }
    final payloadObject = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(
          saveVersion: version,
          payload: payloadObject,
        )) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Player-president tenure control save checksum mismatch.',
      );
    }
    if (version != 1 || payloadObject is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president tenure control payload is invalid.',
      );
    }
    final payload = Map<String, Object?>.from(payloadObject);
    final clubId = payload['controlledClubId'];
    final playerPresidentId = payload['playerPresidentId'];
    final statusName = payload['status'];
    final lostAt = payload['lostAtCompletedSeason'];
    final successor = payload['successorPresidentId'];
    if (clubId is! String ||
        playerPresidentId is! String ||
        statusName is! String ||
        (lostAt != null && lostAt is! int) ||
        (successor != null && successor is! String)) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president tenure control payload fields are invalid.',
      );
    }
    final status = PlayerPresidentTenureControlStatus.values
        .where((item) => item.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Unknown player-president tenure control status.',
      );
    }
    try {
      final state = PlayerPresidentTenureControlState(
        controlledClubId: clubId,
        playerPresidentId: playerPresidentId,
        status: status,
        lostAtCompletedSeason: lostAt as int?,
        successorPresidentId: successor as String?,
      );
      state.validate();
      return state;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid player-president tenure control state: $error',
      );
    }
  }
}
