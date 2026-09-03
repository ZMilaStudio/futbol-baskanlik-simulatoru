import '../core/money.dart';

class ClubFinanceState {
  const ClubFinanceState({
    required this.clubId,
    required this.cash,
    required this.debt,
  });

  final String clubId;
  final Money cash;
  final Money debt;

  String get signature => '$clubId|${cash.minorUnits}|${debt.minorUnits}';
}
