import 'dart:io';

import '../league/club.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_file_save_slot_store.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_deleter.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_loader.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_writer.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';

/// Unified application-facing facade over the mixed save-slot lifecycle.
///
/// M87 composes the existing M83 catalog, M84 loader, M85 writer, and M86
/// deleter around the existing M77 checkpoint and M81 bootstrap stores. It
/// does not cache metadata, merge namespaces, migrate slots, replace bootstrap
/// saves with checkpoints, or create another persisted-state authority. M65
/// remains the only persisted game-state authority.
class PlayerPresidentInteractiveDecisionMixedFileSaveSlotService {
  factory PlayerPresidentInteractiveDecisionMixedFileSaveSlotService({
    required Directory rootDirectory,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  }) {
    final checkpointStore =
        PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: rootDirectory,
    );
    final bootstrapStore =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: rootDirectory,
    );
    return PlayerPresidentInteractiveDecisionMixedFileSaveSlotService.withStores(
      checkpointStore: checkpointStore,
      bootstrapStore: bootstrapStore,
      clubs: clubs,
      leagues: leagues,
    );
  }

  factory PlayerPresidentInteractiveDecisionMixedFileSaveSlotService.withStores({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpointStore,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstrapStore,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  }) {
    final catalog = PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog(
      checkpointCatalog: PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
        store: checkpointStore,
      ),
      bootstrapCatalog:
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
        store: bootstrapStore,
        clubs: clubs,
        leagues: leagues,
      ),
    );
    return PlayerPresidentInteractiveDecisionMixedFileSaveSlotService._(
      catalog: catalog,
      loader: PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader(
        checkpointStore: checkpointStore,
        bootstrapStore: bootstrapStore,
        clubs: clubs,
        leagues: leagues,
      ),
      writer: PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter(
        checkpointStore: checkpointStore,
        bootstrapStore: bootstrapStore,
      ),
      deleter: PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter(
        checkpointStore: checkpointStore,
        bootstrapStore: bootstrapStore,
      ),
    );
  }

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotService._({
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog catalog,
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader loader,
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter writer,
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter deleter,
  })  : _catalog = catalog,
        _loader = loader,
        _writer = writer,
        _deleter = deleter;

  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog _catalog;
  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader _loader;
  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter _writer;
  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter _deleter;

  List<PlayerPresidentInteractiveDecisionMixedSaveSlotSummary> list() =>
      _catalog.list();

  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary? inspect({
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) =>
      _catalog.inspect(source: source, slotId: slotId);

  PlayerPresidentInteractiveDecisionApplicationSession? load({
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) =>
      _loader.load(source: source, slotId: slotId);

  PlayerPresidentInteractiveDecisionApplicationSession? loadSummary(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) =>
      _loader.loadSummary(summary);

  PlayerPresidentInteractiveDecisionMixedSaveSlotSource save({
    required String slotId,
    required PlayerPresidentInteractiveDecisionApplicationSession session,
  }) =>
      _writer.save(slotId: slotId, session: session);

  bool delete({
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) =>
      _deleter.delete(source: source, slotId: slotId);

  bool deleteSummary(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) =>
      _deleter.deleteSummary(summary);
}
