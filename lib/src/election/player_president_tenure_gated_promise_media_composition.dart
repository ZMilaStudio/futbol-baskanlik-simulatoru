import 'dart:convert';

import '../core/simulation_config.dart';
import '../league/club.dart';
import '../media/media_career_engine.dart';
import '../media/media_season_snapshot.dart';
import '../media/player_president_media_statement_control.dart';
import '../promise/player_president_promise_control.dart';
import '../promise/promise_career_engine.dart';
import '../promise/promise_media_career_engine.dart';
import '../promise/promise_season_snapshot.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_domain_memory_save_codec.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../world/world_league.dart';
import 'player_president_tenure_control_gate.dart';
import 'president_reputation_career_engine.dart';
import 'president_tenure.dart';

/// Composes M56 promise choice and M57 media-stance choice over the same
/// president-domain source report.
///
/// Both providers are runtime-only. Promise targets and media event metadata
/// remain canonical because the existing M56/M57 adapters are reused directly.
class PlayerPresidentPromiseMediaDomainCareerEngine {
  PlayerPresidentPromiseMediaDomainCareerEngine({
    required String controlledClubId,
    PlayerPromiseDecisionProvider? promiseProvider,
    PlayerMediaStatementDecisionProvider? mediaProvider,
    AdvancedRuntimeCareerEngine runtimeEngine =
        const AdvancedRuntimeCareerEngine(),
    AdvancedRuntimeHistoryCompactor compactor =
        const AdvancedRuntimeHistoryCompactor(),
    PresidentReputationCareerEngine reputationEngine =
        const PresidentReputationCareerEngine(),
  }) : _delegate = _buildDelegate(
          controlledClubId: controlledClubId,
          promiseProvider: promiseProvider,
          mediaProvider: mediaProvider,
          runtimeEngine: runtimeEngine,
          compactor: compactor,
          reputationEngine: reputationEngine,
        );

  final PresidentDomainCareerEngine _delegate;

  PresidentDomainResumeResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) =>
      _delegate.simulateWithCheckpoint(
        clubs: clubs,
        leagues: leagues,
        config: config,
        seasonCount: seasonCount,
        electionInterval: electionInterval,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );

  PresidentDomainResumeResult resume({
    required PresidentDomainMemoryCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) =>
      _delegate.resume(
        checkpoint: checkpoint,
        seasonCount: seasonCount,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );

  static PresidentDomainCareerEngine _buildDelegate({
    required String controlledClubId,
    required PlayerPromiseDecisionProvider? promiseProvider,
    required PlayerMediaStatementDecisionProvider? mediaProvider,
    required AdvancedRuntimeCareerEngine runtimeEngine,
    required AdvancedRuntimeHistoryCompactor compactor,
    required PresidentReputationCareerEngine reputationEngine,
  }) {
    final sourceEngine = PromiseMediaCareerEngine(
      promiseEngine: PromiseCareerEngine(
        generator: PlayerPresidentPromiseGenerator(
          controlledClubId: controlledClubId,
          decisionProvider: promiseProvider,
        ),
      ),
      mediaEngine: MediaCareerEngine(
        statementEngine: PlayerPresidentMediaStatementEngine(
          controlledClubId: controlledClubId,
          decisionProvider: mediaProvider,
        ),
      ),
    );
    return PresidentDomainCareerEngine(
      runtimeEngine: runtimeEngine,
      compactor: compactor,
      sourceEngine: sourceEngine,
      reputationEngine: reputationEngine,
      resumeEngine: PresidentDomainResumeEngine(
        runtimeEngine: runtimeEngine,
        compactor: compactor,
        sourceEngine: sourceEngine,
        reputationEngine: reputationEngine,
      ),
    );
  }
}

class PlayerPresidentTenureGatedPromiseMediaCheckpoint {
  PlayerPresidentTenureGatedPromiseMediaCheckpoint({
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
        'Active promise/media control must belong to the real incumbent president.',
      );
    }
  }

  String get signature =>
      'tenure=${tenureControl.signature}:domain=${domain.signature}';
}

class PlayerPresidentTenureGatedPromiseMediaSaveCodec {
  const PlayerPresidentTenureGatedPromiseMediaSaveCodec({
    this.domainCodec = const PresidentDomainMemorySaveCodec(),
    this.tenureCodec = const PlayerPresidentTenureControlSaveCodec(),
  });

  static const String format =
      'zmila-fbs-player-president-tenure-gated-promise-media';
  static const int currentSaveVersion = 1;

  final PresidentDomainMemorySaveCodec domainCodec;
  final PlayerPresidentTenureControlSaveCodec tenureCodec;

  String encode(PlayerPresidentTenureGatedPromiseMediaCheckpoint checkpoint) {
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

  PlayerPresidentTenureGatedPromiseMediaCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Tenure-gated promise/media save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Tenure-gated promise/media save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown tenure-gated promise/media save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported tenure-gated promise/media save version $version.',
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
        'Tenure-gated promise/media save checksum mismatch.',
      );
    }
    if (version != 1 || payloadObject is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Tenure-gated promise/media payload is invalid.',
      );
    }
    final payload = Map<String, Object?>.from(payloadObject);
    final domainSave = payload['domainSave'];
    final tenureControlSave = payload['tenureControlSave'];
    if (domainSave is! String || tenureControlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Tenure-gated promise/media payload fields are invalid.',
      );
    }
    try {
      return PlayerPresidentTenureGatedPromiseMediaCheckpoint(
        domain: domainCodec.decode(domainSave),
        tenureControl: tenureCodec.decode(tenureControlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid tenure-gated promise/media payload: $error',
      );
    }
  }
}

class PlayerPresidentTenureGatedPromiseMediaResult {
  PlayerPresidentTenureGatedPromiseMediaResult({
    required this.checkpoint,
    required Iterable<PresidentDomainResumeResult> segments,
  }) : segments = List.unmodifiable(segments);

  final PlayerPresidentTenureGatedPromiseMediaCheckpoint checkpoint;
  final List<PresidentDomainResumeResult> segments;

  List<PromiseSeasonSnapshot> get promiseSnapshots => List.unmodifiable(
        segments.expand(
          (item) => item.report.sourceReport.promiseReport.snapshots,
        ),
      );

  List<MediaSeasonSnapshot> get mediaSnapshots => List.unmodifiable(
        segments.expand(
          (item) => item.report.sourceReport.baselineMediaReport.seasons.expand(
            (season) => season.clubs,
          ),
        ),
      );

  String get signature =>
      'promise=${promiseSnapshots.map((item) => item.signature).join('||')}:'
      'media=${mediaSnapshots.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M63 composes the M61 promise and M62 media controls on one authoritative
/// president-domain checkpoint and one persisted tenure-ownership state.
///
/// The wrapper advances one season at a time. A real election loss disables
/// both external providers from the successor's first season; reelection keeps
/// both active. Persisted loss is sticky, and callbacks remain runtime-only.
class PlayerPresidentTenureGatedPromiseMediaCareerEngine {
  const PlayerPresidentTenureGatedPromiseMediaCareerEngine({
    this.promiseProvider,
    this.mediaProvider,
    this.runtimeEngine = const AdvancedRuntimeCareerEngine(),
    this.compactor = const AdvancedRuntimeHistoryCompactor(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.profileGenerator = const PresidentProfileGenerator(),
  });

  final PlayerPromiseDecisionProvider? promiseProvider;
  final PlayerMediaStatementDecisionProvider? mediaProvider;
  final AdvancedRuntimeCareerEngine runtimeEngine;
  final AdvancedRuntimeHistoryCompactor compactor;
  final PresidentReputationCareerEngine reputationEngine;
  final PlayerPresidentTenureControlGate tenureGate;
  final PresidentProfileGenerator profileGenerator;

  PlayerPresidentTenureGatedPromiseMediaResult simulateWithCheckpoint({
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

    return PlayerPresidentTenureGatedPromiseMediaResult(
      checkpoint: PlayerPresidentTenureGatedPromiseMediaCheckpoint(
        domain: current!,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentTenureGatedPromiseMediaResult resume({
    required PlayerPresidentTenureGatedPromiseMediaCheckpoint checkpoint,
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

    return PlayerPresidentTenureGatedPromiseMediaResult(
      checkpoint: PlayerPresidentTenureGatedPromiseMediaCheckpoint(
        domain: current,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentPromiseMediaDomainCareerEngine _engineFor(
    PlayerPresidentTenureControlState tenure,
  ) =>
      PlayerPresidentPromiseMediaDomainCareerEngine(
        controlledClubId: tenure.controlledClubId,
        promiseProvider: tenure.active ? promiseProvider : null,
        mediaProvider: tenure.active ? mediaProvider : null,
        runtimeEngine: runtimeEngine,
        compactor: compactor,
        reputationEngine: reputationEngine,
      );
}
