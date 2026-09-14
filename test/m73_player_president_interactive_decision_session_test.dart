import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
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

class _PolicyGateway extends PlayerPresidentDecisionGateway {
  @override
  PlayerFacilityInvestmentChoice chooseFacilityInvestment(
    PlayerFacilityInvestmentContext context,
  ) =>
      PlayerFacilityInvestmentChoice.hold;

  @override
  PlayerSponsorOfferChoice chooseSponsor(PlayerSponsorDecisionContext context) =>
      PlayerSponsorOfferChoice(offerId: context.aiChoice.id);

  @override
  PlayerCrisisActionChoice chooseCrisisAction(
    PlayerCrisisDecisionContext context,
  ) =>
      PlayerCrisisActionChoice(action: context.aiDecision.action);

  @override
  PlayerManagerReviewChoice reviewManager(PlayerManagerReviewContext context) =>
      PlayerManagerReviewChoice.replace;

  @override
  PlayerManagerReplacementChoice chooseManagerReplacement(
    PlayerManagerReplacementContext context,
  ) =>
      PlayerManagerReplacementChoice(
        managerId: context.candidates.first.manager.id,
      );

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      context.aiPromise.type;

  @override
  MediaStance chooseMediaStance(
    PlayerMediaStatementDecisionContext context,
  ) =>
      context.aiStatement.stance;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      PlayerTransferStrategyChoice.fromProfile(context.aiProfile);

  @override
  MatchdayTicketPricingChoice chooseTicketPricing(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      context.aiChoice;
}

Object _choiceFor(PlayerPresidentInteractiveDecisionRequest request) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice.hold;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final context = request.contextAs<PlayerSponsorDecisionContext>();
      return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
    case PlayerPresidentInteractiveDecisionKind.crisis:
      final context = request.contextAs<PlayerCrisisDecisionContext>();
      return PlayerCrisisActionChoice(action: context.aiDecision.action);
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return PlayerManagerReviewChoice.replace;
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      final context = request.contextAs<PlayerManagerReplacementContext>();
      return PlayerManagerReplacementChoice(
        managerId: context.candidates.first.manager.id,
      );
    case PlayerPresidentInteractiveDecisionKind.promise:
      return request.contextAs<PlayerPromiseDecisionContext>().aiPromise.type;
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      return request
          .contextAs<PlayerMediaStatementDecisionContext>()
          .aiStatement
          .stance;
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      final context =
          request.contextAs<PlayerTransferStrategyDecisionContext>();
      return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return request
          .contextAs<PlayerPresidentTicketPricingDecisionContext>()
          .aiChoice;
  }
}

PlayerPresidentInteractiveSessionCompleted _drive(
  PlayerPresidentInteractiveDecisionSession session, {
  List<PlayerPresidentInteractiveDecisionKind>? kinds,
  List<String>? keys,
}) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('Interactive decision session did not converge.');
    }
    final request = step.request;
    kinds?.add(request.kind);
    keys?.add(request.key);
    step = session.submit(
      request: request,
      choice: _choiceFor(request),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
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
              ).isNotEmpty &&
              investmentByClub[snapshot.promise.clubId]!.invested,
        )
        .promise
        .clubId;
  });

  PlayerPresidentInteractiveDecisionSession newSession() =>
      PlayerPresidentInteractiveDecisionSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: interactiveClubId,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
        aiCrisisEngine: forcedAi,
        ticketAiPolicy: const _AlwaysBalancedPolicy(),
      );

  test('M73 pauses on one unanswered request without committing progress', () {
    final session = newSession();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final repeated =
        session.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(first.request.sequence, 1);
    expect(repeated.request.key, first.request.key);
    expect(session.answeredDecisionCount, 0);
    expect(session.completed, isNull);
  });

  test('M73 request response session matches direct M72 gateway exactly', () {
    final direct = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      gateway: _PolicyGateway(),
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

    final kinds = <PlayerPresidentInteractiveDecisionKind>[];
    final keys = <String>[];
    final completed = _drive(newSession(), kinds: kinds, keys: keys);

    expect(
      codec.encode(completed.result.checkpoint),
      codec.encode(direct.checkpoint),
    );
    expect(
      completed.result.boundaries.map((item) => item.signature).toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(keys.toSet().length, keys.length);
    expect(
      kinds.toSet(),
      containsAll(PlayerPresidentInteractiveDecisionKind.values),
    );
    expect(completed.decisionCount, keys.length);
  });

  test('M73 rejects stale responses and keeps the current request pending', () {
    final session = newSession();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final next = session.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    ) as PlayerPresidentInteractiveDecisionPending;

    expect(
      () => session.submit(
        request: first.request,
        choice: _choiceFor(first.request),
      ),
      throwsStateError,
    );
    expect(session.pendingDecision!.key, next.request.key);
    expect(session.answeredDecisionCount, 1);
  });

  test('M73 rejects an invalid response without consuming the request', () {
    final session = newSession();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(
      () => session.submit(request: first.request, choice: Object()),
      throwsArgumentError,
    );
    expect(session.pendingDecision!.key, first.request.key);
    expect(session.answeredDecisionCount, 0);
  });

  test('M73 resume from M65 checkpoint matches direct M72 resume', () {
    final initial =
        const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;

    final direct = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      gateway: _PolicyGateway(),
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: initial,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    final session = PlayerPresidentInteractiveDecisionSession.resume(
      checkpoint: codec.decode(codec.encode(initial)),
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
      aiCrisisEngine: forcedAi,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    );
    final completed = _drive(session);

    expect(
      codec.encode(completed.result.checkpoint),
      codec.encode(direct.checkpoint),
    );
    expect(
      completed.result.boundaries.map((item) => item.signature).toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
