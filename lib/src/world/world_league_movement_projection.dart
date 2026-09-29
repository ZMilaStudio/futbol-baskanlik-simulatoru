import 'league_tier.dart';
import 'world_career_season.dart';
import 'world_league.dart';

/// Detached end-of-season movement projection; never publishes a next-world state.
class WorldLeagueMovementResult {
  WorldLeagueMovementResult({
    required this.hasNextSeason,
    required Iterable<WorldLeague> nextLeagues,
    required Iterable<LeagueMovement> movements,
  }) : nextLeagues = List<WorldLeague>.unmodifiable(nextLeagues),
       movements = List<LeagueMovement>.unmodifiable(movements);

  final bool hasNextSeason;
  final List<WorldLeague> nextLeagues;
  final List<LeagueMovement> movements;
}

/// The single M5 legacy promotion/relegation rule, shared with B2.
/// Ordering is historical: second→first, first→second, third→second,
/// second→third. Future-season policy is explicit, not inferred from a table.
class WorldLeagueMovementProjection {
  const WorldLeagueMovementProjection();

  WorldLeagueMovementResult project({
    required List<WorldLeague> currentLeagues,
    required List<LeagueSeasonSnapshot> leagueResults,
    required bool hasNextSeason,
  }) {
    if (currentLeagues.length != 3 || leagueResults.length != 3 ||
        currentLeagues.map((league) => league.tier).toSet().length != 3 ||
        leagueResults.map((result) => result.tier).toSet().length != 3) {
      throw StateError('Movement requires three unique league tiers/results.');
    }
    final leagueByTier = {for (final league in currentLeagues) league.tier: league};
    final reportByTier = {for (final result in leagueResults) result.tier: result.report};
    final members = <String>{};
    for (final tier in LeagueTier.values) {
      final league = leagueByTier[tier];
      final report = reportByTier[tier];
      if (league == null || report == null ||
          league.clubIds.length != 16 || league.clubIds.toSet().length != 16 ||
          report.table.length != 16 ||
          report.table.map((row) => row.clubId).toSet().length != 16 ||
          report.table.map((row) => row.clubId).toSet().difference(league.clubIds.toSet()).isNotEmpty ||
          report.table.any((row) => row.played != 30) ||
          report.championClubId != report.table.first.clubId) {
        throw StateError('Movement table does not match opening membership.');
      }
      for (final id in league.clubIds) {
        if (!members.add(id)) {
          throw StateError('Movement contains duplicate world member.');
        }
      }
    }
    if (members.length != 48) throw StateError('Movement requires 48 clubs.');
    if (!hasNextSeason) {
      return WorldLeagueMovementResult(
        hasNextSeason: false,
        nextLeagues: currentLeagues,
        movements: const <LeagueMovement>[],
      );
    }

    final first = leagueByTier[LeagueTier.first]!;
    final second = leagueByTier[LeagueTier.second]!;
    final third = leagueByTier[LeagueTier.third]!;
    final firstReport = reportByTier[LeagueTier.first]!;
    final secondReport = reportByTier[LeagueTier.second]!;
    final thirdReport = reportByTier[LeagueTier.third]!;

    const slots = 3;
    final relegatedFromFirst = firstReport.table
        .skip(firstReport.table.length - slots)
        .map((row) => row.clubId)
        .toList(growable: false);
    final promotedFromSecond = secondReport.table
        .take(slots)
        .map((row) => row.clubId)
        .toList(growable: false);
    final relegatedFromSecond = secondReport.table
        .skip(secondReport.table.length - slots)
        .map((row) => row.clubId)
        .toList(growable: false);
    final promotedFromThird = thirdReport.table
        .take(slots)
        .map((row) => row.clubId)
        .toList(growable: false);

    final firstIds = first.clubIds.toSet()
      ..removeAll(relegatedFromFirst)
      ..addAll(promotedFromSecond);
    final secondIds = second.clubIds.toSet()
      ..removeAll(promotedFromSecond)
      ..removeAll(relegatedFromSecond)
      ..addAll(relegatedFromFirst)
      ..addAll(promotedFromThird);
    final thirdIds = third.clubIds.toSet()
      ..removeAll(promotedFromThird)
      ..addAll(relegatedFromSecond);
    final nextLeagues = [
      WorldLeague(tier: LeagueTier.first, clubIds: firstIds.toList()..sort()),
      WorldLeague(tier: LeagueTier.second, clubIds: secondIds.toList()..sort()),
      WorldLeague(tier: LeagueTier.third, clubIds: thirdIds.toList()..sort()),
    ];
    final movements = <LeagueMovement>[
      ...promotedFromSecond.map((clubId) => LeagueMovement(
        clubId: clubId, from: LeagueTier.second, to: LeagueTier.first,
      )),
      ...relegatedFromFirst.map((clubId) => LeagueMovement(
        clubId: clubId, from: LeagueTier.first, to: LeagueTier.second,
      )),
      ...promotedFromThird.map((clubId) => LeagueMovement(
        clubId: clubId, from: LeagueTier.third, to: LeagueTier.second,
      )),
      ...relegatedFromSecond.map((clubId) => LeagueMovement(
        clubId: clubId, from: LeagueTier.second, to: LeagueTier.third,
      )),
    ];
    final after = nextLeagues.expand((league) => league.clubIds).toList();
    if (movements.length != 12 ||
        movements.map((movement) => movement.clubId).toSet().length != 12 ||
        nextLeagues.any((league) =>
          league.clubIds.length != 16 || league.clubIds.toSet().length != 16) ||
        after.length != 48 || after.toSet().length != 48 ||
        after.toSet().difference(members).isNotEmpty) {
      throw StateError('Movement world coverage diverged.');
    }
    return WorldLeagueMovementResult(
      hasNextSeason: true, nextLeagues: nextLeagues, movements: movements,
    );
  }
}
