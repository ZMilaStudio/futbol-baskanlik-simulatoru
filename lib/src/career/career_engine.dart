import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import '../season/season_engine.dart';
import 'career_report.dart';
import 'career_season.dart';
import 'club_strength_evolution.dart';

class CareerEngine {
  const CareerEngine({
    this.seasonEngine = const SeasonEngine(),
    this.strengthEvolution = const ClubStrengthEvolution(),
  });

  final SeasonEngine seasonEngine;
  final ClubStrengthEvolution strengthEvolution;

  CareerReport simulate({
    required List<Club> clubs,
    required SimulationConfig config,
    int seasonCount = 20,
    GameDate startDate = const GameDate(2026, 7, 1),
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount', 'Must be positive.');
    }
    final ids = clubs.map((club) => club.id).toSet();
    if (ids.length != clubs.length) {
      throw ArgumentError('Club IDs must be unique.');
    }

    final baselineStrengths = {
      for (final club in clubs) club.id: club.strength,
    };
    var currentClubs = List<Club>.of(clubs, growable: false);
    final seasons = <CareerSeason>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final seasonIndex = config.seasonIndex + offset;
      final seasonStart = startDate.addYears(offset);
      final report = seasonEngine.simulate(
        clubs: currentClubs,
        config: config.copyWith(seasonIndex: seasonIndex),
      );

      seasons.add(
        CareerSeason(
          startDate: seasonStart,
          endDate: seasonStart.addYears(1),
          clubStrengths: {
            for (final club in currentClubs) club.id: club.strength,
          },
          report: report,
        ),
      );

      if (offset < seasonCount - 1) {
        currentClubs = strengthEvolution.evolve(
          currentClubs: currentClubs,
          baselineStrengths: baselineStrengths,
          careerSeed: config.careerSeed,
          nextSeasonIndex: seasonIndex + 1,
          simulationVersion: config.simulationVersion,
        );
      }
    }

    return CareerReport(
      careerSeed: config.careerSeed,
      initialSeasonIndex: config.seasonIndex,
      startDate: startDate,
      endDate: startDate.addYears(seasonCount),
      seasons: seasons,
      finalClubs: currentClubs,
    );
  }
}
