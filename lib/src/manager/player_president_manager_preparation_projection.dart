import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../world/league_tier.dart';
import '../world/world_checkpoint.dart';
import 'manager.dart';
import 'manager_career_season.dart';
import 'manager_fit_model.dart';
import 'player_president_manager_control.dart';

/// Read-only M71 preparation calculations, not checkpoint/application authority.
/// Calling these helpers with a legacy checkpoint does not mint AR-C provenance.
final class PlayerManagerPreparationProjection {
  const PlayerManagerPreparationProjection({
    this.fitModel = const ManagerFitModel(),
    this.candidateLimit = 5,
  }) : assert(candidateLimit > 0);

  final ManagerFitModel fitModel;
  final int candidateLimit;

  PlayerManagerReviewContext review({
    required AdvancedRuntimeCheckpoint advanced,
    required String clubId,
    required String presidentId,
  }) {
    if (advanced.manager.seasons.isEmpty) {
      throw StateError('Manager decision requires a completed manager season.');
    }
    final season = advanced.manager.seasons.last;
    final clubSeason = season.clubs.firstWhere((s) => s.clubId == clubId);
    final incumbent = advanced.manager.managers
        .firstWhere((m) => m.id == clubSeason.managerId);
    final changes = season.changesAfterSeason
        .where((c) => c.clubId == clubId)
        .toList(growable: false);
    if (changes.length > 1) {
      throw StateError(
          'Controlled club has multiple manager changes in one season.');
    }
    final change = changes.isEmpty ? null : changes.single;
    final assignment =
        advanced.manager.assignments.firstWhere((a) => a.clubId == clubId);
    final next = advanced.manager.managers
        .firstWhere((m) => m.id == assignment.managerId);
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
          !advanced.manager.assignments
              .any((a) => a.clubId != clubId && a.managerId == incumbent.id),
      forcedRetirement: forced,
    );
  }

  PlayerManagerReplacementContext replacement({
    required AdvancedRuntimeCheckpoint advanced,
    required PlayerManagerReviewContext review,
  }) {
    final candidates = replacementCandidates(
      advanced: advanced,
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
      seasonIndex: advanced.nextSeasonIndex,
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
  }) {
    final world = advanced.world;
    final assignedElsewhere = advanced.manager.assignments
        .where((item) => item.clubId != clubId)
        .map((item) => item.managerId)
        .toSet();
    final club = world.baseClubs.firstWhere((item) => item.id == clubId);
    final players = world.nextSeasonPlayers
        .where((item) => item.clubId == clubId)
        .toList(growable: false);
    final finance = world.nextSeasonFinanceStates.firstWhere(
      (item) => item.clubId == clubId,
    );
    final tier = _tierFor(world, clubId);
    final candidates = <PlayerManagerCandidate>[];
    for (final manager in advanced.manager.managers) {
      if (manager.id == outgoingManager.id ||
          assignedElsewhere.contains(manager.id) ||
          _ageAt(manager, world) >= manager.retirementAge) {
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
            world: world,
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
    required WorldCheckpoint world,
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
          seasonIndex: world.nextSeasonIndex,
          world: world,
          salt: 17,
          amplitude: 4,
        );
  }

  int _ageAt(Manager manager, WorldCheckpoint world) =>
      manager.startAge + (world.nextSeasonIndex - world.config.seasonIndex);

  LeagueTier _tierFor(WorldCheckpoint world, String clubId) =>
      world.nextSeasonLeagues
          .firstWhere((league) => league.clubIds.contains(clubId))
          .tier;

  double _jitter({
    required String clubId,
    required String managerId,
    required int seasonIndex,
    required WorldCheckpoint world,
    required int salt,
    required double amplitude,
  }) {
    final seed = StableHash.combine32([
      world.config.careerSeed,
      world.config.simulationVersion,
      seasonIndex,
      salt,
      StableHash.string32(clubId),
      StableHash.string32(managerId),
    ]);
    final rng = SeededRng(seed);
    return (rng.nextDouble() - 0.5) * amplitude;
  }
}
