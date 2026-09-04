import 'president_promise.dart';

enum PromiseStatus {
  fulfilled,
  partial,
  broken,
}

enum PromiseResolutionReason {
  debtTargetMet,
  debtReduced,
  debtNotReduced,
  financesStable,
  financesMixed,
  financesWorsened,
  topHalfMet,
  nearTopHalf,
  missedTopHalf,
  survived,
  relegated,
  promoted,
  promotionNearMiss,
  missedPromotion,
  champion,
  titlePodium,
  titleMissed,
}

class PromiseResolution {
  const PromiseResolution({
    required this.promise,
    required this.status,
    required this.reason,
    required this.score,
  });

  final PresidentPromise promise;
  final PromiseStatus status;
  final PromiseResolutionReason reason;
  final int score;

  String get signature =>
      '${promise.id}:${status.name}:${reason.name}:score=$score';
}
