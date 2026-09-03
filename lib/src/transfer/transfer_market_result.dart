import '../finance/club_finance_state.dart';
import '../player/player.dart';
import 'transfer_deal.dart';

class TransferMarketResult {
  TransferMarketResult({
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required List<TransferDeal> deals,
    required this.attemptedOffers,
  })  : players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates),
        deals = List.unmodifiable(deals);

  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final List<TransferDeal> deals;
  final int attemptedOffers;

  String get signature => [
        attemptedOffers,
        ...deals.map((deal) => deal.signature),
        ...financeStates.map((state) => state.signature),
      ].join('||');
}
