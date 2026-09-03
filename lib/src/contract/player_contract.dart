import '../core/money.dart';

class PlayerContract {
  const PlayerContract({
    required this.playerId,
    required this.clubId,
    required this.startSeasonIndex,
    required this.endSeasonIndex,
    required this.annualWage,
  });

  final String playerId;
  final String clubId;
  final int startSeasonIndex;
  final int endSeasonIndex;
  final Money annualWage;

  bool isActiveDuring(int seasonIndex) =>
      seasonIndex >= startSeasonIndex && seasonIndex < endSeasonIndex;

  int yearsRemainingAt(int seasonIndex) {
    final remaining = endSeasonIndex - seasonIndex;
    return remaining < 0 ? 0 : remaining;
  }

  String get signature =>
      '$playerId|$clubId|$startSeasonIndex|$endSeasonIndex|'
      '${annualWage.minorUnits}';
}
