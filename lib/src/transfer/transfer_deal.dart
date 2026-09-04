import '../core/money.dart';
import '../player/player_position.dart';
import 'transfer_installment.dart';

class TransferDeal {
  const TransferDeal({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.fromClubId,
    required this.toClubId,
    required this.marketValue,
    required this.fee,
    Money? upfrontFee,
    this.installments = const [],
  }) : upfrontFee = upfrontFee ?? fee;

  final String playerId;
  final String playerName;
  final PlayerPosition position;
  final String fromClubId;
  final String toClubId;
  final Money marketValue;
  final Money fee;
  final Money upfrontFee;
  final List<TransferInstallment> installments;

  bool get isInstallmentDeal => installments.isNotEmpty;

  Money get futureInstallmentTotal => installments.fold(
        Money.zero,
        (total, installment) => total + installment.amount,
      );

  String get signature {
    final legacy =
        '$playerId|$fromClubId|$toClubId|${position.name}|'
        '${marketValue.minorUnits}|${fee.minorUnits}';
    if (!isInstallmentDeal && upfrontFee == fee) return legacy;
    return '$legacy|upfront=${upfrontFee.minorUnits}|'
        '${installments.map((item) => item.signature).join(',')}';
  }
}
