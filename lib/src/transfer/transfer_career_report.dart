import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import 'transfer_career_season.dart';

class TransferCareerReport {
  TransferCareerReport({
    required this.careerSeed,
    required this.initialPlayerCount,
    required List<ClubFinanceState> initialFinanceStates,
    required List<TransferCareerSeason> seasons,
    required List<Player> finalPlayers,
    required List<ClubFinanceState> finalFinanceStates,
    required List<Club> finalClubs,
  })  : initialFinanceStates = List.unmodifiable(initialFinanceStates),
        seasons = List.unmodifiable(seasons),
        finalPlayers = List.unmodifiable(finalPlayers),
        finalFinanceStates = List.unmodifiable(finalFinanceStates),
        finalClubs = List.unmodifiable(finalClubs);

  final int careerSeed;
  final int initialPlayerCount;
  final List<ClubFinanceState> initialFinanceStates;
  final List<TransferCareerSeason> seasons;
  final List<Player> finalPlayers;
  final List<ClubFinanceState> finalFinanceStates;
  final List<Club> finalClubs;

  int get seasonCount => seasons.length;
  int get totalTransfers => seasons.fold<int>(
        0,
        (sum, season) => sum + season.transfersAfterSeason.length,
      );
  Money get totalTransferVolume => seasons.fold<Money>(
        Money.zero,
        (sum, season) => season.transfersAfterSeason.fold<Money>(
          sum,
          (inner, deal) => inner + deal.fee,
        ),
      );

  String get signature => [
        careerSeed,
        ...seasons.expand(
          (season) => season.transfersAfterSeason.map((deal) => deal.signature),
        ),
        ...finalPlayers.map((player) => player.signature),
        ...finalFinanceStates.map((state) => state.signature),
      ].join('||');
}
