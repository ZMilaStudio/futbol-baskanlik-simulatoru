import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import 'world_career_season.dart';
import 'world_league.dart';

abstract interface class WorldCareerHooks {
  List<Club> adjustClubsForSeason({
    required int seasonIndex,
    required List<Club> squadClubs,
    required List<Player> players,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  });

  void onSeasonCompleted({
    required int seasonIndex,
    required bool hasNextSeason,
    required List<Club> squadClubs,
    required List<Club> effectiveClubs,
    required List<Player> players,
    required List<WorldLeague> leaguesBeforeSeason,
    required List<WorldLeague> leaguesForNextSeason,
    required List<LeagueSeasonSnapshot> leagueResults,
    required List<ClubFinanceSeason> finances,
  });
}

class NoopWorldCareerHooks implements WorldCareerHooks {
  const NoopWorldCareerHooks();

  @override
  List<Club> adjustClubsForSeason({
    required int seasonIndex,
    required List<Club> squadClubs,
    required List<Player> players,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) =>
      squadClubs;

  @override
  void onSeasonCompleted({
    required int seasonIndex,
    required bool hasNextSeason,
    required List<Club> squadClubs,
    required List<Club> effectiveClubs,
    required List<Player> players,
    required List<WorldLeague> leaguesBeforeSeason,
    required List<WorldLeague> leaguesForNextSeason,
    required List<LeagueSeasonSnapshot> leagueResults,
    required List<ClubFinanceSeason> finances,
  }) {}
}
