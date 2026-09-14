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
import 'package:test/test.dart';

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
      throw StateError('M76 application session did not converge.');
    }
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
}

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  late FictionalWorldSetup world;
  late PlayerPresidentTicketPricingRuntimeCheckpoint initial;
  late String controlledClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
  });

  PlayerPresidentTicketPricingRuntimeCheckpoint cloneCheckpoint() =>
      checkpointCodec.decode(checkpointCodec.encode(initial));

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: cloneCheckpoint(),
        resumeConfig: resumeConfig,
      );

  test('M76 exposes the deterministic pending request through one app session',
      () {
    final first = fresh();
    final second = fresh();

    final firstPending =
        first.advance() as PlayerPresidentInteractiveDecisionPending;
    final secondPending =
        second.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(firstPending.request.key, secondPending.request.key);
    expect(first.pendingDecision!.key, firstPending.request.key);
    expect(first.answeredDecisionCount, 0);
  });

  test('M76 save restores the exact next pending request and stable bytes', () {
    final source = fresh();
    PlayerPresidentInteractiveSessionStep step = source.advance();
    for (var index = 0; index < 4; index++) {
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      step = source.submit(
        request: pending.request,
        choice: _choiceFor(pending.request),
      );
    }
    final pendingBefore =
        (step as PlayerPresidentInteractiveDecisionPending).request.key;
    final encoded = source.encodePersistenceBundle();

    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: encoded,
    );
    final pendingAfter =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(pendingAfter.request.key, pendingBefore);
    expect(restored.answeredDecisionCount, 4);
    expect(restored.encodePersistenceBundle(), encoded);
  });

  test('M76 rejected stale response does not mutate persisted transcript', () {
    final session = fresh();
    final first = session.advance() as PlayerPresidentInteractiveDecisionPending;
    final secondStep = session.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    );
    expect(secondStep, isA<PlayerPresidentInteractiveDecisionPending>());
    final before = session.encodePersistenceBundle();

    expect(
      () => session.submit(
        request: first.request,
        choice: _choiceFor(first.request),
      ),
      throwsStateError,
    );

    expect(session.encodePersistenceBundle(), before);
    expect(session.answeredDecisionCount, 1);
  });

  test('M76 restoreEncoded fails closed on corrupted M75 bundle', () {
    final session = fresh();
    final pending = session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
    final encoded = session.encodePersistenceBundle();

    expect(
      () => PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
        encodedBundle: '$encoded-corrupt',
      ),
      throwsA(isA<SaveLoadException>()),
    );
  });

  test('M76 save restore completion has uninterrupted exact parity', () {
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
    expect(step, isA<PlayerPresidentInteractiveDecisionPending>());

    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: partial.encodePersistenceBundle(),
    );
    final completed = _drive(restored);

    expect(
      checkpointCodec.encode(completed.result.checkpoint),
      checkpointCodec.encode(uninterrupted.result.checkpoint),
    );
    expect(
      completed.result.boundaries.map((item) => item.signature).toList(),
      uninterrupted.result.boundaries.map((item) => item.signature).toList(),
    );
    expect(completed.decisionCount, uninterrupted.decisionCount);
  });
}
