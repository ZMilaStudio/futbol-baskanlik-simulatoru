typedef TransferNegotiationPolicyProvider = TransferNegotiationPolicy Function(
  String clubId,
  int decisionSeasonIndex,
);

class TransferNegotiationPolicy {
  const TransferNegotiationPolicy({
    required this.maxBidAdjustmentBps,
  });

  static const neutral = TransferNegotiationPolicy(
    maxBidAdjustmentBps: 0,
  );

  final int maxBidAdjustmentBps;

  String get signature => 'maxBidAdjustment=$maxBidAdjustmentBps';
}
