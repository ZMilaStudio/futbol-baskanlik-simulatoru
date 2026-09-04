import '../transfer/transfer_negotiation_policy.dart';
import 'president_management_profile.dart';

class PresidentRiskAppetiteNegotiationPolicy {
  const PresidentRiskAppetiteNegotiationPolicy();

  TransferNegotiationPolicy forProfile(PresidentManagementProfile profile) =>
      forRiskAppetite(profile.riskAppetite);

  TransferNegotiationPolicy forRiskAppetite(int riskAppetite) {
    final risk = riskAppetite.clamp(20, 90).toInt();
    final adjustmentBps = ((risk - 60) * 20).clamp(-800, 600).toInt();
    return TransferNegotiationPolicy(maxBidAdjustmentBps: adjustmentBps);
  }
}
