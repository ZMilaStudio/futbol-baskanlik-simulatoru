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
      throw StateError('M80 application session did not converge.');
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
  const forcedThreshold = 0;
  const bootstrapCodec =
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec();
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String controlledClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
  });

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

  test('M80 empty bootstrap snapshot restores deterministic first request', () {
    final original = fresh();
    final encoded = original.encodeNewGameBootstrapSnapshot();
    final restored = PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: encoded,
    );

    final originalFirst =
        original.advance() as PlayerPresidentInteractiveDecisionPending;
    final restoredFirst =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(restored.isNewGame, isTrue);
    expect(restored.canPersist, isFalse);
    expect(restored.canPersistBootstrap, isTrue);
    expect(restored.answeredDecisionCount, 0);
    expect(restoredFirst.request.key, originalFirst.request.key);
  });

  test('M80 answered transcript round-trip restores same pending request', () {
    final original = fresh();
    final first =
        original.advance() as PlayerPresidentInteractiveDecisionPending;
    final second = original.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    ) as PlayerPresidentInteractiveDecisionPending;

    final encoded = original.encodeNewGameBootstrapSnapshot();
    final restored = PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: encoded,
    );

    expect(restored.answeredDecisionCount, 1);
    expect(restored.pendingDecision, isNotNull);
    expect(restored.pendingDecision!.key, second.request.key);
    expect(
      bootstrapCodec.encode(restored.newGameBootstrapSnapshot),
      encoded,
    );
  });

  test('M80 bootstrap codec is deterministic and checksum protected', () {
    final session = fresh();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    );

    final encoded = session.encodeNewGameBootstrapSnapshot();
    final decoded = bootstrapCodec.decode(encoded);

    expect(bootstrapCodec.encode(decoded), encoded);

    final tampered = encoded.replaceFirst(controlledClubId, '${controlledClubId}x');
    expect(
      () => bootstrapCodec.decode(tampered),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.checksumMismatch,
        ),
      ),
    );
  });

  test('M80 divergent supplied world fails closed before transcript replay', () {
    final session = fresh();
    final first =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    );
    final snapshot = session.newGameBootstrapSnapshot;

    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );

    expect(
      () => PlayerPresidentInteractiveDecisionApplicationSession
          .restoreNewGameBootstrap(
        clubs: divergentClubs,
        leagues: world.leagues,
        snapshot: snapshot,
      ),
      throwsA(
        isA<SaveLoadException>().having(
          (error) => error.failure,
          'failure',
          SaveLoadFailure.invalidPayload,
        ),
      ),
    );
  });

  test('M80 restored bootstrap completion has uninterrupted exact parity', () {
    final uninterrupted = fresh();
    final first =
        uninterrupted.advance() as PlayerPresidentInteractiveDecisionPending;
    uninterrupted.submit(
      request: first.request,
      choice: _choiceFor(first.request),
    );

    final restored = PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: uninterrupted.encodeNewGameBootstrapSnapshot(),
    );

    final uninterruptedCompleted = _drive(uninterrupted);
    final restoredCompleted = _drive(restored);

    expect(
      checkpointCodec.encode(restoredCompleted.result.checkpoint),
      checkpointCodec.encode(uninterruptedCompleted.result.checkpoint),
    );
    expect(
      restoredCompleted.result.boundaries
          .map((boundary) => boundary.signature)
          .toList(),
      uninterruptedCompleted.result.boundaries
          .map((boundary) => boundary.signature)
          .toList(),
    );
    expect(restoredCompleted.decisionCount, uninterruptedCompleted.decisionCount);
  });

  test('M80 keeps M75 authority boundary and rejects bootstrap on checkpoint origin',
      () {
    final newGame = fresh();
    newGame.advance();

    expect(newGame.canPersist, isFalse);
    expect(newGame.canPersistBootstrap, isTrue);
    expect(() => newGame.encodePersistenceBundle(), throwsStateError);
    expect(newGame.encodeNewGameBootstrapSnapshot(), isNotEmpty);

    final completed = _drive(fresh());
    const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: 1,
      hasFutureSeasonAfterReport: false,
      crisisActivationThreshold: forcedThreshold,
      candidateLimit: 5,
    );
    final checkpointSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: completed.result.checkpoint,
      resumeConfig: resumeConfig,
    );

    expect(checkpointSession.canPersist, isTrue);
    expect(checkpointSession.canPersistBootstrap, isFalse);
    expect(
      () => checkpointSession.newGameBootstrapSnapshot,
      throwsStateError,
    );
    expect(checkpointSession.encodePersistenceBundle(), isNotEmpty);
  });
}
