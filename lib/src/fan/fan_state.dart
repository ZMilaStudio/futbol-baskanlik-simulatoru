import 'fan_trust_reason.dart';

class FanState {
  const FanState({
    required this.clubId,
    required this.sportingTrust,
    required this.financialTrust,
    required this.transferTrust,
    required this.identityTrust,
  });

  factory FanState.initial(String clubId, {int trust = 60}) => FanState(
        clubId: clubId,
        sportingTrust: trust,
        financialTrust: trust,
        transferTrust: trust,
        identityTrust: trust,
      );

  final String clubId;
  final int sportingTrust;
  final int financialTrust;
  final int transferTrust;
  final int identityTrust;

  int get overallTrust =>
      ((sportingTrust * 35 +
                  financialTrust * 30 +
                  transferTrust * 25 +
                  identityTrust * 10) /
              100)
          .round();

  FanState apply(Iterable<FanTrustReason> reasons) {
    var sportingDelta = 0;
    var financialDelta = 0;
    var transferDelta = 0;
    var identityDelta = 0;
    for (final reason in reasons) {
      switch (reason.dimension) {
        case FanTrustDimension.sporting:
          sportingDelta += reason.delta;
        case FanTrustDimension.financial:
          financialDelta += reason.delta;
        case FanTrustDimension.transfer:
          transferDelta += reason.delta;
        case FanTrustDimension.identity:
          identityDelta += reason.delta;
      }
    }
    return FanState(
      clubId: clubId,
      sportingTrust: _nextScore(sportingTrust, sportingDelta),
      financialTrust: _nextScore(financialTrust, financialDelta),
      transferTrust: _nextScore(transferTrust, transferDelta),
      identityTrust: _nextScore(identityTrust, identityDelta),
    );
  }

  static int _nextScore(int current, int delta) {
    final stabilized = current > 60
        ? current - 1
        : current < 60
            ? current + 1
            : current;
    return (stabilized + delta).clamp(0, 100).toInt();
  }

  String get signature =>
      '$clubId:$sportingTrust:$financialTrust:$transferTrust:$identityTrust:$overallTrust';
}
