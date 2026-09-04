enum PresidentElectionOutcome {
  reelected,
  lost,
}

enum PresidentApprovalReason {
  fanOverall,
  fanIdentity,
  mediaCredibility,
  promiseRecord,
}

class PresidentApprovalContribution {
  const PresidentApprovalContribution({
    required this.reason,
    required this.value,
    required this.weightBps,
  });

  final PresidentApprovalReason reason;
  final int value;
  final int weightBps;

  double get weightedPoints => value * weightBps / 10000.0;

  String get signature =>
      '${reason.name}:value=$value:weight=$weightBps:points=${weightedPoints.toStringAsFixed(2)}';
}
