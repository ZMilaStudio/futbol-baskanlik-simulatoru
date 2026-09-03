import '../league/fixture.dart';
import '../league/standing_row.dart';

class SeasonReport {
  const SeasonReport({
    required this.seasonIndex,
    required this.seed,
    required this.championClubId,
    required this.table,
    required this.fixtures,
    required this.homeWins,
    required this.draws,
    required this.awayWins,
    required this.totalGoals,
  });

  final int seasonIndex;
  final int seed;
  final String championClubId;
  final List<StandingRow> table;
  final List<Fixture> fixtures;
  final int homeWins;
  final int draws;
  final int awayWins;
  final int totalGoals;

  int get matchCount => fixtures.length;
  double get averageGoalsPerMatch =>
      matchCount == 0 ? 0 : totalGoals / matchCount;

  Map<String, Object> toJson() => {
        'seasonIndex': seasonIndex,
        'seed': seed,
        'championClubId': championClubId,
        'matchCount': matchCount,
        'homeWins': homeWins,
        'draws': draws,
        'awayWins': awayWins,
        'totalGoals': totalGoals,
        'averageGoalsPerMatch': averageGoalsPerMatch,
        'table': table.map((row) => row.toJson()).toList(),
      };
}
