import 'dart:convert';

import '../core/simulation_config.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_reputation_career_engine.dart';
import '../election/president_tenure.dart';
import '../league/club.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_domain_memory_save_codec.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../world/world_league.dart';
import 'player_president_promise_control.dart';
import 'promise_season_snapshot.dart';

class PlayerPresidentTenureGatedPromiseCheckpoint {
  PlayerPresidentTenureGatedPromiseCheckpoint({
    required this.domain,
    required this.tenureControl,
  }) {
    validate();
  }

  final PresidentDomainMemoryCheckpoint domain;
  final PlayerPresidentTenureControlState tenureControl;

  int get nextSeasonIndex => domain.presidentRuntime.nextSeasonIndex;
  int get completedSeasons => domain.presidentRuntime.completedSeasons;
  String get controlledClubId => tenureControl.controlledClubId;
  bool get playerControlActive => tenureControl.active;

  void validate() {
    domain.validate();
    tenureControl.validate();
    final matches = domain.presidentRuntime.clubs.where(
      (item) => item.clubId == tenureControl.controlledClubId,
    );
    if (matches.length != 1) {
      throw ArgumentError(
        'Tenure-controlled club must exist exactly once in president runtime.',
      );
    }
    if (tenureControl.active &&
        matches.single.tenure.president.id != tenureControl.playerPresidentId) {
      throw ArgumentError(
        'Active promise control must belong to the real incumbent president.',
      );
    }
  }

  String get signature =>
      'tenure=${tenureControl.signature}:domain=${domain.signature}';
}

class PlayerPresidentTenureGatedPromiseSaveCodec {
  const PlayerPresidentTenureGatedPromiseSaveCodec({
    this.domainCodec = const PresidentDomainMemorySaveCodec(),
    this.tenureCodec = const PlayerPresidentTenureControlSaveCodec(),
  });

  static const String format =
      'zmila-fbs-player-president-tenure-gated-promise';
  static const int currentSaveVersion = 1;

  final PresidentDomainMemorySaveCodec domainCodec;
  final PlayerPresidentTenureControlSaveCodec tenureCodec;

  String encode(PlayerPresidentTenureGatedPromiseCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'domainSave': domainCodec.encode(checkpoint.domain),
      'tenureControlSave': tenureCodec.encode(checkpoint.tenureControl),
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

  PlayerPresidentTenureGatedPromiseCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Tenure-gated promise save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Tenure-gated promise save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown tenure-gated promise save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported tenure-gated promise save version $version.',
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
        'Tenure-gated promise save checksum mismatch.',
      );
    }
    if (version != 1 || payloadObject is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Tenure-gated promise payload is invalid.',
      );
    }
    final payload = Map<String, Object?>.from(payloadObject);
    final domainSave = payload['domainSave'];
    final tenureControlSave = payload['tenureControlSave'];
    if (domainSave is! String || tenureControlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Tenure-gated promise payload fields are invalid.',
      );
    }
    try {
      return PlayerPresidentTenureGatedPromiseCheckpoint(
        domain: domainCodec.decode(domainSave),
        tenureControl: tenureCodec.decode(tenureControlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid tenure-gated promise payload: $error',
      );
    }
  }
}

class PlayerPresidentTenureGatedPromiseResult {
  PlayerPresidentTenureGatedPromiseResult({
    required this.checkpoint,
    required Iterable<PresidentDomainResumeResult> segments,
  }) : segments = List.unmodifiable(segments);

  final PlayerPresidentTenureGatedPromiseCheckpoint checkpoint;
  final List<PresidentDomainResumeResult> segments;

  List<PromiseSeasonSnapshot> get promiseSnapshots => List.unmodifiable(
        segments.expand(
          (item) => item.report.sourceReport.promiseReport.snapshots,
        ),
      );

  String get signature =>
      '${promiseSnapshots.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M61 applies M58's real-incumbent tenure ownership to M56 promise choices.
///
/// Promise generation remains canonical: the player may only choose an M11
/// context-valid promise type and M56 still derives every target. The wrapper
/// advances one season at a time so an election loss at the end of a season
/// blocks the external provider from the successor's first preseason onward.
/// Reelection preserves control and a persisted lost state never reactivates.
/// The decision provider remains runtime-only and is absent from the save.
class PlayerPresidentTenureGatedPromiseCareerEngine {
  const PlayerPresidentTenureGatedPromiseCareerEngine({
    this.decisionProvider,
    this.runtimeEngine = const AdvancedRuntimeCareerEngine(),
    this.compactor = const AdvancedRuntimeHistoryCompactor(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.profileGenerator = const PresidentProfileGenerator(),
  });

  final PlayerPromiseDecisionProvider? decisionProvider;
  final AdvancedRuntimeCareerEngine runtimeEngine;
  final AdvancedRuntimeHistoryCompactor compactor;
  final PresidentReputationCareerEngine reputationEngine;
  final PlayerPresidentTenureControlGate tenureGate;
  final PresidentProfileGenerator profileGenerator;

  PlayerPresidentTenureGatedPromiseResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }

    final initialPresident = profileGenerator.generateInitial(
      clubId: controlledClubId,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    var tenure = PlayerPresidentTenureControlState(
      controlledClubId: controlledClubId,
      playerPresidentId: initialPresident.id,
      status: PlayerPresidentTenureControlStatus.active,
    );
    PresidentDomainMemoryCheckpoint? current;
    final segments = <PresidentDomainResumeResult>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final engine = _engineFor(tenure);
      final PresidentDomainResumeResult segment;
      if (current == null) {
        segment = engine.simulateWithCheckpoint(
          clubs: clubs,
          leagues: leagues,
          config: config,
          seasonCount: 1,
          electionInterval: electionInterval,
          hasFutureSeasonAfterReport: hasFuture,
        );
      } else {
        segment = engine.resume(
          checkpoint: current,
          seasonCount: 1,
          hasFutureSeasonAfterReport: hasFuture,
        );
      }
      segments.add(segment);
      current = segment.checkpoint;
      tenure = tenureGate.refresh(
        state: tenure,
        presidentRuntime: current.presidentRuntime,
      );
    }

    return PlayerPresidentTenureGatedPromiseResult(
      checkpoint: PlayerPresidentTenureGatedPromiseCheckpoint(
        domain: current!,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentTenureGatedPromiseResult resume({
    required PlayerPresidentTenureGatedPromiseCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint.domain;
    var tenure = checkpoint.tenureControl;
    final segments = <PresidentDomainResumeResult>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final segment = _engineFor(tenure).resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      segments.add(segment);
      current = segment.checkpoint;
      tenure = tenureGate.refresh(
        state: tenure,
        presidentRuntime: current.presidentRuntime,
      );
    }

    return PlayerPresidentTenureGatedPromiseResult(
      checkpoint: PlayerPresidentTenureGatedPromiseCheckpoint(
        domain: current,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentPromiseDomainCareerEngine _engineFor(
    PlayerPresidentTenureControlState tenure,
  ) =>
      PlayerPresidentPromiseDomainCareerEngine(
        controlledClubId: tenure.controlledClubId,
        decisionProvider: tenure.active ? decisionProvider : null,
        runtimeEngine: runtimeEngine,
        compactor: compactor,
        reputationEngine: reputationEngine,
      );
}
