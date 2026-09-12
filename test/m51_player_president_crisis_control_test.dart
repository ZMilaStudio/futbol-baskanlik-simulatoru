import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const controlled = 't1_02';
  const m50 = PlayerPresidentSponsorControlCareerEngine();
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);
  const codec = PlayerPresidentCrisisControlSaveCodec();

  test('M51 without a crisis provider preserves M50 exactly', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m50.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );
    final player = const PlayerPresidentCrisisControlCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );

    expect(player.checkpoint.control.signature, baseline.checkpoint.signature);
    expect(player.source.signature, baseline.signature);
    expect(player.crisisDecisions, isEmpty);
  });

  test('M51 crisis choice overrides only the controlled club', () {
    final world = const FictionalWorldFactory().build();
    final baseline = const PlayerPresidentSponsorControlCareerEngine(
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
    final player = const PlayerPresidentCrisisControlCareerEngine(
      crisisProvider: _NonAiCrisisProvider(),
      aiCrisisEngine: forcedAi,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );

    expect(player.crisisDecisions, hasLength(1));
    final decision = player.crisisDecisions.single;
    expect(decision.clubId, controlled);
    expect(decision.changedFromAi, isTrue);

    final baselineByClub = {
      for (final item in baseline.boundaries.single.source.crisis.clubs)
        item.clubId: item.resolution!.signature,
    };
    final playerByClub = {
      for (final item in player.boundaries.single.source.crisis.clubs)
        item.clubId: item.resolution!.signature,
    };
    expect(playerByClub[controlled], isNot(baselineByClub[controlled]));
    for (final club in world.clubs.where((club) => club.id != controlled)) {
      expect(playerByClub[club.id], baselineByClub[club.id]);
    }
  });

  test('M51 selected crisis action writes real continuation state without debt', () {
    final world = const FictionalWorldFactory().build();
    final player = const PlayerPresidentCrisisControlCareerEngine(
      crisisProvider: _NonAiCrisisProvider(),
      aiCrisisEngine: forcedAi,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );

    final decision = player.crisisDecisions.single;
    final crisis = player.boundaries.single.source.crisis;
    final finance = crisis.checkpoint.presidentRuntime.runtime.runtime.world
        .nextSeasonFinanceStates
        .firstWhere((item) => item.clubId == controlled);
    final president = crisis.checkpoint.presidentRuntime.clubs
        .firstWhere((item) => item.clubId == controlled);

    expect(finance.signature, decision.resolution.finance.signature);
    expect(
      president.fanReputation.signature,
      decision.resolution.fan.signature,
    );
    expect(
      president.mediaReputation.signature,
      decision.resolution.media.signature,
    );
    expect(finance.debt, decision.context.finance.debt);
  });

  test('M51 does not request a player decision when there is no crisis', () {
    final world = const FictionalWorldFactory().build();
    const noCrisis = CrisisDecisionEngine(activationThreshold: 101);
    final baseline = const PlayerPresidentSponsorControlCareerEngine(
      crisisIntegration: CrisisRuntimeIntegrationEngine(
        decisionEngine: noCrisis,
      ),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
    );
    final player = const PlayerPresidentCrisisControlCareerEngine(
      crisisProvider: _FailIfCalledProvider(),
      aiCrisisEngine: noCrisis,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
    );

    expect(player.crisisDecisions, isEmpty);
    expect(player.checkpoint.control.signature, baseline.checkpoint.signature);
    expect(player.source.signature, baseline.signature);
  });

  test('M51 save round trip and 2 plus 2 resume match four seasons', () {
    final world = const FictionalWorldFactory().build();
    const engine = PlayerPresidentCrisisControlCareerEngine(
      crisisProvider: _RotatingCrisisProvider(),
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

    expect(loaded.controlledClubId, controlled);
    expect(codec.encode(loaded), encoded);
    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(
      [...first.crisisDecisions, ...second.crisisDecisions]
          .map((item) => item.signature)
          .toList(),
      direct.crisisDecisions.map((item) => item.signature).toList(),
    );
    expect(
      [
        ...first.source.sponsorDecisions,
        ...second.source.sponsorDecisions,
      ].map((item) => item.signature).toList(),
      direct.source.sponsorDecisions.map((item) => item.signature).toList(),
    );
  });
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

class _FailIfCalledProvider extends PlayerCrisisDecisionProvider {
  const _FailIfCalledProvider();

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    throw StateError('Provider must not be called without a detected crisis.');
  }
}

class _RotatingCrisisProvider extends PlayerCrisisDecisionProvider {
  const _RotatingCrisisProvider();

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    final index =
        (context.seasonIndex + context.scenario.type.index) %
            context.availableDecisions.length;
    return PlayerCrisisActionChoice(
      action: context.availableDecisions[index].action,
    );
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
