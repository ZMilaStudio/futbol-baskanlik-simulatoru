import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';
import 'manager.dart';
import 'manager_assignment.dart';
import 'manager_fit_model.dart';
import 'manager_pool_generator.dart';

/// Immutable deterministic manager state at a season opening.
///
/// The real manager runtime and application opening projections both use this
/// initializer so initial manager selection and board relationship logic have
/// one implementation.
class ManagerOpeningState {
  ManagerOpeningState({
    required Iterable<Manager> managers,
    required Iterable<ManagerAssignment> assignments,
  })  : managers = List.unmodifiable(managers),
        assignments = List.unmodifiable(assignments);

  final List<Manager> managers;
  final List<ManagerAssignment> assignments;
}

class ManagerOpeningStateInitializer {
  const ManagerOpeningStateInitializer({
    this.poolGenerator = const ManagerPoolGenerator(),
    this.fitModel = const ManagerFitModel(),
  });

  final ManagerPoolGenerator poolGenerator;
  final ManagerFitModel fitModel;

  ManagerOpeningState prepare({
    required int careerSeed,
    required int simulationVersion,
    required int initialSeasonIndex,
    required List<Club> clubs,
    required List<Player> players,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) {
    final managers = poolGenerator.generate(
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
    final managerById = {for (final manager in managers) manager.id: manager};
    final playersByClub = _playersByClub(players);
    final financeByClub = {
      for (final state in financeStates) state.clubId: state,
    };
    final tierByClub = _tierByClub(leagues);
    final available = managerById.keys.toSet();
    final assignments = <ManagerAssignment>[];
    final orderedClubs = List<Club>.of(clubs)
      ..sort((a, b) {
        final tierCompare =
            tierByClub[a.id]!.level.compareTo(tierByClub[b.id]!.level);
        if (tierCompare != 0) return tierCompare;
        final strengthCompare = b.strength.compareTo(a.strength);
        return strengthCompare != 0 ? strengthCompare : a.id.compareTo(b.id);
      });

    for (final club in orderedClubs) {
      final clubPlayers = playersByClub[club.id] ?? const <Player>[];
      final finance = financeByClub[club.id];
      final tier = tierByClub[club.id];
      if (finance == null || tier == null) {
        throw StateError('Missing initial manager context for ${club.id}.');
      }
      final manager = _selectBestManager(
        availableManagerIds: available,
        managerById: managerById,
        club: club,
        players: clubPlayers,
        leagueTier: tier,
        financeState: finance,
        seasonIndex: initialSeasonIndex,
        initialSeasonIndex: initialSeasonIndex,
        careerSeed: careerSeed,
        simulationVersion: simulationVersion,
      );
      final fit = fitModel.score(
        manager: manager,
        club: club,
        players: clubPlayers,
        leagueTier: tier,
        financeState: finance,
      );
      assignments.add(
        ManagerAssignment(
          clubId: club.id,
          managerId: manager.id,
          appointedSeasonIndex: initialSeasonIndex,
          completedSeasons: 0,
          boardRelationship: _initialRelationship(
            clubId: club.id,
            manager: manager,
            fitScore: fit,
            seasonIndex: initialSeasonIndex,
            careerSeed: careerSeed,
            simulationVersion: simulationVersion,
          ),
        ),
      );
      available.remove(manager.id);
    }

    return ManagerOpeningState(
      managers: managers,
      assignments: assignments,
    );
  }

  Manager _selectBestManager({
    required Set<String> availableManagerIds,
    required Map<String, Manager> managerById,
    required Club club,
    required List<Player> players,
    required LeagueTier leagueTier,
    required ClubFinanceState financeState,
    required int seasonIndex,
    required int initialSeasonIndex,
    required int careerSeed,
    required int simulationVersion,
  }) {
    Manager? best;
    var bestScore = double.negativeInfinity;
    final candidateIds = availableManagerIds.toList()..sort();
    for (final managerId in candidateIds) {
      final manager = managerById[managerId]!;
      final age = manager.startAge + (seasonIndex - initialSeasonIndex);
      if (age >= manager.retirementAge) continue;
      final fit = fitModel.score(
        manager: manager,
        club: club,
        players: players,
        leagueTier: leagueTier,
        financeState: financeState,
      );
      final targetReputation = switch (leagueTier) {
        LeagueTier.first => 74,
        LeagueTier.second => 62,
        LeagueTier.third => 54,
      };
      final reputationMismatch =
          (manager.reputation - targetReputation).abs().toDouble();
      final score = fit * 0.55 +
          manager.reputation * 0.25 +
          manager.coaching * 0.20 -
          reputationMismatch * 0.10 +
          _jitter(
            clubId: club.id,
            managerId: manager.id,
            seasonIndex: seasonIndex,
            salt: 17,
            amplitude: 4,
            careerSeed: careerSeed,
            simulationVersion: simulationVersion,
          );
      if (score > bestScore ||
          (score == bestScore &&
              (best == null || manager.id.compareTo(best.id) < 0))) {
        best = manager;
        bestScore = score;
      }
    }
    if (best == null) {
      throw StateError('Initial manager pool cannot cover ${club.id}.');
    }
    return best;
  }

  double _initialRelationship({
    required String clubId,
    required Manager manager,
    required double fitScore,
    required int seasonIndex,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final value = 52.0 +
        fitScore * 0.18 +
        (manager.boardCooperation - 50) * 0.08 +
        _jitter(
          clubId: clubId,
          managerId: manager.id,
          seasonIndex: seasonIndex,
          salt: 29,
          amplitude: 6,
          careerSeed: careerSeed,
          simulationVersion: simulationVersion,
        );
    return value.clamp(48.0, 78.0).toDouble();
  }

  Map<String, List<Player>> _playersByClub(List<Player> players) {
    final result = <String, List<Player>>{};
    for (final player in players) {
      result.putIfAbsent(player.clubId, () => <Player>[]).add(player);
    }
    return result;
  }

  Map<String, LeagueTier> _tierByClub(List<WorldLeague> leagues) {
    final result = <String, LeagueTier>{};
    for (final league in leagues) {
      for (final clubId in league.clubIds) {
        result[clubId] = league.tier;
      }
    }
    return result;
  }

  double _jitter({
    required String clubId,
    required String managerId,
    required int seasonIndex,
    required int salt,
    required double amplitude,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final seed = StableHash.combine32([
      careerSeed,
      simulationVersion,
      seasonIndex,
      salt,
      StableHash.string32(clubId),
      StableHash.string32(managerId),
    ]);
    final rng = SeededRng(seed);
    return (rng.nextDouble() - 0.5) * amplitude;
  }
}
