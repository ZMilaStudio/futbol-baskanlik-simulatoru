import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

class _AlwaysBalancedPolicy extends PresidentMatchdayTicketPricingPolicy {
  const _AlwaysBalancedPolicy();

  @override
  MatchdayTicketPricingChoice choose({
    required PresidentManagementProfile profile,
    required int fanTrust,
    required StadiumAttendanceProfile base,
  }) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced);
}

class _PremiumTicketProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  const _PremiumTicketProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
}

class _CountingPremiumTicketProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  int calls = 0;

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    calls++;
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
  }
}

class _YouthTransferProvider extends PlayerTransferStrategyDecisionProvider {
  const _YouthTransferProvider();

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      const PlayerTransferStrategyChoice(
        financialDiscipline: 60,
        transferAmbition: 60,
        riskAppetite: 60,
        youthOrientation: 90,
      );
}

class _CountingYouthTransferProvider
    extends PlayerTransferStrategyDecisionProvider {
  int calls = 0;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    calls++;
    return const PlayerTransferStrategyChoice(
      financialDiscipline: 60,
      transferAmbition: 60,
      riskAppetite: 60,
      youthOrientation: 90,
    );
  }
}

class _AlternativePromiseProvider extends PlayerPromiseDecisionProvider {
  const _AlternativePromiseProvider();

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      context.allowedTypes.firstWhere(
        (type) => type != context.aiPromise.type,
        orElse: () => context.aiPromise.type,
      );
}

class _CountingAlternativePromiseProvider
    extends PlayerPromiseDecisionProvider {
  int calls = 0;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    calls++;
    return context.allowedTypes.firstWhere(
      (type) => type != context.aiPromise.type,
      orElse: () => context.aiPromise.type,
    );
  }
}

class _AlternativeMediaProvider extends PlayerMediaStatementDecisionProvider {
  const _AlternativeMediaProvider();

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) =>
      context.allowedStances.firstWhere(
        (stance) => stance != context.aiStatement.stance,
      );
}

class _CountingAlternativeMediaProvider
    extends PlayerMediaStatementDecisionProvider {
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    return context.allowedStances.firstWhere(
      (stance) => stance != context.aiStatement.stance,
    );
  }
}

class _HoldFacilityProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _HoldFacilityProvider();

  @override
  PlayerFacilityInvestmentChoice choose(
    PlayerFacilityInvestmentContext context,
  ) =>
      PlayerFacilityInvestmentChoice.hold;
}

class _CountingHoldFacilityProvider
    extends PlayerFacilityInvestmentDecisionProvider {
  int calls = 0;

  @override
  PlayerFacilityInvestmentChoice choose(
    PlayerFacilityInvestmentContext context,
  ) {
    calls++;
    return PlayerFacilityInvestmentChoice.hold;
  }
}

class _NonAiSponsorProvider extends PlayerSponsorDecisionProvider {
  const _NonAiSponsorProvider();

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final alternative = context.offers.firstWhere(
      (offer) => offer.id != context.aiChoice.id,
    );
    return PlayerSponsorOfferChoice(offerId: alternative.id);
  }
}

class _CountingNonAiSponsorProvider extends PlayerSponsorDecisionProvider {
  int calls = 0;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    calls++;
    final alternative = context.offers.firstWhere(
      (offer) => offer.id != context.aiChoice.id,
    );
    return PlayerSponsorOfferChoice(offerId: alternative.id);
  }
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

class _CountingNonAiCrisisProvider extends PlayerCrisisDecisionProvider {
  int calls = 0;

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    calls++;
    final alternative = context.availableDecisions.firstWhere(
      (decision) => decision.action != context.aiDecision.action,
    );
    return PlayerCrisisActionChoice(action: alternative.action);
  }
}

class _RotatingCrisisProvider extends PlayerCrisisDecisionProvider {
  const _RotatingCrisisProvider();

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    final index = (context.seasonIndex + context.scenario.type.index) %
        context.availableDecisions.length;
    return PlayerCrisisActionChoice(
      action: context.availableDecisions[index].action,
    );
  }
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);
  const noCrisis = CrisisDecisionEngine(activationThreshold: 101);

  late FictionalWorldSetup world;
  late String interactiveClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    final discovery =
        const PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: world.clubs.first.id,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final boundary = discovery.boundaries.single;
    final source = boundary.source.source.sponsor.report.sourceReport;
    final mediaByClub = {
      for (final item in source.baselineMediaReport.seasons.single.clubs)
        item.clubId: item,
    };
    final investmentByClub = {
      for (final item in boundary.source.decisions) item.clubId: item,
    };
    interactiveClubId = source.promiseReport.snapshots
        .firstWhere(
          (snapshot) =>
              mediaByClub[snapshot.promise.clubId]!.statement != null &&
              PlayerPresidentPromiseGenerator.allowedPromiseTypes(
                snapshot.context,
              ).any((type) => type != snapshot.promise.type) &&
              investmentByClub[snapshot.promise.clubId]!.invested,
        )
        .promise
        .clubId;
  });

  test('M70 without crisis provider preserves M69 exactly', () {
    const m69 =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: _NonAiSponsorProvider(),
      facilityProvider: _HoldFacilityProvider(),
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const m70 =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: _NonAiSponsorProvider(),
      facilityProvider: _HoldFacilityProvider(),
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = m69.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final composed = m70.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );

    expect(
        codec.encode(composed.checkpoint), codec.encode(baseline.checkpoint));
    expect(
      composed.boundaries.map((item) => item.signature).toList(),
      baseline.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M70 composes seven player providers in one real season boundary', () {
    final crisis = _CountingNonAiCrisisProvider();
    final sponsor = _CountingNonAiSponsorProvider();
    final facility = _CountingHoldFacilityProvider();
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final result =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: crisis,
      sponsorProvider: sponsor,
      facilityProvider: facility,
      promiseProvider: promise,
      mediaProvider: media,
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    expect(crisis.calls, 1);
    expect(sponsor.calls, 1);
    expect(facility.calls, 1);
    expect(promise.calls, 1);
    expect(media.calls, 1);
    expect(transfer.calls, greaterThan(0));
    expect(ticket.calls, 1);
    expect(
      result.boundaries.single.decisionFor(interactiveClubId).providerCalled,
      isTrue,
    );
  });

  test(
      'M70 crisis override changes one club, keeps 47 AI rows exact, and persists real effects',
      () {
    const baselineEngine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const playerEngine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: _NonAiCrisisProvider(),
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = baselineEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
    );
    final player = playerEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
    );

    final baselineCrisis = baseline.boundaries.single.source.source.crisis;
    final playerCrisis = player.boundaries.single.source.source.crisis;
    final baselineByClub = {
      for (final item in baselineCrisis.clubs)
        item.clubId: item.resolution!.signature,
    };
    final playerByClub = {
      for (final item in playerCrisis.clubs)
        item.clubId: item.resolution!.signature,
    };
    expect(
      playerByClub[interactiveClubId],
      isNot(baselineByClub[interactiveClubId]),
    );
    final aiIds = baselineByClub.keys
        .where((id) => id != interactiveClubId)
        .toList(growable: false);
    expect(aiIds, hasLength(47));
    for (final id in aiIds) {
      expect(playerByClub[id], baselineByClub[id], reason: id);
    }

    final snapshot = playerCrisis.clubs
        .firstWhere((item) => item.clubId == interactiveClubId);
    final resolution = snapshot.resolution!;
    final finance = playerCrisis.checkpoint.presidentRuntime.runtime.runtime
        .world.nextSeasonFinanceStates
        .firstWhere((item) => item.clubId == interactiveClubId);
    final president = playerCrisis.checkpoint.presidentRuntime.clubs
        .firstWhere((item) => item.clubId == interactiveClubId);
    expect(finance.signature, resolution.finance.signature);
    expect(president.fanReputation.signature, resolution.fan.signature);
    expect(president.mediaReputation.signature, resolution.media.signature);
    expect(finance.debt, snapshot.context.finance.debt);
  });

  test('M70 does not call player crisis provider when no crisis exists', () {
    const baselineEngine =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisIntegration: CrisisRuntimeIntegrationEngine(
        decisionEngine: noCrisis,
      ),
    );
    final provider = _CountingNonAiCrisisProvider();
    final player =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: provider,
      aiCrisisEngine: noCrisis,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final baseline = baselineEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );

    expect(provider.calls, 0);
    expect(codec.encode(player.checkpoint), codec.encode(baseline.checkpoint));
    expect(player.signature, baseline.signature);
  });

  test('M70 lost and incumbent mismatch both block crisis control', () {
    final seedCheckpoint =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      aiCrisisEngine: forcedAi,
    )
            .simulateWithCheckpoint(
              clubs: world.clubs,
              leagues: world.leagues,
              config: config,
              controlledClubId: interactiveClubId,
              seasonCount: 1,
              hasFutureSeasonAfterReport: true,
            )
            .checkpoint;

    final lostProvider = _CountingNonAiCrisisProvider();
    final lost = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: seedCheckpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm70-former-president',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: seedCheckpoint.completedSeasons,
        successorPresidentId: 'm70-successor-president',
      ),
    );
    final lostResult =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: lostProvider,
      aiCrisisEngine: forcedAi,
    ).resume(
      checkpoint: lost,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(lostProvider.calls, 0);
    expect(lostResult.checkpoint.tenureControl.lost, isTrue);

    final mismatchProvider = _CountingNonAiCrisisProvider();
    final mismatch = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: seedCheckpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm70-non-incumbent-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    final mismatchResult =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: mismatchProvider,
      aiCrisisEngine: forcedAi,
    ).resume(
      checkpoint: mismatch,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(mismatchProvider.calls, 0);
    expect(mismatchResult.checkpoint.tenureControl.lost, isTrue);
  });

  test('M70 M65 codec keeps 2 plus 2 resume deterministic against four seasons',
      () {
    const engine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: _RotatingCrisisProvider(),
      sponsorProvider: _NonAiSponsorProvider(),
      facilityProvider: _HoldFacilityProvider(),
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      aiCrisisEngine: forcedAi,
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 4,
      electionInterval: 4,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final encoded = codec.encode(first.checkpoint);
    final loaded = codec.decode(encoded);
    final second = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(codec.encode(loaded), encoded);
    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
