import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../league/club.dart';

class ClubStrengthEvolution {
  const ClubStrengthEvolution({
    this.maxRandomChange = 1.5,
    this.meanReversionRate = 0.20,
    this.maxDriftFromBaseline = 4.0,
  });

  final double maxRandomChange;
  final double meanReversionRate;
  final double maxDriftFromBaseline;

  List<Club> evolve({
    required List<Club> currentClubs,
    required Map<String, double> baselineStrengths,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
  }) {
    return currentClubs.map((club) {
      final baseline = baselineStrengths[club.id];
      if (baseline == null) {
        throw ArgumentError('Missing baseline strength for ${club.id}.');
      }

      final seed = StableHash.combine32([
        careerSeed,
        simulationVersion,
        nextSeasonIndex,
        StableHash.string32(club.id),
        StableHash.string32('club-strength-evolution'),
      ]);
      final rng = SeededRng(seed);
      final randomChange = (rng.nextDouble() * 2.0 - 1.0) * maxRandomChange;
      final meanReversion = (baseline - club.strength) * meanReversionRate;
      final raw = club.strength + meanReversion + randomChange;
      final lower = baseline - maxDriftFromBaseline;
      final upper = baseline + maxDriftFromBaseline;
      final bounded = raw.clamp(lower, upper).toDouble();
      final rounded = (bounded * 10000).round() / 10000.0;

      return club.copyWith(strength: rounded);
    }).toList(growable: false);
  }
}
