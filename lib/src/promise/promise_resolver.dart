import 'president_promise.dart';
import 'promise_context.dart';
import 'promise_resolution.dart';

class PromiseResolver {
  const PromiseResolver();

  PromiseResolution resolve({
    required PresidentPromise promise,
    required PresidentPromiseOutcome outcome,
  }) {
    if (promise.clubId != outcome.clubId ||
        promise.seasonIndex != outcome.seasonIndex) {
      throw ArgumentError('Promise and outcome must refer to the same club-season.');
    }

    return switch (promise.type) {
      PresidentPromiseType.reduceDebt => _resolveDebt(promise, outcome),
      PresidentPromiseType.stabilizeFinances =>
        _resolveFinancialStability(promise, outcome),
      PresidentPromiseType.finishTopHalf => _resolveTopHalf(promise, outcome),
      PresidentPromiseType.avoidRelegation =>
        _resolveRelegation(promise, outcome),
      PresidentPromiseType.earnPromotion =>
        _resolvePromotion(promise, outcome),
      PresidentPromiseType.challengeTitle => _resolveTitle(promise, outcome),
    };
  }

  PromiseResolution _resolveDebt(
    PresidentPromise promise,
    PresidentPromiseOutcome outcome,
  ) {
    final targetBps = promise.targetDebtReductionBps ?? 800;
    if (outcome.openingDebt.isZero) {
      final keptDebtFree = outcome.closingDebt.isZero;
      return PromiseResolution(
        promise: promise,
        status: keptDebtFree ? PromiseStatus.fulfilled : PromiseStatus.broken,
        reason: keptDebtFree
            ? PromiseResolutionReason.debtTargetMet
            : PromiseResolutionReason.debtNotReduced,
        score: keptDebtFree ? 100 : 0,
      );
    }

    final reduction = outcome.openingDebt - outcome.closingDebt;
    final reductionBps =
        (reduction.minorUnits * 10000) ~/ outcome.openingDebt.minorUnits;
    if (reductionBps >= targetBps) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.fulfilled,
        reason: PromiseResolutionReason.debtTargetMet,
        score: 100,
      );
    }
    if (reductionBps > 0) {
      final rawScore = (reductionBps * 100) ~/ targetBps;
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.partial,
        reason: PromiseResolutionReason.debtReduced,
        score: rawScore < 35 ? 35 : rawScore,
      );
    }
    return PromiseResolution(
      promise: promise,
      status: PromiseStatus.broken,
      reason: PromiseResolutionReason.debtNotReduced,
      score: 0,
    );
  }

  PromiseResolution _resolveFinancialStability(
    PresidentPromise promise,
    PresidentPromiseOutcome outcome,
  ) {
    final noEmergency = outcome.emergencyBorrowing.isZero;
    final debtControlled = outcome.openingDebt.isZero
        ? outcome.closingDebt.isZero
        : outcome.closingDebt <= outcome.openingDebt.scaleBasisPoints(10500);

    if (noEmergency && debtControlled) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.fulfilled,
        reason: PromiseResolutionReason.financesStable,
        score: 100,
      );
    }
    if (noEmergency || debtControlled) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.partial,
        reason: PromiseResolutionReason.financesMixed,
        score: 55,
      );
    }
    return PromiseResolution(
      promise: promise,
      status: PromiseStatus.broken,
      reason: PromiseResolutionReason.financesWorsened,
      score: 0,
    );
  }

  PromiseResolution _resolveTopHalf(
    PresidentPromise promise,
    PresidentPromiseOutcome outcome,
  ) {
    final target = promise.targetLeaguePosition ?? outcome.leagueSize ~/ 2;
    if (outcome.leaguePosition <= target) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.fulfilled,
        reason: PromiseResolutionReason.topHalfMet,
        score: 100,
      );
    }
    if (outcome.leaguePosition <= target + 2) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.partial,
        reason: PromiseResolutionReason.nearTopHalf,
        score: 55,
      );
    }
    return PromiseResolution(
      promise: promise,
      status: PromiseStatus.broken,
      reason: PromiseResolutionReason.missedTopHalf,
      score: 0,
    );
  }

  PromiseResolution _resolveRelegation(
    PresidentPromise promise,
    PresidentPromiseOutcome outcome,
  ) {
    final survived = !outcome.relegated;
    return PromiseResolution(
      promise: promise,
      status: survived ? PromiseStatus.fulfilled : PromiseStatus.broken,
      reason: survived
          ? PromiseResolutionReason.survived
          : PromiseResolutionReason.relegated,
      score: survived ? 100 : 0,
    );
  }

  PromiseResolution _resolvePromotion(
    PresidentPromise promise,
    PresidentPromiseOutcome outcome,
  ) {
    if (outcome.promoted) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.fulfilled,
        reason: PromiseResolutionReason.promoted,
        score: 100,
      );
    }
    if (outcome.leaguePosition <= 5) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.partial,
        reason: PromiseResolutionReason.promotionNearMiss,
        score: 55,
      );
    }
    return PromiseResolution(
      promise: promise,
      status: PromiseStatus.broken,
      reason: PromiseResolutionReason.missedPromotion,
      score: 0,
    );
  }

  PromiseResolution _resolveTitle(
    PresidentPromise promise,
    PresidentPromiseOutcome outcome,
  ) {
    if (outcome.leaguePosition == 1) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.fulfilled,
        reason: PromiseResolutionReason.champion,
        score: 100,
      );
    }
    if (outcome.leaguePosition <= 3) {
      return PromiseResolution(
        promise: promise,
        status: PromiseStatus.partial,
        reason: PromiseResolutionReason.titlePodium,
        score: 60,
      );
    }
    return PromiseResolution(
      promise: promise,
      status: PromiseStatus.broken,
      reason: PromiseResolutionReason.titleMissed,
      score: 0,
    );
  }
}
