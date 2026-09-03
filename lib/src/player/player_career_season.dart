import '../core/game_date.dart';
import '../league/club.dart';
import '../season/season_report.dart';
import 'player.dart';

class PlayerCareerSeason {
  PlayerCareerSeason({
    required this.startDate,
    required this.endDate,
    required List<Club> clubs,
    required List<Player> players,
    required List<Player> retiredAfterSeason,
    required List<Player> youthIntakeAfterSeason,
    required this.report,
  })  : clubs = List.unmodifiable(clubs),
        players = List.unmodifiable(players),
        retiredAfterSeason = List.unmodifiable(retiredAfterSeason),
        youthIntakeAfterSeason = List.unmodifiable(youthIntakeAfterSeason);

  final GameDate startDate;
  final GameDate endDate;
  final List<Club> clubs;
  final List<Player> players;
  final List<Player> retiredAfterSeason;
  final List<Player> youthIntakeAfterSeason;
  final SeasonReport report;

  double get averageAge => players.isEmpty
      ? 0
      : players.fold<int>(0, (sum, player) => sum + player.age) /
          players.length;
}
