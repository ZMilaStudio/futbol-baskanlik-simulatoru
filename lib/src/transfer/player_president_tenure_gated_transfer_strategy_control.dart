import '../election/player_president_tenure_control_gate.dart';
import '../election/president_management_profile.dart';
import '../world/world_career_engine.dart';
import 'player_president_transfer_strategy_control.dart';
import 'president_transfer_strategy_world_bridge.dart';

/// M60 applies M58's persisted incumbent-president ownership state to M55's
/// transfer-strategy decision surface.
///
/// The player provider is consulted only while the tenure state is active and
/// the controlled club's real AI profile still belongs to the captured player
/// president identity. A successor profile therefore falls back immediately to
/// the untouched AI map. A persisted `lost` state stays blocked even if the old
/// president id appears again later.
///
/// The decision provider remains runtime-only. M60 does not serialize provider
/// callbacks and does not change M55's transfer traits or M54's explicit-policy
/// precedence.
class PlayerPresidentTenureGatedTransferStrategyProfileProvider
    extends PresidentTransferStrategyProfileProvider {
  const PlayerPresidentTenureGatedTransferStrategyProfileProvider({
    required this.aiProfileProvider,
    required this.tenureControl,
    this.decisionProvider,
  });

  final PresidentTransferStrategyProfileProvider aiProfileProvider;
  final PlayerPresidentTenureControlState tenureControl;
  final PlayerTransferStrategyDecisionProvider? decisionProvider;

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) {
    final aiProfiles = aiProfileProvider.profilesForWindow(context);
    final provider = decisionProvider;
    if (provider == null) return aiProfiles;

    tenureControl.validate();
    final controlledClubId = tenureControl.controlledClubId;
    if (!context.clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError.value(
        controlledClubId,
        'controlledClubId',
        'Controlled club must participate in the transfer window.',
      );
    }
    final aiProfile = aiProfiles[controlledClubId];
    if (aiProfile == null) {
      throw ArgumentError(
        'AI transfer profile must cover the controlled club.',
      );
    }

    if (tenureControl.lost ||
        aiProfile.presidentId != tenureControl.playerPresidentId) {
      return aiProfiles;
    }

    return PlayerPresidentTransferStrategyProfileProvider(
      aiProfileProvider: _ResolvedProfileProvider(aiProfiles),
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).profilesForWindow(context);
  }
}

class PlayerPresidentTenureGatedTransferStrategyWorldBridge {
  const PlayerPresidentTenureGatedTransferStrategyWorldBridge();

  WorldCareerEngine wrap({
    required WorldCareerEngine base,
    required PresidentTransferStrategyProfileProvider aiProfileProvider,
    required PlayerPresidentTenureControlState tenureControl,
    PlayerTransferStrategyDecisionProvider? decisionProvider,
  }) =>
      const PresidentTransferStrategyWorldBridge().wrap(
        base: base,
        profileProvider:
            PlayerPresidentTenureGatedTransferStrategyProfileProvider(
          aiProfileProvider: aiProfileProvider,
          tenureControl: tenureControl,
          decisionProvider: decisionProvider,
        ),
      );
}

class _ResolvedProfileProvider extends PresidentTransferStrategyProfileProvider {
  const _ResolvedProfileProvider(this.profiles);

  final Map<String, PresidentManagementProfile> profiles;

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) =>
      profiles;
}
