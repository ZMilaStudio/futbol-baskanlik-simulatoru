import '../league/club.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'player_president_interactive_decision_session.dart';

/// Deterministic, read-only load-game projection for one M81 bootstrap slot.
///
/// M82 derives every field from the exact M80 bootstrap restored by M81. No
/// metadata sidecar is persisted, so summaries cannot drift away from the
/// replay-only bootstrap or its M74 transcript.
class PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary {
  const PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary({
    required this.slotId,
    required this.controlledClubId,
    required this.controlledClubName,
    required this.initialSeasonIndex,
    required this.careerSeed,
    required this.simulationVersion,
    required this.answeredDecisionCount,
    required this.pendingDecisionKind,
    required this.sessionCompleted,
    required this.resumeSeasonCount,
    required this.hasFutureSeasonAfterReport,
    required this.electionInterval,
  });

  final String slotId;
  final String controlledClubId;
  final String controlledClubName;
  final int initialSeasonIndex;
  final int careerSeed;
  final int simulationVersion;
  final int answeredDecisionCount;
  final PlayerPresidentInteractiveDecisionKind? pendingDecisionKind;
  final bool sessionCompleted;
  final int resumeSeasonCount;
  final bool hasFutureSeasonAfterReport;
  final int electionInterval;

  String get signature =>
      'slot=$slotId:club=$controlledClubId:$controlledClubName:'
      'initialSeason=$initialSeasonIndex:seed=$careerSeed:'
      'version=$simulationVersion:answers=$answeredDecisionCount:'
      'pending=${pendingDecisionKind?.name ?? 'none'}:'
      'sessionCompleted=$sessionCompleted:resume=$resumeSeasonCount:'
      'future=$hasFutureSeasonAfterReport:election=$electionInterval';
}

/// Read-only catalog facade over M81 pre-checkpoint bootstrap file slots.
///
/// Inspecting a slot uses the same M80 checksum/format validation, supplied
/// world fingerprint guard, and deterministic M74 replay as M81 load. Corrupt
/// or divergent slots therefore fail closed instead of exposing stale UI
/// metadata. The catalog never creates a metadata sidecar or another state
/// authority; M65 remains the persisted game-state authority.
class PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog {
  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog({
    required this.store,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  })  : clubs = List<Club>.unmodifiable(clubs),
        leagues = List<WorldLeague>.unmodifiable(leagues);

  final PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      store;
  final List<Club> clubs;
  final List<WorldLeague> leagues;

  PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary? inspect(
    String slotId,
  ) {
    final session = store.load(
      slotId: slotId,
      clubs: clubs,
      leagues: leagues,
    );
    if (session == null) {
      return null;
    }

    final snapshot = session.newGameBootstrapSnapshot;
    final controlledClub = clubs.singleWhere(
      (club) => club.id == snapshot.controlledClubId,
    );

    return PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary(
      slotId: slotId,
      controlledClubId: snapshot.controlledClubId,
      controlledClubName: controlledClub.name,
      initialSeasonIndex: snapshot.config.seasonIndex,
      careerSeed: snapshot.config.careerSeed,
      simulationVersion: snapshot.config.simulationVersion,
      answeredDecisionCount: session.answeredDecisionCount,
      pendingDecisionKind: session.pendingDecision?.kind,
      sessionCompleted: session.completed != null,
      resumeSeasonCount: session.resumeConfig.seasonCount,
      hasFutureSeasonAfterReport:
          session.resumeConfig.hasFutureSeasonAfterReport,
      electionInterval: snapshot.electionInterval,
    );
  }

  List<PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary>
      list() {
    final summaries =
        <PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary>[];
    for (final slotId in store.listSlotIds()) {
      final summary = inspect(slotId);
      if (summary == null) {
        throw StateError(
          'Bootstrap save slot $slotId disappeared while the catalog was reading it.',
        );
      }
      summaries.add(summary);
    }
    return List<
        PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary>.unmodifiable(
      summaries,
    );
  }
}
