import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';
import 'manager.dart';
import 'manager_assignment.dart';
import 'manager_career_season.dart';
import 'manager_fit_model.dart';
import 'player_president_manager_control.dart';

/// Read-only algorithm inputs, NOT a manager/source ownership capability.
/// The trusted transition separately proves ownership before using this view.
final class ManagerPreparationRuntimeView {
  ManagerPreparationRuntimeView({
    required this.config,
    required this.targetSeasonIndex,
    required this.completedSeason,
    required Iterable<Manager> managers,
    required Iterable<ManagerAssignment> assignments,
    required Iterable<Club> baseClubs,
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
    required Iterable<WorldLeague> leagues,
  })  : managers = List.unmodifiable(managers),
        assignments = List.unmodifiable(assignments),
        baseClubs = List.unmodifiable(baseClubs),
        players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates),
        leagues = List.unmodifiable(leagues) {
    if (targetSeasonIndex != completedSeason.seasonIndex + 1) {
      throw StateError(
          'Manager preparation requires the immediate successor season.');
    }
  }

  factory ManagerPreparationRuntimeView.fromCheckpoint(
      AdvancedRuntimeCheckpoint advanced) {
    if (advanced.manager.seasons.isEmpty) {
      throw StateError('Manager decision requires a completed manager season.');
    }
    return ManagerPreparationRuntimeView(
      config: advanced.world.config,
      targetSeasonIndex: advanced.nextSeasonIndex,
      completedSeason: advanced.manager.seasons.last,
      managers: advanced.manager.managers,
      assignments: advanced.manager.assignments,
      baseClubs: advanced.world.baseClubs,
      players: advanced.world.nextSeasonPlayers,
      financeStates: advanced.world.nextSeasonFinanceStates,
      leagues: advanced.world.nextSeasonLeagues,
    );
  }

  final SimulationConfig config;
  final int targetSeasonIndex;
  final ManagerCareerSeason completedSeason;
  final List<Manager> managers;
  final List<ManagerAssignment> assignments;
  final List<Club> baseClubs;
  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final List<WorldLeague> leagues;
}

/// Read-only M71 preparation calculations, not checkpoint/application authority.
/// Calling these helpers with a legacy checkpoint does not mint AR-C provenance.
final class PlayerManagerPreparationProjection {
  const PlayerManagerPreparationProjection({
    this.fitModel = const ManagerFitModel(),
    this.candidateLimit = 5,
  }) : assert(candidateLimit > 0);

  final ManagerFitModel fitModel;
  final int candidateLimit;

  ManagerAssignment newAssignmentRuntime({
    required ManagerPreparationRuntimeView view,
    required String clubId,
    required PlayerManagerCandidate candidate,
  }) {
    final manager = candidate.manager;
    final relationship = (52.0 +
            candidate.fitScore * 0.18 +
            (manager.boardCooperation - 50) * 0.08 +
            _jitter(
              clubId: clubId,
              managerId: manager.id,
              seasonIndex: view.targetSeasonIndex,
              view: view,
              salt: 29,
              amplitude: 6,
            ))
        .clamp(48.0, 78.0)
        .toDouble();
    return ManagerAssignment(
      clubId: clubId,
      managerId: manager.id,
      appointedSeasonIndex: view.targetSeasonIndex,
      completedSeasons: 0,
      boardRelationship: relationship,
    );
  }

  ManagerAssignment retainedAssignmentRuntime({
    required ManagerPreparationRuntimeView view,
    required ManagerClubSeason clubSeason,
    required List<ManagerCareerSeason> completedHistory,
  }) {
    if (completedHistory.isEmpty ||
        !identical(completedHistory.last, view.completedSeason)) {
      throw StateError('Retain requires exact completed manager history.');
    }
    var completed = 0;
    for (final season in completedHistory.reversed) {
      final record =
          season.clubs.firstWhere((item) => item.clubId == clubSeason.clubId);
      if (record.managerId != clubSeason.managerId) break;
      completed++;
    }
    return ManagerAssignment(
      clubId: clubSeason.clubId,
      managerId: clubSeason.managerId,
      appointedSeasonIndex: view.targetSeasonIndex - completed,
      completedSeasons: completed,
      boardRelationship: clubSeason.relationshipAfter,
    );
  }

  PlayerManagerReviewContext review({
    required AdvancedRuntimeCheckpoint advanced,
    required String clubId,
    required String presidentId,
  }) =>
      reviewRuntime(
        view: ManagerPreparationRuntimeView.fromCheckpoint(advanced),
        clubId: clubId,
        presidentId: presidentId,
      );

  PlayerManagerReviewContext reviewRuntime({
    required ManagerPreparationRuntimeView view,
    required String clubId,
    required String presidentId,
  }) {
    final season = view.completedSeason;
    final clubSeason = season.clubs.firstWhere((s) => s.clubId == clubId);
    final incumbent =
        view.managers.firstWhere((m) => m.id == clubSeason.managerId);
    final changes = season.changesAfterSeason
        .where((c) => c.clubId == clubId)
        .toList(growable: false);
    if (changes.length > 1) {
      throw StateError(
          'Controlled club has multiple manager changes in one season.');
    }
    final change = changes.isEmpty ? null : changes.single;
    final assignment = view.assignments.firstWhere((a) => a.clubId == clubId);
    final next = view.managers.firstWhere((m) => m.id == assignment.managerId);
    final forced = change?.reason == ManagerChangeReason.retirement;
    return PlayerManagerReviewContext(
      seasonIndex: season.seasonIndex,
      clubId: clubId,
      presidentId: presidentId,
      currentManager: incumbent,
      season: clubSeason,
      aiWouldReplace: change != null,
      aiReason: change?.reason,
      aiNextManager: next,
      canRetain: !forced &&
          !view.assignments
              .any((a) => a.clubId != clubId && a.managerId == incumbent.id),
      forcedRetirement: forced,
    );
  }

  PlayerManagerReplacementContext replacement({
    required AdvancedRuntimeCheckpoint advanced,
    required PlayerManagerReviewContext review,
  }) =>
      replacementRuntime(
        view: ManagerPreparationRuntimeView.fromCheckpoint(advanced),
        review: review,
      );

  PlayerManagerReplacementContext replacementRuntime({
    required ManagerPreparationRuntimeView view,
    required PlayerManagerReviewContext review,
  }) {
    if (view.completedSeason.seasonIndex != review.seasonIndex) {
      throw StateError('Manager review season mismatch.');
    }
    final candidates = replacementCandidatesRuntime(
      view: view,
      clubId: review.clubId,
      outgoingManager: review.currentManager,
      preferredAiManager: review.aiWouldReplace ? review.aiNextManager : null,
    );
    if (candidates.isEmpty) {
      throw StateError('No eligible manager candidates are available.');
    }
    final ai = review.aiWouldReplace
        ? candidates.firstWhere((c) => c.manager.id == review.aiNextManager.id,
            orElse: () => candidates.first)
        : candidates.first;
    return PlayerManagerReplacementContext(
      seasonIndex: view.targetSeasonIndex,
      clubId: review.clubId,
      presidentId: review.presidentId,
      outgoingManager: review.currentManager,
      reason: review.aiReason ?? ManagerChangeReason.boardBreakdown,
      candidates: candidates,
      aiChoice: ai.manager,
    );
  }

  /// AR-C accepts an exact offered object, never a fabricated value-equal manager.
  PlayerManagerCandidate validateSelected(
      PlayerManagerReplacementContext context, Manager selected) {
    final matches =
        context.candidates.where((c) => identical(c.manager, selected));
    if (matches.length != 1) {
      throw ArgumentError('Manager must be the exact offered candidate.');
    }
    return matches.single;
  }

  List<PlayerManagerCandidate> replacementCandidates({
    required AdvancedRuntimeCheckpoint advanced,
    required String clubId,
    required Manager outgoingManager,
    Manager? preferredAiManager,
  }) =>
      replacementCandidatesRuntime(
        view: ManagerPreparationRuntimeView.fromCheckpoint(advanced),
        clubId: clubId,
        outgoingManager: outgoingManager,
        preferredAiManager: preferredAiManager,
      );

  List<PlayerManagerCandidate> replacementCandidatesRuntime({
    required ManagerPreparationRuntimeView view,
    required String clubId,
    required Manager outgoingManager,
    Manager? preferredAiManager,
  }) {
    final assignedElsewhere = view.assignments
        .where((item) => item.clubId != clubId)
        .map((item) => item.managerId)
        .toSet();
    final club = view.baseClubs.firstWhere((item) => item.id == clubId);
    final players = view.players
        .where((item) => item.clubId == clubId)
        .toList(growable: false);
    final finance = view.financeStates.firstWhere(
      (item) => item.clubId == clubId,
    );
    final tier =
        view.leagues.firstWhere((l) => l.clubIds.contains(clubId)).tier;
    final candidates = <PlayerManagerCandidate>[];
    for (final manager in view.managers) {
      if (manager.id == outgoingManager.id ||
          assignedElsewhere.contains(manager.id) ||
          manager.startAge +
                  (view.targetSeasonIndex - view.config.seasonIndex) >=
              manager.retirementAge) {
        continue;
      }
      final fit = fitModel.score(
        manager: manager,
        club: club,
        players: players,
        leagueTier: tier,
        financeState: finance,
      );
      candidates.add(
        PlayerManagerCandidate(
          manager: manager,
          fitScore: fit,
          selectionScore: _selectionScore(
            manager: manager,
            fitScore: fit,
            clubId: clubId,
            tier: tier,
            view: view,
          ),
        ),
      );
    }
    candidates.sort((a, b) {
      final score = b.selectionScore.compareTo(a.selectionScore);
      return score != 0 ? score : a.manager.id.compareTo(b.manager.id);
    });

    final selected = <PlayerManagerCandidate>[];
    if (preferredAiManager != null) {
      final preferred = candidates.where(
        (item) => item.manager.id == preferredAiManager.id,
      );
      if (preferred.isNotEmpty) selected.add(preferred.first);
    }
    for (final candidate in candidates) {
      if (selected.any((item) => item.manager.id == candidate.manager.id)) {
        continue;
      }
      selected.add(candidate);
      if (selected.length >= candidateLimit) break;
    }
    return List.unmodifiable(selected);
  }

  double _selectionScore({
    required Manager manager,
    required double fitScore,
    required String clubId,
    required LeagueTier tier,
    required ManagerPreparationRuntimeView view,
  }) {
    final targetReputation = switch (tier) {
      LeagueTier.first => 74,
      LeagueTier.second => 62,
      LeagueTier.third => 54,
    };
    final mismatch = (manager.reputation - targetReputation).abs().toDouble();
    return fitScore * 0.55 +
        manager.reputation * 0.25 +
        manager.coaching * 0.20 -
        mismatch * 0.10 +
        _jitter(
          clubId: clubId,
          managerId: manager.id,
          seasonIndex: view.targetSeasonIndex,
          view: view,
          salt: 17,
          amplitude: 4,
        );
  }

  double _jitter({
    required String clubId,
    required String managerId,
    required int seasonIndex,
    required ManagerPreparationRuntimeView view,
    required int salt,
    required double amplitude,
  }) {
    final seed = StableHash.combine32([
      view.config.careerSeed,
      view.config.simulationVersion,
      seasonIndex,
      salt,
      StableHash.string32(clubId),
      StableHash.string32(managerId),
    ]);
    final rng = SeededRng(seed);
    return (rng.nextDouble() - 0.5) * amplitude;
  }
}
