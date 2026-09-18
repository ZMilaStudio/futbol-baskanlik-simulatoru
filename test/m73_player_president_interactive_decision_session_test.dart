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

String _consequenceSignature(
  PlayerPresidentInteractiveDecisionConsequence consequence,
) =>
    switch (consequence) {
      PlayerPresidentFacilityInvestmentConsequence(:final decision) =>
        decision.signature,
      PlayerPresidentSponsorConsequence(:final decision, :final contract) =>
        '${decision.signature}:${contract.signature}',
      PlayerPresidentCrisisConsequence(:final decision) => decision.signature,
      PlayerPresidentManagerReviewConsequence(:final context, :final choice) =>
        '${context.signature}:${choice.name}',
      PlayerPresidentManagerReplacementConsequence(
        :final decision,
        :final assignment,
      ) =>
        '${decision.signature}:${assignment.clubId}:${assignment.managerId}',
      PlayerPresidentPromiseConsequence(:final promise) => promise.signature,
      PlayerPresidentMediaStatementConsequence(:final statement) =>
        statement.signature,
      PlayerPresidentTransferStrategyConsequence(:final effectiveProfile) =>
        effectiveProfile.signature,
      PlayerPresidentTicketPricingConsequence(:final decision) =>
        decision.signature,
    };

void _expectAuthoritativeConsequence(
  PlayerPresidentInteractiveDecisionRequest request,
  Object choice,
  PlayerPresidentInteractiveDecisionConsequence consequence,
) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      final selected = choice as PlayerFacilityInvestmentChoice;
      final result =
          (consequence as PlayerPresidentFacilityInvestmentConsequence)
              .decision;
      expect(result.playerControlled, isTrue);
      expect(result.requestedChoice, same(selected));
      expect(result.clubId, request.clubId);
      expect(result.decision.spend.minorUnits, greaterThanOrEqualTo(0));
      expect(
        result.decision.academyAfterLevel -
            result.decision.academyBeforeLevel,
        result.decision.academyAppliedUpgrades,
      );
      expect(
        result.decision.trainingGroundAfterLevel -
            result.decision.trainingGroundBeforeLevel,
        result.decision.trainingGroundAppliedUpgrades,
      );
      expect(
        result.decision.stadiumAfterLevel -
            result.decision.stadiumBeforeLevel,
        result.decision.stadiumAppliedUpgrades,
      );
      return;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final selected = choice as PlayerSponsorOfferChoice;
      final result = consequence as PlayerPresidentSponsorConsequence;
      expect(result.decision.choice, same(selected));
      expect(result.decision.selectedOffer.id, selected.offerId);
      expect(
        result.contract.offer.signature,
        result.decision.selectedOffer.signature,
      );
      expect(
        result.contract.startSeasonIndex,
        result.decision.context.seasonIndex,
      );
      expect(
        result.contract.acceptedByPresidentId,
        result.decision.context.presidentId,
      );
      return;
    case PlayerPresidentInteractiveDecisionKind.crisis:
      final selected = choice as PlayerCrisisActionChoice;
      final result =
          (consequence as PlayerPresidentCrisisConsequence).decision;
      expect(result.choice, same(selected));
      expect(result.selectedDecision.action, selected.action);
      final applied = result.resolution.decision.effect;
      expect(result.resolution.decision.action, selected.action);
      expect(
        applied.cashDelta.minorUnits,
        result.resolution.finance.cash.minorUnits -
            result.context.finance.cash.minorUnits,
      );
      expect(
        applied.fanTrustDelta,
        result.resolution.fan.overallTrust - result.context.fan.overallTrust,
      );
      expect(
        applied.mediaCredibilityDelta,
        result.resolution.media.credibility -
            result.context.media.credibility,
      );
      return;
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      final selected = choice as PlayerManagerReviewChoice;
      final result = consequence as PlayerPresidentManagerReviewConsequence;
      expect(result.choice, selected);
      expect(result.context.clubId, request.clubId);
      expect(
        result.replacementRequired,
        selected == PlayerManagerReviewChoice.replace,
      );
      return;
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      final selected = choice as PlayerManagerReplacementChoice;
      final result =
          consequence as PlayerPresidentManagerReplacementConsequence;
      final context = request.contextAs<PlayerManagerReplacementContext>();
      expect(result.decision.replacementChoice, same(selected));
      expect(result.decision.selectedManager!.id, selected.managerId);
      expect(result.assignment.clubId, request.clubId);
      expect(result.assignment.managerId, selected.managerId);
      expect(result.decision.replacementContext!.reason, context.reason);
      return;
    case PlayerPresidentInteractiveDecisionKind.promise:
      final selected = choice as PresidentPromiseType;
      final result = consequence as PlayerPresidentPromiseConsequence;
      final expected = PlayerPresidentPromiseGenerator.canonicalPromiseFor(
        context: result.context.context,
        type: selected,
      );
      expect(result.promise.signature, expected.signature);
      return;
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      final selected = choice as MediaStance;
      final result = consequence as PlayerPresidentMediaStatementConsequence;
      expect(result.statement.stance, selected);
      expect(result.statement.id, result.context.aiStatement.id);
      expect(
        result.statement.targetManagerId,
        result.context.aiStatement.targetManagerId,
      );
      expect(result.statement.topic, result.context.aiStatement.topic);
      return;
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      final selected = choice as PlayerTransferStrategyChoice;
      final result =
          consequence as PlayerPresidentTransferStrategyConsequence;
      expect(
        result.effectiveProfile.signature,
        selected.applyTo(result.context.aiProfile).signature,
      );
      expect(
        result.effectiveProfile.financialDiscipline,
        selected.financialDiscipline,
      );
      expect(result.effectiveProfile.transferAmbition, selected.transferAmbition);
      expect(result.effectiveProfile.riskAppetite, selected.riskAppetite);
      expect(result.effectiveProfile.youthOrientation, selected.youthOrientation);
      return;
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      final selected = choice as MatchdayTicketPricingChoice;
      final result =
          (consequence as PlayerPresidentTicketPricingConsequence).decision;
      final expected = const MatchdayTicketPricingPolicy().apply(
        base: result.context.baseAttendance,
        tier: selected.tier,
      );
      expect(result.choice, same(selected));
      expect(result.outcome.signature, expected.signature);
      return;
  }
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
    expect(submission.resolution.hasConsequence, isTrue);
    expect(submission.resolution.consequence.kind, pending.request.kind);
    expect(
      submission.resolution.consequence.controlledClubId,
      pending.request.clubId,
    );

    final next = submission.nextStep;
    if (next is PlayerPresidentInteractiveDecisionPending) {
      expect(session.pendingDecision!.key, next.request.key);
    } else {
      expect(next, isA<PlayerPresidentInteractiveSessionCompleted>());
      expect(session.completed, same(next));
    }
    expect(session.answeredDecisionCount, 1);
  });

  test('M90 stage 2 captures authoritative consequences for all nine kinds',
      () {
    final session = newSession();
    final captured = <PlayerPresidentInteractiveDecisionKind,
        PlayerPresidentInteractiveDecisionConsequence>{};
    PlayerPresidentInteractiveSessionStep step = session.advance();
    PlayerPresidentInteractiveDecisionSubmissionResult? lastSubmission;
    var guard = 0;

    while (step is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) throw StateError('M90 consequence session did not converge.');
      final request = step.request;
      final choice = _choiceFor(request);
      final submission =
          session.submitWithResolution(request: request, choice: choice);
      final resolution = submission.resolution;

      expect(resolution.requestKey, request.key);
      expect(resolution.kind, request.kind);
      expect(resolution.acceptedChoice, same(choice));
      expect(resolution.consequence.kind, request.kind);
      expect(resolution.consequence.controlledClubId, request.clubId);
      expect(captured.containsKey(request.kind), isFalse);
      captured[request.kind] = resolution.consequence;
      _expectAuthoritativeConsequence(request, choice, resolution.consequence);

      lastSubmission = submission;
      step = submission.nextStep;
    }

    expect(
      captured.keys.toSet(),
      PlayerPresidentInteractiveDecisionKind.values.toSet(),
    );
    expect(captured.length, 9);
    expect(lastSubmission, isNotNull);
    expect(
      lastSubmission!.nextStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );
  });

  test('M90 facility consequence separates requested from actually applied',
      () {
    final session = newSession();
    PlayerPresidentInteractiveSessionStep step = session.advance();
    var guard = 0;
    while (step is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) throw StateError('Facility consequence not reached.');
      final request = step.request;
      if (request.kind ==
          PlayerPresidentInteractiveDecisionKind.facilityInvestment) {
        const choice = PlayerFacilityInvestmentChoice(
          academyUpgrades: 2,
          trainingGroundUpgrades: 2,
          stadiumUpgrades: 2,
        );
        final submission =
            session.submitWithResolution(request: request, choice: choice);
        final consequence = submission.resolution
            .consequenceAs<PlayerPresidentFacilityInvestmentConsequence>();
        final applied = consequence.decision.decision;
        expect(consequence.decision.requestedChoice, same(choice));
        expect(
          applied.academyAppliedUpgrades +
              applied.trainingGroundAppliedUpgrades +
              applied.stadiumAppliedUpgrades,
          lessThan(
            choice.academyUpgrades +
                choice.trainingGroundUpgrades +
                choice.stadiumUpgrades,
          ),
        );
        return;
      }
      step = session
          .submitWithResolution(
            request: request,
            choice: _choiceFor(request),
          )
          .nextStep;
    }
    fail('Expected a facility investment request.');
  });

  test('M90 manager review retain and replace stay distinct', () {
    final retainSession = newSession();
    PlayerPresidentInteractiveSessionStep retainStep = retainSession.advance();
    var guard = 0;
    while (retainStep is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) throw StateError('Manager review not reached.');
      final request = retainStep.request;
      if (request.kind == PlayerPresidentInteractiveDecisionKind.managerReview) {
        final context = request.contextAs<PlayerManagerReviewContext>();
        expect(context.canRetain, isTrue);
        final submission = retainSession.submitWithResolution(
          request: request,
          choice: PlayerManagerReviewChoice.retain,
        );
        final consequence = submission.resolution
            .consequenceAs<PlayerPresidentManagerReviewConsequence>();
        expect(consequence.retained, isTrue);
        expect(consequence.replacementRequired, isFalse);
        expect(consequence.context.currentManager.id, context.currentManager.id);
        break;
      }
      retainStep = retainSession
          .submitWithResolution(
            request: request,
            choice: _choiceFor(request),
          )
          .nextStep;
    }

    final replaceSession = newSession();
    PlayerPresidentInteractiveSessionStep replaceStep = replaceSession.advance();
    guard = 0;
    while (replaceStep is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) throw StateError('Manager review not reached.');
      final request = replaceStep.request;
      if (request.kind == PlayerPresidentInteractiveDecisionKind.managerReview) {
        final submission = replaceSession.submitWithResolution(
          request: request,
          choice: PlayerManagerReviewChoice.replace,
        );
        final consequence = submission.resolution
            .consequenceAs<PlayerPresidentManagerReviewConsequence>();
        expect(consequence.retained, isFalse);
        expect(consequence.replacementRequired, isTrue);
        expect(submission.nextStep,
            isA<PlayerPresidentInteractiveDecisionPending>());
        expect(
          (submission.nextStep as PlayerPresidentInteractiveDecisionPending)
              .request
              .kind,
          PlayerPresidentInteractiveDecisionKind.managerReplacement,
        );
        return;
      }
      replaceStep = replaceSession
          .submitWithResolution(
            request: request,
            choice: _choiceFor(request),
          )
          .nextStep;
    }
    fail('Expected manager review requests.');
  });

  test('M90 current-submit capture ignores prior replayed consequences', () {
    final session = newSession();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    final firstSubmission = session.submitWithResolution(
      request: first.request,
      choice: _choiceFor(first.request),
    );
    final second =
        firstSubmission.nextStep as PlayerPresidentInteractiveDecisionPending;
    final secondChoice = _choiceFor(second.request);
    final secondSubmission = session.submitWithResolution(
      request: second.request,
      choice: secondChoice,
    );

    expect(secondSubmission.resolution.requestKey, second.request.key);
    expect(secondSubmission.resolution.kind, second.request.kind);
    expect(secondSubmission.resolution.acceptedChoice, same(secondChoice));
    expect(secondSubmission.resolution.consequence.kind, second.request.kind);
    expect(
      secondSubmission.resolution.consequence.kind,
      isNot(firstSubmission.resolution.consequence.kind),
    );
  });

  test('M90 consequence capture is deterministic across equivalent sessions',
      () {
    final left = newSession();
    final right = newSession();
    PlayerPresidentInteractiveSessionStep leftStep = left.advance();
    PlayerPresidentInteractiveSessionStep rightStep = right.advance();
    var guard = 0;

    while (leftStep is PlayerPresidentInteractiveDecisionPending &&
        rightStep is PlayerPresidentInteractiveDecisionPending) {
      guard++;
      if (guard > 100) throw StateError('Determinism sessions did not converge.');
      expect(rightStep.request.key, leftStep.request.key);
      final leftChoice = _choiceFor(leftStep.request);
      final rightChoice = _choiceFor(rightStep.request);
      final leftSubmission = left.submitWithResolution(
        request: leftStep.request,
        choice: leftChoice,
      );
      final rightSubmission = right.submitWithResolution(
        request: rightStep.request,
        choice: rightChoice,
      );
      expect(
        _consequenceSignature(rightSubmission.resolution.consequence),
        _consequenceSignature(leftSubmission.resolution.consequence),
      );
      leftStep = leftSubmission.nextStep;
      rightStep = rightSubmission.nextStep;
    }
    expect(leftStep.runtimeType, rightStep.runtimeType);
    expect(leftStep, isA<PlayerPresidentInteractiveSessionCompleted>());
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
