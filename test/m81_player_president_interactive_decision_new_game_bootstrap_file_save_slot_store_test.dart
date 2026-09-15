import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
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

PlayerPresidentInteractiveSessionStep _answer(
  PlayerPresidentInteractiveDecisionApplicationSession session,
  PlayerPresidentInteractiveSessionStep step,
) {
  final pending = step as PlayerPresidentInteractiveDecisionPending;
  return session.submit(
    request: pending.request,
    choice: _choiceFor(pending.request),
  );
}

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const bootstrapCodec =
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec();
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  late Directory root;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    checkpoint = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('fbs-m81-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
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
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      );

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(checkpoint)),
        resumeConfig: resumeConfig,
      );

  test('M81 bootstrap slot survives a fresh store instance at exact pending request',
      () {
    final session = fresh();
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var index = 0; index < 4; index++) {
      step = _answer(session, step);
    }
    final pendingBefore =
        (step as PlayerPresidentInteractiveDecisionPending).request.key;
    final encodedBefore = bootstrapCodec.encode(session.newGameBootstrapSnapshot);

    PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    ).save('new-game-1', session);

    final restored =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    ).load(
      slotId: 'new-game-1',
      clubs: world.clubs,
      leagues: world.leagues,
    )!;

    expect(restored.pendingDecision?.key, pendingBefore);
    expect(restored.answeredDecisionCount, 4);
    expect(restored.isNewGame, isTrue);
    expect(restored.canPersist, isFalse);
    expect(
      restored.encodeNewGameBootstrapSnapshot(),
      encodedBefore,
    );
  });

  test('M81 overwrite keeps only the latest exact M80 bootstrap', () {
    final store =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();
    var step = session.advance();
    step = _answer(session, step);
    store.save('new-game-1', session);

    step = _answer(session, step);
    store.save('new-game-1', session);

    final restored = store.load(
      slotId: 'new-game-1',
      clubs: world.clubs,
      leagues: world.leagues,
    )!;
    expect(restored.answeredDecisionCount, 2);
    expect(
      restored.encodeNewGameBootstrapSnapshot(),
      session.encodeNewGameBootstrapSnapshot(),
    );
    expect(store.listSlotIds(), <String>['new-game-1']);
  });

  test('M81 rejects invalid ids and checkpoint-backed sessions without disk mutation',
      () {
    final store =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();

    for (final slotId in <String>['', '../escape', 'a/b', r'a\b', 'two words']) {
      expect(() => store.save(slotId, session), throwsArgumentError);
      expect(
        () => store.load(
          slotId: slotId,
          clubs: world.clubs,
          leagues: world.leagues,
        ),
        throwsArgumentError,
      );
    }
    expect(root.listSync(), isEmpty);

    expect(
      () => store.save('checkpoint', checkpointSession()),
      throwsStateError,
    );
    expect(root.listSync(), isEmpty);
  });

  test('M81 recovers a committed bootstrap backup after interrupted replacement',
      () {
    final store =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();
    final step = session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(request: step.request, choice: _choiceFor(step.request));
    store.save('new-game-1', session);

    final target = File(
      '${root.path}${Platform.pathSeparator}new-game-1.fbs.bootstrap.json',
    );
    final backup = File('${target.path}.bak');
    target.renameSync(backup.path);
    File('${target.path}.tmp').writeAsStringSync('incomplete');

    final restored =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    ).load(
      slotId: 'new-game-1',
      clubs: world.clubs,
      leagues: world.leagues,
    )!;

    expect(restored.answeredDecisionCount, 1);
    expect(target.existsSync(), isTrue);
    expect(backup.existsSync(), isFalse);
  });

  test('M81 corrupted bytes and divergent supplied world both fail closed', () {
    final store =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    store.save('new-game-1', fresh());
    final target = File(
      '${root.path}${Platform.pathSeparator}new-game-1.fbs.bootstrap.json',
    );
    target.writeAsStringSync('{"corrupt":true}', flush: true);

    expect(
      () => store.load(
        slotId: 'new-game-1',
        clubs: world.clubs,
        leagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );

    store.save('new-game-1', fresh());
    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    expect(
      () => store.load(
        slotId: 'new-game-1',
        clubs: divergentClubs,
        leagues: world.leagues,
      ),
      throwsA(
        predicate<SaveLoadException>(
          (error) => error.failure == SaveLoadFailure.invalidPayload,
        ),
      ),
    );
  });

  test('M81 listing and delete stay isolated from M77 checkpoint slots', () {
    final bootstrapStore =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final checkpointStore = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );

    bootstrapStore.save('z-slot', fresh());
    bootstrapStore.save('a-slot', fresh());
    checkpointStore.save('checkpoint-only', checkpointSession());

    expect(bootstrapStore.listSlotIds(), <String>['a-slot', 'z-slot']);
    expect(checkpointStore.listSlotIds(), <String>['checkpoint-only']);
    expect(bootstrapStore.contains('checkpoint-only'), isFalse);
    expect(checkpointStore.contains('a-slot'), isFalse);

    expect(bootstrapStore.delete('a-slot'), isTrue);
    expect(bootstrapStore.contains('a-slot'), isFalse);
    expect(
      bootstrapStore.load(
        slotId: 'a-slot',
        clubs: world.clubs,
        leagues: world.leagues,
      ),
      isNull,
    );
    expect(bootstrapStore.listSlotIds(), <String>['z-slot']);
    expect(checkpointStore.contains('checkpoint-only'), isTrue);
  });
}
