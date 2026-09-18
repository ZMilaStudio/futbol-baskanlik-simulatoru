import 'dart:convert';

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
      throw StateError('M74 transcript session did not converge.');
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
  const transcriptCodec =
      PlayerPresidentInteractiveDecisionTranscriptSaveCodec();
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String controlledClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
  });

  PlayerPresidentInteractiveDecisionSession freshBase() =>
      PlayerPresidentInteractiveDecisionSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
        aiCrisisEngine: forcedAi,
      );

  PlayerPresidentInteractiveDecisionTranscriptSession partialFresh(
    int answerCount,
  ) {
    final session = PlayerPresidentInteractiveDecisionTranscriptSession(
      freshBase(),
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

  test('M74 round trips a partial transcript and restores the exact pending key',
      () {
    final partial = partialFresh(3);
    final pendingBefore = partial.pendingDecision!;
    final encoded = partial.encodeSnapshot();
    final decoded = transcriptCodec.decode(encoded);

    final restored =
        PlayerPresidentInteractiveDecisionTranscriptSession.restore(
      session: freshBase(),
      snapshot: decoded,
    );
    final pendingAfter = restored.advance()
        as PlayerPresidentInteractiveDecisionPending;

    expect(restored.answeredDecisionCount, 3);
    expect(pendingAfter.request.key, pendingBefore.key);
    expect(transcriptCodec.encode(decoded), encoded);
  });

  test('M74 restored fresh session completes with uninterrupted M73 parity', () {
    final uninterrupted = _drive(
      PlayerPresidentInteractiveDecisionTranscriptSession(freshBase()),
    );
    final partial = partialFresh(4);
    final restored =
        PlayerPresidentInteractiveDecisionTranscriptSession.restoreEncoded(
      session: freshBase(),
      encodedTranscript: partial.encodeSnapshot(),
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

  test('M74 restores transcript on top of an authoritative M65 checkpoint', () {
    final initial =
        const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
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
          seasonCount: 1,
          hasFutureSeasonAfterReport: true,
          aiCrisisEngine: forcedAi,
        );

    final uninterrupted = _drive(
      PlayerPresidentInteractiveDecisionTranscriptSession(resumedBase()),
    );
    final partial = PlayerPresidentInteractiveDecisionTranscriptSession(
      resumedBase(),
    );
    var step = partial.advance();
    for (var index = 0; index < 2; index++) {
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      step = partial.submit(
        request: pending.request,
        choice: _choiceFor(pending.request),
      );
    }
    final pendingBefore =
        (step as PlayerPresidentInteractiveDecisionPending).request;

    final restored =
        PlayerPresidentInteractiveDecisionTranscriptSession.restoreEncoded(
      session: resumedBase(),
      encodedTranscript: partial.encodeSnapshot(),
    );
    expect(restored.pendingDecision!.key, pendingBefore.key);
    final completed = _drive(restored);

    expect(
      checkpointCodec.encode(completed.result.checkpoint),
      checkpointCodec.encode(uninterrupted.result.checkpoint),
    );
    expect(
      completed.result.boundaries.map((item) => item.signature).toList(),
      uninterrupted.result.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M74 rejects checksum corruption before transcript replay', () {
    final encoded = partialFresh(1).encodeSnapshot();
    final root = jsonDecode(encoded) as Map<String, dynamic>;
    final payload = root['payload'] as Map<String, dynamic>;
    final entries = payload['entries'] as List<dynamic>;
    final first = entries.first as Map<String, dynamic>;
    first['requestKey'] = '${first['requestKey']}-corrupt';

    expect(
      () => transcriptCodec.decode(jsonEncode(root)),
      throwsA(isA<Exception>()),
    );
  });

  test('M74 rejects a stale checksum-valid transcript entry during restore', () {
    final partial = partialFresh(1);
    final original = partial.snapshot.entries.single;
    final stale = PlayerPresidentInteractiveDecisionTranscriptSnapshot(
      entries: [
        PlayerPresidentInteractiveDecisionTranscriptEntry(
          requestKey: '${original.requestKey}-stale',
          kind: original.kind,
          choice: original.choice,
        ),
      ],
    );

    expect(
      () => PlayerPresidentInteractiveDecisionTranscriptSession.restore(
        session: freshBase(),
        snapshot: transcriptCodec.decode(transcriptCodec.encode(stale)),
      ),
      throwsA(isA<Exception>()),
    );
  });
  test('M90 stage 3 M74 additive submit returns resolution and records once',
      () {
    final session =
        PlayerPresidentInteractiveDecisionTranscriptSession(freshBase());
    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final choice = _choiceFor(pending.request);

    final result = session.submitWithResolution(
      request: pending.request,
      choice: choice,
    );

    expect(result.resolution.requestKey, pending.request.key);
    expect(result.resolution.kind, pending.request.kind);
    expect(result.resolution.acceptedChoice, same(choice));
    expect(result.resolution.consequence.kind, pending.request.kind);
    expect(session.answeredDecisionCount, 1);
    expect(session.snapshot.entries, hasLength(1));
    expect(session.snapshot.entries.single.requestKey, pending.request.key);
    expect(session.snapshot.entries.single.kind, pending.request.kind);
    expect(result.nextStep, isA<PlayerPresidentInteractiveDecisionPending>());
  });

  test('M90 stage 3 M74 additive stale and invalid submits do not mutate transcript',
      () {
    final session =
        PlayerPresidentInteractiveDecisionTranscriptSession(freshBase());
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final firstChoice = _choiceFor(first.request);
    final accepted = session.submitWithResolution(
      request: first.request,
      choice: firstChoice,
    );
    final before = session.encodeSnapshot();
    final beforeCount = session.answeredDecisionCount;

    expect(
      () => session.submitWithResolution(
        request: first.request,
        choice: firstChoice,
      ),
      throwsStateError,
    );
    expect(session.answeredDecisionCount, beforeCount);
    expect(session.encodeSnapshot(), before);

    final current =
        accepted.nextStep as PlayerPresidentInteractiveDecisionPending;
    expect(
      () => session.submitWithResolution(
        request: current.request,
        choice: Object(),
      ),
      throwsArgumentError,
    );
    expect(session.answeredDecisionCount, beforeCount);
    expect(session.encodeSnapshot(), before);
  });

  test('M90 stage 3 M74 legacy and additive submit keep nextStep and bytes parity',
      () {
    final legacy =
        PlayerPresidentInteractiveDecisionTranscriptSession(freshBase());
    final additive =
        PlayerPresidentInteractiveDecisionTranscriptSession(freshBase());
    final legacyPending =
        legacy.advance() as PlayerPresidentInteractiveDecisionPending;
    final additivePending =
        additive.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(additivePending.request.key, legacyPending.request.key);

    final legacyNext = legacy.submit(
      request: legacyPending.request,
      choice: _choiceFor(legacyPending.request),
    );
    final additiveResult = additive.submitWithResolution(
      request: additivePending.request,
      choice: _choiceFor(additivePending.request),
    );

    expect(additiveResult.nextStep.runtimeType, legacyNext.runtimeType);
    expect(
      (additiveResult.nextStep as PlayerPresidentInteractiveDecisionPending)
          .request
          .key,
      (legacyNext as PlayerPresidentInteractiveDecisionPending).request.key,
    );
    expect(additive.encodeSnapshot(), legacy.encodeSnapshot());
    expect(additive.answeredDecisionCount, legacy.answeredDecisionCount);
  });

  test('M90 stage 3 M74 additive restore keeps only current authoritative boundary',
      () {
    final source =
        PlayerPresidentInteractiveDecisionTranscriptSession(freshBase());
    PlayerPresidentInteractiveSessionStep step = source.advance();
    for (var index = 0; index < 3; index++) {
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      step = source
          .submitWithResolution(
            request: pending.request,
            choice: _choiceFor(pending.request),
          )
          .nextStep;
    }
    final pendingBefore =
        (step as PlayerPresidentInteractiveDecisionPending).request;
    final encoded = source.encodeSnapshot();

    final restored =
        PlayerPresidentInteractiveDecisionTranscriptSession.restoreEncoded(
      session: freshBase(),
      encodedTranscript: encoded,
    );
    expect(restored.answeredDecisionCount, 3);
    expect(restored.pendingDecision!.key, pendingBefore.key);
    expect(restored.encodeSnapshot(), encoded);

    final current =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(current.request.key, pendingBefore.key);
    final result = restored.submitWithResolution(
      request: current.request,
      choice: _choiceFor(current.request),
    );
    expect(result.resolution.requestKey, current.request.key);
    expect(result.resolution.kind, current.request.kind);
    expect(restored.answeredDecisionCount, 4);
  });

  test('M90 stage 3 keeps M74 envelope and entry schema unchanged', () {
    final session =
        PlayerPresidentInteractiveDecisionTranscriptSession(freshBase());
    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submitWithResolution(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );

    final root =
        jsonDecode(session.encodeSnapshot()) as Map<String, dynamic>;
    expect(
      root.keys.toSet(),
      {'format', 'saveVersion', 'checksum', 'payload'},
    );
    expect(
      root['format'],
      PlayerPresidentInteractiveDecisionTranscriptSaveCodec.format,
    );
    expect(
      root['saveVersion'],
      PlayerPresidentInteractiveDecisionTranscriptSaveCodec.currentSaveVersion,
    );
    final payload = root['payload'] as Map<String, dynamic>;
    expect(payload.keys.toSet(), {'entries'});
    final entry =
        (payload['entries'] as List<dynamic>).single as Map<String, dynamic>;
    expect(entry.keys.toSet(), {'requestKey', 'kind', 'choice'});
    expect(entry.containsKey('resolution'), isFalse);
    expect(entry.containsKey('consequence'), isFalse);
  });


}
