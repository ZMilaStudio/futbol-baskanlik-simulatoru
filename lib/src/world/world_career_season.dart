import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../season/season_report.dart';
import '../transfer/transfer_deal.dart';
import 'league_tier.dart';
import 'world_league.dart';

class LeagueSeasonSnapshot {
  const LeagueSeasonSnapshot({
    required this.tier,
    required this.report,
  });

  final LeagueTier tier;
  final SeasonReport report;
}

class LeagueMovement {
  const LeagueMovement({
    required this.clubId,
    required this.from,
    required this.to,
  });

  final String clubId;
  final LeagueTier from;
  final LeagueTier to;

  String get signature => '$clubId:${from.level}>${to.level}';
}

class WorldCareerSeason {
  WorldCareerSeason({
    required this.seasonIndex,
    required Iterable<WorldLeague> leaguesBeforeSeason,
    required Iterable<Club> clubs,
    required Iterable<Player> players,
    required Iterable<LeagueSeasonSnapshot> leagueResults,
    required Iterable<ClubFinanceSeason> finances,
    required Iterable<Player> retiredAfterSeason,
    required Iterable<Player> youthIntakeAfterSeason,
    required Iterable<TransferDeal> transfersAfterSeason,
    required Iterable<ClubFinanceState> financeStatesAfterWindow,
    required Iterable<LeagueMovement> movementsAfterSeason,
    required Iterable<WorldLeague> leaguesAfterTransition,
    Iterable<TransferCashMovement> cashMovementsAfterWindow = const [],
  })  : leaguesBeforeSeason = List.unmodifiable(leaguesBeforeSeason),
        clubs = List.unmodifiable(clubs),
        players = List.unmodifiable(players),
        leagueResults = List.unmodifiable(leagueResults),
        finances = List.unmodifiable(finances),
        retiredAfterSeason = List.unmodifiable(retiredAfterSeason),
        youthIntakeAfterSeason = List.unmodifiable(youthIntakeAfterSeason),
        transfersAfterSeason = List.unmodifiable(transfersAfterSeason),
        financeStatesAfterWindow = List.unmodifiable(financeStatesAfterWindow),
        movementsAfterSeason = List.unmodifiable(movementsAfterSeason),
        leaguesAfterTransition = List.unmodifiable(leaguesAfterTransition),
        cashMovementsAfterWindow = List.unmodifiable(cashMovementsAfterWindow);

  final int seasonIndex;
  final List<WorldLeague> leaguesBeforeSeason;
  final List<Club> clubs;
  final List<Player> players;
  final List<LeagueSeasonSnapshot> leagueResults;
  final List<ClubFinanceSeason> finances;
  final List<Player> retiredAfterSeason;
  final List<Player> youthIntakeAfterSeason;
  final List<TransferDeal> transfersAfterSeason;
  final List<ClubFinanceState> financeStatesAfterWindow;
  final List<LeagueMovement> movementsAfterSeason;
  final List<WorldLeague> leaguesAfterTransition;
  final List<TransferCashMovement> cashMovementsAfterWindow;

  int get matchCount => leagueResults.fold(
        0,
        (total, result) => total + result.report.matchCount,
      );
}
