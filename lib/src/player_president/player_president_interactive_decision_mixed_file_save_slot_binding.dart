import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_mixed_file_save_slot_service.dart';

/// Transient application binding between one typed M83 mixed save-slot
/// identity and the M76/M79 application session loaded from that exact slot.
///
/// M88 does not persist binding metadata, merge namespaces, rename/copy slots,
/// or create a new game-state authority. The typed source + raw slot id stay in
/// memory only so application/UI callers can save back to or delete the exact
/// slot they opened without carrying that identity separately.
class PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding {
  PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding._({
    required this.service,
    required this.source,
    required this.slotId,
    required this.session,
  });

  /// Opens one existing typed slot identity. Missing slots return null.
  static PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding? open({
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotService service,
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) {
    final summary = service.inspect(source: source, slotId: slotId);
    if (summary == null) {
      return null;
    }
    return openSummary(service: service, summary: summary);
  }

  /// Opens the exact typed identity carried by an M83 summary. Stale summaries
  /// whose underlying slot no longer exists return null.
  static PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding?
      openSummary({
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotService service,
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  }) {
    final session = service.loadSummary(summary);
    if (session == null) {
      return null;
    }
    final routedSource = _sourceForSession(session);
    if (routedSource != summary.source) {
      throw StateError(
        'Mixed save-slot source/session origin mismatch for ${summary.identity}.',
      );
    }
    return PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding._(
      service: service,
      source: summary.source,
      slotId: summary.slotId,
      session: session,
    );
  }

  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotService service;
  final PlayerPresidentInteractiveDecisionMixedSaveSlotSource source;
  final String slotId;
  final PlayerPresidentInteractiveDecisionApplicationSession session;

  String get identity => '${source.name}:$slotId';

  /// Refreshes source metadata through M87 without caching or sidecars.
  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary? inspect() =>
      service.inspect(source: source, slotId: slotId);

  bool get exists => inspect() != null;

  /// Persists the currently bound mutable application session back to the same
  /// raw slot id. Session origin must still route to the bound namespace.
  PlayerPresidentInteractiveDecisionMixedSaveSlotSource saveBack() {
    final expectedSource = _sourceForSession(session);
    if (expectedSource != source) {
      throw StateError(
        'Bound save-slot source $source no longer matches session origin '
        '${session.origin}.',
      );
    }
    final routedSource = service.save(slotId: slotId, session: session);
    if (routedSource != source) {
      throw StateError(
        'M87 routed save-back for $identity to unexpected source $routedSource.',
      );
    }
    return routedSource;
  }

  /// Deletes only the exact typed slot identity that was opened.
  bool delete() => service.delete(source: source, slotId: slotId);

  static PlayerPresidentInteractiveDecisionMixedSaveSlotSource _sourceForSession(
    PlayerPresidentInteractiveDecisionApplicationSession session,
  ) {
    switch (session.origin) {
      case PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint:
        return PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint;
      case PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame:
        return PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap;
    }
  }
}
