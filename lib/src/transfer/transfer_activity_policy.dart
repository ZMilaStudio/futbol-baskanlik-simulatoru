typedef TransferActivityPolicyProvider = TransferActivityPolicy Function(
  String clubId,
  int decisionSeasonIndex,
);

class TransferActivityPolicy {
  const TransferActivityPolicy({required this.maxDealsPerWindow})
      : assert(maxDealsPerWindow > 0);

  static const neutral = TransferActivityPolicy(maxDealsPerWindow: 2);

  final int maxDealsPerWindow;

  String get signature => 'maxDeals=$maxDealsPerWindow';
}
