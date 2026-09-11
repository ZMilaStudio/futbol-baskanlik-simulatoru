import '../core/money.dart';

class StadiumFacilityState {
  StadiumFacilityState({required this.clubId, required this.level}) {
    if (clubId == '') {
      throw ArgumentError('Stadium clubId cannot be empty.');
    }
    if (level < 0 || level > StadiumInvestmentPolicy.maxLevel) {
      throw ArgumentError.value(level, 'level', 'Must be between 0 and 5.');
    }
  }

  final String clubId;
  final int level;

  StadiumFacilityState copyWith({int? level}) =>
      StadiumFacilityState(clubId: clubId, level: level ?? this.level);
}

class StadiumInvestmentDecision {
  const StadiumInvestmentDecision({
    required this.before,
    required this.after,
    required this.cost,
  });

  final StadiumFacilityState before;
  final StadiumFacilityState after;
  final Money cost;

  bool get upgraded => after.level > before.level;
}

class StadiumInvestmentPolicy {
  const StadiumInvestmentPolicy();

  static const int maxLevel = 5;

  StadiumInvestmentDecision upgrade(StadiumFacilityState state) {
    if (state.level >= maxLevel) {
      return StadiumInvestmentDecision(
        before: state,
        after: state,
        cost: Money.zero,
      );
    }
    final nextLevel = state.level + 1;
    return StadiumInvestmentDecision(
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
    const costs = <int>[5000000, 10000000, 18000000, 28000000, 40000000];
    return Money.fromUnits(costs[targetLevel - 1]);
  }

  int matchdayRevenueMultiplierBps(int level) {
    _validateLevel(level);
    return 10000 + level * 750;
  }

  void _validateLevel(int level) {
    if (level < 0 || level > maxLevel) {
      throw ArgumentError.value(level, 'level', 'Must be between 0 and 5.');
    }
  }
}
