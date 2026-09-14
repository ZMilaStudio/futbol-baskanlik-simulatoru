import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

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
  PlayerPresidentInteractiveDecisionApplicationSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M76 canonical session did not converge.');
    }
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
}

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final config = SimulationConfig(careerSeed: seed);
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  final initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(initial)),
        resumeConfig: resumeConfig,
      );

  final uninterrupted = _drive(fresh());

  final partial = fresh();
  PlayerPresidentInteractiveSessionStep step = partial.advance();
  for (var index = 0; index < 4; index++) {
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    step = partial.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
  }
  final pendingBefore =
      (step as PlayerPresidentInteractiveDecisionPending).request.key;
  final encoded = partial.encodePersistenceBundle();

  final restored =
      PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
    encodedBundle: encoded,
  );
  final pendingAfter =
      (restored.advance() as PlayerPresidentInteractiveDecisionPending)
          .request
          .key;
  final stableSave = restored.encodePersistenceBundle() == encoded;
  final completed = _drive(restored);

  final pendingRestore = pendingBefore == pendingAfter;
  final parityM75 = checkpointCodec.encode(completed.result.checkpoint) ==
          checkpointCodec.encode(uninterrupted.result.checkpoint) &&
      completed.result.boundaries.map((item) => item.signature).join('||') ==
          uninterrupted.result.boundaries
              .map((item) => item.signature)
              .join('||');

  if (!pendingRestore || !stableSave || !parityM75) {
    throw StateError(
      'M76 failed: pendingRestore=$pendingRestore stableSave=$stableSave '
      'parityM75=$parityM75',
    );
  }

  print(
    'M76_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_SESSION_PASS '
    'controlled=$controlledClubId savedDecisions=${partial.answeredDecisionCount} '
    'pendingRestore=$pendingRestore stableSave=$stableSave '
    'applicationLifecycle=true atomicBundle=M75 parityM75=$parityM75 '
    'saveAuthority=M65 worldClubs=${world.clubs.length} seed=$seed',
  );
}
