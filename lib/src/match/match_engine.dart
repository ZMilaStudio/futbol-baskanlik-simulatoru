import 'dart:math' as math;

import '../core/seeded_rng.dart';
import '../core/simulation_config.dart';
import '../core/stable_hash.dart';
import '../league/club.dart';
import '../league/fixture.dart';
import 'match_result.dart';
import 'poisson_sampler.dart';

class MatchEngine {
  const MatchEngine();

  MatchResult simulate({
    required Fixture fixture,
    required Club home,
    required Club away,
    required SimulationConfig config,
  }) {
    final rawDiff =
        (home.strength + config.homeAdvantageRating) - away.strength;
    final diff = rawDiff.clamp(-30.0, 30.0).toDouble();

    final homeLambda =
        (config.baseHomeGoals * math.exp(diff / config.ratingScale))
            .clamp(config.minExpectedGoals, config.maxExpectedGoals)
            .toDouble();
    final awayLambda =
        (config.baseAwayGoals * math.exp(-diff / config.ratingScale))
            .clamp(config.minExpectedGoals, config.maxExpectedGoals)
            .toDouble();

    final matchSeed = StableHash.combine32([
      config.careerSeed,
      config.seasonIndex,
      config.simulationVersion,
      StableHash.string32(fixture.id),
    ]);
    final rng = SeededRng(matchSeed);

    return MatchResult(
      homeGoals: PoissonSampler.sample(homeLambda, rng),
      awayGoals: PoissonSampler.sample(awayLambda, rng),
      homeExpectedGoals: homeLambda,
      awayExpectedGoals: awayLambda,
      matchSeed: matchSeed,
    );
  }
}
