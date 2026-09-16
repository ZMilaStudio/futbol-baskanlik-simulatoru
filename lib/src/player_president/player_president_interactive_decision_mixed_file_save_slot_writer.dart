import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_file_save_slot_store.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';

/// Application-facing save dispatcher for the two physical save namespaces.
///
/// M85 creates no save format, migration, metadata cache, or persisted state
/// authority. Checkpoint-backed sessions are delegated unchanged to M77 and
/// pre-checkpoint new-game sessions are delegated unchanged to M81. The two
/// namespaces remain separate even when they use the same raw slot id, and
/// M65 remains the only persisted game-state authority.
class PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter {
  const PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter({
    required this.checkpointStore,
    required this.bootstrapStore,
  });

  final PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpointStore;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      bootstrapStore;

  PlayerPresidentInteractiveDecisionMixedSaveSlotSource save({
    required String slotId,
    required PlayerPresidentInteractiveDecisionApplicationSession session,
  }) {
    switch (session.origin) {
      case PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint:
        checkpointStore.save(slotId, session);
        return PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint;
      case PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame:
        bootstrapStore.save(slotId, session);
        return PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap;
    }
  }
}
