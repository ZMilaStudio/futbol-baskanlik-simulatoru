import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../world/league_tier.dart';
import '../world/world_career_hooks.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import 'manager.dart';
import 'manager_assignment.dart';
import 'manager_career_season.dart';
import 'manager_fit_model.dart';
import 'manager_impact_model.dart';
import 'manager_patience_policy.dart';
import 'manager_pool_generator.dart';

class ManagerCareerController implements WorldCareerHooks {
  ManagerCareerController({
    required this.careerSeed,
    required this.simulationVersion,
    required this.initialSeasonIndex,
    this.poolGenerator = const ManagerPoolGenerator(),
    this.fitModel = const ManagerFitModel(),
    this.impactModel = const ManagerImpactModel(),
    this.patienceProvider,
    this.dismissalPolicy = const ManagerDismissalPolicy(),
  });

  final int careerSeed;
  final int simulationVersion;
  final int initialSeasonIndex;
  final ManagerPoolGenerator poolGenerator;
  final ManagerFitModel fitModel;
  final ManagerImpactModel impactModel;
  final ManagerPatienceProvider? patienceProvider;
  final ManagerDismissalPolicy dismissalPolicy;

  bool _initialized = false;
  List<Manager> _managers = const [];
  Map<String, Manager> _managerById = const {};
  Map<String, ManagerAssignment> _assignments = const {};
  Map<String, _PendingManagerClubSeason> _pending = const {};
  final List<ManagerCareerSeason> _seasons = [];

  List<Manager> get managers => List.unmodifiable(_managers);
  List<ManagerCareerSeason> get seasons => List.unmodifiable(_seasons);
  List<ManagerAssignment> get finalAssignments {
    final values = _assignments.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return List.unmodifiable(values);
  }

  @override
  List<Club> adjustClubsForSeason({
    required int seasonIndex,
    required List<Club> squadClubs,
    required List<Player> players,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) {
    if (!_initialized) {
      _initialize(
        seasonIndex: seasonIndex,
        clubs: squadClubs,
        players: players,
        leagues: leagues,
        financeStates: financeStates,
      );
    }
    if (_pending.isNotEmpty) {
      throw StateError('Previous manager season was not completed.');
    }

    final playersByClub = _playersByClub(players);
    final financeByClub = {
      for (final state in financeStates) state.clubId: state,
    };
    final tierByClub = _tierByClub(leagues);
    final expectedPositions = _expectedPositions(squadClubs, leagues);
    final pending = <String, _PendingManagerClubSeason>{};
    final effective = <Club>[];

    for (final club in squadClubs) {
      final assignment = _assignments[club.id];
      if (assignment == null) {
        throw StateError('Missing manager assignment for ${club.id}.');
      }
      final manager = _managerById[assignment.managerId]!;
      final clubPlayers = playersByClub[club.id] ?? const <Player>[];
      final finance = financeByClub[club.id];
      final tier = tierByClub[club.id];
      if (finance == null || tier == null) {
        throw StateError('Missing manager context for ${club.id}.');
      }
      final fit = fitModel.score(
        manager: manager,
        club: club,
        players: clubPlayers,
        leagueTier: tier,
        financeState: finance,
      );
      final impact = impactModel.calculate(
        manager: manager,
        fitScore: fit,
        boardRelationship: assignment.boardRelationship,
        players: clubPlayers,
      );
      final managerAge = _ageAt(manager, seasonIndex);
      pending[club.id] = _PendingManagerClubSeason(
        clubId: club.id,
        managerId: manager.id,
        managerAge: managerAge,
        fitScore: fit,
        strengthImpact: impact,
        relationshipBefore: assignment.boardRelationship,
        expectedPosition: expectedPositions[club.id]!,
      );
      effective.add(
        club.copyWith(
          strength: (club.strength + impact).clamp(45.0, 94.0).toDouble(),
        ),
      );
    }

    _pending = pending;
    return List.unmodifiable(effective);
  }

  @override
  void onSeasonCompleted({
    required int seasonIndex,
    required bool hasNextSeason,
    required List<Club> squadClubs,
    required List<Club> effectiveClubs,
    required List<Player> players,
    required List<WorldLeague> leaguesBeforeSeason,
    required List<WorldLeague> leaguesForNextSeason,
    required List<LeagueSeasonSnapshot> leagueResults,
    required List<ClubFinanceSeason> finances,
  }) {
    if (!_initialized || _pending.length != squadClubs.length) {
      throw StateError('Manager season completion has no matching setup.');
    }

    final actualPositions = _actualPositions(leagueResults);
    final clubById = {for (final club in squadClubs) club.id: club};
    final playersByClub = _playersByClub(players);
    final nextTierByClub = _tierByClub(leaguesForNextSeason);
    final closingFinance = {
      for (final finance in finances)
        finance.clubId: ClubFinanceState(
          clubId: finance.clubId,
          cash: finance.closingCash,
          debt: finance.closingDebt,
        ),
    };

    final retained = <String, ManagerAssignment>{};
    final replacements = <_Replacement>[];
    final clubSeasons = <ManagerClubSeason>[];
    final pendingValues = _pending.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));

    for (final pending in pendingValues) {
      final assignment = _assignments[pending.clubId]!;
      final manager = _managerById[pending.managerId]!;
      final actualPosition = actualPositions[pending.clubId];
      if (actualPosition == null) {
        throw StateError('Missing league finish for ${pending.clubId}.');
      }
      final relationshipAfter = _updatedRelationship(
        manager: manager,
        relationshipBefore: pending.relationshipBefore,
        fitScore: pending.fitScore,
        expectedPosition: pending.expectedPosition,
        actualPosition: actualPosition,
      );
      final managerPatience = patienceProvider?.call(
            pending.clubId,
            seasonIndex,
          ) ??
          ManagerDismissalPolicy.neutralPatience;
      final reason = _changeReason(
        manager: manager,
        seasonIndex: seasonIndex,
        hasNextSeason: hasNextSeason,
        relationshipAfter: relationshipAfter,
        expectedPosition: pending.expectedPosition,
        actualPosition: actualPosition,
        managerPatience: managerPatience,
      );

      clubSeasons.add(
        ManagerClubSeason(
          clubId: pending.clubId,
          managerId: pending.managerId,
          managerAge: pending.managerAge,
          fitScore: pending.fitScore,
          strengthImpact: pending.strengthImpact,
          relationshipBefore: pending.relationshipBefore,
          relationshipAfter: relationshipAfter,
          expectedPosition: pending.expectedPosition,
          actualPosition: actualPosition,
          changedAfterSeason: reason != null,
        ),
      );

      if (reason == null) {
        retained[pending.clubId] = assignment.copyWith(
          completedSeasons: assignment.completedSeasons + 1,
          boardRelationship: relationshipAfter,
        );
      } else {
        replacements.add(
          _Replacement(
            clubId: pending.clubId,
            oldManagerId: pending.managerId,
            reason: reason,
          ),
        );
      }
    }

    final changes = <ManagerChange>[];
    if (hasNextSeason && replacements.isNotEmpty) {
      final retainedManagerIds = retained.values
          .map((assignment) => assignment.managerId)
          .toSet();
      final nextSeasonIndex = seasonIndex + 1;
      final available = _managers
          .where(
            (manager) =>
                !retainedManagerIds.contains(manager.id) &&
                _ageAt(manager, nextSeasonIndex) < manager.retirementAge,
          )
          .map((manager) => manager.id)
          .toSet();

      replacements.sort((a, b) => a.clubId.compareTo(b.clubId));
      for (final replacement in replacements) {
        final club = clubById[replacement.clubId]!;
        final clubPlayers = playersByClub[replacement.clubId] ?? const <Player>[];
        final finance = closingFinance[replacement.clubId]!;
        final tier = nextTierByClub[replacement.clubId]!;
        final manager = _selectBestManager(
          availableManagerIds: available,
          excludedManagerId: replacement.oldManagerId,
          club: club,
          players: clubPlayers,
          leagueTier: tier,
          financeState: finance,
          seasonIndex: nextSeasonIndex,
        );
        final fit = fitModel.score(
          manager: manager,
          club: club,
          players: clubPlayers,
          leagueTier: tier,
          financeState: finance,
        );
        retained[replacement.clubId] = ManagerAssignment(
          clubId: replacement.clubId,
          managerId: manager.id,
          appointedSeasonIndex: nextSeasonIndex,
          completedSeasons: 0,
          boardRelationship: _initialRelationship(
            clubId: replacement.clubId,
            manager: manager,
            fitScore: fit,
            seasonIndex: nextSeasonIndex,
          ),
        );
        available.remove(manager.id);
        changes.add(
          ManagerChange(
            clubId: replacement.clubId,
            fromManagerId: replacement.oldManagerId,
            toManagerId: manager.id,
            reason: replacement.reason,
          ),
        );
      }
    }

    if (retained.length != squadClubs.length) {
      throw StateError('Every club must leave a season with one manager.');
    }

    _assignments = Map.unmodifiable(retained);
    _seasons.add(
      ManagerCareerSeason(
        seasonIndex: seasonIndex,
        clubs: clubSeasons,
        changesAfterSeason: changes,
      ),
    );
    _pending = const {};
  }

  void _initialize({
    required int seasonIndex,
    required List<Club> clubs,
    required List<Player> players,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) {
    _managers = poolGenerator.generate(
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
    _managerById = {for (final manager in _managers) manager.id: manager};
    final playersByClub = _playersByClub(players);
    final financeByClub = {
      for (final state in financeStates) state.clubId: state,
    };
    final tierByClub = _tierByClub(leagues);
    final available = _managerById.keys.toSet();
    final assignments = <String, ManagerAssignment>{};
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
      final finance = financeByClub[club.id]!;
      final tier = tierByClub[club.id]!;
      final manager = _selectBestManager(
        availableManagerIds: available,
        club: club,
        players: clubPlayers,
        leagueTier: tier,
        financeState: finance,
        seasonIndex: seasonIndex,
      );
      final fit = fitModel.score(
        manager: manager,
        club: club,
        players: clubPlayers,
        leagueTier: tier,
        financeState: finance,
      );
      assignments[club.id] = ManagerAssignment(
        clubId: club.id,
        managerId: manager.id,
        appointedSeasonIndex: seasonIndex,
        completedSeasons: 0,
        boardRelationship: _initialRelationship(
          clubId: club.id,
          manager: manager,
          fitScore: fit,
          seasonIndex: seasonIndex,
        ),
      );
      available.remove(manager.id);
    }

    _assignments = Map.unmodifiable(assignments);
    _initialized = true;
  }

  Manager _selectBestManager({
    required Set<String> availableManagerIds,
    required Club club,
    required List<Player> players,
    required LeagueTier leagueTier,
    required ClubFinanceState financeState,
    required int seasonIndex,
    String? excludedManagerId,
  }) {
    Manager? best;
    var bestScore = double.negativeInfinity;
    final candidateIds = availableManagerIds.toList()..sort();
    for (final managerId in candidateIds) {
      if (managerId == excludedManagerId) continue;
      final manager = _managerById[managerId]!;
      if (_ageAt(manager, seasonIndex) >= manager.retirementAge) continue;
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
          );
      if (score > bestScore ||
          (score == bestScore && (best == null || manager.id.compareTo(best.id) < 0))) {
        best = manager;
        bestScore = score;
      }
    }
    if (best == null) {
      throw StateError('No eligible manager available for ${club.id}.');
    }
    return best;
  }

  double _initialRelationship({
    required String clubId,
    required Manager manager,
    required double fitScore,
    required int seasonIndex,
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
        );
    return value.clamp(48.0, 78.0).toDouble();
  }

  double _updatedRelationship({
    required Manager manager,
    required double relationshipBefore,
    required double fitScore,
    required int expectedPosition,
    required int actualPosition,
  }) {
    var delta = (expectedPosition - actualPosition) * 4.0;
    if (actualPosition <= 3) delta += 4;
    if (actualPosition >= 14) delta -= 5;
    if (expectedPosition <= 3 && actualPosition >= 7) delta -= 4;
    delta += (fitScore - 50) * 0.04;
    delta += (manager.boardCooperation - 60) * 0.025;
    delta = delta.clamp(-20.0, 12.0).toDouble();
    return (relationshipBefore + delta).clamp(0.0, 100.0).toDouble();
  }

  ManagerChangeReason? _changeReason({
    required Manager manager,
    required int seasonIndex,
    required bool hasNextSeason,
    required double relationshipAfter,
    required int expectedPosition,
    required int actualPosition,
    required int managerPatience,
  }) {
    if (!hasNextSeason) return null;
    if (_ageAt(manager, seasonIndex + 1) >= manager.retirementAge) {
      return ManagerChangeReason.retirement;
    }
    final thresholds = dismissalPolicy.thresholds(managerPatience);
    if (relationshipAfter < thresholds.boardBreakdownRelationship) {
      return ManagerChangeReason.boardBreakdown;
    }
    final underperformance = actualPosition - expectedPosition;
    if (underperformance >= thresholds.underperformanceGap &&
        relationshipAfter < thresholds.underperformanceRelationship) {
      return ManagerChangeReason.performance;
    }
    if (actualPosition >= 15 &&
        expectedPosition <= 10 &&
        relationshipAfter < thresholds.relegationRelationship) {
      return ManagerChangeReason.performance;
    }
    return null;
  }

  int _ageAt(Manager manager, int seasonIndex) =>
      manager.startAge + (seasonIndex - initialSeasonIndex);

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

  Map<String, int> _expectedPositions(
    List<Club> clubs,
    List<WorldLeague> leagues,
  ) {
    final clubById = {for (final club in clubs) club.id: club};
    final positions = <String, int>{};
    for (final league in leagues) {
      final leagueClubs = league.clubIds.map((id) => clubById[id]!).toList()
        ..sort((a, b) {
          final strengthCompare = b.strength.compareTo(a.strength);
          return strengthCompare != 0 ? strengthCompare : a.id.compareTo(b.id);
        });
      for (var index = 0; index < leagueClubs.length; index++) {
        positions[leagueClubs[index].id] = index + 1;
      }
    }
    return positions;
  }

  Map<String, int> _actualPositions(
    List<LeagueSeasonSnapshot> leagueResults,
  ) {
    final positions = <String, int>{};
    for (final result in leagueResults) {
      for (var index = 0; index < result.report.table.length; index++) {
        positions[result.report.table[index].clubId] = index + 1;
      }
    }
    return positions;
  }

  double _jitter({
    required String clubId,
    required String managerId,
    required int seasonIndex,
    required int salt,
    required double amplitude,
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

class _PendingManagerClubSeason {
  const _PendingManagerClubSeason({
    required this.clubId,
    required this.managerId,
    required this.managerAge,
    required this.fitScore,
    required this.strengthImpact,
    required this.relationshipBefore,
    required this.expectedPosition,
  });

  final String clubId;
  final String managerId;
  final int managerAge;
  final double fitScore;
  final double strengthImpact;
  final double relationshipBefore;
  final int expectedPosition;
}

class _Replacement {
  const _Replacement({
    required this.clubId,
    required this.oldManagerId,
    required this.reason,
  });

  final String clubId;
  final String oldManagerId;
  final ManagerChangeReason reason;
}
