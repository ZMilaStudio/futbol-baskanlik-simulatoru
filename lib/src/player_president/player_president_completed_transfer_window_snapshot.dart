import '../core/money.dart';
import '../player/player_position.dart';

final class PlayerPresidentCompletedTransferInstallment {
  const PlayerPresidentCompletedTransferInstallment({
    required this.dueSeasonIndex,
    required this.amount,
  });
  final int dueSeasonIndex;
  final Money amount;
  String get signature => '$dueSeasonIndex:${amount.minorUnits}';
}

/// Detached values from one actual permanent deal. No engine object is retained.
final class PlayerPresidentCompletedTransferDeal {
  PlayerPresidentCompletedTransferDeal({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.fromClubId,
    required this.toClubId,
    required this.marketValue,
    required this.fee,
    required this.upfrontFee,
    required Iterable<PlayerPresidentCompletedTransferInstallment> installments,
  }) : installments = List.unmodifiable(installments);
  final String playerId;
  final String playerName;
  final PlayerPosition position;
  final String fromClubId;
  final String toClubId;
  final Money marketValue;
  final Money fee;
  final Money upfrontFee;
  final List<PlayerPresidentCompletedTransferInstallment> installments;
  String get signature =>
      '$playerId|$playerName|${position.name}|$fromClubId|$toClubId|'
      '${marketValue.minorUnits}|${fee.minorUnits}|${upfrontFee.minorUnits}|'
      '${installments.map((row) => row.signature).join(',')}';
}

/// One newly agreed loan, without returns, balances or inferred direction.
final class PlayerPresidentCompletedTransferLoan {
  const PlayerPresidentCompletedTransferLoan({
    required this.playerId,
    required this.parentClubId,
    required this.loanClubId,
    required this.startSeasonIndex,
    required this.endSeasonIndex,
    required this.loanFee,
    required this.loanClubWageShareBps,
  });
  final String playerId;
  final String parentClubId;
  final String loanClubId;
  final int startSeasonIndex;
  final int endSeasonIndex;
  final Money loanFee;
  final int loanClubWageShareBps;
  String get signature =>
      '$playerId|$parentClubId|$loanClubId|$startSeasonIndex|$endSeasonIndex|'
      '${loanFee.minorUnits}|$loanClubWageShareBps';
}

/// Immutable observations in original producer order; never transfer authority.
final class PlayerPresidentCompletedTransferWindowSnapshot {
  PlayerPresidentCompletedTransferWindowSnapshot({
    required this.completedSeasonIndex,
    required this.targetSeasonIndex,
    required this.controlledClubId,
    required Iterable<PlayerPresidentCompletedTransferDeal> transfers,
    required Iterable<PlayerPresidentCompletedTransferLoan> loans,
  })  : transfers = List.unmodifiable(transfers),
        loans = List.unmodifiable(loans);
  final int completedSeasonIndex;
  final int targetSeasonIndex;
  final String controlledClubId;
  final List<PlayerPresidentCompletedTransferDeal> transfers;
  final List<PlayerPresidentCompletedTransferLoan> loans;
  String get signature =>
      '$completedSeasonIndex|$targetSeasonIndex|$controlledClubId|'
      '${transfers.map((row) => row.signature).join('||')}|'
      '${loans.map((row) => row.signature).join('||')}';
}
