import '../transfer/transfer_youth_preference_policy.dart';

class PresidentYouthOrientationTransferPolicy {
  const PresidentYouthOrientationTransferPolicy();

  TransferYouthPreferencePolicy forYouthOrientation(int youthOrientation) {
    final orientation = youthOrientation.clamp(20, 90).toInt();
    final scaleBps = (10000 + (orientation - 60) * 100)
        .clamp(6000, 13000)
        .toInt();
    return TransferYouthPreferencePolicy(
      youthSignalScaleBps: scaleBps,
    );
  }
}
