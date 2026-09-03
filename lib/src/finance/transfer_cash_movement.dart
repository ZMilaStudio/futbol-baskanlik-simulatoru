import '../core/money.dart';

class TransferCashMovement {
  const TransferCashMovement({
    required this.fromClubId,
    required this.toClubId,
    required this.amount,
    required this.reason,
    required this.referenceId,
  });

  final String fromClubId;
  final String toClubId;
  final Money amount;
  final String reason;
  final String referenceId;

  String get signature =>
      '$fromClubId|$toClubId|${amount.minorUnits}|$reason|$referenceId';
}
