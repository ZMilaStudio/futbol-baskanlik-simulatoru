import '../core/game_date.dart';
import '../league/club.dart';
import 'career_season.dart';

class CareerReport {
  CareerReport({
    required this.careerSeed,
    required this.initialSeasonIndex,
    required this.startDate,
    required this.endDate,
    required List<CareerSeason> seasons,
    required List<Club> finalClubs,
  })  : seasons = List.unmodifiable(seasons),
        finalClubs = List.unmodifiable(finalClubs);

  final int careerSeed;
  final int initialSeasonIndex;
  final GameDate startDate;
  final GameDate endDate;
  final List<CareerSeason> seasons;
  final List<Club> finalClubs;

  int get seasonCount => seasons.length;

  int get totalMatches => seasons.fold(
        0,
        (total, season) => total + season.report.matchCount,
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
