import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
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
      throw StateError('M93 application session did not converge.');
    }
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String turnoverClubId;
  late PlayerPresidentTicketPricingRuntimeCheckpoint beforeLossCheckpoint;
  late PlayerPresidentTicketPricingRuntimeCheckpoint lostCheckpoint;

  setUpAll(() {
    world = const FictionalWorldFactory().build();

    const domainEngine = PresidentDomainCareerEngine();
    final beforeElection = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final afterElection = domainEngine.resume(
      checkpoint: beforeElection.checkpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final beforeByClub = {
      for (final state in beforeElection.checkpoint.presidentRuntime.clubs)
        state.clubId: state.tenure.president.id,
    };
    final afterByClub = {
      for (final state in afterElection.checkpoint.presidentRuntime.clubs)
        state.clubId: state.tenure.president.id,
    };
    turnoverClubId = beforeByClub.keys.firstWhere(
      (clubId) => beforeByClub[clubId] != afterByClub[clubId],
    );

    const gatewayEngine =
        PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine();
    beforeLossCheckpoint = gatewayEngine
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          controlledClubId: turnoverClubId,
          seasonCount: 3,
          electionInterval: 4,
          hasFutureSeasonAfterReport: true,
        )
        .checkpoint;
    lostCheckpoint = gatewayEngine
        .resume(
          checkpoint: beforeLossCheckpoint,
          seasonCount: 1,
          hasFutureSeasonAfterReport: true,
        )
        .checkpoint;

    expect(beforeLossCheckpoint.tenureControl.active, isTrue);
    expect(lostCheckpoint.tenureControl.lost, isTrue);
    expect(lostCheckpoint.tenureControl.lostAtCompletedSeason, 4);
  });

  test('M93 completed tenure seam is null before completion', () {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: world.clubs.first.id,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );

    expect(session.completedTenureControl, isNull);
    expect(
      () => session.continuePlayerCareerToNextSeason(),
      throwsStateError,
    );
  });

  test('M93 active Completed exposes tenure and returns unadvanced next session',
      () {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: world.clubs.first.id,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );

    final completed = _drive(session);
    expect(session.completedTenureControl, same(completed.result.checkpoint.tenureControl));
    expect(session.completedTenureControl!.active, isTrue);

    final next = session.continuePlayerCareerToNextSeason();
    expect(
      next.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(next.checkpointOrNull, same(completed.result.checkpoint));
    expect(next.completed, isNull);
    expect(next.pendingDecision, isNull);
  });

  test('M93 M92 opening control can be active before final lost boundary', () {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpointCodec.decode(
        checkpointCodec.encode(beforeLossCheckpoint),
      ),
      resumeConfig: resumeConfig,
    );

    final opening = session.preparedSeasonDashboard;
    expect(opening.playerControlActive, isTrue);
    expect(opening.playerControl.status, PlayerPresidentTenureControlStatus.active);

    const gatewayEngine =
        PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine();
    final finalBoundary = gatewayEngine.resume(
      checkpoint: beforeLossCheckpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    expect(finalBoundary.checkpoint.tenureControl.lost, isTrue);
    expect(finalBoundary.checkpoint.tenureControl.lostAtCompletedSeason, 4);
    expect(opening.playerControlActive, isTrue);
  });

  test('M93 lost checkpoint resumes generically but player continuation fails closed',
      () {
    final application =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpointCodec.decode(checkpointCodec.encode(lostCheckpoint)),
      resumeConfig: resumeConfig,
    );

    expect(application.completedTenureControl, isNull);
    final completed = application.advance();
    expect(completed, isA<PlayerPresidentInteractiveSessionCompleted>());
    expect(application.completed!.decisionCount, 0);
    expect(application.completedTenureControl!.lost, isTrue);
    expect(application.completedTenureControl!.lostAtCompletedSeason, 4);
    expect(
      () => application.continuePlayerCareerToNextSeason(),
      throwsStateError,
    );

    final generic = PlayerPresidentInteractiveDecisionSession.resume(
      checkpoint: checkpointCodec.decode(checkpointCodec.encode(lostCheckpoint)),
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final genericStep = generic.advance();
    expect(genericStep, isA<PlayerPresidentInteractiveSessionCompleted>());
    expect(
      (genericStep as PlayerPresidentInteractiveSessionCompleted).decisionCount,
      0,
    );
  });

  test('M93 M75 restore re-derives the same permanent lost authority', () {
    final source = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpointCodec.decode(checkpointCodec.encode(lostCheckpoint)),
      resumeConfig: resumeConfig,
    );
    source.advance();
    final before = source.completedTenureControl!;
    final encoded = source.encodePersistenceBundle();

    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: encoded,
    );
    expect(restored.completedTenureControl, isNull);
    final restoredStep = restored.advance();
    expect(restoredStep, isA<PlayerPresidentInteractiveSessionCompleted>());
    expect(restored.completedTenureControl!.signature, before.signature);
    expect(restored.completedTenureControl!.lostAtCompletedSeason, 4);
    expect(PlayerPresidentTicketPricingRuntimeSaveCodec.currentSaveVersion, 1);
  });
}
