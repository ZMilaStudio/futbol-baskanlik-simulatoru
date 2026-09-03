import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../transfer/transfer_deal.dart';
import 'world_league.dart';

class WorldTransferPostProcessResult {
  WorldTransferPostProcessResult({
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
    Iterable<TransferCashMovement> cashMovements = const [],
  })  : players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates),
        cashMovements = List.unmodifiable(cashMovements);

  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final List<TransferCashMovement> cashMovements;
}

abstract interface class WorldTransferHooks {
  WorldTransferPostProcessResult afterPermanentTransfers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required List<TransferDeal> permanentTransfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
  });
}

class NoopWorldTransferHooks implements WorldTransferHooks {
  const NoopWorldTransferHooks();

  @override
  WorldTransferPostProcessResult afterPermanentTransfers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required List<TransferDeal> permanentTransfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
  }) =>
      WorldTransferPostProcessResult(
        players: players,
        financeStates: financeStates,
      );
}
