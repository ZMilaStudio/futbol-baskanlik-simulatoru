import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import '../season/season_engine.dart';
import 'player.dart';
import 'player_career_report.dart';
import 'player_career_season.dart';
import 'player_lifecycle_engine.dart';
import 'player_pool_generator.dart';
import 'team_strength_calculator.dart';

class PlayerCareerEngine {
  const PlayerCareerEngine({
    this.seasonEngine = const SeasonEngine(),
    this.poolGenerator = const PlayerPoolGenerator(),
    this.lifecycleEngine = const PlayerLifecycleEngine(),
    this.strengthCalculator = const TeamStrengthCalculator(),
  });

  final SeasonEngine seasonEngine;
  final PlayerPoolGenerator poolGenerator;
  final PlayerLifecycleEngine lifecycleEngine;
  final TeamStrengthCalculator strengthCalculator;

  PlayerCareerReport simulate({
    required List<Club> clubs,
    required SimulationConfig config,
    int seasonCount = 20,
    GameDate startDate = const GameDate(2026, 7, 1),
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount', 'Must be positive.');
    }
    final clubIds = clubs.map((club) => club.id).toSet();
    if (clubIds.length != clubs.length) {
      throw ArgumentError('Club IDs must be unique.');
    }

    var currentPlayers = poolGenerator.generate(
      clubs: clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final initialPlayerCount = currentPlayers.length;
    final seasons = <PlayerCareerSeason>[];
    var currentClubs = strengthCalculator.deriveClubs(
      baseClubs: clubs,
      players: currentPlayers,
    );

    for (var offset = 0; offset < seasonCount; offset++) {
      final seasonIndex = config.seasonIndex + offset;
      final seasonStart = startDate.addYears(offset);
      currentClubs = strengthCalculator.deriveClubs(
        baseClubs: clubs,
        players: currentPlayers,
      );
      final report = seasonEngine.simulate(
        clubs: currentClubs,
        config: config.copyWith(seasonIndex: seasonIndex),
      );

      List<Player> retiredAfterSeason = const [];
      List<Player> youthIntakeAfterSeason = const [];
      if (offset < seasonCount - 1) {
        final transition = lifecycleEngine.advance(
          currentPlayers: currentPlayers,
          currentClubs: currentClubs,
          referenceClubs: clubs,
          careerSeed: config.careerSeed,
          nextSeasonIndex: seasonIndex + 1,
          simulationVersion: config.simulationVersion,
        );
        retiredAfterSeason = transition.retiredPlayers;
        youthIntakeAfterSeason = transition.youthIntake;

        seasons.add(
          PlayerCareerSeason(
            startDate: seasonStart,
            endDate: seasonStart.addYears(1),
            clubs: currentClubs,
            players: currentPlayers,
            retiredAfterSeason: retiredAfterSeason,
            youthIntakeAfterSeason: youthIntakeAfterSeason,
            report: report,
          ),
        );
        currentPlayers = transition.activePlayers;
      } else {
        seasons.add(
          PlayerCareerSeason(
            startDate: seasonStart,
            endDate: seasonStart.addYears(1),
            clubs: currentClubs,
            players: currentPlayers,
            retiredAfterSeason: retiredAfterSeason,
            youthIntakeAfterSeason: youthIntakeAfterSeason,
            report: report,
          ),
        );
      }
    }

    final finalClubs = strengthCalculator.deriveClubs(
      baseClubs: clubs,
      players: currentPlayers,
    );

    return PlayerCareerReport(
      careerSeed: config.careerSeed,
      initialSeasonIndex: config.seasonIndex,
      startDate: startDate,
      endDate: startDate.addYears(seasonCount),
      initialPlayerCount: initialPlayerCount,
      seasons: seasons,
      finalPlayers: currentPlayers,
      finalClubs: finalClubs,
    );
  }
}
