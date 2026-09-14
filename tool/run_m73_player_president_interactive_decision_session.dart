import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

class _CanonicalGateway extends PlayerPresidentDecisionGateway {
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

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);

  final direct = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
    gateway: _CanonicalGateway(),
    aiCrisisEngine: forcedAi,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );

  final session = PlayerPresidentInteractiveDecisionSession.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    aiCrisisEngine: forcedAi,
  );

  final kinds = <PlayerPresidentInteractiveDecisionKind>{};
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M73 canonical session did not converge.');
    }
    kinds.add(step.request.kind);
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request),
    );
  }
  final completed = step as PlayerPresidentInteractiveSessionCompleted;
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  final parity = codec.encode(completed.result.checkpoint) ==
          codec.encode(direct.checkpoint) &&
      completed.result.boundaries.single.signature ==
          direct.boundaries.single.signature;

  if (!parity ||
      completed.decisionCount == 0 ||
      !kinds.contains(PlayerPresidentInteractiveDecisionKind.managerReview) ||
      session.pendingDecision != null ||
      session.completed == null) {
    throw StateError('M73 canonical interactive-session invariant failed.');
  }

  print(
    'M73_PLAYER_PRESIDENT_INTERACTIVE_DECISION_SESSION_PASS '
    'controlled=$controlledClubId decisions=${completed.decisionCount} '
    'uniqueKinds=${kinds.length} pauseReplay=true parityM72=$parity '
    'singleCheckpoint=true saveAuthority=M65 '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
