class ManagerAssignment {
  const ManagerAssignment({
    required this.clubId,
    required this.managerId,
    required this.appointedSeasonIndex,
    required this.completedSeasons,
    required this.boardRelationship,
  });

  final String clubId;
  final String managerId;
  final int appointedSeasonIndex;
  final int completedSeasons;
  final double boardRelationship;

  ManagerAssignment copyWith({
    String? managerId,
    int? appointedSeasonIndex,
    int? completedSeasons,
    double? boardRelationship,
  }) =>
      ManagerAssignment(
        clubId: clubId,
        managerId: managerId ?? this.managerId,
        appointedSeasonIndex:
            appointedSeasonIndex ?? this.appointedSeasonIndex,
        completedSeasons: completedSeasons ?? this.completedSeasons,
        boardRelationship: boardRelationship ?? this.boardRelationship,
      );

  String get signature =>
      '$clubId|$managerId|$appointedSeasonIndex|$completedSeasons|'
      '${boardRelationship.toStringAsFixed(3)}';
}
