import '../core/money.dart';

typedef TransferBudgetPolicyProvider = TransferBudgetPolicy Function(
  String clubId,
  int decisionSeasonIndex,
);

class TransferBudgetPolicy {
  const TransferBudgetPolicy({
    required this.reserveCash,
    required this.windowSpendCapBps,
    required this.totalCommitmentCapBps,
  });

  static const neutral = TransferBudgetPolicy(
    reserveCash: Money.fromUnits(2000000),
    windowSpendCapBps: 3500,
    totalCommitmentCapBps: 9000,
  );

  final Money reserveCash;
  final int windowSpendCapBps;
  final int totalCommitmentCapBps;

  String get signature =>
      'reserve=${reserveCash.minorUnits}:'
      'window=$windowSpendCapBps:commitment=$totalCommitmentCapBps';
}
