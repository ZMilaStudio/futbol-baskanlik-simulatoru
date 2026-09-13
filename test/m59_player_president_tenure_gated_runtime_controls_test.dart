import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_runtime_controls.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const forcedCrisis = CrisisDecisionEngine(activationThreshold: 0);
  const codec = PlayerPresidentTenureGatedRuntimeSaveCodec();

  late String turnoverClubId;
  late String reelectedClubId;

  setUpAll(() {
    final world = const FictionalWorldFactory().build();
    const domain = PresidentDomainCareerEngine();
    final before = domain.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final after = domain.resume(
      checkpoint: before.checkpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final beforeIds = {
      for (final item in before.checkpoint.presidentRuntime.clubs)
        item.clubId: item.tenure.president.id,
    };
    final afterIds = {
      for (final item in after.checkpoint.presidentRuntime.clubs)
        item.clubId: item.tenure.president.id,
    };
    turnoverClubId = beforeIds.keys.firstWhere(
      (clubId) => beforeIds[clubId] != afterIds[clubId],
    );
    reelectedClubId = beforeIds.keys.firstWhere(
      (clubId) => beforeIds[clubId] == afterIds[clubId],
    );
  });

  test('M59 active incumbent delegates nested decisions to player providers', () {
    final world = const FictionalWorldFactory().build();
    final calls = _ProviderCalls();
    final result = _probeEngine(calls).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );

    expect(result.checkpoint.tenureControl.active, isTrue);
    expect(calls.facilityPresidentIds, isNotEmpty);
    expect(calls.crisisPresidentIds, isNotEmpty);
    expect(calls.managerPresidentIds, isNotEmpty);
    expect(calls.sponsorPresidentIds, isNotEmpty);
    final playerId = result.checkpoint.tenureControl.playerPresidentId;
    expect(_allIds(calls).every((id) => id == playerId), isTrue);
  });

  test('M59 real turnover blocks external providers in the turnover boundary', () {
    final world = const FictionalWorldFactory().build();
    final beforeCalls = _ProviderCalls();
    final before = _probeEngine(beforeCalls).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final turnoverCalls = _ProviderCalls();
    final after = _probeEngine(turnoverCalls).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );

    expect(before.checkpoint.tenureControl.active, isTrue);
    expect(after.checkpoint.tenureControl.lost, isTrue);
    expect(after.checkpoint.tenureControl.lostAtCompletedSeason, 4);
    expect(
      after.checkpoint.tenureControl.successorPresidentId,
      isNot(after.checkpoint.tenureControl.playerPresidentId),
    );
    final playerId = after.checkpoint.tenureControl.playerPresidentId;
    expect(_allIds(turnoverCalls).every((id) => id == playerId), isTrue);
    expect(
      turnoverCalls.facilityPresidentIds.length,
      beforeCalls.facilityPresidentIds.length,
    );
    expect(
      turnoverCalls.crisisPresidentIds.length,
      beforeCalls.crisisPresidentIds.length,
    );
  });

  test('M59 reelection keeps player runtime control active', () {
    final world = const FictionalWorldFactory().build();
    final beforeCalls = _ProviderCalls();
    _probeEngine(beforeCalls).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final afterCalls = _ProviderCalls();
    final after = _probeEngine(afterCalls).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );

    expect(after.checkpoint.tenureControl.active, isTrue);
    expect(
      afterCalls.facilityPresidentIds.length,
      beforeCalls.facilityPresidentIds.length + 1,
    );
    expect(
      afterCalls.crisisPresidentIds.length,
      beforeCalls.crisisPresidentIds.length + 1,
    );
    final playerId = after.checkpoint.tenureControl.playerPresidentId;
    expect(_allIds(afterCalls).every((id) => id == playerId), isTrue);
  });

  test('M59 lost control resumes on exact AI path without provider calls', () {
    final world = const FictionalWorldFactory().build();
    final lost = _probeEngine(_ProviderCalls()).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    expect(lost.checkpoint.tenureControl.lost, isTrue);

    const baselineEngine = PlayerPresidentTenureGatedRuntimeCareerEngine(
      aiCrisisEngine: forcedCrisis,
    );
    const poisonEngine = PlayerPresidentTenureGatedRuntimeCareerEngine(
      managerProvider: _PoisonManagerProvider(),
      crisisProvider: _PoisonCrisisProvider(),
      sponsorProvider: _PoisonSponsorProvider(),
      facilityProvider: _PoisonFacilityProvider(),
      aiCrisisEngine: forcedCrisis,
    );
    final baseline = baselineEngine.resume(
      checkpoint: lost.checkpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final guarded = poisonEngine.resume(
      checkpoint: lost.checkpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    expect(guarded.checkpoint.tenureControl.lost, isTrue);
    expect(guarded.checkpoint.signature, baseline.checkpoint.signature);
  });

  test('M59 save round trip and 2 plus 2 resume are deterministic', () {
    final world = const FictionalWorldFactory().build();
    const engine = PlayerPresidentTenureGatedRuntimeCareerEngine(
      managerProvider: _AiManagerProvider(),
      crisisProvider: _AiCrisisProvider(),
      sponsorProvider: _AiSponsorProvider(),
      facilityProvider: _HoldFacilityProvider(),
      aiCrisisEngine: forcedCrisis,
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 2,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final encoded = codec.encode(first.checkpoint);
    final loaded = codec.decode(encoded);
    final second = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
      hasFutureSeasonAfterReport: true,
    );

    expect(codec.encode(loaded), encoded);
    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(second.checkpoint.tenureControl.active, isTrue);
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(
      [...first.managerDecisions, ...second.managerDecisions]
          .map((item) => item.signature)
          .toList(),
      direct.managerDecisions.map((item) => item.signature).toList(),
    );
  });
}

PlayerPresidentTenureGatedRuntimeCareerEngine _probeEngine(_ProviderCalls calls) =>
    PlayerPresidentTenureGatedRuntimeCareerEngine(
      managerProvider: _ProbeManagerProvider(calls),
      crisisProvider: _ProbeCrisisProvider(calls),
      sponsorProvider: _ProbeSponsorProvider(calls),
      facilityProvider: _ProbeFacilityProvider(calls),
      aiCrisisEngine: const CrisisDecisionEngine(activationThreshold: 0),
    );

Iterable<String> _allIds(_ProviderCalls calls) sync* {
  yield* calls.facilityPresidentIds;
  yield* calls.sponsorPresidentIds;
  yield* calls.crisisPresidentIds;
  yield* calls.managerPresidentIds;
}

class _ProviderCalls {
  final List<String> facilityPresidentIds = [];
  final List<String> sponsorPresidentIds = [];
  final List<String> crisisPresidentIds = [];
  final List<String> managerPresidentIds = [];
}

class _ProbeFacilityProvider extends PlayerFacilityInvestmentDecisionProvider {
  _ProbeFacilityProvider(this.calls);
  final _ProviderCalls calls;

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    calls.facilityPresidentIds.add(context.presidentId);
    return PlayerFacilityInvestmentChoice.hold;
  }
}

class _ProbeSponsorProvider extends PlayerSponsorDecisionProvider {
  _ProbeSponsorProvider(this.calls);
  final _ProviderCalls calls;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    calls.sponsorPresidentIds.add(context.presidentId);
    return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
  }
}

class _ProbeCrisisProvider extends PlayerCrisisDecisionProvider {
  _ProbeCrisisProvider(this.calls);
  final _ProviderCalls calls;

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    calls.crisisPresidentIds.add(context.presidentId);
    return PlayerCrisisActionChoice(action: context.aiDecision.action);
  }
}

class _ProbeManagerProvider extends PlayerManagerDecisionProvider {
  _ProbeManagerProvider(this.calls);
  final _ProviderCalls calls;

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    calls.managerPresidentIds.add(context.presidentId);
    return context.aiWouldReplace
        ? PlayerManagerReviewChoice.replace
        : PlayerManagerReviewChoice.retain;
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    calls.managerPresidentIds.add(context.presidentId);
    return PlayerManagerReplacementChoice(managerId: context.aiChoice.id);
  }
}

class _HoldFacilityProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _HoldFacilityProvider();
  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) =>
      PlayerFacilityInvestmentChoice.hold;
}

class _AiSponsorProvider extends PlayerSponsorDecisionProvider {
  const _AiSponsorProvider();
  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) =>
      PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
}

class _AiCrisisProvider extends PlayerCrisisDecisionProvider {
  const _AiCrisisProvider();
  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) =>
      PlayerCrisisActionChoice(action: context.aiDecision.action);
}

class _AiManagerProvider extends PlayerManagerDecisionProvider {
  const _AiManagerProvider();
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

class _PoisonFacilityProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _PoisonFacilityProvider();
  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    throw StateError('Facility provider must not run after presidency loss.');
  }
}

class _PoisonSponsorProvider extends PlayerSponsorDecisionProvider {
  const _PoisonSponsorProvider();
  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    throw StateError('Sponsor provider must not run after presidency loss.');
  }
}

class _PoisonCrisisProvider extends PlayerCrisisDecisionProvider {
  const _PoisonCrisisProvider();
  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    throw StateError('Crisis provider must not run after presidency loss.');
  }
}

class _PoisonManagerProvider extends PlayerManagerDecisionProvider {
  const _PoisonManagerProvider();
  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    throw StateError('Manager provider must not run after presidency loss.');
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    throw StateError('Manager replacement provider must not run after presidency loss.');
  }
}
