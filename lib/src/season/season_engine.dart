import '../core/simulation_config.dart';
import '../league/club.dart';
import '../league/fixture.dart';
import '../league/fixture_generator.dart';
import '../league/standing_row.dart';
import '../match/match_engine.dart';
import 'season_report.dart';

class SeasonEngine {
  const SeasonEngine({
    this.fixtureGenerator = const FixtureGenerator(),
    this.matchEngine = const MatchEngine(),
  });

  final FixtureGenerator fixtureGenerator;
  final MatchEngine matchEngine;

  SeasonReport simulate({
    required List<Club> clubs,
    required SimulationConfig config,
  }) {
    final byId = {for (final club in clubs) club.id: club};
    if (byId.length != clubs.length) {
      throw ArgumentError('Club IDs must be unique.');
    }

    final fixtures = fixtureGenerator.generateDoubleRoundRobin(
      clubs: clubs,
      seasonIndex: config.seasonIndex,
    );
    final standings = {
      for (final club in clubs) club.id: StandingRow(clubId: club.id),
    };
    final completed = <Fixture>[];
    var homeWins = 0;
    var draws = 0;
    var awayWins = 0;
    var totalGoals = 0;

    for (final fixture in fixtures) {
      final home = byId[fixture.homeClubId]!;
      final away = byId[fixture.awayClubId]!;
      final result = matchEngine.simulate(
        fixture: fixture,
        home: home,
        away: away,
        config: config,
      );
      completed.add(fixture.withResult(result));
      standings[home.id]!.record(
        scored: result.homeGoals,
        conceded: result.awayGoals,
      );
      standings[away.id]!.record(
        scored: result.awayGoals,
        conceded: result.homeGoals,
      );
      totalGoals += result.homeGoals + result.awayGoals;
      if (result.homeGoals > result.awayGoals) {
        homeWins++;
      } else if (result.homeGoals == result.awayGoals) {
        draws++;
      } else {
        awayWins++;
      }
    }

    final table = standings.values.toList()
      ..sort((a, b) {
        var cmp = b.points.compareTo(a.points);
        if (cmp != 0) return cmp;
        cmp = b.goalDifference.compareTo(a.goalDifference);
        if (cmp != 0) return cmp;
        cmp = b.goalsFor.compareTo(a.goalsFor);
        if (cmp != 0) return cmp;
        cmp = b.wins.compareTo(a.wins);
        if (cmp != 0) return cmp;
        return a.clubId.compareTo(b.clubId);
      });

    return SeasonReport(
      seasonIndex: config.seasonIndex,
      seed: config.careerSeed,
      championClubId: table.first.clubId,
      table: table,
      fixtures: completed,
      homeWins: homeWins,
      draws: draws,
      awayWins: awayWins,
      totalGoals: totalGoals,
    );
  }
}
