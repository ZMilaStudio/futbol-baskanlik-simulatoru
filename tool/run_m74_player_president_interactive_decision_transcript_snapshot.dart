import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_transcript_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

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
  PlayerPresidentInteractiveDecisionTranscriptSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M74 canonical transcript session did not converge.');
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
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);
  const transcriptCodec =
      PlayerPresidentInteractiveDecisionTranscriptSaveCodec();
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  PlayerPresidentInteractiveDecisionSession base() =>
      PlayerPresidentInteractiveDecisionSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: SimulationConfig(careerSeed: seed),
        controlledClubId: controlledClubId,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
        aiCrisisEngine: forcedAi,
      );

  final uninterrupted = _drive(
    PlayerPresidentInteractiveDecisionTranscriptSession(base()),
  );

  final partial = PlayerPresidentInteractiveDecisionTranscriptSession(base());
  PlayerPresidentInteractiveSessionStep step = partial.advance();
  const pauseAfter = 4;
  for (var index = 0; index < pauseAfter; index++) {
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    step = partial.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
  }
  final pendingBefore =
      (step as PlayerPresidentInteractiveDecisionPending).request;
  final encoded = partial.encodeSnapshot();
  final decoded = transcriptCodec.decode(encoded);
  final canonicalRoundTrip = transcriptCodec.encode(decoded) == encoded;

  final restored =
      PlayerPresidentInteractiveDecisionTranscriptSession.restore(
    session: base(),
    snapshot: decoded,
  );
  final pendingAfter =
      restored.advance() as PlayerPresidentInteractiveDecisionPending;
  final pendingMatch = pendingAfter.request.key == pendingBefore.key;
  final completed = _drive(restored);

  final parity = checkpointCodec.encode(completed.result.checkpoint) ==
          checkpointCodec.encode(uninterrupted.result.checkpoint) &&
      completed.result.boundaries.single.signature ==
          uninterrupted.result.boundaries.single.signature &&
      completed.decisionCount == uninterrupted.decisionCount;

  if (!canonicalRoundTrip ||
      !pendingMatch ||
      !parity ||
      decoded.decisionCount != pauseAfter ||
      restored.completed == null) {
    throw StateError('M74 canonical transcript snapshot invariant failed.');
  }

  print(
    'M74_PLAYER_PRESIDENT_INTERACTIVE_DECISION_TRANSCRIPT_SNAPSHOT_PASS '
    'controlled=$controlledClubId savedDecisions=${decoded.decisionCount} '
    'pendingRestore=$pendingMatch canonicalRoundTrip=$canonicalRoundTrip '
    'parityM73=$parity transcriptOnly=true singleCheckpoint=true '
    'saveAuthority=M65 worldClubs=${world.clubs.length} seed=$seed',
  );
}
