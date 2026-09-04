import '../media/media_state.dart';
import 'president_promise.dart';
import 'promise_media_credibility_change.dart';
import 'promise_resolution.dart';

class PromiseMediaImpactEngine {
  const PromiseMediaImpactEngine();

  PromiseMediaCredibilityChange evaluate({
    required MediaState state,
    required PromiseResolution resolution,
  }) {
    final rawDelta = _rawDelta(resolution);
    var adjustedDelta = rawDelta;
    final projected = state.credibility + rawDelta;

    // Promise history should matter without pinning long careers to 0/100.
    if (rawDelta > 0 && projected > 88) {
      adjustedDelta -= 1;
    } else if (rawDelta < 0 && projected < 30) {
      adjustedDelta += 1;
    }

    final after = (state.credibility + adjustedDelta).clamp(0, 100).toInt();
    return PromiseMediaCredibilityChange(
      clubId: resolution.promise.clubId,
      seasonIndex: resolution.promise.seasonIndex,
      promiseId: resolution.promise.id,
      promiseType: resolution.promise.type,
      status: resolution.status,
      code: 'promise_media_${resolution.status.name}_${resolution.promise.type.name}',
      delta: after - state.credibility,
      before: state.credibility,
      after: after,
    );
  }

  int _rawDelta(PromiseResolution resolution) {
    final type = resolution.promise.type;
    switch (resolution.status) {
      case PromiseStatus.fulfilled:
        return type == PresidentPromiseType.challengeTitle ||
                type == PresidentPromiseType.earnPromotion ||
                _isFinancial(type)
            ? 2
            : 1;
      case PromiseStatus.partial:
        return 0;
      case PromiseStatus.broken:
        if (type == PresidentPromiseType.avoidRelegation) return -3;
        if (type == PresidentPromiseType.challengeTitle ||
            type == PresidentPromiseType.earnPromotion ||
            _isFinancial(type)) {
          return -2;
        }
        return -1;
    }
  }

  bool _isFinancial(PresidentPromiseType type) =>
      type == PresidentPromiseType.reduceDebt ||
      type == PresidentPromiseType.stabilizeFinances;
}
