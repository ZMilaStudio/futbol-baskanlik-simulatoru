import '../core/money.dart';

enum ContractEventType {
  initial,
  youth,
  renewal,
  released,
  freeAgentSigning,
  transferContract,
}

class ContractEvent {
  const ContractEvent({
    required this.seasonIndex,
    required this.playerId,
    required this.type,
    required this.fromClubId,
    required this.toClubId,
    required this.annualWage,
    required this.endSeasonIndex,
  });

  final int seasonIndex;
  final String playerId;
  final ContractEventType type;
  final String? fromClubId;
  final String? toClubId;
  final Money? annualWage;
  final int? endSeasonIndex;

  String get signature =>
      '$seasonIndex|$playerId|${type.name}|${fromClubId ?? '-'}|'
      '${toClubId ?? '-'}|${annualWage?.minorUnits ?? -1}|'
      '${endSeasonIndex ?? -1}';
}
