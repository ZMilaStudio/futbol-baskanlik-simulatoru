import '../core/money.dart';
import '../transfer/transfer_budget_policy.dart';
import 'president_management_profile.dart';

class PresidentFinancialDisciplineTransferPolicy {
  const PresidentFinancialDisciplineTransferPolicy();

  TransferBudgetPolicy forProfile(PresidentManagementProfile profile) =>
      forDiscipline(profile.financialDiscipline);

  TransferBudgetPolicy forDiscipline(int financialDiscipline) {
    final discipline = financialDiscipline.clamp(20, 90).toInt();
    final deltaFromNeutral = discipline - 60;
    final reserveUnits = 2000000 + deltaFromNeutral * 30000;
    final windowSpendCapBps =
        (3500 - deltaFromNeutral * 25).clamp(2500, 4700).toInt();
    final totalCommitmentCapBps =
        (9000 - deltaFromNeutral * 50).clamp(7000, 11500).toInt();

    return TransferBudgetPolicy(
      reserveCash: Money.fromUnits(reserveUnits),
      windowSpendCapBps: windowSpendCapBps,
      totalCommitmentCapBps: totalCommitmentCapBps,
    );
  }
}
