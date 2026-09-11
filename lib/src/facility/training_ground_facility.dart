import '../core/money.dart';

class TrainingGroundFacilityState {
  TrainingGroundFacilityState({required this.clubId, required this.level}) {
    if (clubId == '') {
      throw ArgumentError('Training ground clubId cannot be empty.');
    }
    if (level < 0 || level > TrainingGroundInvestmentPolicy.maxLevel) {
      throw ArgumentError.value(level, 'level', 'Must be between 0 and 5.');
    }
  }

  final String clubId;
  final int level;

  TrainingGroundFacilityState copyWith({int? level}) =>
      TrainingGroundFacilityState(clubId: clubId, level: level ?? this.level);
}

class TrainingGroundInvestmentDecision {
  const TrainingGroundInvestmentDecision({
    required this.before,
    required this.after,
    required this.cost,
  });

  final TrainingGroundFacilityState before;
  final TrainingGroundFacilityState after;
  final Money cost;

  bool get upgraded => after.level > before.level;
}

class TrainingGroundInvestmentPolicy {
  const TrainingGroundInvestmentPolicy();

  static const int maxLevel = 5;

  TrainingGroundInvestmentDecision upgrade(TrainingGroundFacilityState state) {
    if (state.level >= maxLevel) {
      return TrainingGroundInvestmentDecision(
        before: state,
        after: state,
        cost: Money.zero,
      );
    }
    final nextLevel = state.level + 1;
    return TrainingGroundInvestmentDecision(
      before: state,
      after: state.copyWith(level: nextLevel),
      cost: upgradeCost(nextLevel),
    );
  }

  Money upgradeCost(int targetLevel) {
    if (targetLevel < 1 || targetLevel > maxLevel) {
      throw ArgumentError.value(
        targetLevel,
        'targetLevel',
        'Must be between 1 and 5.',
      );
    }
    const costs = <int>[4000000, 8000000, 14000000, 22000000, 32000000];
    return Money.fromUnits(costs[targetLevel - 1]);
  }

  int positiveDevelopmentMultiplierBps(int level) {
    _validateLevel(level);
    return 10000 + level * 500;
  }

  double applyDevelopmentMultiplier(double delta, int level) {
    _validateLevel(level);
    if (delta <= 0 || level == 0) return delta;
    return delta * positiveDevelopmentMultiplierBps(level) / 10000;
  }

  void _validateLevel(int level) {
    if (level < 0 || level > maxLevel) {
      throw ArgumentError.value(level, 'level', 'Must be between 0 and 5.');
    }
  }
}
