import '../core/money.dart';

class LoanAgreement {
  const LoanAgreement({
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

  bool isActiveDuring(int seasonIndex) =>
      seasonIndex >= startSeasonIndex && seasonIndex < endSeasonIndex;

  String get signature =>
      '$playerId|$parentClubId|$loanClubId|$startSeasonIndex|$endSeasonIndex|'
      '${loanFee.minorUnits}|$loanClubWageShareBps';
}
