import '../core/money.dart';

class TransferInstallment {
  const TransferInstallment({
    required this.dueSeasonIndex,
    required this.amount,
  });

  final int dueSeasonIndex;
  final Money amount;

  String get signature => '$dueSeasonIndex:${amount.minorUnits}';
}

class TransferInstallmentObligation {
  const TransferInstallmentObligation({
    required this.playerId,
    required this.fromClubId,
    required this.toClubId,
    required this.createdSeasonIndex,
    required this.installments,
  });

  final String playerId;
  final String fromClubId;
  final String toClubId;
  final int createdSeasonIndex;
  final List<TransferInstallment> installments;

  Money get totalFutureAmount => installments.fold(
        Money.zero,
        (total, installment) => total + installment.amount,
      );

  String get signature =>
      '$playerId|$fromClubId|$toClubId|$createdSeasonIndex|'
      '${installments.map((item) => item.signature).join(',')}';
}
