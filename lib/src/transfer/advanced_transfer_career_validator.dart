import '../core/money.dart';
import '../world/world_career_validator.dart';
import 'advanced_transfer_career_report.dart';

class AdvancedTransferCareerValidator {
  const AdvancedTransferCareerValidator({
    this.worldValidator = const WorldCareerValidator(),
  });

  final WorldCareerValidator worldValidator;

  List<String> validate(AdvancedTransferCareerReport report) {
    final issues = <String>[
      ...worldValidator.validate(report.worldReport),
    ];
    if (report.worldReport.seasons.isEmpty) return issues;

    final finalSeasonIndex = report.worldReport.seasons.last.seasonIndex;
    final finalPlayersById = {
      for (final player in report.worldReport.finalPlayers) player.id: player,
    };
    final activeLoanByPlayer = {
      for (final loan in report.activeLoans) loan.playerId: loan,
    };
    if (activeLoanByPlayer.length != report.activeLoans.length) {
      issues.add('A player has multiple active loans.');
    }

    final contractByPlayer = <String, dynamic>{};
    for (final contract in report.activeContracts) {
      if (contractByPlayer.containsKey(contract.playerId)) {
        issues.add('Duplicate active contract for ${contract.playerId}.');
        continue;
      }
      contractByPlayer[contract.playerId] = contract;
      final player = finalPlayersById[contract.playerId];
      if (player == null) {
        issues.add('Contract references missing final player ${contract.playerId}.');
        continue;
      }
      if (player.isFreeAgent) {
        issues.add('Free agent ${player.id} has an active contract.');
        continue;
      }
      final loan = activeLoanByPlayer[player.id];
      if (loan != null && loan.isActiveDuring(finalSeasonIndex)) {
        if (contract.clubId != loan.parentClubId ||
            player.clubId != loan.loanClubId) {
          issues.add('Final loan contract mismatch for ${player.id}.');
        }
      } else if (player.clubId != contract.clubId) {
        issues.add('Final contract club mismatch for ${player.id}.');
      }
      if (!contract.isActiveDuring(finalSeasonIndex) ||
          contract.annualWage <= Money.zero) {
        issues.add('Invalid final contract for ${player.id}.');
      }
    }

    for (final player in report.worldReport.finalPlayers) {
      final hasContract = contractByPlayer.containsKey(player.id);
      if (player.isFreeAgent && hasContract) {
        issues.add('Final free agent ${player.id} must not have a contract.');
      }
      if (!player.isFreeAgent && !hasContract) {
        issues.add('Final club player ${player.id} is missing a contract.');
      }
    }

    final loanSeasonKeys = <String>{};
    for (final loan in report.loanHistory) {
      final key = '${loan.playerId}|${loan.startSeasonIndex}';
      if (!loanSeasonKeys.add(key)) {
        issues.add('Duplicate loan season for ${loan.playerId}.');
      }
      if (loan.parentClubId == loan.loanClubId ||
          loan.endSeasonIndex != loan.startSeasonIndex + 1 ||
          loan.loanFee <= Money.zero ||
          loan.loanClubWageShareBps < 4500 ||
          loan.loanClubWageShareBps > 8000) {
        issues.add('Invalid loan agreement for ${loan.playerId}.');
        continue;
      }
      final season = report.worldReport.seasons
          .where((item) => item.seasonIndex == loan.startSeasonIndex)
          .firstOrNull;
      if (season != null) {
        final player = season.players
            .where((item) => item.id == loan.playerId)
            .firstOrNull;
        if (player == null || player.clubId != loan.loanClubId) {
          issues.add('Loan roster mismatch for ${loan.playerId}.');
        }
      }
    }

    final transferByKey = <String, dynamic>{};
    for (final season in report.worldReport.seasons) {
      for (final deal in season.transfersAfterSeason) {
        transferByKey[
          '${season.seasonIndex}|${deal.playerId}|${deal.fromClubId}|${deal.toClubId}'
        ] = deal;
      }
    }
    final expectedIncome = <String, Money>{};
    final expectedExpense = <String, Money>{};
    for (final obligation in report.installmentObligations) {
      final key =
          '${obligation.createdSeasonIndex}|${obligation.playerId}|${obligation.fromClubId}|${obligation.toClubId}';
      final deal = transferByKey[key];
      if (deal == null || !deal.isInstallmentDeal) {
        issues.add('Installment obligation has no source deal ${obligation.playerId}.');
        continue;
      }
      if (obligation.totalFutureAmount != deal.futureInstallmentTotal) {
        issues.add('Installment obligation total mismatch ${obligation.playerId}.');
      }
      for (final installment in obligation.installments) {
        if (installment.amount <= Money.zero ||
            installment.dueSeasonIndex <= obligation.createdSeasonIndex) {
          issues.add('Invalid installment schedule ${obligation.playerId}.');
          continue;
        }
        final incomeKey =
            '${installment.dueSeasonIndex}|${obligation.fromClubId}';
        final expenseKey =
            '${installment.dueSeasonIndex}|${obligation.toClubId}';
        expectedIncome[incomeKey] =
            (expectedIncome[incomeKey] ?? Money.zero) + installment.amount;
        expectedExpense[expenseKey] =
            (expectedExpense[expenseKey] ?? Money.zero) + installment.amount;
      }
    }

    for (final season in report.worldReport.seasons) {
      for (final finance in season.finances) {
        final key = '${season.seasonIndex}|${finance.clubId}';
        final expectedIn = expectedIncome[key] ?? Money.zero;
        final expectedOut = expectedExpense[key] ?? Money.zero;
        if (finance.transferInstallmentIncome != expectedIn) {
          issues.add('Installment income mismatch $key.');
        }
        if (finance.transferInstallmentExpense != expectedOut) {
          issues.add('Installment expense mismatch $key.');
        }
        if (finance.expectedClosingCash != finance.closingCash ||
            finance.expectedClosingDebt != finance.closingDebt) {
          issues.add('Finance equation mismatch $key.');
        }
      }
    }

    if (report.totalInstallmentsPaid > report.totalInstallmentCommitment) {
      issues.add('Paid installments exceed committed installments.');
    }
    if (report.installmentDeals != report.installmentObligations.length) {
      issues.add('Installment deal/obligation count mismatch.');
    }

    return issues;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
