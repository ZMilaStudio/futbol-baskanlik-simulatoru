import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';
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

class _TrackingGateway extends PlayerPresidentDecisionGateway {
  int facilityCalls = 0;
  int sponsorCalls = 0;
  int crisisCalls = 0;
  int managerReviewCalls = 0;
  int managerReplacementCalls = 0;
  int promiseCalls = 0;
  int mediaCalls = 0;
  int transferCalls = 0;
  int ticketCalls = 0;
  final Set<String> clubIds = {};

  @override
  PlayerFacilityInvestmentChoice chooseFacilityInvestment(
    PlayerFacilityInvestmentContext context,
  ) {
    facilityCalls++;
    clubIds.add(context.clubId);
    return PlayerFacilityInvestmentChoice.hold;
  }

  @override
  PlayerSponsorOfferChoice chooseSponsor(PlayerSponsorDecisionContext context) {
    sponsorCalls++;
    clubIds.add(context.clubId);
    final alternative = context.offers.firstWhere(
      (offer) => offer.id != context.aiChoice.id,
      orElse: () => context.aiChoice,
    );
    return PlayerSponsorOfferChoice(offerId: alternative.id);
  }

  @override
  PlayerCrisisActionChoice chooseCrisisAction(
    PlayerCrisisDecisionContext context,
  ) {
    crisisCalls++;
    clubIds.add(context.clubId);
    final alternative = context.availableDecisions.firstWhere(
      (decision) => decision.action != context.aiDecision.action,
      orElse: () => context.aiDecision,
    );
    return PlayerCrisisActionChoice(action: alternative.action);
  }

  @override
  PlayerManagerReviewChoice reviewManager(PlayerManagerReviewContext context) {
    managerReviewCalls++;
    clubIds.add(context.clubId);
    return PlayerManagerReviewChoice.replace;
  }

  @override
  PlayerManagerReplacementChoice chooseManagerReplacement(
    PlayerManagerReplacementContext context,
  ) {
    managerReplacementCalls++;
    clubIds.add(context.clubId);
    final alternative = context.candidates.firstWhere(
      (candidate) => candidate.manager.id != context.aiChoice.id,
      orElse: () => context.candidates.first,
    );
    return PlayerManagerReplacementChoice(managerId: alternative.manager.id);
  }

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    promiseCalls++;
    clubIds.add(context.controlledClubId);
    return context.allowedTypes.firstWhere(
      (type) => type != context.aiPromise.type,
      orElse: () => context.aiPromise.type,
    );
  }

  @override
  MediaStance chooseMediaStance(
    PlayerMediaStatementDecisionContext context,
  ) {
    mediaCalls++;
    clubIds.add(context.controlledClubId);
    return context.allowedStances.firstWhere(
      (stance) => stance != context.aiStatement.stance,
      orElse: () => context.aiStatement.stance,
    );
  }

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    transferCalls++;
    clubIds.add(context.controlledClubId);
    return const PlayerTransferStrategyChoice(
      financialDiscipline: 60,
      transferAmbition: 60,
      riskAppetite: 60,
      youthOrientation: 90,
    );
  }

  @override
  MatchdayTicketPricingChoice chooseTicketPricing(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    ticketCalls++;
    clubIds.add(context.clubId);
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
  }
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);

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

  test('M72 without gateway preserves M71 exactly', () {
    const m71 =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    const m72 = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine();

    final baseline = m71.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final composed = m72.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );

    expect(codec.encode(composed.checkpoint), codec.encode(baseline.checkpoint));
    expect(
      composed.boundaries.map((item) => item.signature).toList(),
      baseline.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M72 routes eight decision domains through one gateway', () {
    final gateway = _TrackingGateway();
    final result = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      gateway: gateway,
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

    expect(gateway.facilityCalls, 1);
    expect(gateway.sponsorCalls, 1);
    expect(gateway.crisisCalls, 1);
    expect(gateway.managerReviewCalls, 1);
    expect(gateway.managerReplacementCalls, 1);
    expect(gateway.promiseCalls, 1);
    expect(gateway.mediaCalls, 1);
    expect(gateway.transferCalls, greaterThan(0));
    expect(gateway.ticketCalls, 1);
    expect(gateway.clubIds, {interactiveClubId});
    expect(result.managerDecisions, hasLength(1));
    expect(result.checkpoint.controlledClubId, interactiveClubId);
  });

  test('M72 gateway remains runtime-only across M65 save resume', () {
    final directGateway = _TrackingGateway();
    final direct = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      gateway: directGateway,
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 4,
      electionInterval: 4,
    );

    final splitGateway = _TrackingGateway();
    final engine = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      gateway: splitGateway,
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
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
