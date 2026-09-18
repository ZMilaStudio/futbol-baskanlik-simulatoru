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

  test('M90 stage 1 additive submit returns accepted resolution and next step',
      () {
    final session = newSession();
    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final choice = _choiceFor(pending.request);

    final submission = session.submitWithResolution(
      request: pending.request,
      choice: choice,
    );

    expect(submission.resolution.requestKey, pending.request.key);
    expect(submission.resolution.kind, pending.request.kind);
    expect(submission.resolution.acceptedChoice, same(choice));
    expect(submission.resolution.choiceAs<Object>(), same(choice));
    expect(submission.resolution.hasConsequence, isFalse);
    expect(submission.resolution.consequence, isNull);

    final next = submission.nextStep;
    if (next is PlayerPresidentInteractiveDecisionPending) {
      expect(session.pendingDecision!.key, next.request.key);
    } else {
      expect(next, isA<PlayerPresidentInteractiveSessionCompleted>());
      expect(session.completed, same(next));
    }
    expect(session.answeredDecisionCount, 1);
  });

  test('M90 stage 1 additive nextStep preserves legacy submit parity', () {
    final legacySession = newSession();
    final additiveSession = newSession();
    final legacyPending =
        legacySession.advance() as PlayerPresidentInteractiveDecisionPending;
    final additivePending =
        additiveSession.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(additivePending.request.key, legacyPending.request.key);

    final legacyNext = legacySession.submit(
      request: legacyPending.request,
      choice: _choiceFor(legacyPending.request),
    );
    final additive = additiveSession.submitWithResolution(
      request: additivePending.request,
      choice: _choiceFor(additivePending.request),
    );
    final additiveNext = additive.nextStep;

    expect(additiveNext.runtimeType, legacyNext.runtimeType);
    if (legacyNext is PlayerPresidentInteractiveDecisionPending &&
        additiveNext is PlayerPresidentInteractiveDecisionPending) {
      expect(additiveNext.request.key, legacyNext.request.key);
    } else {
      final legacyCompleted =
          legacyNext as PlayerPresidentInteractiveSessionCompleted;
      final additiveCompleted =
          additiveNext as PlayerPresidentInteractiveSessionCompleted;
      expect(
        codec.encode(additiveCompleted.result.checkpoint),
        codec.encode(legacyCompleted.result.checkpoint),
      );
    }
    expect(
      additiveSession.answeredDecisionCount,
      legacySession.answeredDecisionCount,
    );
  });

  test('M90 stage 1 stale additive submit produces no result or consumption', () {
    final session = newSession();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final accepted = session.submitWithResolution(
      request: first.request,
      choice: _choiceFor(first.request),
    );
    expect(accepted.nextStep, isA<PlayerPresidentInteractiveDecisionPending>());
    final countBefore = session.answeredDecisionCount;
    PlayerPresidentInteractiveDecisionSubmissionResult? staleResult;

    expect(
      () {
        staleResult = session.submitWithResolution(
          request: first.request,
          choice: _choiceFor(first.request),
        );
      },
      throwsStateError,
    );
    expect(staleResult, isNull);
    expect(session.answeredDecisionCount, countBefore);
  });

  test('M90 stage 1 invalid additive submit produces no result or consumption',
      () {
    final session = newSession();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    PlayerPresidentInteractiveDecisionSubmissionResult? invalidResult;

    expect(
      () {
        invalidResult = session.submitWithResolution(
          request: first.request,
          choice: Object(),
        );
      },
      throwsArgumentError,
    );
    expect(invalidResult, isNull);
    expect(session.answeredDecisionCount, 0);
    expect(session.pendingDecision!.key, first.request.key);
  });

  test('M90 stage 1 additive replay stays deterministic against legacy M73', () {
    final legacy = _drive(newSession());

    final additiveSession = newSession();
    PlayerPresidentInteractiveSessionStep step = additiveSession.advance();
    var guard = 0;
    while (step is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) {
        throw StateError('Additive M90 stage 1 session did not converge.');
      }
      final pending = step;
      step = additiveSession
          .submitWithResolution(
            request: pending.request,
            choice: _choiceFor(pending.request),
          )
          .nextStep;
    }
    final additive = step as PlayerPresidentInteractiveSessionCompleted;

    expect(
      codec.encode(additive.result.checkpoint),
      codec.encode(legacy.result.checkpoint),
    );
    expect(
      additive.result.boundaries.map((item) => item.signature).toList(),
      legacy.result.boundaries.map((item) => item.signature).toList(),
    );
    expect(additive.decisionCount, legacy.decisionCount);
  });

  test('M90 stage 1 leaves the M74 transcript envelope and entries unchanged',
      () {
    const transcriptCodec =
        PlayerPresidentInteractiveDecisionTranscriptSaveCodec();
    final transcriptSession =
        PlayerPresidentInteractiveDecisionTranscriptSession(newSession());
    final pending =
        transcriptSession.advance() as PlayerPresidentInteractiveDecisionPending;
    transcriptSession.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );

    final root =
        jsonDecode(transcriptSession.encodeSnapshot()) as Map<String, dynamic>;
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
    final entries = payload['entries'] as List<dynamic>;
    final entry = entries.single as Map<String, dynamic>;
    expect(entry.keys.toSet(), {'requestKey', 'kind', 'choice'});
    expect(entry.containsKey('resolution'), isFalse);
    expect(entry.containsKey('consequence'), isFalse);
    expect(
      transcriptCodec
          .decode(transcriptSession.encodeSnapshot())
          .entries
          .single
          .requestKey,
      pending.request.key,
    );
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
