import '../core/game_date.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';

class CareerCheckpoint {
  CareerCheckpoint({
    required this.config,
    required this.careerStartDate,
    required this.completedSeasons,
    required Map<String, double> baselineStrengths,
    required List<Club> nextSeasonClubs,
  })  : baselineStrengths = Map.unmodifiable(baselineStrengths),
        nextSeasonClubs = List.unmodifiable(nextSeasonClubs) {
    validate();
  }

  final SimulationConfig config;
  final GameDate careerStartDate;
  final int completedSeasons;
  final Map<String, double> baselineStrengths;
  final List<Club> nextSeasonClubs;

  int get nextSeasonIndex => config.seasonIndex + completedSeasons;
  GameDate get nextSeasonStartDate => careerStartDate.addYears(completedSeasons);

  void validate() {
    if (completedSeasons < 0) {
      throw ArgumentError.value(
        completedSeasons,
        'completedSeasons',
        'Cannot be negative.',
      );
    }
    if (nextSeasonClubs.isEmpty) {
      throw ArgumentError('Career checkpoint must contain clubs.');
    }

    final ids = nextSeasonClubs.map((club) => club.id).toSet();
    if (ids.length != nextSeasonClubs.length) {
      throw ArgumentError('Career checkpoint club IDs must be unique.');
    }
    if (baselineStrengths.length != nextSeasonClubs.length ||
        !ids.every(baselineStrengths.containsKey)) {
      throw ArgumentError(
        'Career checkpoint baseline strengths must match the club set.',
      );
    }

    for (final club in nextSeasonClubs) {
      final baseline = baselineStrengths[club.id]!;
      if (!baseline.isFinite || !club.strength.isFinite) {
        throw ArgumentError('Career checkpoint strengths must be finite.');
      }
    }
  }
}
