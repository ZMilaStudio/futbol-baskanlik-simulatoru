import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_runtime_controls.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const domain = PresidentDomainCareerEngine();
  const forcedCrisis = CrisisDecisionEngine(activationThreshold: 0);
  const codec = PlayerPresidentTenureGatedRuntimeSaveCodec();

  final beforeElection = domain.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 3,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final afterElection = domain.resume(
    checkpoint: beforeElection.checkpoint,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final beforeIds = {
    for (final item in beforeElection.checkpoint.presidentRuntime.clubs)
      item.clubId: item.tenure.president.id,
  };
  final afterIds = {
    for (final item in afterElection.checkpoint.presidentRuntime.clubs)
      item.clubId: item.tenure.president.id,
  };
  final turnoverClub = beforeIds.keys.firstWhere(
    (id) => beforeIds[id] != afterIds[id],
  );
  final reelectedClub = beforeIds.keys.firstWhere(
    (id) => beforeIds[id] == afterIds[id],
  );

  final beforeCalls = _Calls();
  final before = _probeEngine(beforeCalls).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: turnoverClub,
    seasonCount: 3,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final turnoverCalls = _Calls();
  final turnover = _probeEngine(turnoverCalls).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: turnoverClub,
    seasonCount: 4,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final reelectedBeforeCalls = _Calls();
  _probeEngine(reelectedBeforeCalls).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClub,
    seasonCount: 3,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final reelectedCalls = _Calls();
  final reelected = _probeEngine(reelectedCalls).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClub,
    seasonCount: 4,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );

  final restoredLost = codec.decode(codec.encode(turnover.checkpoint));
  const aiEngine = PlayerPresidentTenureGatedRuntimeCareerEngine(
    aiCrisisEngine: forcedCrisis,
  );
  const poisonEngine = PlayerPresidentTenureGatedRuntimeCareerEngine(
    managerProvider: _PoisonManager(),
    crisisProvider: _PoisonCrisis(),
    sponsorProvider: _PoisonSponsor(),
    facilityProvider: _PoisonFacility(),
    aiCrisisEngine: forcedCrisis,
  );
  final aiAfterLoss = aiEngine.resume(
    checkpoint: restoredLost,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final guardedAfterLoss = poisonEngine.resume(
    checkpoint: restoredLost,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );

  const deterministicEngine = PlayerPresidentTenureGatedRuntimeCareerEngine(
    managerProvider: _AiManager(),
    crisisProvider: _AiCrisis(),
    sponsorProvider: _AiSponsor(),
    facilityProvider: _HoldFacility(),
    aiCrisisEngine: forcedCrisis,
  );
  final direct = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClub,
    seasonCount: 4,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final splitFirst = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClub,
    seasonCount: 2,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final splitSecond = deterministicEngine.resume(
    checkpoint: codec.decode(codec.encode(splitFirst.checkpoint)),
    seasonCount: 2,
    hasFutureSeasonAfterReport: true,
  );

  final playerId = turnover.checkpoint.tenureControl.playerPresidentId;
  final activeDelegation = before.checkpoint.tenureControl.active &&
      beforeCalls.facilityIds.isNotEmpty &&
      beforeCalls.crisisIds.isNotEmpty &&
      beforeCalls.managerIds.isNotEmpty &&
      beforeCalls.sponsorIds.isNotEmpty;
  final turnoverStopsControl = turnover.checkpoint.tenureControl.lost &&
      turnover.checkpoint.tenureControl.lostAtCompletedSeason == 4 &&
      _allIds(turnoverCalls).every((id) => id == playerId) &&
      turnoverCalls.facilityIds.length == beforeCalls.facilityIds.length &&
      turnoverCalls.crisisIds.length == beforeCalls.crisisIds.length;
  final reelectionKeepsControl = reelected.checkpoint.tenureControl.active &&
      reelectedCalls.facilityIds.length ==
          reelectedBeforeCalls.facilityIds.length + 1 &&
      reelectedCalls.crisisIds.length == reelectedBeforeCalls.crisisIds.length + 1;
  final exactAiAfterLoss =
      guardedAfterLoss.checkpoint.signature == aiAfterLoss.checkpoint.signature;
  final deterministic =
      codec.encode(splitSecond.checkpoint) == codec.encode(direct.checkpoint);

  if (!activeDelegation ||
      !turnoverStopsControl ||
      !reelectionKeepsControl ||
      !exactAiAfterLoss ||
      !deterministic) {
    throw StateError(
      'M59 mismatch active=$activeDelegation turnover=$turnoverStopsControl '
      'reelection=$reelectionKeepsControl aiAfterLoss=$exactAiAfterLoss '
      'deterministic=$deterministic',
    );
  }

  print(
    'M59_PLAYER_PRESIDENT_TENURE_GATED_RUNTIME_CONTROLS_PASS '
    'turnoverClub=$turnoverClub reelectedClub=$reelectedClub '
    'activeDelegation=$activeDelegation '
    'turnoverStopsControl=$turnoverStopsControl '
    'reelectionKeepsControl=$reelectionKeepsControl '
    'exactAiAfterLoss=$exactAiAfterLoss deterministic=$deterministic '
    'worldClubs=${world.clubs.length}',
  );
}

PlayerPresidentTenureGatedRuntimeCareerEngine _probeEngine(_Calls calls) =>
    PlayerPresidentTenureGatedRuntimeCareerEngine(
      managerProvider: _ProbeManager(calls),
      crisisProvider: _ProbeCrisis(calls),
      sponsorProvider: _ProbeSponsor(calls),
      facilityProvider: _ProbeFacility(calls),
      aiCrisisEngine: const CrisisDecisionEngine(activationThreshold: 0),
    );

Iterable<String> _allIds(_Calls calls) sync* {
  yield* calls.facilityIds;
  yield* calls.sponsorIds;
  yield* calls.crisisIds;
  yield* calls.managerIds;
}

class _Calls {
  final List<String> facilityIds = [];
  final List<String> sponsorIds = [];
  final List<String> crisisIds = [];
  final List<String> managerIds = [];
}

class _ProbeFacility extends PlayerFacilityInvestmentDecisionProvider {
  _ProbeFacility(this.calls);
  final _Calls calls;
  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    calls.facilityIds.add(context.presidentId);
    return PlayerFacilityInvestmentChoice.hold;
  }
}

class _ProbeSponsor extends PlayerSponsorDecisionProvider {
  _ProbeSponsor(this.calls);
  final _Calls calls;
  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    calls.sponsorIds.add(context.presidentId);
    return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
  }
}

class _ProbeCrisis extends PlayerCrisisDecisionProvider {
  _ProbeCrisis(this.calls);
  final _Calls calls;
  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    calls.crisisIds.add(context.presidentId);
    return PlayerCrisisActionChoice(action: context.aiDecision.action);
  }
}

class _ProbeManager extends PlayerManagerDecisionProvider {
  _ProbeManager(this.calls);
  final _Calls calls;
  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    calls.managerIds.add(context.presidentId);
    return context.aiWouldReplace
        ? PlayerManagerReviewChoice.replace
        : PlayerManagerReviewChoice.retain;
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    calls.managerIds.add(context.presidentId);
    return PlayerManagerReplacementChoice(managerId: context.aiChoice.id);
  }
}

class _HoldFacility extends PlayerFacilityInvestmentDecisionProvider {
  const _HoldFacility();
  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) =>
      PlayerFacilityInvestmentChoice.hold;
}

class _AiSponsor extends PlayerSponsorDecisionProvider {
  const _AiSponsor();
  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) =>
      PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
}

class _AiCrisis extends PlayerCrisisDecisionProvider {
  const _AiCrisis();
  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) =>
      PlayerCrisisActionChoice(action: context.aiDecision.action);
}

class _AiManager extends PlayerManagerDecisionProvider {
  const _AiManager();
  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) =>
      context.aiWouldReplace
          ? PlayerManagerReviewChoice.replace
          : PlayerManagerReviewChoice.retain;
  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) =>
      PlayerManagerReplacementChoice(managerId: context.aiChoice.id);
}

class _PoisonFacility extends PlayerFacilityInvestmentDecisionProvider {
  const _PoisonFacility();
  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    throw StateError('Facility provider called after presidency loss.');
  }
}

class _PoisonSponsor extends PlayerSponsorDecisionProvider {
  const _PoisonSponsor();
  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    throw StateError('Sponsor provider called after presidency loss.');
  }
}

class _PoisonCrisis extends PlayerCrisisDecisionProvider {
  const _PoisonCrisis();
  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    throw StateError('Crisis provider called after presidency loss.');
  }
}

class _PoisonManager extends PlayerManagerDecisionProvider {
  const _PoisonManager();
  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    throw StateError('Manager provider called after presidency loss.');
  }
  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    throw StateError('Manager replacement called after presidency loss.');
  }
}
