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
      throw StateError('M79 application session did not converge.');
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
      throw StateError('M79 raw session did not converge.');
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
  const forcedThreshold = 0;
  final config = SimulationConfig(careerSeed: seed);

  PlayerPresidentInteractiveDecisionApplicationSession freshApplication() =>
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

  PlayerPresidentInteractiveDecisionSession freshRaw() =>
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

  final deterministicA = freshApplication();
  final deterministicB = freshApplication();
  final firstA =
      deterministicA.advance() as PlayerPresidentInteractiveDecisionPending;
  final firstB =
      deterministicB.advance() as PlayerPresidentInteractiveDecisionPending;
  final deterministic = firstA.request.key == firstB.request.key;

  var persistenceBlocked = false;
  try {
    deterministicA.encodePersistenceBundle();
  } on StateError {
    persistenceBlocked = true;
  }

  final applicationCompleted = _driveApplication(freshApplication());
  final rawCompleted = _driveRaw(freshRaw());
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  final parity =
      checkpointCodec.encode(applicationCompleted.result.checkpoint) ==
          checkpointCodec.encode(rawCompleted.result.checkpoint) &&
      applicationCompleted.result.boundaries.single.signature ==
          rawCompleted.result.boundaries.single.signature &&
      applicationCompleted.decisionCount == rawCompleted.decisionCount;

  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: false,
    crisisActivationThreshold: forcedThreshold,
    candidateLimit: 5,
  );
  final handoff = PlayerPresidentInteractiveDecisionApplicationSession.resume(
    checkpoint: applicationCompleted.result.checkpoint,
    resumeConfig: resumeConfig,
  );
  final checkpointHandoff = handoff.canPersist &&
      !handoff.isNewGame &&
      handoff.checkpointOrNull != null &&
      handoff.encodePersistenceBundle().isNotEmpty;

  final startOwned = deterministicA.isNewGame &&
      !deterministicA.canPersist &&
      deterministicA.checkpointOrNull == null &&
      deterministicA.newGameElectionInterval == 4;

  if (!deterministic ||
      !persistenceBlocked ||
      !parity ||
      !checkpointHandoff ||
      !startOwned ||
      applicationCompleted.decisionCount == 0) {
    throw StateError('M79 application new-game session invariant failed.');
  }

  print(
    'M79_PLAYER_PRESIDENT_INTERACTIVE_DECISION_APPLICATION_NEW_GAME_SESSION_PASS '
    'controlled=$controlledClubId decisions=${applicationCompleted.decisionCount} '
    'startOwned=$startOwned deterministic=$deterministic '
    'persistenceBlocked=$persistenceBlocked parityM73=$parity '
    'checkpointHandoff=$checkpointHandoff saveAuthority=M65 '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
