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

class _AlwaysBalancedPolicy extends PresidentMatchdayTicketPricingPolicy {
  const _AlwaysBalancedPolicy();

  @override
  MatchdayTicketPricingChoice choose({
    required PresidentManagementProfile profile,
    required int fanTrust,
    required StadiumAttendanceProfile base,
  }) => const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced);
}

class _PremiumTicketProvider extends PlayerMatchdayTicketPricingDecisionProvider {
  const _PremiumTicketProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) => const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
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
  ) => const PlayerTransferStrategyChoice(
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

class _CountingAlternativePromiseProvider extends PlayerPromiseDecisionProvider {
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
  ) => PlayerFacilityInvestmentChoice.hold;
}

class _CountingHoldFacilityProvider
    extends PlayerFacilityInvestmentDecisionProvider {
  int calls = 0;

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
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

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  final discovery = const
      PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    ticketAiPolicy: _AlwaysBalancedPolicy(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: world.clubs.first.id,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final discoveryBoundary = discovery.boundaries.single;
  final source = discoveryBoundary.source.source.sponsor.report.sourceReport;
  final mediaByClub = {
    for (final item in source.baselineMediaReport.seasons.single.clubs)
      item.clubId: item,
  };
  final investmentByClub = {
    for (final item in discoveryBoundary.source.decisions) item.clubId: item,
  };
  final controlled = source.promiseReport.snapshots
      .firstWhere(
        (snapshot) =>
            mediaByClub[snapshot.promise.clubId]!.statement != null &&
            PlayerPresidentPromiseGenerator.allowedPromiseTypes(snapshot.context)
                .any((type) => type != snapshot.promise.type) &&
            investmentByClub[snapshot.promise.clubId]!.invested,
      )
      .promise
      .clubId;

  const m68 =
      PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    facilityProvider: _HoldFacilityProvider(),
    promiseProvider: _AlternativePromiseProvider(),
    mediaProvider: _AlternativeMediaProvider(),
    transferStrategyProvider: _YouthTransferProvider(),
    ticketPricingProvider: _PremiumTicketProvider(),
    ticketAiPolicy: _AlwaysBalancedPolicy(),
  );
  const parityEngine =
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
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final parity = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final m68ParityWithoutSponsor =
      codec.encode(parity.checkpoint) == codec.encode(baseline.checkpoint) &&
          parity.signature == baseline.signature;

  final sponsor = _CountingNonAiSponsorProvider();
  final facility = _CountingHoldFacilityProvider();
  final promise = _CountingAlternativePromiseProvider();
  final media = _CountingAlternativeMediaProvider();
  final transfer = _CountingYouthTransferProvider();
  final ticket = _CountingPremiumTicketProvider();
  final composed =
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
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final sixProviders = sponsor.calls == 1 &&
      facility.calls == 1 &&
      promise.calls == 1 &&
      media.calls == 1 &&
      transfer.calls > 0 &&
      ticket.calls == 1;

  final aiBaseline = const
      PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    ticketAiPolicy: _AlwaysBalancedPolicy(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final baselineContracts = {
    for (final item in aiBaseline.boundaries.single.source.source.sponsor.contracts)
      item.offer.clubId: item.signature,
  };
  final playerContracts = {
    for (final item in composed.boundaries.single.source.source.sponsor.contracts)
      item.offer.clubId: item.signature,
  };
  final aiIds = baselineContracts.keys.where((id) => id != controlled);
  final aiParity47 = aiIds.length == 47 &&
      aiIds.every((id) => playerContracts[id] == baselineContracts[id]);
  final sponsorChanged = playerContracts[controlled] != baselineContracts[controlled];

  final seedCheckpoint = const
      PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    sponsorProvider: _LabelSponsorProvider('bold'),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;
  final lostCheckpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
    runtime: seedCheckpoint.runtime,
    tenureControl: PlayerPresidentTenureControlState(
      controlledClubId: controlled,
      playerPresidentId: 'm69-former-president',
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: seedCheckpoint.completedSeasons,
      successorPresidentId: 'm69-successor-president',
    ),
  );
  final blockedSponsor = _CountingNonAiSponsorProvider();
  final blocked =
      PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    sponsorProvider: blockedSponsor,
  ).resume(
    checkpoint: lostCheckpoint,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final lostBlocksSponsor =
      blockedSponsor.calls == 0 && blocked.checkpoint.tenureControl.lost;

  const deterministicEngine =
      PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    sponsorProvider: _NonAiSponsorProvider(),
    facilityProvider: _HoldFacilityProvider(),
    promiseProvider: _AlternativePromiseProvider(),
    mediaProvider: _AlternativeMediaProvider(),
    transferStrategyProvider: _YouthTransferProvider(),
    ticketPricingProvider: _PremiumTicketProvider(),
  );
  final direct = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 4,
    electionInterval: 4,
  );
  final first = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final resumed = deterministicEngine.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );
  final saveResume =
      codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint) &&
          [...first.boundaries, ...resumed.boundaries]
                  .map((item) => item.signature)
                  .join('||') ==
              direct.boundaries.map((item) => item.signature).join('||');

  if (!m68ParityWithoutSponsor ||
      !sixProviders ||
      !sponsorChanged ||
      !aiParity47 ||
      !lostBlocksSponsor ||
      !saveResume) {
    throw StateError(
      'M69 canonical failure: m68Parity=$m68ParityWithoutSponsor '
      'sixProviders=$sixProviders sponsorChanged=$sponsorChanged '
      'aiParity47=$aiParity47 lostBlocksSponsor=$lostBlocksSponsor '
      'saveResume=$saveResume',
    );
  }

  print(
    'M69_PLAYER_PRESIDENT_TENURE_GATED_FACILITY_SPONSOR_PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS '
    'controlled=$controlled m68ParityWithoutSponsor=$m68ParityWithoutSponsor '
    'sixProviders=$sixProviders sponsorChanged=$sponsorChanged '
    'aiParity=47 lostBlocksSponsor=$lostBlocksSponsor '
    'singleCheckpoint=true saveResume=$saveResume '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
