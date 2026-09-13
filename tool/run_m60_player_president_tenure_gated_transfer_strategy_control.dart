import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_world_bridge.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  const playerPresidentId = 'm60-player-incumbent';

  final aiProfiles = {
    for (final club in world.clubs)
      club.id: _profile(
        club.id == controlledClubId
            ? playerPresidentId
            : '${club.id}-ai-president',
      ),
  };
  final context = PresidentTransferStrategyWindowContext(
    clubs: world.clubs,
    players: const [],
    financeStates: const [],
    careerSeed: seed,
    seasonIndex: 4,
    simulationVersion: 1,
  );
  final activeState = PlayerPresidentTenureControlState(
    controlledClubId: controlledClubId,
    playerPresidentId: playerPresidentId,
    status: PlayerPresidentTenureControlStatus.active,
  );

  final activeDecision = _CountingDecisionProvider();
  final active = PlayerPresidentTenureGatedTransferStrategyProfileProvider(
    aiProfileProvider: _StaticProfileProvider(aiProfiles),
    tenureControl: activeState,
    decisionProvider: activeDecision,
  ).profilesForWindow(context);
  final activeDelegation = activeDecision.calls == 1 &&
      active[controlledClubId]!.youthOrientation == 90;
  final aiParityCount = world.clubs.skip(1).where((club) {
    return active[club.id]!.signature == aiProfiles[club.id]!.signature;
  }).length;

  final successorProfiles = Map<String, PresidentManagementProfile>.from(
    aiProfiles,
  );
  successorProfiles[controlledClubId] = _profile('m60-successor');
  final successorDecision = _CountingDecisionProvider();
  final successor = PlayerPresidentTenureGatedTransferStrategyProfileProvider(
    aiProfileProvider: _StaticProfileProvider(successorProfiles),
    tenureControl: activeState,
    decisionProvider: successorDecision,
  ).profilesForWindow(context);
  final turnoverStopsControl = successorDecision.calls == 0 &&
      _mapSignature(successor) == _mapSignature(successorProfiles);

  final reelectionDecision = _CountingDecisionProvider();
  final reelection =
      PlayerPresidentTenureGatedTransferStrategyProfileProvider(
    aiProfileProvider: _StaticProfileProvider(aiProfiles),
    tenureControl: activeState,
    decisionProvider: reelectionDecision,
  ).profilesForWindow(context);
  final reelectionKeepsControl = reelectionDecision.calls == 1 &&
      reelection[controlledClubId]!.youthOrientation == 90;

  final lostState = PlayerPresidentTenureControlState(
    controlledClubId: controlledClubId,
    playerPresidentId: playerPresidentId,
    status: PlayerPresidentTenureControlStatus.lost,
    lostAtCompletedSeason: 4,
    successorPresidentId: 'm60-successor',
  );
  final restoredLost = const PlayerPresidentTenureControlSaveCodec().decode(
    const PlayerPresidentTenureControlSaveCodec().encode(lostState),
  );
  final lostDecision = _CountingDecisionProvider();
  final lost = PlayerPresidentTenureGatedTransferStrategyProfileProvider(
    aiProfileProvider: _StaticProfileProvider(aiProfiles),
    tenureControl: restoredLost,
    decisionProvider: lostDecision,
  ).profilesForWindow(context);
  final stickyLoss = lostDecision.calls == 0 &&
      _mapSignature(lost) == _mapSignature(aiProfiles);

  final repeatDecision = _CountingDecisionProvider();
  final repeat = PlayerPresidentTenureGatedTransferStrategyProfileProvider(
    aiProfileProvider: _StaticProfileProvider(aiProfiles),
    tenureControl: activeState,
    decisionProvider: repeatDecision,
  ).profilesForWindow(context);
  final deterministic = _mapSignature(active) == _mapSignature(repeat);

  if (!activeDelegation ||
      !turnoverStopsControl ||
      !reelectionKeepsControl ||
      !stickyLoss ||
      aiParityCount != 47 ||
      !deterministic) {
    throw StateError(
      'M60 canonical failure: active=$activeDelegation '
      'turnover=$turnoverStopsControl reelection=$reelectionKeepsControl '
      'sticky=$stickyLoss aiParity=$aiParityCount deterministic=$deterministic',
    );
  }

  print(
    'M60_PLAYER_PRESIDENT_TENURE_GATED_TRANSFER_STRATEGY_CONTROL_PASS '
    'controlled=$controlledClubId aiParity=$aiParityCount '
    'activeDelegation=$activeDelegation '
    'turnoverStopsControl=$turnoverStopsControl '
    'reelectionKeepsControl=$reelectionKeepsControl '
    'stickyLoss=$stickyLoss deterministic=$deterministic '
    'worldClubs=${world.clubs.length}',
  );
}

String _mapSignature(Map<String, PresidentManagementProfile> profiles) {
  final ids = profiles.keys.toList()..sort();
  return ids.map((id) => '$id=${profiles[id]!.signature}').join('|');
}

class _StaticProfileProvider extends PresidentTransferStrategyProfileProvider {
  const _StaticProfileProvider(this.profiles);

  final Map<String, PresidentManagementProfile> profiles;

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) =>
      profiles;
}

class _CountingDecisionProvider extends PlayerTransferStrategyDecisionProvider {
  int calls = 0;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    calls++;
    return const PlayerTransferStrategyChoice(
      financialDiscipline: 90,
      transferAmbition: 20,
      riskAppetite: 20,
      youthOrientation: 90,
    );
  }
}

PresidentManagementProfile _profile(String presidentId) =>
    PresidentManagementProfile(
      presidentId: presidentId,
      archetype: PresidentManagementArchetype.balanced,
      financialDiscipline: 60,
      riskAppetite: 60,
      transferAmbition: 60,
      youthOrientation: 60,
      managerPatience: 60,
    );
