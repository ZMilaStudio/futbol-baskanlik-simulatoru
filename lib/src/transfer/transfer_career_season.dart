import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../season/season_report.dart';
import 'transfer_deal.dart';

class TransferCareerSeason {
  TransferCareerSeason({
    required this.seasonIndex,
    required List<Club> clubs,
    required List<Player> players,
    required this.report,
    required List<ClubFinanceSeason> finances,
    required List<Player> retiredAfterSeason,
    required List<Player> youthIntakeAfterSeason,
    required List<TransferDeal> transfersAfterSeason,
    required List<ClubFinanceState> financeStatesAfterWindow,
  })  : clubs = List.unmodifiable(clubs),
        players = List.unmodifiable(players),
        finances = List.unmodifiable(finances),
        retiredAfterSeason = List.unmodifiable(retiredAfterSeason),
        youthIntakeAfterSeason = List.unmodifiable(youthIntakeAfterSeason),
        transfersAfterSeason = List.unmodifiable(transfersAfterSeason),
        financeStatesAfterWindow = List.unmodifiable(financeStatesAfterWindow);

  final int seasonIndex;
  final List<Club> clubs;
  final List<Player> players;
  final SeasonReport report;
  final List<ClubFinanceSeason> finances;
  final List<Player> retiredAfterSeason;
  final List<Player> youthIntakeAfterSeason;
  final List<TransferDeal> transfersAfterSeason;
  final List<ClubFinanceState> financeStatesAfterWindow;
}
