import '../league/club.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_file_save_slot_store.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';

/// Source-aware load dispatcher for the mixed M83 save-slot projection.
///
/// M84 creates no save format, migration, metadata cache, or persisted state
/// authority. Checkpoint loads are delegated unchanged to M77 and bootstrap
/// loads are delegated unchanged to M81, including M81 world validation.
/// Existing interrupted-commit recovery performed by those child stores also
/// remains their responsibility. M65 stays the only persisted game-state
/// authority.
class PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader {
  PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader({
    required this.checkpointStore,
    required this.bootstrapStore,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  })  : clubs = List<Club>.unmodifiable(clubs),
        leagues = List<WorldLeague>.unmodifiable(leagues);

  final PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpointStore;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      bootstrapStore;
  final List<Club> clubs;
  final List<WorldLeague> leagues;

  PlayerPresidentInteractiveDecisionApplicationSession? load({
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) {
    switch (source) {
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint:
        return checkpointStore.load(slotId);
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap:
        return bootstrapStore.load(
          slotId: slotId,
          clubs: clubs,
          leagues: leagues,
        );
    }
  }

  PlayerPresidentInteractiveDecisionApplicationSession? loadSummary(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) =>
      load(source: summary.source, slotId: summary.slotId);
}
