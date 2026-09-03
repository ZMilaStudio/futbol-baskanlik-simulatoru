import '../core/money.dart';
import 'financial_health.dart';

class ClubFinanceSeason {
  const ClubFinanceSeason({
    required this.clubId,
    required this.openingCash,
    required this.openingDebt,
    required this.centralRevenue,
    required this.sponsorRevenue,
    required this.matchdayRevenue,
    required this.prizeRevenue,
    required this.wageExpense,
    required this.operatingExpense,
    required this.interestExpense,
    required this.principalRepaid,
    required this.emergencyBorrowing,
    required this.closingCash,
    required this.closingDebt,
    required this.health,
  });

  final String clubId;
  final Money openingCash;
  final Money openingDebt;
  final Money centralRevenue;
  final Money sponsorRevenue;
  final Money matchdayRevenue;
  final Money prizeRevenue;
  final Money wageExpense;
  final Money operatingExpense;
  final Money interestExpense;
  final Money principalRepaid;
  final Money emergencyBorrowing;
  final Money closingCash;
  final Money closingDebt;
  final FinancialHealth health;

  Money get totalRevenue =>
      centralRevenue + sponsorRevenue + matchdayRevenue + prizeRevenue;

  Money get profitAndLossExpenses =>
      wageExpense + operatingExpense + interestExpense;

  Money get operatingResult => totalRevenue - profitAndLossExpenses;

  Money get expectedClosingCash =>
      openingCash +
      totalRevenue -
      profitAndLossExpenses -
      principalRepaid +
      emergencyBorrowing;

  Money get expectedClosingDebt =>
      openingDebt - principalRepaid + emergencyBorrowing;

  String get signature =>
      '$clubId|${openingCash.minorUnits}|${openingDebt.minorUnits}|'
      '${totalRevenue.minorUnits}|${profitAndLossExpenses.minorUnits}|'
      '${principalRepaid.minorUnits}|${emergencyBorrowing.minorUnits}|'
      '${closingCash.minorUnits}|${closingDebt.minorUnits}|${health.name}';
}
