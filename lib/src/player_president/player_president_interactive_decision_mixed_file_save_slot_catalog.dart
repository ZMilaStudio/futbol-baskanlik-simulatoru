import 'player_president_interactive_decision_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'player_president_interactive_decision_session.dart';

/// Physical save namespace represented by one mixed load-game entry.
enum PlayerPresidentInteractiveDecisionMixedSaveSlotSource {
  checkpoint,
  newGameBootstrap,
}

/// Read-only application projection over either an M78 checkpoint summary or
/// an M82 pre-checkpoint bootstrap summary.
///
/// M83 does not copy or persist game state. The source-specific summary remains
/// available so callers can inspect the exact M78/M82 metadata without a new
/// save schema or metadata sidecar.
class PlayerPresidentInteractiveDecisionMixedSaveSlotSummary {
  const PlayerPresidentInteractiveDecisionMixedSaveSlotSummary._({
    required this.source,
    required this.slotId,
    required this.controlledClubId,
    required this.controlledClubName,
    required this.answeredDecisionCount,
    required this.pendingDecisionKind,
    required this.sessionCompleted,
    required this.resumeSeasonCount,
    required this.hasFutureSeasonAfterReport,
    required this.checkpointSummary,
    required this.bootstrapSummary,
  });

  factory PlayerPresidentInteractiveDecisionMixedSaveSlotSummary.checkpoint(
    PlayerPresidentInteractiveDecisionSaveSlotSummary summary,
  ) =>
      PlayerPresidentInteractiveDecisionMixedSaveSlotSummary._(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: summary.slotId,
        controlledClubId: summary.controlledClubId,
        controlledClubName: summary.controlledClubName,
        answeredDecisionCount: summary.answeredDecisionCount,
        pendingDecisionKind: summary.pendingDecisionKind,
        sessionCompleted: summary.sessionCompleted,
        resumeSeasonCount: summary.resumeSeasonCount,
        hasFutureSeasonAfterReport: summary.hasFutureSeasonAfterReport,
        checkpointSummary: summary,
        bootstrapSummary: null,
      );

  factory PlayerPresidentInteractiveDecisionMixedSaveSlotSummary.bootstrap(
    PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary summary,
  ) =>
      PlayerPresidentInteractiveDecisionMixedSaveSlotSummary._(
        source:
            PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap,
        slotId: summary.slotId,
        controlledClubId: summary.controlledClubId,
        controlledClubName: summary.controlledClubName,
        answeredDecisionCount: summary.answeredDecisionCount,
        pendingDecisionKind: summary.pendingDecisionKind,
        sessionCompleted: summary.sessionCompleted,
        resumeSeasonCount: summary.resumeSeasonCount,
        hasFutureSeasonAfterReport: summary.hasFutureSeasonAfterReport,
        checkpointSummary: null,
        bootstrapSummary: summary,
      );

  final PlayerPresidentInteractiveDecisionMixedSaveSlotSource source;
  final String slotId;
  final String controlledClubId;
  final String controlledClubName;
  final int answeredDecisionCount;
  final PlayerPresidentInteractiveDecisionKind? pendingDecisionKind;
  final bool sessionCompleted;
  final int resumeSeasonCount;
  final bool hasFutureSeasonAfterReport;
  final PlayerPresidentInteractiveDecisionSaveSlotSummary? checkpointSummary;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapSaveSlotSummary?
      bootstrapSummary;

  bool get isCheckpoint =>
      source == PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint;

  bool get isNewGameBootstrap => source ==
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap;

  /// Stable identity that remains distinct when both namespaces use the same
  /// human-facing slot id.
  String get identity => '${source.name}:$slotId';

  String get signature {
    final sourceSignature =
        checkpointSummary?.signature ?? bootstrapSummary!.signature;
    return 'source=${source.name}:$sourceSignature';
  }
}

/// Deterministic read-only catalog combining the existing M78 checkpoint and
/// M82 bootstrap catalogs without merging their storage namespaces.
///
/// Decode/checksum/replay/world validation is delegated to the source catalog.
/// Consequently corrupt data still fails closed, and M65 remains the single
/// persisted game-state authority. Lists are ordered by slot id first and then
/// checkpoint before bootstrap, so same-id entries remain stable and distinct.
class PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog {
  const PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog({
    required this.checkpointCatalog,
    required this.bootstrapCatalog,
  });

  final PlayerPresidentInteractiveDecisionFileSaveSlotCatalog checkpointCatalog;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog
      bootstrapCatalog;

  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary? inspect({
    required PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
    required String slotId,
  }) {
    switch (source) {
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint:
        final summary = checkpointCatalog.inspect(slotId);
        return summary == null
            ? null
            : PlayerPresidentInteractiveDecisionMixedSaveSlotSummary.checkpoint(
                summary,
              );
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap:
        final summary = bootstrapCatalog.inspect(slotId);
        return summary == null
            ? null
            : PlayerPresidentInteractiveDecisionMixedSaveSlotSummary.bootstrap(
                summary,
              );
    }
  }

  List<PlayerPresidentInteractiveDecisionMixedSaveSlotSummary> list() {
    final summaries = <PlayerPresidentInteractiveDecisionMixedSaveSlotSummary>[
      ...checkpointCatalog.list().map(
            PlayerPresidentInteractiveDecisionMixedSaveSlotSummary.checkpoint,
          ),
      ...bootstrapCatalog.list().map(
            PlayerPresidentInteractiveDecisionMixedSaveSlotSummary.bootstrap,
          ),
    ];
    summaries.sort(_compare);
    return List<PlayerPresidentInteractiveDecisionMixedSaveSlotSummary>.unmodifiable(
      summaries,
    );
  }

  static int _compare(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary left,
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary right,
  ) {
    final slotComparison = left.slotId.compareTo(right.slotId);
    if (slotComparison != 0) {
      return slotComparison;
    }
    return _sourceRank(left.source).compareTo(_sourceRank(right.source));
  }

  static int _sourceRank(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
  ) {
    switch (source) {
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint:
        return 0;
      case PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap:
        return 1;
    }
  }
}
