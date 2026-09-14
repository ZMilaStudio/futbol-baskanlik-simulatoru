import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart';
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
      PlayerFacilityInvestmentContext context) {
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

class _LabelSponsorProvider extends PlayerSponsorDecisionProvider {
  const _LabelSponsorProvider(this.label);

  final String label;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final offer = context.offers.firstWhere(
      (item) => item.id.endsWith('-$label'),
    );
    return PlayerSponsorOfferChoice(offerId: offer.id);
  }
}

class _CountingLabelSponsorProvider extends PlayerSponsorDecisionProvider {
  _CountingLabelSponsorProvider(this.label);

  final String label;
  int calls = 0;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    calls++;
    final offer = context.offers.firstWhere(
      (item) => item.id.endsWith('-$label'),
    );
    return PlayerSponsorOfferChoice(offerId: offer.id);
  }
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

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

  test('M69 without sponsor provider preserves M68 exactly', () {
    const m68 =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      facilityProvider: _HoldFacilityProvider(),
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const m69 =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      facilityProvider: _HoldFacilityProvider(),
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = m68.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final composed = m69.simulateWithCheckpoint(
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

  test('M69 composes six player providers in one real season boundary', () {
    final sponsor = _CountingNonAiSponsorProvider();
    final facility = _CountingHoldFacilityProvider();
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final result =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: sponsor,
      facilityProvider: facility,
      promiseProvider: promise,
      mediaProvider: media,
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

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
      'M69 sponsor override changes one club and keeps 47 AI sponsor rows exact',
      () {
    const baselineEngine =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const playerEngine =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: _NonAiSponsorProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = baselineEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final player = playerEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    final baselineSponsor = baseline.boundaries.single.source.source.sponsor;
    final playerSponsor = player.boundaries.single.source.source.sponsor;
    final baselineByClub = {
      for (final item in baselineSponsor.contracts)
        item.offer.clubId: item.signature,
    };
    final playerByClub = {
      for (final item in playerSponsor.contracts)
        item.offer.clubId: item.signature,
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
    expect(
      player.boundaries.single.financeFor(interactiveClubId).sponsorRevenue,
      playerSponsor.revenueByClub[interactiveClubId],
    );
  });

  test('M69 active multi-year sponsor contract is not reselected', () {
    final sponsor = _CountingLabelSponsorProvider('stable');
    final result =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: sponsor,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 3,
    );

    expect(sponsor.calls, 1);
    final signatures = result.boundaries
        .map(
          (boundary) => boundary.source.source.sponsor.contracts
              .firstWhere(
                (item) => item.offer.clubId == interactiveClubId,
              )
              .signature,
        )
        .toList(growable: false);
    expect(signatures.toSet(), hasLength(1));
  });

  test('M69 lost and incumbent mismatch both block sponsor control', () {
    final boldSeed =
        const PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: _LabelSponsorProvider('bold'),
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

    final lostProvider = _CountingNonAiSponsorProvider();
    final lost = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: boldSeed.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm69-former-president',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: boldSeed.completedSeasons,
        successorPresidentId: 'm69-successor-president',
      ),
    );
    final lostResult =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: lostProvider,
    ).resume(
      checkpoint: lost,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(lostProvider.calls, 0);
    expect(lostResult.checkpoint.tenureControl.lost, isTrue);

    final mismatchProvider = _CountingNonAiSponsorProvider();
    final mismatch = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: boldSeed.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm69-non-incumbent-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    final mismatchResult =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: mismatchProvider,
    ).resume(
      checkpoint: mismatch,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(mismatchProvider.calls, 0);
    expect(mismatchResult.checkpoint.tenureControl.lost, isTrue);
  });

  test('M69 M65 codec 2 plus 2 resume matches uninterrupted four seasons', () {
    const engine =
        PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: _NonAiSponsorProvider(),
      facilityProvider: _HoldFacilityProvider(),
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
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
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final resumed = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
