import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_transcript_snapshot.dart';
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
  PlayerPresidentInteractiveDecisionTranscriptSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M75 canonical session did not converge.');
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
  const transcriptCodec =
      PlayerPresidentInteractiveDecisionTranscriptSaveCodec();
  const bundleCodec =
      PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec();
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

  PlayerPresidentInteractiveDecisionSession resumedBase() =>
      PlayerPresidentInteractiveDecisionSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(initial)),
        seasonCount: resumeConfig.seasonCount,
        hasFutureSeasonAfterReport:
            resumeConfig.hasFutureSeasonAfterReport,
        aiCrisisEngine: const CrisisDecisionEngine(activationThreshold: 0),
        candidateLimit: resumeConfig.candidateLimit,
      );

  final uninterrupted = _drive(
    PlayerPresidentInteractiveDecisionTranscriptSession(resumedBase()),
  );

  final partial = PlayerPresidentInteractiveDecisionTranscriptSession(
    resumedBase(),
  );
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

  final bundle = PlayerPresidentInteractiveDecisionPersistenceBundle(
    checkpoint: checkpointCodec.decode(checkpointCodec.encode(initial)),
    transcript: partial.snapshot,
    resumeConfig: resumeConfig,
  );
  final encoded = bundleCodec.encode(bundle);
  final decoded = bundleCodec.decode(encoded);
  final restored = decoded.restoreSession();
  final pendingAfter =
      (restored.advance() as PlayerPresidentInteractiveDecisionPending)
          .request
          .key;
  final completed = _drive(restored);

  final canonicalRoundTrip = bundleCodec.encode(decoded) == encoded;
  final nestedM65 = checkpointCodec.encode(decoded.checkpoint) ==
      checkpointCodec.encode(initial);
  final nestedM74 = transcriptCodec.encode(decoded.transcript) ==
      transcriptCodec.encode(partial.snapshot);
  final pendingRestore = pendingBefore == pendingAfter;
  final parityM74 = checkpointCodec.encode(completed.result.checkpoint) ==
          checkpointCodec.encode(uninterrupted.result.checkpoint) &&
      completed.result.boundaries.map((item) => item.signature).join('||') ==
          uninterrupted.result.boundaries
              .map((item) => item.signature)
              .join('||');

  if (!canonicalRoundTrip ||
      !nestedM65 ||
      !nestedM74 ||
      !pendingRestore ||
      !parityM74) {
    throw StateError(
      'M75 failed: roundTrip=$canonicalRoundTrip nestedM65=$nestedM65 '
      'nestedM74=$nestedM74 pendingRestore=$pendingRestore '
      'parityM74=$parityM74',
    );
  }

  print(
    'M75_PLAYER_PRESIDENT_INTERACTIVE_DECISION_PERSISTENCE_BUNDLE_PASS '
    'controlled=$controlledClubId savedDecisions=${partial.answeredDecisionCount} '
    'pendingRestore=$pendingRestore canonicalRoundTrip=$canonicalRoundTrip '
    'atomicBundle=true nestedChecksums=true parityM74=$parityM74 '
    'singleCheckpoint=true saveAuthority=M65 worldClubs=${world.clubs.length} '
    'seed=$seed',
  );
}
