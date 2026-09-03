import '../core/money.dart';
import '../player/player_position.dart';

class TransferDeal {
  const TransferDeal({
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.fromClubId,
    required this.toClubId,
    required this.marketValue,
    required this.fee,
  });

  final String playerId;
  final String playerName;
  final PlayerPosition position;
  final String fromClubId;
  final String toClubId;
  final Money marketValue;
  final Money fee;

  String get signature =>
      '$playerId|$fromClubId|$toClubId|${position.name}|'
      '${marketValue.minorUnits}|${fee.minorUnits}';
}
