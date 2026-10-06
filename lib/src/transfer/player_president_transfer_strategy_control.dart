import '../election/president_management_profile.dart';
import '../world/world_career_engine.dart';
import 'president_transfer_strategy_world_bridge.dart';

class PlayerTransferStrategyChoice {
  const PlayerTransferStrategyChoice({
    required this.financialDiscipline,
    required this.transferAmbition,
    required this.riskAppetite,
    required this.youthOrientation,
  });

  factory PlayerTransferStrategyChoice.fromProfile(
    PresidentManagementProfile profile,
  ) =>
      PlayerTransferStrategyChoice(
        financialDiscipline: profile.financialDiscipline,
        transferAmbition: profile.transferAmbition,
        riskAppetite: profile.riskAppetite,
        youthOrientation: profile.youthOrientation,
      );

  final int financialDiscipline;
  final int transferAmbition;
  final int riskAppetite;
  final int youthOrientation;

  void validate() {
    _validateTrait('financialDiscipline', financialDiscipline);
    _validateTrait('transferAmbition', transferAmbition);
    _validateTrait('riskAppetite', riskAppetite);
    _validateTrait('youthOrientation', youthOrientation);
  }

  PresidentManagementProfile applyTo(PresidentManagementProfile aiProfile) {
    validate();
    return PresidentManagementProfile(
      presidentId: aiProfile.presidentId,
      archetype: aiProfile.archetype,
      financialDiscipline: financialDiscipline,
      riskAppetite: riskAppetite,
      transferAmbition: transferAmbition,
      youthOrientation: youthOrientation,
      managerPatience: aiProfile.managerPatience,
    );
  }

  String get signature =>
      'finance=$financialDiscipline:transfer=$transferAmbition:'
      'risk=$riskAppetite:youth=$youthOrientation';

  static void _validateTrait(String name, int value) {
    if (value < 20 || value > 90) {
      throw ArgumentError.value(value, name, 'Must be between 20 and 90.');
    }
  }
}

class PlayerTransferStrategyDecisionContext {
  const PlayerTransferStrategyDecisionContext({
    required this.window,
    required this.controlledClubId,
    required this.aiProfile,
  });

  final PresidentTransferStrategyWindowContext window;
  final String controlledClubId;
  final PresidentManagementProfile aiProfile;

  int get seasonIndex => window.seasonIndex;
  int get decisionSeasonIndex => window.decisionSeasonIndex;

  String get signature => '${window.signature}:controlled=$controlledClubId:'
      'ai=${aiProfile.signature}';
}

abstract class PlayerTransferStrategyDecisionProvider {
  const PlayerTransferStrategyDecisionProvider();

  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  );

  void onApplied(
    PlayerTransferStrategyDecisionContext context,
    PlayerTransferStrategyChoice choice,
    PresidentManagementProfile effectiveProfile,
  ) {}
}

/// M55 overlays a player-president transfer strategy on top of the AI profile
/// map consumed by M54. Only the controlled club can be changed; all other
/// clubs keep their original AI president profile exactly.
///
/// The provider itself is deliberately not persisted. The controlled club is
/// already owned by the player-president runtime introduced in M49-M52 and can
/// be supplied again when composing this opt-in bridge.
class PlayerPresidentTransferStrategyProfileProvider
    extends PresidentTransferStrategyProfileProvider {
  const PlayerPresidentTransferStrategyProfileProvider({
    required this.aiProfileProvider,
    required this.controlledClubId,
    this.decisionProvider,
  });

  final PresidentTransferStrategyProfileProvider aiProfileProvider;
  final String controlledClubId;
  final PlayerTransferStrategyDecisionProvider? decisionProvider;

  /// Prepares AI profiles and the exact controlled context once. This does not
  /// choose a player answer, invoke onApplied, or run the transfer market.
  PreparedPlayerTransferStrategy prepareControlled(
    PresidentTransferStrategyWindowContext context,
  ) {
    final aiProfiles = aiProfileProvider.profilesForWindow(context);
    return _prepareControlled(context, aiProfiles);
  }

  PreparedPlayerTransferStrategy _prepareControlled(
    PresidentTransferStrategyWindowContext context,
    Map<String, PresidentManagementProfile> aiProfiles,
  ) {
    if (controlledClubId.isEmpty ||
        !context.clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Controlled club must participate in the window.');
    }
    final profile = aiProfiles[controlledClubId];
    if (profile == null) {
      throw ArgumentError(
          'AI transfer profile must cover the controlled club.');
    }
    return PreparedPlayerTransferStrategy._(
      PlayerTransferStrategyDecisionContext(
        window: context,
        controlledClubId: controlledClubId,
        aiProfile: profile,
      ),
      aiProfiles,
    );
  }

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) {
    final aiProfiles = aiProfileProvider.profilesForWindow(context);
    final provider = decisionProvider;
    if (provider == null) return aiProfiles;

    final prepared = _prepareControlled(context, aiProfiles);
    final decisionContext = prepared.context;
    final choice = provider.chooseTransferStrategy(decisionContext);
    return prepared.accept(
      expectedContext: decisionContext,
      choice: choice,
      provider: provider,
    );
  }
}

/// Single prepared decision attempt, not an authoritative world capability.
/// Invalid choices leave the exact context available; a callback failure is
/// terminal because external callbacks cannot be rolled back safely.
final class PreparedPlayerTransferStrategy {
  PreparedPlayerTransferStrategy._(
      this.context, Map<String, PresidentManagementProfile> aiProfiles)
      : aiProfiles = Map.unmodifiable(aiProfiles);
  final PlayerTransferStrategyDecisionContext context;
  final Map<String, PresidentManagementProfile> aiProfiles;
  PlayerTransferStrategyChoice? _accepted;
  Map<String, PresidentManagementProfile>? _effective;
  bool _failed = false;

  Map<String, PresidentManagementProfile> accept({
    required PlayerTransferStrategyDecisionContext expectedContext,
    required PlayerTransferStrategyChoice choice,
    PlayerTransferStrategyDecisionProvider? provider,
  }) {
    if (_failed || !identical(context, expectedContext)) {
      throw StateError('Foreign context or failed transfer decision attempt.');
    }
    choice.validate();
    final previous = _accepted;
    if (previous != null) {
      if (previous.signature != choice.signature) {
        throw StateError('Conflicting duplicate transfer strategy answer.');
      }
      return _effective!;
    }
    final profile = choice.applyTo(context.aiProfile);
    final effective = Map<String, PresidentManagementProfile>.from(aiProfiles);
    effective[context.controlledClubId] = profile;
    final result =
        Map<String, PresidentManagementProfile>.unmodifiable(effective);
    try {
      provider?.onApplied(context, choice, profile);
    } catch (_) {
      _failed = true;
      rethrow;
    }
    _accepted = choice;
    return _effective = result;
  }
}

class PlayerPresidentTransferStrategyWorldBridge {
  const PlayerPresidentTransferStrategyWorldBridge();

  WorldCareerEngine wrap({
    required WorldCareerEngine base,
    required PresidentTransferStrategyProfileProvider aiProfileProvider,
    required String controlledClubId,
    PlayerTransferStrategyDecisionProvider? decisionProvider,
  }) =>
      const PresidentTransferStrategyWorldBridge().wrap(
        base: base,
        profileProvider: PlayerPresidentTransferStrategyProfileProvider(
          aiProfileProvider: aiProfileProvider,
          controlledClubId: controlledClubId,
          decisionProvider: decisionProvider,
        ),
      );
}
