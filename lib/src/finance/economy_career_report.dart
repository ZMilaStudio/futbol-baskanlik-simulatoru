import '../core/money.dart';
import '../player/player_career_report.dart';
import 'club_finance_state.dart';
import 'economy_career_season.dart';
import 'financial_health.dart';

class EconomyCareerReport {
  EconomyCareerReport({
    required this.playerCareer,
    required List<ClubFinanceState> initialStates,
    required List<EconomyCareerSeason> seasons,
    required List<ClubFinanceState> finalStates,
  })  : initialStates = List.unmodifiable(initialStates),
        seasons = List.unmodifiable(seasons),
        finalStates = List.unmodifiable(finalStates);

  final PlayerCareerReport playerCareer;
  final List<ClubFinanceState> initialStates;
  final List<EconomyCareerSeason> seasons;
  final List<ClubFinanceState> finalStates;

  int get seasonCount => seasons.length;
  int get totalMatches => playerCareer.totalMatches;

  Money get totalEmergencyBorrowing {
    var total = Money.zero;
    for (final season in seasons) {
      for (final club in season.clubs) {
        total += club.emergencyBorrowing;
      }
    }
    return total;
  }

  Money get finalTotalCash => finalStates.fold(
        Money.zero,
        (sum, state) => sum + state.cash,
      );

  Money get finalTotalDebt => finalStates.fold(
        Money.zero,
        (sum, state) => sum + state.debt,
      );

  Map<FinancialHealth, int> get finalHealthDistribution {
    final counts = <FinancialHealth, int>{};
    if (seasons.isEmpty) {
      return counts;
    }
    for (final club in seasons.last.clubs) {
      counts.update(
        club.health,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return Map.unmodifiable(counts);
  }

  String get signature => [
        ...playerCareer.seasons.map((season) => season.report.championClubId),
        ...finalStates.map((state) => state.signature),
        totalEmergencyBorrowing.minorUnits.toString(),
      ].join('||');
}
