typedef ManagerPatienceProvider = int Function(String clubId, int seasonIndex);

class ManagerDismissalThresholds {
  const ManagerDismissalThresholds({
    required this.managerPatience,
    required this.boardBreakdownRelationship,
    required this.underperformanceGap,
    required this.underperformanceRelationship,
    required this.relegationRelationship,
  });

  final int managerPatience;
  final int boardBreakdownRelationship;
  final int underperformanceGap;
  final int underperformanceRelationship;
  final int relegationRelationship;

  String get signature =>
      'patience=$managerPatience:board=$boardBreakdownRelationship:'
      'gap=$underperformanceGap:underRel=$underperformanceRelationship:'
      'relegationRel=$relegationRelationship';
}

class ManagerDismissalPolicy {
  const ManagerDismissalPolicy();

  static const neutralPatience = 60;

  ManagerDismissalThresholds thresholds(int managerPatience) {
    final patience = managerPatience.clamp(20, 90).toInt();
    final tenPointOffset = (neutralPatience - patience) / 10.0;
    final board = (28 + tenPointOffset * 2)
        .round()
        .clamp(20, 36)
        .toInt();
    final underperformanceRelationship = (46 + tenPointOffset * 2)
        .round()
        .clamp(38, 54)
        .toInt();
    final relegationRelationship = (52 + tenPointOffset * 2)
        .round()
        .clamp(46, 60)
        .toInt();
    final underperformanceGap = patience <= 35
        ? 4
        : patience >= 80
            ? 6
            : 5;

    return ManagerDismissalThresholds(
      managerPatience: patience,
      boardBreakdownRelationship: board,
      underperformanceGap: underperformanceGap,
      underperformanceRelationship: underperformanceRelationship,
      relegationRelationship: relegationRelationship,
    );
  }
}
