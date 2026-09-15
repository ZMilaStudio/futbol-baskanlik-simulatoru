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

PlayerPresidentInteractiveSessionCompleted _driveApplication(
  PlayerPresidentInteractiveDecisionApplicationSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M79 application new-game session did not converge.');
    }
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
}

PlayerPresidentInteractiveSessionCompleted _driveRaw(
  PlayerPresidentInteractiveDecisionSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M79 raw new-game session did not converge.');
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
  const forcedThreshold = 0;

  late FictionalWorldSetup world;
  late String controlledClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
  });

  PlayerPresidentInteractiveDecisionApplicationSession freshStart() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: forcedThreshold,
        candidateLimit: 5,
      );

  PlayerPresidentInteractiveDecisionSession freshRawStart() =>
      PlayerPresidentInteractiveDecisionSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        aiCrisisEngine:
            const CrisisDecisionEngine(activationThreshold: forcedThreshold),
        candidateLimit: 5,
      );

  test('M79 application start owns the deterministic M73 new-game request', () {
    final first = freshStart();
    final second = freshStart();
    final raw = freshRawStart();

    final firstPending =
        first.advance() as PlayerPresidentInteractiveDecisionPending;
    final secondPending =
        second.advance() as PlayerPresidentInteractiveDecisionPending;
    final rawPending = raw.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(first.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame);
    expect(first.isNewGame, isTrue);
    expect(first.canPersist, isFalse);
    expect(first.checkpointOrNull, isNull);
    expect(first.newGameElectionInterval, 4);
    expect(first.resumeConfig.seasonCount, 1);
    expect(firstPending.request.key, secondPending.request.key);
    expect(firstPending.request.key, rawPending.request.key);
  });

  test('M79 new-game application completion has exact M73 parity', () {
    final applicationCompleted = _driveApplication(freshStart());
    final rawCompleted = _driveRaw(freshRawStart());

    expect(
      checkpointCodec.encode(applicationCompleted.result.checkpoint),
      checkpointCodec.encode(rawCompleted.result.checkpoint),
    );
    expect(
      applicationCompleted.result.boundaries
          .map((boundary) => boundary.signature)
          .toList(),
      rawCompleted.result.boundaries
          .map((boundary) => boundary.signature)
          .toList(),
    );
    expect(applicationCompleted.decisionCount, rawCompleted.decisionCount);
  });

  test('M79 pre-checkpoint M75 persistence is explicitly fail-closed', () {
    final session = freshStart();
    final first = session.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(() => session.checkpoint, throwsStateError);
    expect(() => session.persistenceBundle, throwsStateError);
    expect(() => session.encodePersistenceBundle(), throwsStateError);

    final next = session.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    ) as PlayerPresidentInteractiveDecisionPending;
    final answered = session.answeredDecisionCount;
    final pendingKey = next.request.key;

    expect(() => session.encodePersistenceBundle(), throwsStateError);
    expect(session.answeredDecisionCount, answered);
    expect(session.pendingDecision!.key, pendingKey);
  });

  test('M79 completed new game hands off to existing checkpoint lifecycle', () {
    final completed = _driveApplication(freshStart());
    const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: 1,
      hasFutureSeasonAfterReport: false,
      crisisActivationThreshold: forcedThreshold,
      candidateLimit: 5,
    );

    final application = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: completed.result.checkpoint,
      resumeConfig: resumeConfig,
    );
    final raw = PlayerPresidentInteractiveDecisionSession.resume(
      checkpoint: completed.result.checkpoint,
      seasonCount: resumeConfig.seasonCount,
      hasFutureSeasonAfterReport: resumeConfig.hasFutureSeasonAfterReport,
      aiCrisisEngine:
          const CrisisDecisionEngine(activationThreshold: forcedThreshold),
      candidateLimit: resumeConfig.candidateLimit,
    );

    expect(application.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint);
    expect(application.isNewGame, isFalse);
    expect(application.canPersist, isTrue);
    expect(application.checkpointOrNull, isNotNull);
    expect(application.encodePersistenceBundle(), isNotEmpty);

    final applicationPending =
        application.advance() as PlayerPresidentInteractiveDecisionPending;
    final rawPending = raw.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(applicationPending.request.key, rawPending.request.key);
  });

  test('M79 start preserves new-game input validation', () {
    expect(
      () => PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: 'missing-club',
        seasonCount: 1,
      ),
      throwsArgumentError,
    );
  });
}
