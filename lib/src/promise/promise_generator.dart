import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../world/league_tier.dart';
import 'president_promise.dart';
import 'promise_context.dart';

class PromiseGenerator {
  const PromiseGenerator();

  PresidentPromise generate({
    required PresidentPromiseContext context,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final rng = SeededRng(
      StableHash.combine32([
        careerSeed,
        simulationVersion,
        context.seasonIndex,
        StableHash.string32(context.clubId),
        StableHash.string32('president-promise'),
      ]),
    );

    final type = _chooseType(context, rng);
    final targetPosition = switch (type) {
      PresidentPromiseType.finishTopHalf => context.leagueSize ~/ 2,
      PresidentPromiseType.earnPromotion => 3,
      PresidentPromiseType.challengeTitle => 1,
      _ => null,
    };
    final debtTargetBps = type == PresidentPromiseType.reduceDebt
        ? (context.severeFinancialStress ? 1200 : 800)
        : null;

    return PresidentPromise(
      id: 'promise_${context.clubId}_s${context.seasonIndex}',
      clubId: context.clubId,
      seasonIndex: context.seasonIndex,
      type: type,
      targetLeaguePosition: targetPosition,
      targetDebtReductionBps: debtTargetBps,
    );
  }

  PresidentPromiseType _chooseType(
    PresidentPromiseContext context,
    SeededRng rng,
  ) {
    if (context.financialStress && rng.nextDouble() < 0.60) {
      return rng.nextDouble() < 0.62
          ? PresidentPromiseType.reduceDebt
          : PresidentPromiseType.stabilizeFinances;
    }

    if (context.expectedPosition >= context.leagueSize - 3) {
      return PresidentPromiseType.avoidRelegation;
    }

    if (context.tier != LeagueTier.first && context.expectedPosition <= 5) {
      return PresidentPromiseType.earnPromotion;
    }

    if (context.tier == LeagueTier.first && context.expectedPosition <= 3) {
      return PresidentPromiseType.challengeTitle;
    }

    return PresidentPromiseType.finishTopHalf;
  }
}
