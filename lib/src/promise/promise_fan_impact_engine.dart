import '../fan/fan_trust_reason.dart';
import 'president_promise.dart';
import 'promise_resolution.dart';

class PromiseFanImpactEngine {
  const PromiseFanImpactEngine();

  List<FanTrustReason> evaluate(PromiseResolution resolution) {
    final reasons = <FanTrustReason>[
      _identityReason(resolution),
    ];
    if (_isFinancialPromise(resolution.promise.type)) {
      reasons.add(_financialReason(resolution));
    }
    return reasons;
  }

  FanTrustReason _identityReason(PromiseResolution resolution) {
    final type = resolution.promise.type;
    final status = resolution.status;
    final int delta;

    switch (status) {
      case PromiseStatus.fulfilled:
        delta = type == PresidentPromiseType.challengeTitle ||
                type == PresidentPromiseType.earnPromotion
            ? 3
            : 2;
      case PromiseStatus.partial:
        delta = 1;
      case PromiseStatus.broken:
        if (type == PresidentPromiseType.avoidRelegation) {
          delta = -4;
        } else if (type == PresidentPromiseType.challengeTitle ||
            type == PresidentPromiseType.earnPromotion ||
            _isFinancialPromise(type)) {
          delta = -3;
        } else {
          delta = -2;
        }
    }

    return FanTrustReason(
      dimension: FanTrustDimension.identity,
      code: 'promise_${status.name}_${type.name}',
      delta: delta,
    );
  }

  FanTrustReason _financialReason(PromiseResolution resolution) {
    final delta = switch (resolution.status) {
      PromiseStatus.fulfilled => 2,
      PromiseStatus.partial => 1,
      PromiseStatus.broken => -2,
    };
    return FanTrustReason(
      dimension: FanTrustDimension.financial,
      code:
          'promise_financial_${resolution.status.name}_${resolution.promise.type.name}',
      delta: delta,
    );
  }

  bool _isFinancialPromise(PresidentPromiseType type) =>
      type == PresidentPromiseType.reduceDebt ||
      type == PresidentPromiseType.stabilizeFinances;
}
