import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const controlled = 't1_02';
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);
  const codec = PlayerPresidentCrisisControlSaveCodec();

  final baseline = const PlayerPresidentSponsorControlCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final neutral = const PlayerPresidentCrisisControlCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final neutralM50Parity =
      neutral.checkpoint.control.signature == baseline.checkpoint.signature &&
          neutral.source.signature == baseline.signature;

  final forcedBaseline = const PlayerPresidentSponsorControlCareerEngine(
    crisisIntegration: CrisisRuntimeIntegrationEngine(
      decisionEngine: forcedAi,
    ),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
  );
  final forcedPlayerParity = const PlayerPresidentCrisisControlCareerEngine(
    crisisProvider: _NonAiCrisisProvider(),
    aiCrisisEngine: forcedAi,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
  );

  const engine = PlayerPresidentCrisisControlCareerEngine(
    crisisProvider: _NonAiCrisisProvider(),
    sponsorProvider: _BoldSponsorProvider(),
    facilityProvider: _AlternatingFacilityProvider(),
    aiCrisisEngine: forcedAi,
  );
  final direct = engine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 4,
    electionInterval: 2,
  );

  final parityDecision = forcedPlayerParity.crisisDecisions.single;
  final forcedBaselineByClub = {
    for (final item in forcedBaseline.boundaries.first.source.crisis.clubs)
      item.clubId: item.resolution!.signature,
  };
  final parityPlayerByClub = {
    for (final item
        in forcedPlayerParity.boundaries.first.source.crisis.clubs)
      item.clubId: item.resolution!.signature,
  };
  final aiParityCount = world.clubs
      .where((club) => club.id != controlled)
      .where(
        (club) =>
            parityPlayerByClub[club.id] == forcedBaselineByClub[club.id],
      )
      .length;

  final firstDecision = direct.crisisDecisions.first;
  final firstCrisis = direct.boundaries.first.source.crisis;
  final finance = firstCrisis.checkpoint.presidentRuntime.runtime.runtime.world
      .nextSeasonFinanceStates
      .firstWhere((item) => item.clubId == controlled);
  final president = firstCrisis.checkpoint.presidentRuntime.clubs
      .firstWhere((item) => item.clubId == controlled);
  final crisisStateWired =
      finance.signature == firstDecision.resolution.finance.signature &&
          president.fanReputation.signature ==
              firstDecision.resolution.fan.signature &&
          president.mediaReputation.signature ==
              firstDecision.resolution.media.signature;
  final debtPreserved = finance.debt == firstDecision.context.finance.debt;

  final first = engine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
    electionInterval: 2,
    hasFutureSeasonAfterReport: true,
  );
  final encoded = codec.encode(first.checkpoint);
  final loaded = codec.decode(encoded);
  final second = engine.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );
  final finalCheckpointMatch =
      codec.encode(second.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch =
      [...first.boundaries, ...second.boundaries]
              .map((item) => item.signature)
              .join('||') ==
          direct.boundaries.map((item) => item.signature).join('||');
  final decisionMatch =
      [...first.crisisDecisions, ...second.crisisDecisions]
              .map((item) => item.signature)
              .join('||') ==
          direct.crisisDecisions.map((item) => item.signature).join('||');
  final sponsorDecisionMatch =
      [
        ...first.source.sponsorDecisions,
        ...second.source.sponsorDecisions,
      ].map((item) => item.signature).join('||') ==
          direct.source.sponsorDecisions
              .map((item) => item.signature)
              .join('||');
  final controlledClubPersisted = loaded.controlledClubId == controlled &&
      second.checkpoint.controlledClubId == controlled;
  final playerCrisisWindows = direct.crisisDecisions.length;
  final changedFromAiCount =
      direct.crisisDecisions.where((item) => item.changedFromAi).length;

  if (!neutralM50Parity) {
    throw StateError('M51 no-provider path must preserve M50 exactly.');
  }
  if (parityDecision.clubId != controlled || !parityDecision.changedFromAi) {
    throw StateError('M51 player must override only the controlled crisis.');
  }
  if (aiParityCount != world.clubs.length - 1) {
    throw StateError('M51 must preserve AI crisis results for the other 47 clubs.');
  }
  if (!crisisStateWired || !debtPreserved) {
    throw StateError('M51 player crisis action must reach real state without debt.');
  }
  if (!controlledClubPersisted) {
    throw StateError('M51 controlled club must persist through save/load.');
  }
  if (!finalCheckpointMatch ||
      !boundaryMatch ||
      !decisionMatch ||
      !sponsorDecisionMatch) {
    throw StateError('M51 save/resume parity failed.');
  }
  if (playerCrisisWindows != 4 || changedFromAiCount != 4) {
    throw StateError('M51 forced canonical run must create four player overrides.');
  }

  print('M51_PLAYER_CRISIS_CONTROL_PASS');
  print('seed=$seed');
  print('controlledClub=$controlled');
  print('aiParityCount=$aiParityCount');
  print('playerCrisisWindows=$playerCrisisWindows');
  print('changedFromAiCount=$changedFromAiCount');
  print('firstScenario=${firstDecision.context.scenario.signature}');
  print('firstAiAction=${firstDecision.aiDecision.action.name}');
  print('firstPlayerAction=${firstDecision.selectedDecision.action.name}');
  print('neutralM50Parity=$neutralM50Parity');
  print('crisisStateWired=$crisisStateWired');
  print('debtPreserved=$debtPreserved');
  print('controlledClubPersisted=$controlledClubPersisted');
  print('finalCheckpointMatch=$finalCheckpointMatch');
  print('boundaryMatch=$boundaryMatch');
  print('decisionMatch=$decisionMatch');
  print('sponsorDecisionMatch=$sponsorDecisionMatch');
  print('saveBytes=${encoded.length}');
}

class _NonAiCrisisProvider extends PlayerCrisisDecisionProvider {
  const _NonAiCrisisProvider();

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    final alternative = context.availableDecisions.firstWhere(
      (decision) => decision.action != context.aiDecision.action,
    );
    return PlayerCrisisActionChoice(action: alternative.action);
  }
}

class _BoldSponsorProvider extends PlayerSponsorDecisionProvider {
  const _BoldSponsorProvider();

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final offer = context.offers.firstWhere((item) => item.id.endsWith('-bold'));
    return PlayerSponsorOfferChoice(offerId: offer.id);
  }
}

class _AlternatingFacilityProvider
    extends PlayerFacilityInvestmentDecisionProvider {
  const _AlternatingFacilityProvider();

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    if (context.seasonIndex.isEven) {
      return const PlayerFacilityInvestmentChoice(stadiumUpgrades: 1);
    }
    return const PlayerFacilityInvestmentChoice(trainingGroundUpgrades: 1);
  }
}
