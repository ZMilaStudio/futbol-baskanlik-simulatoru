import '../match/match_result.dart';

class Fixture {
  const Fixture({
    required this.id,
    required this.seasonIndex,
    required this.round,
    required this.homeClubId,
    required this.awayClubId,
    this.result,
  });

  final String id;
  final int seasonIndex;
  final int round;
  final String homeClubId;
  final String awayClubId;
  final MatchResult? result;

  bool get isPlayed => result != null;

  Fixture withResult(MatchResult value) => Fixture(
        id: id,
        seasonIndex: seasonIndex,
        round: round,
        homeClubId: homeClubId,
        awayClubId: awayClubId,
        result: value,
      );
}
