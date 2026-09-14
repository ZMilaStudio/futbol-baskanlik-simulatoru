import '../crisis/crisis_decision_core.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'player_president_interactive_decision_persistence_bundle.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_interactive_decision_transcript_snapshot.dart';

/// Application-facing lifecycle owner for one checkpoint-backed interactive
/// player-president session.
///
/// M76 deliberately does not create a new game-state authority. The immutable
/// starting game state remains the M65 checkpoint, accepted answers remain M74
/// replay metadata, and persistence remains the M75 atomic bundle. This class
/// only keeps those pieces paired while an application drives advance/submit
/// and save/restore operations.
class PlayerPresidentInteractiveDecisionApplicationSession {
  PlayerPresidentInteractiveDecisionApplicationSession._({
    required this.checkpoint,
    required this.resumeConfig,
    required PlayerPresidentInteractiveDecisionTranscriptSession session,
    required this.bundleCodec,
  }) : _session = session;

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
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
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
      checkpoint: bundle.checkpoint,
      resumeConfig: bundle.resumeConfig,
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

  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  final PlayerPresidentInteractiveDecisionResumeConfig resumeConfig;
  final PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
      bundleCodec;
  final PlayerPresidentInteractiveDecisionTranscriptSession _session;

  int get answeredDecisionCount => _session.answeredDecisionCount;
  PlayerPresidentInteractiveDecisionRequest? get pendingDecision =>
      _session.pendingDecision;
  PlayerPresidentInteractiveSessionCompleted? get completed =>
      _session.completed;

  PlayerPresidentInteractiveDecisionPersistenceBundle get persistenceBundle =>
      PlayerPresidentInteractiveDecisionPersistenceBundle(
        checkpoint: checkpoint,
        transcript: _session.snapshot,
        resumeConfig: resumeConfig,
      );

  String encodePersistenceBundle() => bundleCodec.encode(persistenceBundle);

  PlayerPresidentInteractiveSessionStep advance() => _session.advance();

  PlayerPresidentInteractiveSessionStep submit({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      _session.submit(request: request, choice: choice);
}
