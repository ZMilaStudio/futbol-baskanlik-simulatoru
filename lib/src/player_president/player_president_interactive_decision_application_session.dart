import '../core/simulation_config.dart';
import '../crisis/crisis_decision_core.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../world/world_league.dart';
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
/// M76 introduced the checkpoint-backed lifecycle. M79 also lets the
/// application own M73's deterministic new-game start path without reaching
/// into M73 directly. This still does not create a new persistence authority:
/// pre-checkpoint new-game sessions are intentionally non-persistable until a
/// later milestone defines a deterministic bootstrap save representation.
/// M65 remains the only persisted game-state authority, accepted answers remain
/// M74 replay metadata, and checkpoint-backed persistence remains the M75
/// atomic bundle.
class PlayerPresidentInteractiveDecisionApplicationSession {
  PlayerPresidentInteractiveDecisionApplicationSession._({
    required this.origin,
    required PlayerPresidentTicketPricingRuntimeCheckpoint? checkpoint,
    required this.resumeConfig,
    required this.newGameElectionInterval,
    required PlayerPresidentInteractiveDecisionTranscriptSession session,
    required this.bundleCodec,
  })  : _checkpoint = checkpoint,
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
      session: PlayerPresidentInteractiveDecisionTranscriptSession(base),
      bundleCodec: bundleCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required PlayerPresidentInteractiveDecisionResumeConfig resumeConfig,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
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
      session: PlayerPresidentInteractiveDecisionTranscriptSession(base),
      bundleCodec: bundleCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.restore({
    required PlayerPresidentInteractiveDecisionPersistenceBundle bundle,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
  }) {
    bundle.validate();
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
      checkpoint: bundle.checkpoint,
      resumeConfig: bundle.resumeConfig,
      newGameElectionInterval: null,
      session: bundle.restoreSession(),
      bundleCodec: bundleCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded({
    required String encodedBundle,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
  }) {
    final bundle = bundleCodec.decode(encodedBundle);
    return PlayerPresidentInteractiveDecisionApplicationSession.restore(
      bundle: bundle,
      bundleCodec: bundleCodec,
    );
  }

  final PlayerPresidentInteractiveDecisionApplicationSessionOrigin origin;
  final PlayerPresidentTicketPricingRuntimeCheckpoint? _checkpoint;
  final PlayerPresidentInteractiveDecisionResumeConfig resumeConfig;
  final int? newGameElectionInterval;
  final PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
      bundleCodec;
  final PlayerPresidentInteractiveDecisionTranscriptSession _session;

  bool get isNewGame =>
      origin == PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame;

  bool get canPersist => _checkpoint != null;

  PlayerPresidentTicketPricingRuntimeCheckpoint? get checkpointOrNull =>
      _checkpoint;

  PlayerPresidentTicketPricingRuntimeCheckpoint get checkpoint {
    final checkpoint = _checkpoint;
    if (checkpoint == null) {
      throw StateError(
        'New-game application sessions do not have an M65 checkpoint and '
        'cannot be persisted by M75 before a bootstrap-save milestone.',
      );
    }
    return checkpoint;
  }

  int get answeredDecisionCount => _session.answeredDecisionCount;
  PlayerPresidentInteractiveDecisionRequest? get pendingDecision =>
      _session.pendingDecision;
  PlayerPresidentInteractiveSessionCompleted? get completed =>
      _session.completed;

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
