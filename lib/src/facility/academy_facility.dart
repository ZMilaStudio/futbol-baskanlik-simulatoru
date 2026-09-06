import '../core/money.dart';

class AcademyFacilityState {
  AcademyFacilityState({required this.clubId, required this.level}) {
    if (clubId == '') {
      throw ArgumentError('Academy clubId cannot be empty.');
    }
    if (level < 0 || level > AcademyInvestmentPolicy.maxLevel) {
      throw ArgumentError.value(level, 'level', 'Must be between 0 and 5.');
    }
  }

  final String clubId;
  final int level;

  AcademyFacilityState copyWith({int? level}) =>
      AcademyFacilityState(clubId: clubId, level: level ?? this.level);
}

class AcademyInvestmentDecision {
  const AcademyInvestmentDecision({
    required this.before,
    required this.after,
    required this.cost,
  });

  final AcademyFacilityState before;
  final AcademyFacilityState after;
  final Money cost;

  bool get upgraded => after.level > before.level;
}

class AcademyInvestmentPolicy {
  const AcademyInvestmentPolicy();

  static const int maxLevel = 5;

  AcademyInvestmentDecision upgrade(AcademyFacilityState state) {
    if (state.level >= maxLevel) {
      return AcademyInvestmentDecision(
        before: state,
        after: state,
        cost: Money.zero,
      );
    }
    final nextLevel = state.level + 1;
    return AcademyInvestmentDecision(
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
    const costs = <int>[3000000, 6000000, 10000000, 15000000, 22000000];
    return Money.fromUnits(costs[targetLevel - 1]);
  }

  int targetLevelForYouthOrientation(int youthOrientation) {
    if (youthOrientation < 0 || youthOrientation > 100) {
      throw ArgumentError.value(
        youthOrientation,
        'youthOrientation',
        'Must be between 0 and 100.',
      );
    }
    if (youthOrientation >= 88) return 5;
    if (youthOrientation >= 75) return 4;
    if (youthOrientation >= 60) return 3;
    if (youthOrientation >= 45) return 2;
    if (youthOrientation >= 30) return 1;
    return 0;
  }

  double abilityBonus(int level) {
    _validateLevel(level);
    return level * 0.6;
  }

  double potentialBonus(int level) {
    _validateLevel(level);
    return level * 1.2;
  }

  void _validateLevel(int level) {
    if (level < 0 || level > maxLevel) {
      throw ArgumentError.value(level, 'level', 'Must be between 0 and 5.');
    }
  }
}
