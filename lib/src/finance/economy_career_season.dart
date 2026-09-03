import 'club_finance_season.dart';

class EconomyCareerSeason {
  EconomyCareerSeason({
    required this.seasonIndex,
    required List<ClubFinanceSeason> clubs,
  }) : clubs = List.unmodifiable(clubs);

  final int seasonIndex;
  final List<ClubFinanceSeason> clubs;

  ClubFinanceSeason forClub(String clubId) =>
      clubs.firstWhere((club) => club.clubId == clubId);
}
