import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../transfer/transfer_deal.dart';
import 'world_league.dart';

abstract interface class WorldRosterHooks {
  Map<String, Money>? annualWagesByClub({
    required int seasonIndex,
    required List<Player> players,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  });

  List<Player> prepareNextSeasonPlayers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> activePlayers,
    required List<Player> retiredPlayers,
    required List<Player> youthIntake,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  });

  Map<String, int>? contractYearsRemainingForTransfer({
    required int nextSeasonIndex,
    required List<Player> players,
  });

  void onTransferWindowCompleted({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> playersBeforeWindow,
    required List<Player> playersAfterWindow,
    required List<TransferDeal> transfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  });
}

class NoopWorldRosterHooks implements WorldRosterHooks {
  const NoopWorldRosterHooks();

  @override
  Map<String, Money>? annualWagesByClub({
    required int seasonIndex,
    required List<Player> players,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) =>
      null;

  @override
  List<Player> prepareNextSeasonPlayers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> activePlayers,
    required List<Player> retiredPlayers,
    required List<Player> youthIntake,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  }) =>
      activePlayers;

  @override
  Map<String, int>? contractYearsRemainingForTransfer({
    required int nextSeasonIndex,
    required List<Player> players,
  }) =>
      null;

  @override
  void onTransferWindowCompleted({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> playersBeforeWindow,
    required List<Player> playersAfterWindow,
    required List<TransferDeal> transfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  }) {}
}
