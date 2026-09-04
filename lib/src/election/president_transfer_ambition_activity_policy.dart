import '../transfer/transfer_activity_policy.dart';
import 'president_management_profile.dart';

class PresidentTransferAmbitionActivityPolicy {
  const PresidentTransferAmbitionActivityPolicy();

  TransferActivityPolicy forProfile(PresidentManagementProfile profile) =>
      forAmbition(profile.transferAmbition);

  TransferActivityPolicy forAmbition(int transferAmbition) {
    final ambition = transferAmbition.clamp(20, 90).toInt();
    if (ambition < 45) {
      return const TransferActivityPolicy(maxDealsPerWindow: 1);
    }
    if (ambition >= 75) {
      return const TransferActivityPolicy(maxDealsPerWindow: 3);
    }
    return TransferActivityPolicy.neutral;
  }
}
