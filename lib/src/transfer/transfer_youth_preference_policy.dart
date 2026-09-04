typedef TransferYouthPreferencePolicyProvider = TransferYouthPreferencePolicy Function(
  String clubId,
  int decisionSeasonIndex,
);

class TransferYouthPreferencePolicy {
  const TransferYouthPreferencePolicy({
    required this.youthSignalScaleBps,
  }) : assert(youthSignalScaleBps > 0);

  final int youthSignalScaleBps;

  static const neutral = TransferYouthPreferencePolicy(
    youthSignalScaleBps: 10000,
  );

  double applyYouthSignal(double signal) =>
      signal * youthSignalScaleBps / 10000.0;
}
