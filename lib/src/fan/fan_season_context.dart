import '../core/money.dart';
import '../finance/financial_health.dart';
import '../world/league_tier.dart';

class FanSeasonContext {
  const FanSeasonContext({
    required this.clubId,
    required this.seasonIndex,
    required this.tier,
    required this.leaguePosition,
    required this.leagueSize,
    required this.clubStrength,
    required this.financialHealth,
    required this.closingCash,
    required this.closingDebt,
    required this.emergencyBorrowing,
    required this.permanentBuys,
    required this.permanentSales,
    required this.installmentBuys,
    required this.loanIns,
    required this.loanOuts,
    required this.transferSpend,
    required this.transferIncome,
    required this.promoted,
    required this.relegated,
    required this.hasTransferWindow,
  });

  final String clubId;
  final int seasonIndex;
  final LeagueTier tier;
  final int leaguePosition;
  final int leagueSize;
  final double clubStrength;
  final FinancialHealth financialHealth;
  final Money closingCash;
  final Money closingDebt;
  final Money emergencyBorrowing;
  final int permanentBuys;
  final int permanentSales;
  final int installmentBuys;
  final int loanIns;
  final int loanOuts;
  final Money transferSpend;
  final Money transferIncome;
  final bool promoted;
  final bool relegated;
  final bool hasTransferWindow;

  bool get topQuarter => leaguePosition <= ((leagueSize + 3) ~/ 4);
  bool get bottomQuarter => leaguePosition > ((leagueSize * 3) ~/ 4);
  int get totalIncoming => permanentBuys + loanIns;

  bool get financiallyStressed =>
      financialHealth == FinancialHealth.tight ||
      financialHealth == FinancialHealth.debtCrisis ||
      (emergencyBorrowing > Money.zero && closingDebt > closingCash);

  int get transferSpendBpsOfCash {
    if (closingCash <= Money.zero) {
      return transferSpend > Money.zero ? 10000 : 0;
    }
    return (transferSpend.minorUnits * 10000) ~/ closingCash.minorUnits;
  }

  String get signature =>
      '$clubId:$seasonIndex:${tier.level}:$leaguePosition/$leagueSize:'
      '${clubStrength.toStringAsFixed(2)}:${financialHealth.name}:'
      '${closingCash.minorUnits}:${closingDebt.minorUnits}:'
      '${emergencyBorrowing.minorUnits}:$permanentBuys:$permanentSales:'
      '$installmentBuys:$loanIns:$loanOuts:${transferSpend.minorUnits}:'
      '${transferIncome.minorUnits}:$promoted:$relegated:$hasTransferWindow';
}
