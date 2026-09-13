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
import 'media_season_snapshot.dart';
import 'player_president_media_statement_control.dart';

class PlayerPresidentTenureGatedMediaStatementCheckpoint {
  PlayerPresidentTenureGatedMediaStatementCheckpoint({
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
        'Active media statement control must belong to the real incumbent president.',
      );
    }
  }

  String get signature =>
      'tenure=${tenureControl.signature}:domain=${domain.signature}';
}

class PlayerPresidentTenureGatedMediaStatementSaveCodec {
  const PlayerPresidentTenureGatedMediaStatementSaveCodec({
    this.domainCodec = const PresidentDomainMemorySaveCodec(),
    this.tenureCodec = const PlayerPresidentTenureControlSaveCodec(),
  });

  static const String format =
      'zmila-fbs-player-president-tenure-gated-media-statement';
  static const int currentSaveVersion = 1;

  final PresidentDomainMemorySaveCodec domainCodec;
  final PlayerPresidentTenureControlSaveCodec tenureCodec;

  String encode(
    PlayerPresidentTenureGatedMediaStatementCheckpoint checkpoint,
  ) {
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

  PlayerPresidentTenureGatedMediaStatementCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Tenure-gated media statement save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Tenure-gated media statement save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown tenure-gated media statement save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported tenure-gated media statement save version $version.',
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
        'Tenure-gated media statement save checksum mismatch.',
      );
    }
    if (version != 1 || payloadObject is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Tenure-gated media statement payload is invalid.',
      );
    }
    final payload = Map<String, Object?>.from(payloadObject);
    final domainSave = payload['domainSave'];
    final tenureControlSave = payload['tenureControlSave'];
    if (domainSave is! String || tenureControlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Tenure-gated media statement payload fields are invalid.',
      );
    }
    try {
      return PlayerPresidentTenureGatedMediaStatementCheckpoint(
        domain: domainCodec.decode(domainSave),
        tenureControl: tenureCodec.decode(tenureControlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid tenure-gated media statement payload: $error',
      );
    }
  }
}

class PlayerPresidentTenureGatedMediaStatementResult {
  PlayerPresidentTenureGatedMediaStatementResult({
    required this.checkpoint,
    required Iterable<PresidentDomainResumeResult> segments,
  }) : segments = List.unmodifiable(segments);

  final PlayerPresidentTenureGatedMediaStatementCheckpoint checkpoint;
  final List<PresidentDomainResumeResult> segments;

  List<MediaSeasonSnapshot> get mediaSnapshots => List.unmodifiable(
        segments.expand(
          (item) => item.report.sourceReport.baselineMediaReport.seasons.expand(
            (season) => season.clubs,
          ),
        ),
      );

  String get signature =>
      '${mediaSnapshots.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M62 applies M58's real-incumbent tenure ownership to M57 media-statement
/// stance choices.
///
/// M10 event generation remains canonical: the player cannot create a press
/// event or change its topic, manager target or id. While the captured player
/// president remains the real incumbent, M57 may delegate only the stance of a
/// real event. The wrapper advances one season at a time so an election loss at
/// the end of a season blocks the external provider from the successor's first
/// season onward. Reelection preserves control and a persisted lost state never
/// reactivates. The decision provider remains runtime-only and is absent from
/// the save.
class PlayerPresidentTenureGatedMediaStatementCareerEngine {
  const PlayerPresidentTenureGatedMediaStatementCareerEngine({
    this.decisionProvider,
    this.runtimeEngine = const AdvancedRuntimeCareerEngine(),
    this.compactor = const AdvancedRuntimeHistoryCompactor(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.profileGenerator = const PresidentProfileGenerator(),
  });

  final PlayerMediaStatementDecisionProvider? decisionProvider;
  final AdvancedRuntimeCareerEngine runtimeEngine;
  final AdvancedRuntimeHistoryCompactor compactor;
  final PresidentReputationCareerEngine reputationEngine;
  final PlayerPresidentTenureControlGate tenureGate;
  final PresidentProfileGenerator profileGenerator;

  PlayerPresidentTenureGatedMediaStatementResult simulateWithCheckpoint({
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

    return PlayerPresidentTenureGatedMediaStatementResult(
      checkpoint: PlayerPresidentTenureGatedMediaStatementCheckpoint(
        domain: current!,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentTenureGatedMediaStatementResult resume({
    required PlayerPresidentTenureGatedMediaStatementCheckpoint checkpoint,
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

    return PlayerPresidentTenureGatedMediaStatementResult(
      checkpoint: PlayerPresidentTenureGatedMediaStatementCheckpoint(
        domain: current,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentMediaStatementDomainCareerEngine _engineFor(
    PlayerPresidentTenureControlState tenure,
  ) =>
      PlayerPresidentMediaStatementDomainCareerEngine(
        controlledClubId: tenure.controlledClubId,
        decisionProvider: tenure.active ? decisionProvider : null,
        runtimeEngine: runtimeEngine,
        compactor: compactor,
        reputationEngine: reputationEngine,
      );
}
