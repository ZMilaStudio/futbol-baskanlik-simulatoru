import '../core/simulation_config.dart';
import '../crisis/crisis_decision_core.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
import 'player_president_interactive_decision_persistence_bundle.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_interactive_decision_transcript_snapshot.dart';

enum PlayerPresidentInteractiveDecisionApplicationSessionOrigin {
  newGame,
  checkpoint,
}

/// Application-facing lifecycle owner for one interactive player-president
/// session.
///
/// M76 introduced the checkpoint-backed lifecycle. M79 added deterministic
/// new-game start ownership. M80 adds replay-only pre-checkpoint bootstrap
/// persistence without persisting partial game state: M65 remains the only
/// game-state authority, M74 remains accepted-answer replay metadata, and M75
/// remains the checkpoint-backed atomic persistence bundle.
class PlayerPresidentInteractiveDecisionApplicationSession {
  PlayerPresidentInteractiveDecisionApplicationSession._({
    required this.origin,
    required PlayerPresidentTicketPricingRuntimeCheckpoint? checkpoint,
    required this.resumeConfig,
    required this.newGameElectionInterval,
    required SimulationConfig? newGameConfig,
    required String? newGameControlledClubId,
    required String? newGameWorldFingerprint,
    required PlayerPresidentInteractiveDecisionTranscriptSession session,
    required this.bundleCodec,
    required this.bootstrapCodec,
  })  : _checkpoint = checkpoint,
        _newGameConfig = newGameConfig,
        _newGameControlledClubId = newGameControlledClubId,
        _newGameWorldFingerprint = newGameWorldFingerprint,
        _session = session;

  factory PlayerPresidentInteractiveDecisionApplicationSession.start({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
    int crisisActivationThreshold = 55,
    int candidateLimit = 5,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    final resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      crisisActivationThreshold: crisisActivationThreshold,
      candidateLimit: candidateLimit,
    );
    resumeConfig.validate();
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }

    final base = PlayerPresidentInteractiveDecisionSession.start(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold: crisisActivationThreshold,
      ),
      candidateLimit: candidateLimit,
    );
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
      checkpoint: null,
      resumeConfig: resumeConfig,
      newGameElectionInterval: electionInterval,
      newGameConfig: config,
      newGameControlledClubId: controlledClubId,
      newGameWorldFingerprint:
          PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot
              .worldFingerprintFor(clubs: clubs, leagues: leagues),
      session: PlayerPresidentInteractiveDecisionTranscriptSession(base),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession
      .restoreNewGameBootstrap({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot
        snapshot,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    snapshot.validateWorld(clubs: clubs, leagues: leagues);

    final base = PlayerPresidentInteractiveDecisionSession.start(
      clubs: clubs,
      leagues: leagues,
      config: snapshot.config,
      controlledClubId: snapshot.controlledClubId,
      seasonCount: snapshot.resumeConfig.seasonCount,
      electionInterval: snapshot.electionInterval,
      hasFutureSeasonAfterReport:
          snapshot.resumeConfig.hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold:
            snapshot.resumeConfig.crisisActivationThreshold,
      ),
      candidateLimit: snapshot.resumeConfig.candidateLimit,
    );

    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
      checkpoint: null,
      resumeConfig: snapshot.resumeConfig,
      newGameElectionInterval: snapshot.electionInterval,
      newGameConfig: snapshot.config,
      newGameControlledClubId: snapshot.controlledClubId,
      newGameWorldFingerprint: snapshot.worldFingerprint,
      session: PlayerPresidentInteractiveDecisionTranscriptSession.restore(
        session: base,
        snapshot: snapshot.transcript,
      ),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession
      .restoreEncodedNewGameBootstrap({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required String encodedBootstrap,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) =>
          PlayerPresidentInteractiveDecisionApplicationSession
              .restoreNewGameBootstrap(
            clubs: clubs,
            leagues: leagues,
            snapshot: bootstrapCodec.decode(encodedBootstrap),
            bundleCodec: bundleCodec,
            bootstrapCodec: bootstrapCodec,
          );

  factory PlayerPresidentInteractiveDecisionApplicationSession.resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required PlayerPresidentInteractiveDecisionResumeConfig resumeConfig,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    checkpoint.validate();
    resumeConfig.validate();
    final base = PlayerPresidentInteractiveDecisionSession.resume(
      checkpoint: checkpoint,
      seasonCount: resumeConfig.seasonCount,
      hasFutureSeasonAfterReport: resumeConfig.hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold: resumeConfig.crisisActivationThreshold,
      ),
      candidateLimit: resumeConfig.candidateLimit,
    );
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
      newGameElectionInterval: null,
      newGameConfig: null,
      newGameControlledClubId: null,
      newGameWorldFingerprint: null,
      session: PlayerPresidentInteractiveDecisionTranscriptSession(base),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.restore({
    required PlayerPresidentInteractiveDecisionPersistenceBundle bundle,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    bundle.validate();
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
      checkpoint: bundle.checkpoint,
      resumeConfig: bundle.resumeConfig,
      newGameElectionInterval: null,
      newGameConfig: null,
      newGameControlledClubId: null,
      newGameWorldFingerprint: null,
      session: bundle.restoreSession(),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded({
    required String encodedBundle,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    final bundle = bundleCodec.decode(encodedBundle);
    return PlayerPresidentInteractiveDecisionApplicationSession.restore(
      bundle: bundle,
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  final PlayerPresidentInteractiveDecisionApplicationSessionOrigin origin;
  final PlayerPresidentTicketPricingRuntimeCheckpoint? _checkpoint;
  final PlayerPresidentInteractiveDecisionResumeConfig resumeConfig;
  final int? newGameElectionInterval;
  final SimulationConfig? _newGameConfig;
  final String? _newGameControlledClubId;
  final String? _newGameWorldFingerprint;
  final PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
      bundleCodec;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
      bootstrapCodec;
  final PlayerPresidentInteractiveDecisionTranscriptSession _session;

  bool get isNewGame =>
      origin == PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame;

  bool get canPersist => _checkpoint != null;

  bool get canPersistBootstrap =>
      isNewGame &&
      _newGameConfig != null &&
      _newGameControlledClubId != null &&
      _newGameWorldFingerprint != null;

  PlayerPresidentTicketPricingRuntimeCheckpoint? get checkpointOrNull =>
      _checkpoint;

  PlayerPresidentTicketPricingRuntimeCheckpoint get checkpoint {
    final checkpoint = _checkpoint;
    if (checkpoint == null) {
      throw StateError(
        'New-game application sessions do not have an M65 checkpoint and '
        'cannot be persisted by M75 before checkpoint handoff.',
      );
    }
    return checkpoint;
  }

  int get answeredDecisionCount => _session.answeredDecisionCount;
  PlayerPresidentInteractiveDecisionRequest? get pendingDecision =>
      _session.pendingDecision;
  PlayerPresidentInteractiveSessionCompleted? get completed =>
      _session.completed;

  PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot
      get newGameBootstrapSnapshot {
    final config = _newGameConfig;
    final controlledClubId = _newGameControlledClubId;
    final worldFingerprint = _newGameWorldFingerprint;
    final electionInterval = newGameElectionInterval;
    if (!isNewGame ||
        config == null ||
        controlledClubId == null ||
        worldFingerprint == null ||
        electionInterval == null) {
      throw StateError(
        'Checkpoint-backed application sessions do not have an M80 '
        'new-game bootstrap snapshot.',
      );
    }
    return PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot(
      worldFingerprint: worldFingerprint,
      config: config,
      controlledClubId: controlledClubId,
      electionInterval: electionInterval,
      resumeConfig: resumeConfig,
      transcript: _session.snapshot,
    );
  }

  String encodeNewGameBootstrapSnapshot() =>
      bootstrapCodec.encode(newGameBootstrapSnapshot);

  PlayerPresidentInteractiveDecisionPersistenceBundle get persistenceBundle {
    final checkpoint = _checkpoint;
    if (checkpoint == null) {
      throw StateError(
        'Pre-checkpoint new-game sessions cannot be encoded as an M75 bundle.',
      );
    }
    return PlayerPresidentInteractiveDecisionPersistenceBundle(
      checkpoint: checkpoint,
      transcript: _session.snapshot,
      resumeConfig: resumeConfig,
    );
  }

  String encodePersistenceBundle() => bundleCodec.encode(persistenceBundle);

  PlayerPresidentInteractiveSessionStep advance() => _session.advance();

  PlayerPresidentInteractiveSessionStep submit({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      _session.submit(request: request, choice: choice);
}
