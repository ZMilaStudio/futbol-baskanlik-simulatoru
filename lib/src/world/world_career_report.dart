import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../finance/financial_health.dart';
import '../league/club.dart';
import '../player/player.dart';
import 'league_tier.dart';
import 'world_career_season.dart';
import 'world_league.dart';

class WorldCareerReport {
  WorldCareerReport({
    required this.careerSeed,
    required this.initialPlayerCount,
    required this.initialFinanceStates,
    required this.initialLeagues,
    required this.seasons,
    required this.finalPlayers,
    required this.finalFinanceStates,
    required this.finalClubs,
    required this.finalLeagues,
  });

  final int careerSeed;
  final int initialPlayerCount;
  final List<ClubFinanceState> initialFinanceStates;
  final List<WorldLeague> initialLeagues;
  final List<WorldCareerSeason> seasons;
  final List<Player> finalPlayers;
  final List<ClubFinanceState> finalFinanceStates;
  final List<Club> finalClubs;
  final List<WorldLeague> finalLeagues;

  int get seasonCount => seasons.length;
  int get initialClubCount =>
      initialLeagues.fold(0, (sum, league) => sum + league.clubIds.length);
  int get totalMatches =>
      seasons.fold(0, (sum, season) => sum + season.matchCount);
  int get totalTransfers => seasons.fold(
        0,
        (sum, season) => sum + season.transfersAfterSeason.length,
      );
  int get totalRetirements => seasons.fold(
        0,
        (sum, season) => sum + season.retiredAfterSeason.length,
      );
  int get totalYouthIntakes => seasons.fold(
        0,
        (sum, season) => sum + season.youthIntakeAfterSeason.length,
      );
  int get totalMovements => seasons.fold(
        0,
        (sum, season) => sum + season.movementsAfterSeason.length,
      );

  Money get totalTransferVolume {
    var total = Money.zero;
    for (final season in seasons) {
      for (final deal in season.transfersAfterSeason) {
        total += deal.fee;
      }
    }
    return total;
  }

  Money get totalEmergencyBorrowing {
    var total = Money.zero;
    for (final season in seasons) {
      for (final finance in season.finances) {
        total += finance.emergencyBorrowing;
      }
    }
    return total;
  }

  Money get finalTotalCash => finalFinanceStates.fold(
        Money.zero,
        (total, state) => total + state.cash,
      );
  Money get finalTotalDebt => finalFinanceStates.fold(
        Money.zero,
        (total, state) => total + state.debt,
      );

  Map<FinancialHealth, int> get finalHealthCounts {
    final counts = <FinancialHealth, int>{};
    for (final finance in seasons.last.finances) {
      counts.update(
        finance.health,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  Map<String, int> get firstTierChampions {
    final counts = <String, int>{};
    for (final season in seasons) {
      final first = season.leagueResults
          .firstWhere((result) => result.tier == LeagueTier.first);
      counts.update(
        first.report.championClubId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  String get signature {
    final buffer = StringBuffer()
      ..write('seed=$careerSeed|players=$initialPlayerCount');
    for (final season in seasons) {
      buffer.write('|s${season.seasonIndex}');
      final leagueResults = List<LeagueSeasonSnapshot>.of(season.leagueResults)
        ..sort((a, b) => a.tier.level.compareTo(b.tier.level));
      for (final result in leagueResults) {
        buffer.write(
          ':l${result.tier.level}=${result.report.championClubId}',
        );
      }
      for (final movement in season.movementsAfterSeason) {
        buffer.write(':m=${movement.signature}');
      }
      for (final deal in season.transfersAfterSeason) {
        buffer.write(
          ':t=${deal.playerId}:${deal.fromClubId}>${deal.toClubId}:${deal.fee.minorUnits}',
        );
      }
    }
    final finances = List<ClubFinanceState>.of(finalFinanceStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final state in finances) {
      buffer.write(
        '|f=${state.clubId}:${state.cash.minorUnits}:${state.debt.minorUnits}',
      );
    }
    return buffer.toString();
  }
}
