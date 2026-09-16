import 'player_president_interactive_decision_file_save_slot_store.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';

/// Source-aware delete dispatcher for the two physical save namespaces.
///
/// M86 creates no save format, migration, replacement policy, metadata cache,
/// or persisted state authority. Delete requests are delegated unchanged to
/// the existing M77 checkpoint or M81 bootstrap store selected by the M83
/// source identity. Same-id entries in the sibling namespace are never
/// removed implicitly, and M65 remains the only persisted game-state
/// authority.
class PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter {
  const PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter({
    required this.checkpointStore,
    required this.bootstrapStore,
  });

  final PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpointStore;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      bootstrapStore;

  bool delete({
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) {
    switch (source) {
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint:
        return checkpointStore.delete(slotId);
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap:
        return bootstrapStore.delete(slotId);
    }
  }

  bool deleteSummary(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) =>
      delete(source: summary.source, slotId: summary.slotId);
}
