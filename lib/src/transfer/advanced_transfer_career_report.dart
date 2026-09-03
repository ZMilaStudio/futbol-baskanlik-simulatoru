import '../contract/contract_event.dart';
import '../contract/player_contract.dart';
import '../core/money.dart';
import '../world/world_career_report.dart';
import 'loan_agreement.dart';
import 'transfer_installment.dart';

class AdvancedTransferCareerReport {
  AdvancedTransferCareerReport({
    required this.worldReport,
    required Iterable<PlayerContract> activeContracts,
    required Iterable<ContractEvent> contractEvents,
    required Iterable<LoanAgreement> loanHistory,
    required Iterable<LoanAgreement> activeLoans,
    required Iterable<TransferInstallmentObligation> installmentObligations,
  })  : activeContracts = List.unmodifiable(activeContracts),
        contractEvents = List.unmodifiable(contractEvents),
        loanHistory = List.unmodifiable(loanHistory),
        activeLoans = List.unmodifiable(activeLoans),
        installmentObligations = List.unmodifiable(installmentObligations);

  final WorldCareerReport worldReport;
  final List<PlayerContract> activeContracts;
  final List<ContractEvent> contractEvents;
  final List<LoanAgreement> loanHistory;
  final List<LoanAgreement> activeLoans;
  final List<TransferInstallmentObligation> installmentObligations;

  int get installmentDeals => worldReport.seasons
      .expand((season) => season.transfersAfterSeason)
      .where((deal) => deal.isInstallmentDeal)
      .length;

  int get totalLoans => loanHistory.length;

  Money get totalLoanFees => loanHistory.fold(
        Money.zero,
        (total, loan) => total + loan.loanFee,
      );

  Money get totalInstallmentCommitment => installmentObligations.fold(
        Money.zero,
        (total, obligation) => total + obligation.totalFutureAmount,
      );

  Money get totalInstallmentsPaid => worldReport.seasons.fold(
        Money.zero,
        (total, season) =>
            total +
            season.finances.fold(
              Money.zero,
              (seasonTotal, finance) =>
                  seasonTotal + finance.transferInstallmentExpense,
            ),
      );

  Money get outstandingInstallments {
    final lastSeasonIndex = worldReport.seasons.last.seasonIndex;
    return installmentObligations.fold(Money.zero, (total, obligation) {
      return total +
          obligation.installments
              .where((item) => item.dueSeasonIndex > lastSeasonIndex)
              .fold(Money.zero, (sum, item) => sum + item.amount);
    });
  }

  double get averageLoanWageShareBps {
    if (loanHistory.isEmpty) return 0;
    return loanHistory.fold<int>(
          0,
          (total, loan) => total + loan.loanClubWageShareBps,
        ) /
        loanHistory.length;
  }

  String get signature {
    final buffer = StringBuffer(worldReport.signature);
    final contracts = List<PlayerContract>.of(activeContracts)
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    for (final contract in contracts) {
      buffer.write('|m8contract=${contract.signature}');
    }
    for (final loan in loanHistory) {
      buffer.write('|loan=${loan.signature}');
    }
    for (final obligation in installmentObligations) {
      buffer.write('|installment=${obligation.signature}');
    }
    return buffer.toString();
  }
}
