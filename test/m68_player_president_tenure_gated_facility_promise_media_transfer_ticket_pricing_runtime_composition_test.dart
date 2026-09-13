import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart';
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
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) =>
      PlayerFacilityInvestmentChoice.hold;
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

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String interactiveClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
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

  test('M68 without facility provider preserves M67 exactly', () {
    const m67 =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const m68 =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = m67.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final composed = m68.simulateWithCheckpoint(
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

  test('M68 composes five player providers in one real season boundary', () {
    final facility = _CountingHoldFacilityProvider();
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final composed =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
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

    expect(facility.calls, 1);
    expect(promise.calls, 1);
    expect(media.calls, 1);
    expect(transfer.calls, greaterThan(0));
    expect(ticket.calls, 1);
    expect(composed.boundaries.single.decisionFor(interactiveClubId).providerCalled,
        isTrue);
    expect(
      composed.boundaries.single.source.decisions
          .singleWhere((item) => item.clubId == interactiveClubId)
          .invested,
      isFalse,
    );
  });

  test('M68 facility override changes one club and keeps 47 AI investments exact',
      () {
    const baselineEngine =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const playerEngine =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      facilityProvider: _HoldFacilityProvider(),
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

    final baselineDecisions = {
      for (final item in baseline.boundaries.single.source.decisions)
        item.clubId: item,
    };
    final playerDecisions = {
      for (final item in player.boundaries.single.source.decisions)
        item.clubId: item,
    };
    expect(baselineDecisions[interactiveClubId]!.invested, isTrue);
    expect(playerDecisions[interactiveClubId]!.invested, isFalse);
    final aiIds = baselineDecisions.keys
        .where((clubId) => clubId != interactiveClubId)
        .toList(growable: false);
    expect(aiIds, hasLength(47));
    for (final clubId in aiIds) {
      expect(
        playerDecisions[clubId]!.signature,
        baselineDecisions[clubId]!.signature,
        reason: clubId,
      );
    }
  });

  test('M68 lost and incumbent mismatch both block facility control', () {
    final seed = const
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;

    final lostProvider = _CountingHoldFacilityProvider();
    final lost = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: seed.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm68-former-president',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: seed.completedSeasons,
        successorPresidentId: 'm68-successor-president',
      ),
    );
    final lostResult =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      facilityProvider: lostProvider,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: lost,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(lostProvider.calls, 0);
    expect(lostResult.checkpoint.tenureControl.lost, isTrue);

    final mismatchProvider = _CountingHoldFacilityProvider();
    final mismatch = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: seed.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm68-non-incumbent-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    final mismatchResult =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      facilityProvider: mismatchProvider,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: mismatch,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(mismatchProvider.calls, 0);
    expect(mismatchResult.checkpoint.tenureControl.lost, isTrue);
  });

  test('M68 M65 codec 2 plus 2 resume matches uninterrupted four seasons', () {
    const engine =
        PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
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
