import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../player/player.dart';
import 'loan_agreement.dart';

class LoanMarketResult {
  LoanMarketResult({
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
    required Iterable<LoanAgreement> agreements,
    required Iterable<TransferCashMovement> cashMovements,
  })  : players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates),
        agreements = List.unmodifiable(agreements),
        cashMovements = List.unmodifiable(cashMovements);

  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final List<LoanAgreement> agreements;
  final List<TransferCashMovement> cashMovements;
}
