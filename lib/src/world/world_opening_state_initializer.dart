import '../core/simulation_config.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_pool_generator.dart';
import 'world_league.dart';

/// Deterministic season-opening world inputs shared by the real runtime and
/// read-only application projections.
///
/// This is not a checkpoint and is never persisted. It only materializes the
/// canonical immutable inputs that already exist before a season is simulated.
class WorldOpeningState {
  WorldOpeningState({
    required Iterable<Club> baseClubs,
    required Iterable<WorldLeague> leagues,
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
  })  : baseClubs = List.unmodifiable(baseClubs),
        leagues = List.unmodifiable(leagues),
        players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates);

  final List<Club> baseClubs;
  final List<WorldLeague> leagues;
  final List<Player> players;
  final List<ClubFinanceState> financeStates;
}

class WorldOpeningStateInitializer {
  const WorldOpeningStateInitializer({
    this.poolGenerator = const PlayerPoolGenerator(),
    this.economyEngine = const BasicEconomyEngine(),
  });

  final PlayerPoolGenerator poolGenerator;
  final BasicEconomyEngine economyEngine;

  WorldOpeningState prepare({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
  }) {
    final baseClubs = List<Club>.unmodifiable(clubs);
    final openingLeagues = List<WorldLeague>.of(leagues)
      ..sort((a, b) => a.tier.level.compareTo(b.tier.level));
    final sortedLeagues = List<WorldLeague>.unmodifiable(openingLeagues);
    final players = poolGenerator.generate(
      clubs: baseClubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );

    final byId = {for (final club in baseClubs) club.id: club};
    final financeStates = <ClubFinanceState>[];
    for (final league in sortedLeagues) {
      final leagueClubs = league.clubIds
          .map((clubId) => byId[clubId]!)
          .toList(growable: false);
      financeStates.addAll(
        economyEngine.initialStates(
          clubs: leagueClubs,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
          economicScaleBps: league.tier.economicScaleBps,
        ),
      );
    }
    financeStates.sort((a, b) => a.clubId.compareTo(b.clubId));

    return WorldOpeningState(
      baseClubs: baseClubs,
      leagues: sortedLeagues,
      players: players,
      financeStates: financeStates,
    );
  }
}
