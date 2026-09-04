import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import '../season/season_engine.dart';
import 'career_checkpoint.dart';
import 'career_report.dart';
import 'career_season.dart';
import 'career_simulation_result.dart';
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
  }) =>
      simulateWithCheckpoint(
        clubs: clubs,
        config: config,
        seasonCount: seasonCount,
        startDate: startDate,
      ).report;

  CareerSimulationResult simulateWithCheckpoint({
    required List<Club> clubs,
    required SimulationConfig config,
    int seasonCount = 20,
    GameDate startDate = const GameDate(2026, 7, 1),
  }) {
    final checkpoint = CareerCheckpoint(
      config: config,
      careerStartDate: startDate,
      completedSeasons: 0,
      baselineStrengths: {
        for (final club in clubs) club.id: club.strength,
      },
      nextSeasonClubs: clubs,
    );
    return resume(checkpoint: checkpoint, seasonCount: seasonCount);
  }

  CareerSimulationResult resume({
    required CareerCheckpoint checkpoint,
    required int seasonCount,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount', 'Must be positive.');
    }
    checkpoint.validate();

    var currentClubs = List<Club>.of(
      checkpoint.nextSeasonClubs,
      growable: false,
    );
    var lastSeasonClubs = currentClubs;
    final seasons = <CareerSeason>[];
    final segmentStartDate = checkpoint.nextSeasonStartDate;
    final segmentInitialSeasonIndex = checkpoint.nextSeasonIndex;

    for (var offset = 0; offset < seasonCount; offset++) {
      final seasonIndex = segmentInitialSeasonIndex + offset;
      final seasonStart = segmentStartDate.addYears(offset);
      lastSeasonClubs = currentClubs;
      final report = seasonEngine.simulate(
        clubs: currentClubs,
        config: checkpoint.config.copyWith(seasonIndex: seasonIndex),
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

      currentClubs = strengthEvolution.evolve(
        currentClubs: currentClubs,
        baselineStrengths: checkpoint.baselineStrengths,
        careerSeed: checkpoint.config.careerSeed,
        nextSeasonIndex: seasonIndex + 1,
        simulationVersion: checkpoint.config.simulationVersion,
      );
    }

    final report = CareerReport(
      careerSeed: checkpoint.config.careerSeed,
      initialSeasonIndex: segmentInitialSeasonIndex,
      startDate: segmentStartDate,
      endDate: segmentStartDate.addYears(seasonCount),
      seasons: seasons,
      finalClubs: lastSeasonClubs,
    );
    final nextCheckpoint = CareerCheckpoint(
      config: checkpoint.config,
      careerStartDate: checkpoint.careerStartDate,
      completedSeasons: checkpoint.completedSeasons + seasonCount,
      baselineStrengths: checkpoint.baselineStrengths,
      nextSeasonClubs: currentClubs,
    );

    return CareerSimulationResult(
      report: report,
      checkpoint: nextCheckpoint,
    );
  }
}
