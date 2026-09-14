import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_promise_media_transfer_ticket_pricing_runtime_composition.dart';
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

class _AlternativeManagerProvider extends PlayerManagerDecisionProvider {
  const _AlternativeManagerProvider();

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) =>
      PlayerManagerReviewChoice.replace;

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    final alternative = context.candidates.firstWhere(
      (candidate) => candidate.manager.id != context.aiChoice.id,
      orElse: () => context.candidates.first,
    );
    return PlayerManagerReplacementChoice(managerId: alternative.manager.id);
  }
}

class _CountingAlternativeManagerProvider extends PlayerManagerDecisionProvider {
  int reviewCalls = 0;
  int replacementCalls = 0;
  final List<String> presidentIds = [];

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    reviewCalls++;
    presidentIds.add(context.presidentId);
    return PlayerManagerReviewChoice.replace;
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    replacementCalls++;
    presidentIds.add(context.presidentId);
    final alternative = context.candidates.firstWhere(
      (candidate) => candidate.manager.id != context.aiChoice.id,
      orElse: () => context.candidates.first,
    );
    return PlayerManagerReplacementChoice(managerId: alternative.manager.id);
  }
}

Map<String, String> _managerAssignments(
  PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
) =>
    {
      for (final item in checkpoint.runtime.runtime.domain.presidentRuntime.runtime
          .runtime.manager.assignments)
        item.clubId: item.managerId,
    };

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);

  late FictionalWorldSetup world;
  late String interactiveClubId;
  late String turnoverClubId;

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
  });

  test('M71 without manager provider preserves M70 exactly', () {
    const source =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    const m71 =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sourceEngine: source,
    );

    final baseline = source.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final composed = m71.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );

    expect(codec.encode(composed.checkpoint), codec.encode(baseline.checkpoint));
    expect(
      composed.boundaries.map((item) => item.source.signature).toList(),
      baseline.boundaries.map((item) => item.signature).toList(),
    );
    expect(composed.managerDecisions, isEmpty);
  });

  test('M71 manager override changes one club and keeps 47 AI assignments exact',
      () {
    const source =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    final baseline = source.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final player =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: _AlternativeManagerProvider(),
      sourceEngine: source,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    final ai = _managerAssignments(baseline.checkpoint);
    final controlled = _managerAssignments(player.checkpoint);
    expect(controlled[interactiveClubId], isNot(ai[interactiveClubId]));
    final otherIds = ai.keys.where((id) => id != interactiveClubId).toList();
    expect(otherIds, hasLength(47));
    for (final id in otherIds) {
      expect(controlled[id], ai[id], reason: id);
    }
    expect(player.managerDecisions, hasLength(1));
    expect(player.managerDecisions.single.changedFromAi, isTrue);
  });

  test('M71 composes eight player providers in one real season boundary', () {
    final crisis = _CountingNonAiCrisisProvider();
    final sponsor = _CountingNonAiSponsorProvider();
    final facility = _CountingHoldFacilityProvider();
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final manager = _CountingAlternativeManagerProvider();
    final source =
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
    );
    final result =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: manager,
      sourceEngine: source,
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
    expect(manager.reviewCalls, 1);
    expect(manager.replacementCalls, 1);
    expect(result.managerDecisions, hasLength(1));
  });

  test('M71 final season without future does not request manager decision', () {
    final manager = _CountingAlternativeManagerProvider();
    const source =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    final baseline = source.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
    );
    final player =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: manager,
      sourceEngine: source,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
    );

    expect(manager.reviewCalls, 0);
    expect(manager.replacementCalls, 0);
    expect(player.managerDecisions, isEmpty);
    expect(codec.encode(player.checkpoint), codec.encode(baseline.checkpoint));
  });

  test('M71 real turnover blocks manager provider on successor boundary', () {
    final beforeProvider = _CountingAlternativeManagerProvider();
    final before =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: beforeProvider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final turnoverProvider = _CountingAlternativeManagerProvider();
    final after =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: turnoverProvider,
    ).simulateWithCheckpoint(
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
    expect(turnoverProvider.reviewCalls, beforeProvider.reviewCalls);
    final playerId = after.checkpoint.tenureControl.playerPresidentId;
    expect(turnoverProvider.presidentIds.every((id) => id == playerId), isTrue);
  });

  test('M71 M65 codec keeps 2 plus 2 resume deterministic against four seasons',
      () {
    const engine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: _AlternativeManagerProvider(),
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
