import '../core/game_date.dart';
import '../season/season_report.dart';

class CareerSeason {
  CareerSeason({
    required this.startDate,
    required this.endDate,
    required Map<String, double> clubStrengths,
    required this.report,
  }) : clubStrengths = Map.unmodifiable(clubStrengths);

  final GameDate startDate;
  final GameDate endDate;
  final Map<String, double> clubStrengths;
  final SeasonReport report;
}
