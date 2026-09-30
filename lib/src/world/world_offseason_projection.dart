import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../player/team_strength_calculator.dart';
import '../transfer/transfer_deal.dart';
import '../transfer/transfer_market_engine.dart';
import 'world_league.dart';
import 'world_roster_hooks.dart';
import 'world_transfer_hooks.dart';

class WorldOffseasonProjectionResult {
  WorldOffseasonProjectionResult({
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
    required Iterable<Player> retired,
    required Iterable<Player> youthIntake,
    required Iterable<TransferDeal> transfers,
    required Iterable<TransferCashMovement> cashMovements,
    required Iterable<WorldLeague> nextLeagues,
  })  : players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates),
        retired = List.unmodifiable(retired),
        youthIntake = List.unmodifiable(youthIntake),
        transfers = List.unmodifiable(transfers),
        cashMovements = List.unmodifiable(cashMovements),
        nextLeagues = List.unmodifiable(nextLeagues);
  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final List<Player> retired;
  final List<Player> youthIntake;
  final List<TransferDeal> transfers;
  final List<TransferCashMovement> cashMovements;
  final List<WorldLeague> nextLeagues;
}

/// Shared legacy ordering. Terminal calls intentionally do no lifecycle work.
class WorldOffseasonProjection {
  const WorldOffseasonProjection({
    this.lifecycleEngine = const PlayerLifecycleEngine(),
    this.strengthCalculator = const TeamStrengthCalculator(),
    this.transferMarketEngine = const TransferMarketEngine(),
  });
  final PlayerLifecycleEngine lifecycleEngine;
  final TeamStrengthCalculator strengthCalculator;
  final TransferMarketEngine transferMarketEngine;

  WorldOffseasonProjectionResult project({
    required bool hasNextSeason,
    required int seasonIndex,
    required SimulationConfig config,
    required List<Player> players,
    required List<Club> baseClubs,
    required List<Club> squadClubs,
    required List<ClubFinanceState> closingFinanceStates,
    required List<WorldLeague> nextLeagues,
    required WorldRosterHooks rosterHooks,
    required WorldTransferHooks transferHooks,
    required bool enableTransferInstallments,
  }) {
    if (!hasNextSeason)
      return WorldOffseasonProjectionResult(
        players: List.unmodifiable(players),
        financeStates: List.unmodifiable(closingFinanceStates),
        retired: const [],
        youthIntake: const [],
        transfers: const [],
        cashMovements: const [],
        nextLeagues: nextLeagues,
      );
    final lifecycle = lifecycleEngine.advance(
      currentPlayers: players,
      currentClubs: squadClubs,
      referenceClubs: baseClubs,
      careerSeed: config.careerSeed,
      nextSeasonIndex: seasonIndex + 1,
      simulationVersion: config.simulationVersion,
    );
    final prepared = rosterHooks.prepareNextSeasonPlayers(
      seasonIndex: seasonIndex,
      nextSeasonIndex: seasonIndex + 1,
      activePlayers: lifecycle.activePlayers,
      retiredPlayers: lifecycle.retiredPlayers,
      youthIntake: lifecycle.youthIntake,
      clubs: squadClubs,
      leaguesForNextSeason: nextLeagues,
      financeStates: closingFinanceStates,
    );
    final clubs = strengthCalculator.deriveClubs(
      baseClubs: baseClubs,
      players: prepared,
    );
    final market = transferMarketEngine.simulateWindow(
      clubs: clubs,
      players: prepared,
      financeStates: closingFinanceStates,
      careerSeed: config.careerSeed,
      seasonIndex: seasonIndex,
      simulationVersion: config.simulationVersion,
      contractYearsRemainingByPlayer:
          rosterHooks.contractYearsRemainingForTransfer(
        nextSeasonIndex: seasonIndex + 1,
        players: prepared,
      ),
      enableInstallments: enableTransferInstallments,
    );
    rosterHooks.onTransferWindowCompleted(
      seasonIndex: seasonIndex,
      nextSeasonIndex: seasonIndex + 1,
      playersBeforeWindow: prepared,
      playersAfterWindow: market.players,
      transfers: market.deals,
      clubs: clubs,
      leaguesForNextSeason: nextLeagues,
      financeStates: market.financeStates,
    );
    final post = transferHooks.afterPermanentTransfers(
      seasonIndex: seasonIndex,
      nextSeasonIndex: seasonIndex + 1,
      players: market.players,
      financeStates: market.financeStates,
      permanentTransfers: market.deals,
      clubs: clubs,
      leaguesForNextSeason: nextLeagues,
    );
    return WorldOffseasonProjectionResult(
      players: List.unmodifiable(post.players),
      financeStates: List.unmodifiable(post.financeStates),
      retired: lifecycle.retiredPlayers,
      youthIntake: lifecycle.youthIntake,
      transfers: market.deals,
      cashMovements: post.cashMovements,
      nextLeagues: nextLeagues,
    );
  }
}
