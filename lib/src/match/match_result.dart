class MatchResult {
  const MatchResult({
    required this.homeGoals,
    required this.awayGoals,
    required this.homeExpectedGoals,
    required this.awayExpectedGoals,
    required this.matchSeed,
  });

  final int homeGoals;
  final int awayGoals;
  final double homeExpectedGoals;
  final double awayExpectedGoals;
  final int matchSeed;
}
