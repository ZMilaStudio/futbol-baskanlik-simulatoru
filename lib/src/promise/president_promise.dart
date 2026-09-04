enum PresidentPromiseType {
  reduceDebt,
  stabilizeFinances,
  finishTopHalf,
  avoidRelegation,
  earnPromotion,
  challengeTitle,
}

class PresidentPromise {
  const PresidentPromise({
    required this.id,
    required this.clubId,
    required this.seasonIndex,
    required this.type,
    this.targetLeaguePosition,
    this.targetDebtReductionBps,
  });

  final String id;
  final String clubId;
  final int seasonIndex;
  final PresidentPromiseType type;
  final int? targetLeaguePosition;
  final int? targetDebtReductionBps;

  String get signature =>
      '$id:$clubId:s$seasonIndex:${type.name}:'
      'pos=${targetLeaguePosition ?? 0}:debtBps=${targetDebtReductionBps ?? 0}';
}
