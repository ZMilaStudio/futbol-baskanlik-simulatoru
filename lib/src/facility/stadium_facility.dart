import 'dart:math' as math;

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

class StadiumAttendanceProfile {
  const StadiumAttendanceProfile({
    required this.level,
    required this.capacity,
    required this.demand,
    required this.attendance,
    required this.occupancyBps,
    required this.ticketYieldBps,
    required this.revenueMultiplierBps,
  });

  final int level;
  final int capacity;
  final int demand;
  final int attendance;
  final int occupancyBps;
  final int ticketYieldBps;
  final int revenueMultiplierBps;
}

class StadiumInvestmentPolicy {
  const StadiumInvestmentPolicy();

  static const int maxLevel = 5;
  static const int neutralFanTrust = 60;
  static const List<int> _capacityByLevel = <int>[
    18000,
    20500,
    23500,
    27000,
    31000,
    36000,
  ];
  static const List<int> _ticketYieldBpsByLevel = <int>[
    10000,
    10150,
    10300,
    10450,
    10600,
    10750,
  ];

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

  int capacityForLevel(int level) {
    _validateLevel(level);
    return _capacityByLevel[level];
  }

  int ticketYieldBpsForLevel(int level) {
    _validateLevel(level);
    return _ticketYieldBpsByLevel[level];
  }

  int fanTrustDemandMultiplierBps(int fanTrust) {
    if (fanTrust < 0 || fanTrust > 100) {
      throw ArgumentError.value(fanTrust, 'fanTrust', 'Must be between 0 and 100.');
    }
    // Trust 60 is deliberately neutral so every M40 caller that omits fan
    // state keeps the exact same demand semantics. The bounded slope keeps fan
    // sentiment material without overpowering sporting strength and position.
    return 7000 + fanTrust * 50;
  }

  int demandSeats({
    required double clubStrength,
    required int leaguePosition,
    int fanTrust = neutralFanTrust,
  }) {
    if (!clubStrength.isFinite || clubStrength <= 0) {
      throw ArgumentError.value(
        clubStrength,
        'clubStrength',
        'Must be finite and positive.',
      );
    }
    if (leaguePosition < 1 || leaguePosition > 16) {
      throw ArgumentError.value(
        leaguePosition,
        'leaguePosition',
        'Must be between 1 and 16.',
      );
    }

    final strengthDemand =
        (math.max(0.0, clubStrength - 50.0) * 280).round();
    final positionDemand = (17 - leaguePosition) * 300;
    final sportingDemand =
        (10000 + strengthDemand + positionDemand).clamp(8000, 50000).toInt();
    final trustMultiplierBps = fanTrustDemandMultiplierBps(fanTrust);
    return ((sportingDemand * trustMultiplierBps) ~/ 10000)
        .clamp(8000, 50000)
        .toInt();
  }

  StadiumAttendanceProfile attendanceProfile({
    required int level,
    required double clubStrength,
    required int leaguePosition,
    int fanTrust = neutralFanTrust,
  }) {
    _validateLevel(level);
    final capacity = capacityForLevel(level);
    final demand = demandSeats(
      clubStrength: clubStrength,
      leaguePosition: leaguePosition,
      fanTrust: fanTrust,
    );
    final attendance = math.min(capacity, demand);
    final occupancyBps = (attendance * 10000) ~/ capacity;
    final ticketYieldBps = ticketYieldBpsForLevel(level);

    if (level == 0) {
      return StadiumAttendanceProfile(
        level: level,
        capacity: capacity,
        demand: demand,
        attendance: attendance,
        occupancyBps: occupancyBps,
        ticketYieldBps: ticketYieldBps,
        revenueMultiplierBps: 10000,
      );
    }

    final baselineAttendance = math.min(capacityForLevel(0), demand);
    final rawMultiplierBps =
        (attendance * ticketYieldBps) ~/ math.max(1, baselineAttendance);
    final ceilingBps = matchdayRevenueMultiplierBps(level);
    final revenueMultiplierBps = rawMultiplierBps
        .clamp(10000, ceilingBps)
        .toInt();

    return StadiumAttendanceProfile(
      level: level,
      capacity: capacity,
      demand: demand,
      attendance: attendance,
      occupancyBps: occupancyBps,
      ticketYieldBps: ticketYieldBps,
      revenueMultiplierBps: revenueMultiplierBps,
    );
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
