import 'player_president_interactive_decision_file_save_slot_store.dart';
import 'player_president_interactive_decision_session.dart';

/// Deterministic, read-only load-game projection for one M77 save slot.
///
/// M78 does not persist a metadata sidecar. Every field is derived from the
/// exact M75 bundle restored by M77, so slot summaries cannot drift away from
/// the authoritative M65 game state and M74 transcript.
class PlayerPresidentInteractiveDecisionSaveSlotSummary {
  const PlayerPresidentInteractiveDecisionSaveSlotSummary({
    required this.slotId,
    required this.controlledClubId,
    required this.controlledClubName,
    required this.completedSeasons,
    required this.nextSeasonIndex,
    required this.answeredDecisionCount,
    required this.playerControlActive,
    required this.pendingDecisionKind,
    required this.sessionCompleted,
    required this.resumeSeasonCount,
    required this.hasFutureSeasonAfterReport,
  });

  final String slotId;
  final String controlledClubId;
  final String controlledClubName;
  final int completedSeasons;
  final int nextSeasonIndex;
  final int answeredDecisionCount;
  final bool playerControlActive;
  final PlayerPresidentInteractiveDecisionKind? pendingDecisionKind;
  final bool sessionCompleted;
  final int resumeSeasonCount;
  final bool hasFutureSeasonAfterReport;

  String get signature =>
      'slot=$slotId:club=$controlledClubId:$controlledClubName:'
      'completed=$completedSeasons:next=$nextSeasonIndex:'
      'answers=$answeredDecisionCount:control=$playerControlActive:'
      'pending=${pendingDecisionKind?.name ?? 'none'}:'
      'sessionCompleted=$sessionCompleted:resume=$resumeSeasonCount:'
      'future=$hasFutureSeasonAfterReport';
}

/// Read-only catalog facade over M77 file slots.
///
/// Inspecting a slot performs the same M75 decode + deterministic M74 replay as
/// [PlayerPresidentInteractiveDecisionFileSaveSlotStore.load]. Corrupt or
/// divergent saves therefore fail closed instead of producing stale UI
/// metadata. The catalog never writes or mutates save bytes.
class PlayerPresidentInteractiveDecisionFileSaveSlotCatalog {
  const PlayerPresidentInteractiveDecisionFileSaveSlotCatalog({
    required this.store,
  });

  final PlayerPresidentInteractiveDecisionFileSaveSlotStore store;

  PlayerPresidentInteractiveDecisionSaveSlotSummary? inspect(String slotId) {
    final session = store.load(slotId);
    if (session == null) {
      return null;
    }

    final checkpoint = session.checkpoint;
    final controlledClub = checkpoint.runtime.runtime.domain.presidentRuntime
        .runtime.runtime.world.baseClubs
        .singleWhere((club) => club.id == checkpoint.controlledClubId);

    return PlayerPresidentInteractiveDecisionSaveSlotSummary(
      slotId: slotId,
      controlledClubId: checkpoint.controlledClubId,
      controlledClubName: controlledClub.name,
      completedSeasons: checkpoint.completedSeasons,
      nextSeasonIndex: checkpoint.nextSeasonIndex,
      answeredDecisionCount: session.answeredDecisionCount,
      playerControlActive: checkpoint.playerControlActive,
      pendingDecisionKind: session.pendingDecision?.kind,
      sessionCompleted: session.completed != null,
      resumeSeasonCount: session.resumeConfig.seasonCount,
      hasFutureSeasonAfterReport:
          session.resumeConfig.hasFutureSeasonAfterReport,
    );
  }

  List<PlayerPresidentInteractiveDecisionSaveSlotSummary> list() {
    final summaries = <PlayerPresidentInteractiveDecisionSaveSlotSummary>[];
    for (final slotId in store.listSlotIds()) {
      final summary = inspect(slotId);
      if (summary == null) {
        throw StateError(
          'Save slot $slotId disappeared while the catalog was reading it.',
        );
      }
      summaries.add(summary);
    }
    return List<PlayerPresidentInteractiveDecisionSaveSlotSummary>.unmodifiable(
      summaries,
    );
  }
}
