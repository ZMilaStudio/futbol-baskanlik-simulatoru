import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
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

  PlayerPresidentInteractiveDecisionApplicationSession freshNewGame() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
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
  test('M90 stage 3 M76 additive checkpoint submit exposes authoritative result',
      () {
    final session = fresh();
    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final choice = _choiceFor(pending.request);

    final result = session.submitWithResolution(
      request: pending.request,
      choice: choice,
    );

    expect(session.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint);
    expect(result.resolution.requestKey, pending.request.key);
    expect(result.resolution.kind, pending.request.kind);
    expect(result.resolution.acceptedChoice, same(choice));
    expect(result.resolution.consequence.kind, pending.request.kind);
    expect(session.answeredDecisionCount, 1);
  });

  test('M90 stage 3 M76 additive new-game submit exposes authoritative result',
      () {
    final session = freshNewGame();
    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final choice = _choiceFor(pending.request);

    final result = session.submitWithResolution(
      request: pending.request,
      choice: choice,
    );

    expect(session.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame);
    expect(result.resolution.requestKey, pending.request.key);
    expect(result.resolution.kind, pending.request.kind);
    expect(result.resolution.acceptedChoice, same(choice));
    expect(result.resolution.consequence.kind, pending.request.kind);
    expect(session.answeredDecisionCount, 1);
    expect(session.newGameBootstrapSnapshot.transcript.decisionCount, 1);
  });

  test('M90 stage 3 M76 passes all nine consequence kinds through application',
      () {
    final session = freshNewGame();
    final seen = <PlayerPresidentInteractiveDecisionKind>{};
    PlayerPresidentInteractiveSessionStep step = session.advance();
    var guard = 0;

    while (step is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) {
        throw StateError('M90 application consequence drive did not converge.');
      }
      final request = step.request;
      final choice = _choiceFor(request);
      final result = session.submitWithResolution(
        request: request,
        choice: choice,
      );
      expect(result.resolution.requestKey, request.key);
      expect(result.resolution.kind, request.kind);
      expect(result.resolution.acceptedChoice, same(choice));
      expect(result.resolution.consequence.kind, request.kind);
      seen.add(request.kind);
      step = result.nextStep;
    }

    expect(seen, PlayerPresidentInteractiveDecisionKind.values.toSet());
    expect(session.answeredDecisionCount, 9);
    expect(step, isA<PlayerPresidentInteractiveSessionCompleted>());
  });

  test('M90 stage 3 M76 additive save restores at next checkpoint boundary',
      () {
    final source = fresh();
    final pending =
        source.advance() as PlayerPresidentInteractiveDecisionPending;
    final result = source.submitWithResolution(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
    final next =
        result.nextStep as PlayerPresidentInteractiveDecisionPending;
    final encoded = source.encodePersistenceBundle();

    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: encoded,
    );
    expect(restored.answeredDecisionCount, 1);
    expect(restored.pendingDecision!.key, next.request.key);
    final restoredBoundary =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(restoredBoundary.request.key, next.request.key);
    expect(restored.encodePersistenceBundle(), encoded);
  });

  test('M90 stage 3 M76 additive bootstrap restores at next new-game boundary',
      () {
    final source = freshNewGame();
    final pending =
        source.advance() as PlayerPresidentInteractiveDecisionPending;
    final result = source.submitWithResolution(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
    final next =
        result.nextStep as PlayerPresidentInteractiveDecisionPending;
    final encoded = source.encodeNewGameBootstrapSnapshot();

    final restored = PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: encoded,
    );
    expect(restored.answeredDecisionCount, 1);
    expect(restored.pendingDecision!.key, next.request.key);
    final restoredBoundary =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(restoredBoundary.request.key, next.request.key);
    expect(restored.encodeNewGameBootstrapSnapshot(), encoded);
  });

  test('M90 stage 3 M76 additive stale and invalid submits do not mutate saves',
      () {
    final checkpointSession = fresh();
    final first = checkpointSession.advance()
        as PlayerPresidentInteractiveDecisionPending;
    final firstChoice = _choiceFor(first.request);
    final accepted = checkpointSession.submitWithResolution(
      request: first.request,
      choice: firstChoice,
    );
    final beforeBundle = checkpointSession.encodePersistenceBundle();
    final beforeCount = checkpointSession.answeredDecisionCount;

    expect(
      () => checkpointSession.submitWithResolution(
        request: first.request,
        choice: firstChoice,
      ),
      throwsStateError,
    );
    expect(checkpointSession.encodePersistenceBundle(), beforeBundle);
    expect(checkpointSession.answeredDecisionCount, beforeCount);

    final current =
        accepted.nextStep as PlayerPresidentInteractiveDecisionPending;
    expect(
      () => checkpointSession.submitWithResolution(
        request: current.request,
        choice: Object(),
      ),
      throwsArgumentError,
    );
    expect(checkpointSession.encodePersistenceBundle(), beforeBundle);
    expect(checkpointSession.answeredDecisionCount, beforeCount);

    final newGame = freshNewGame();
    final newFirst =
        newGame.advance() as PlayerPresidentInteractiveDecisionPending;
    final newChoice = _choiceFor(newFirst.request);
    final newAccepted = newGame.submitWithResolution(
      request: newFirst.request,
      choice: newChoice,
    );
    final beforeBootstrap = newGame.encodeNewGameBootstrapSnapshot();
    final newCount = newGame.answeredDecisionCount;

    expect(
      () => newGame.submitWithResolution(
        request: newFirst.request,
        choice: newChoice,
      ),
      throwsStateError,
    );
    expect(newGame.encodeNewGameBootstrapSnapshot(), beforeBootstrap);
    expect(newGame.answeredDecisionCount, newCount);

    final newCurrent =
        newAccepted.nextStep as PlayerPresidentInteractiveDecisionPending;
    expect(
      () => newGame.submitWithResolution(
        request: newCurrent.request,
        choice: Object(),
      ),
      throwsArgumentError,
    );
    expect(newGame.encodeNewGameBootstrapSnapshot(), beforeBootstrap);
    expect(newGame.answeredDecisionCount, newCount);
  });

  test('M90 stage 3 keeps M75 and M80 encoded schemas unchanged', () {
    final checkpointSession = fresh();
    final checkpointPending = checkpointSession.advance()
        as PlayerPresidentInteractiveDecisionPending;
    checkpointSession.submitWithResolution(
      request: checkpointPending.request,
      choice: _choiceFor(checkpointPending.request),
    );
    final bundleRoot = jsonDecode(checkpointSession.encodePersistenceBundle())
        as Map<String, dynamic>;
    expect(
      bundleRoot.keys.toSet(),
      {'format', 'saveVersion', 'checksum', 'payload'},
    );
    expect(
      bundleRoot['format'],
      PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec.format,
    );
    expect(
      bundleRoot['saveVersion'],
      PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
          .currentSaveVersion,
    );
    final bundlePayload =
        bundleRoot['payload'] as Map<String, dynamic>;
    expect(
      bundlePayload.keys.toSet(),
      {'resumeConfig', 'gameStateSave', 'transcriptSave'},
    );

    final newGame = freshNewGame();
    final newPending =
        newGame.advance() as PlayerPresidentInteractiveDecisionPending;
    newGame.submitWithResolution(
      request: newPending.request,
      choice: _choiceFor(newPending.request),
    );
    final bootstrapRoot =
        jsonDecode(newGame.encodeNewGameBootstrapSnapshot())
            as Map<String, dynamic>;
    expect(
      bootstrapRoot.keys.toSet(),
      {'format', 'saveVersion', 'checksum', 'payload'},
    );
    expect(
      bootstrapRoot['format'],
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
          .format,
    );
    expect(
      bootstrapRoot['saveVersion'],
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
          .currentSaveVersion,
    );
    final bootstrapPayload =
        bootstrapRoot['payload'] as Map<String, dynamic>;
    expect(
      bootstrapPayload.keys.toSet(),
      {
        'worldFingerprint',
        'config',
        'controlledClubId',
        'electionInterval',
        'resumeConfig',
        'transcript',
      },
    );
  });


}
