enum ManagerChangeReason {
  performance,
  boardBreakdown,
  retirement,
}

class ManagerClubSeason {
  const ManagerClubSeason({
    required this.clubId,
    required this.managerId,
    required this.managerAge,
    required this.fitScore,
    required this.strengthImpact,
    required this.relationshipBefore,
    required this.relationshipAfter,
    required this.expectedPosition,
    required this.actualPosition,
    required this.changedAfterSeason,
  });

  final String clubId;
  final String managerId;
  final int managerAge;
  final double fitScore;
  final double strengthImpact;
  final double relationshipBefore;
  final double relationshipAfter;
  final int expectedPosition;
  final int actualPosition;
  final bool changedAfterSeason;

  String get signature =>
      '$clubId:$managerId:$managerAge:${fitScore.toStringAsFixed(3)}:'
      '${strengthImpact.toStringAsFixed(3)}:'
      '${relationshipBefore.toStringAsFixed(3)}>${relationshipAfter.toStringAsFixed(3)}:'
      '$expectedPosition>$actualPosition:$changedAfterSeason';
}

class ManagerChange {
  const ManagerChange({
    required this.clubId,
    required this.fromManagerId,
    required this.toManagerId,
    required this.reason,
  });

  final String clubId;
  final String fromManagerId;
  final String toManagerId;
  final ManagerChangeReason reason;

  String get signature =>
      '$clubId:$fromManagerId>$toManagerId:${reason.name}';
}

class ManagerCareerSeason {
  ManagerCareerSeason({
    required this.seasonIndex,
    required Iterable<ManagerClubSeason> clubs,
    required Iterable<ManagerChange> changesAfterSeason,
  })  : clubs = List.unmodifiable(clubs),
        changesAfterSeason = List.unmodifiable(changesAfterSeason);

  final int seasonIndex;
  final List<ManagerClubSeason> clubs;
  final List<ManagerChange> changesAfterSeason;

  String get signature {
    final sortedClubs = List<ManagerClubSeason>.of(clubs)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final sortedChanges = List<ManagerChange>.of(changesAfterSeason)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return 's$seasonIndex|${sortedClubs.map((club) => club.signature).join('|')}|'
        '${sortedChanges.map((change) => change.signature).join('|')}';
  }
}
