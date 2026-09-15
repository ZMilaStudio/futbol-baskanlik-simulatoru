import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
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

PlayerPresidentInteractiveSessionCompleted _drive(
  PlayerPresidentInteractiveDecisionApplicationSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M80 bootstrap session did not converge.');
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
  const forcedThreshold = 0;
  const bootstrapCodec =
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec();
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
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

  final original = fresh();
  final first = original.advance() as PlayerPresidentInteractiveDecisionPending;
  final second = original.submit(
    request: first.request,
    choice: _choiceFor(first.request),
  ) as PlayerPresidentInteractiveDecisionPending;

  final encoded = original.encodeNewGameBootstrapSnapshot();
  final decoded = bootstrapCodec.decode(encoded);
  final stableCodec = bootstrapCodec.encode(decoded) == encoded;

  final restored =
      PlayerPresidentInteractiveDecisionApplicationSession
          .restoreEncodedNewGameBootstrap(
    clubs: world.clubs,
    leagues: world.leagues,
    encodedBootstrap: encoded,
  );
  final bootstrapRoundTrip = restored.isNewGame &&
      !restored.canPersist &&
      restored.canPersistBootstrap &&
      restored.answeredDecisionCount == 1 &&
      restored.pendingDecision?.key == second.request.key;

  var worldGuard = false;
  final divergentClubs = List<Club>.of(world.clubs);
  divergentClubs[0] = divergentClubs[0].copyWith(
    strength: divergentClubs[0].strength + 0.5,
  );
  try {
    PlayerPresidentInteractiveDecisionApplicationSession.restoreNewGameBootstrap(
      clubs: divergentClubs,
      leagues: world.leagues,
      snapshot: decoded,
    );
  } on SaveLoadException catch (error) {
    worldGuard = error.failure == SaveLoadFailure.invalidPayload;
  }

  var m75Blocked = false;
  try {
    original.encodePersistenceBundle();
  } on StateError {
    m75Blocked = true;
  }

  final uninterruptedCompleted = _drive(original);
  final restoredCompleted = _drive(restored);
  final parity =
      checkpointCodec.encode(uninterruptedCompleted.result.checkpoint) ==
              checkpointCodec.encode(restoredCompleted.result.checkpoint) &&
          uninterruptedCompleted.decisionCount ==
              restoredCompleted.decisionCount &&
          uninterruptedCompleted.result.boundaries.single.signature ==
              restoredCompleted.result.boundaries.single.signature;

  if (!stableCodec ||
      !bootstrapRoundTrip ||
      !worldGuard ||
      !m75Blocked ||
      !parity) {
    throw StateError('M80 new-game bootstrap snapshot invariant failed.');
  }

  print(
    'M80_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_SNAPSHOT_PASS '
    'controlled=$controlledClubId decisions=${restoredCompleted.decisionCount} '
    'bootstrapRoundTrip=$bootstrapRoundTrip stableCodec=$stableCodec '
    'worldGuard=$worldGuard m75Blocked=$m75Blocked parity=$parity '
    'saveAuthority=M65 replayMetadata=M74 checkpointBundle=M75 '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
