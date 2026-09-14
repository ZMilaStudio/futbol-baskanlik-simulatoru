import 'dart:convert';

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
  PlayerPresidentInteractiveDecisionTranscriptSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M75 persistence session did not converge.');
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
  const forcedAi = CrisisDecisionEngine(activationThreshold: 0);
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

  PlayerPresidentTicketPricingRuntimeCheckpoint cloneCheckpoint(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
  ) =>
      checkpointCodec.decode(checkpointCodec.encode(checkpoint));

  PlayerPresidentInteractiveDecisionSession resumedBase(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
  ) =>
      PlayerPresidentInteractiveDecisionSession.resume(
        checkpoint: cloneCheckpoint(checkpoint),
        seasonCount: resumeConfig.seasonCount,
        hasFutureSeasonAfterReport:
            resumeConfig.hasFutureSeasonAfterReport,
        aiCrisisEngine: forcedAi,
        candidateLimit: resumeConfig.candidateLimit,
      );

  PlayerPresidentInteractiveDecisionTranscriptSession partial(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    int answerCount,
  ) {
    final session = PlayerPresidentInteractiveDecisionTranscriptSession(
      resumedBase(checkpoint),
    );
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var index = 0; index < answerCount; index++) {
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      step = session.submit(
        request: pending.request,
        choice: _choiceFor(pending.request),
      );
    }
    expect(step, isA<PlayerPresidentInteractiveDecisionPending>());
    return session;
  }

  PlayerPresidentInteractiveDecisionPersistenceBundle bundleFor(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    PlayerPresidentInteractiveDecisionTranscriptSnapshot transcript,
  ) =>
      PlayerPresidentInteractiveDecisionPersistenceBundle(
        checkpoint: cloneCheckpoint(checkpoint),
        transcript: transcript,
        resumeConfig: resumeConfig,
      );

  test('M75 canonical bundle round trip preserves M65 and M74 inner saves', () {
    final source = partial(initial, 3);
    final bundle = bundleFor(initial, source.snapshot);
    final encoded = bundleCodec.encode(bundle);
    final decoded = bundleCodec.decode(encoded);

    expect(bundleCodec.encode(decoded), encoded);
    expect(
      checkpointCodec.encode(decoded.checkpoint),
      checkpointCodec.encode(initial),
    );
    expect(
      transcriptCodec.encode(decoded.transcript),
      transcriptCodec.encode(source.snapshot),
    );
    expect(decoded.resumeConfig.signature, resumeConfig.signature);
    expect(decoded.answeredDecisionCount, 3);
  });

  test('M75 restores exact pending request and completes with M74 parity', () {
    final uninterrupted = _drive(
      PlayerPresidentInteractiveDecisionTranscriptSession(resumedBase(initial)),
    );
    final source = partial(initial, 4);
    final pendingBefore = source.pendingDecision!.key;
    final decoded = bundleCodec.decode(
      bundleCodec.encode(bundleFor(initial, source.snapshot)),
    );

    final restored = decoded.restoreSession();
    final pendingAfter =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(pendingAfter.request.key, pendingBefore);

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

  test('M75 rejects a checksum-valid stale transcript paired to another M65 save',
      () {
    final alternateClubId = world.clubs[1].id;
    final alternateCheckpoint =
        const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: alternateClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
    final alternateTranscript = partial(alternateCheckpoint, 1).snapshot;
    final mismatched = bundleFor(initial, alternateTranscript);
    final decoded = bundleCodec.decode(bundleCodec.encode(mismatched));

    expect(decoded.restoreSession, throwsA(isA<SaveLoadException>()));
  });

  test('M75 outer checksum rejects bundle corruption before nested restore', () {
    final source = partial(initial, 1);
    final encoded = bundleCodec.encode(bundleFor(initial, source.snapshot));
    final root = jsonDecode(encoded) as Map<String, dynamic>;
    final payload = root['payload'] as Map<String, dynamic>;
    payload['transcriptSave'] = '${payload['transcriptSave']}-corrupt';

    expect(
      () => bundleCodec.decode(jsonEncode(root)),
      throwsA(isA<SaveLoadException>()),
    );
  });

  test('M75 validates nested M65 save even with a valid outer checksum', () {
    final source = partial(initial, 1);
    final encoded = bundleCodec.encode(bundleFor(initial, source.snapshot));
    final root = jsonDecode(encoded) as Map<String, dynamic>;
    final payload = Map<String, Object?>.from(
      root['payload'] as Map<String, dynamic>,
    );
    payload['gameStateSave'] = '{"broken":true}';
    root['payload'] = payload;
    root['checksum'] = SaveChecksum.forPayload(
      saveVersion: root['saveVersion'] as int,
      payload: payload,
    );

    expect(
      () => bundleCodec.decode(SaveChecksum.canonicalJson(root)),
      throwsA(isA<SaveLoadException>()),
    );
  });
}
