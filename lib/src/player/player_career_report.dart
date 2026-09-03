import '../core/game_date.dart';
import '../league/club.dart';
import 'player.dart';
import 'player_career_season.dart';

class PlayerCareerReport {
  PlayerCareerReport({
    required this.careerSeed,
    required this.initialSeasonIndex,
    required this.startDate,
    required this.endDate,
    required this.initialPlayerCount,
    required List<PlayerCareerSeason> seasons,
    required List<Player> finalPlayers,
    required List<Club> finalClubs,
  })  : seasons = List.unmodifiable(seasons),
        finalPlayers = List.unmodifiable(finalPlayers),
        finalClubs = List.unmodifiable(finalClubs);

  final int careerSeed;
  final int initialSeasonIndex;
  final GameDate startDate;
  final GameDate endDate;
  final int initialPlayerCount;
  final List<PlayerCareerSeason> seasons;
  final List<Player> finalPlayers;
  final List<Club> finalClubs;

  int get seasonCount => seasons.length;

  int get totalMatches => seasons.fold(
        0,
        (total, season) => total + season.report.matchCount,
      );

  int get totalRetirements => seasons.fold(
        0,
        (total, season) => total + season.retiredAfterSeason.length,
      );

  int get totalYouthIntakes => seasons.fold(
        0,
        (total, season) => total + season.youthIntakeAfterSeason.length,
      );

  Map<String, int> get championships {
    final totals = <String, int>{};
    for (final season in seasons) {
      totals.update(
        season.report.championClubId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return Map.unmodifiable(totals);
  }
}
