import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
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
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  late FictionalWorldSetup world;
  late PlayerPresidentTicketPricingRuntimeCheckpoint initial;
  late String controlledClubId;
  late Directory root;

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

  setUp(() {
    root = Directory.systemTemp.createTempSync('fbs-m83-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(initial)),
        resumeConfig: resumeConfig,
      );

  PlayerPresidentInteractiveDecisionApplicationSession bootstrapSession() =>
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

  PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpointStore() =>
      PlayerPresidentInteractiveDecisionFileSaveSlotStore(rootDirectory: root);

  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      bootstrapStore() =>
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
            rootDirectory: root,
          );

  PlayerPresidentInteractiveDecisionFileSaveSlotCatalog checkpointCatalog(
    PlayerPresidentInteractiveDecisionFileSaveSlotStore store,
  ) =>
      PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(store: store);

  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog
      bootstrapCatalog(
    PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore store, {
    List<Club>? clubs,
  }) =>
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
            store: store,
            clubs: clubs ?? world.clubs,
            leagues: world.leagues,
          );

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog mixedCatalog({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpoints,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstraps,
    List<Club>? clubs,
  }) =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog(
        checkpointCatalog: checkpointCatalog(checkpoints),
        bootstrapCatalog: bootstrapCatalog(bootstraps, clubs: clubs),
      );

  test('M83 lists checkpoint and bootstrap saves as one read-only projection',
      () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();

    final checkpoint = checkpointSession();
    var checkpointStep = checkpoint.advance();
    checkpointStep = _answer(checkpoint, checkpointStep);
    checkpoints.save('career-b', checkpoint);

    final bootstrap = bootstrapSession();
    var bootstrapStep = bootstrap.advance();
    bootstrapStep = _answer(bootstrap, bootstrapStep);
    bootstrapStep = _answer(bootstrap, bootstrapStep);
    bootstraps.save('new-a', bootstrap);

    final checkpointFile = File(
      '${root.path}${Platform.pathSeparator}career-b.fbs.json',
    );
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}new-a.fbs.bootstrap.json',
    );
    final checkpointBefore = checkpointFile.readAsStringSync();
    final bootstrapBefore = bootstrapFile.readAsStringSync();

    final summaries = mixedCatalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    ).list();

    expect(summaries.map((item) => item.slotId), <String>['career-b', 'new-a']);
    expect(
      summaries.map((item) => item.source),
      <PlayerPresidentInteractiveDecisionMixedSaveSlotSource>[
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap,
      ],
    );
    expect(summaries.map((item) => item.answeredDecisionCount), <int>[1, 2]);
    expect(summaries.every((item) => item.controlledClubId == controlledClubId),
        isTrue);
    expect(
      summaries.every(
        (item) => item.controlledClubName == world.clubs.first.name,
      ),
      isTrue,
    );
    expect(checkpointFile.readAsStringSync(), checkpointBefore);
    expect(bootstrapFile.readAsStringSync(), bootstrapBefore);
  });

  test('M83 preserves same-id entries from both namespaces deterministically',
      () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('shared', checkpointSession());
    bootstraps.save('shared', bootstrapSession());

    final summaries = mixedCatalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    ).list();

    expect(summaries.length, 2);
    expect(
      summaries.map((item) => item.identity),
      <String>['checkpoint:shared', 'newGameBootstrap:shared'],
    );
    expect(summaries[0].isCheckpoint, isTrue);
    expect(summaries[1].isNewGameBootstrap, isTrue);
  });

  test('M83 inspect routes explicitly and preserves missing/invalid contracts',
      () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('checkpoint-only', checkpointSession());
    bootstraps.save('bootstrap-only', bootstrapSession());
    final catalog = mixedCatalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    expect(
      catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'checkpoint-only',
      )?.isCheckpoint,
      isTrue,
    );
    expect(
      catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'bootstrap-only',
      )?.isNewGameBootstrap,
      isTrue,
    );
    expect(
      catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'bootstrap-only',
      ),
      isNull,
    );
    expect(
      catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'checkpoint-only',
      ),
      isNull,
    );
    expect(
      () => catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
    expect(
      () => catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
  });

  test('M83 delegates corrupt-save and bootstrap world guards fail closed', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('career', checkpointSession());
    File('${root.path}${Platform.pathSeparator}career.fbs.json')
        .writeAsStringSync('{"corrupt":true}', flush: true);

    final catalog = mixedCatalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );
    expect(
      () => catalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'career',
      ),
      throwsA(isA<SaveLoadException>()),
    );

    checkpoints.save('career', checkpointSession());
    bootstraps.save('new-game', bootstrapSession());
    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    final divergentCatalog = mixedCatalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
      clubs: divergentClubs,
    );
    expect(
      () => divergentCatalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'new-game',
      ),
      throwsA(
        predicate<SaveLoadException>(
          (error) => error.failure == SaveLoadFailure.invalidPayload,
        ),
      ),
    );
  });

  test('M83 keeps exact M78/M82 detail and creates no metadata sidecar', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('career', checkpointSession());
    bootstraps.save('new-game', bootstrapSession());

    final directCheckpoint = checkpointCatalog(checkpoints).inspect('career')!;
    final directBootstrap =
        bootstrapCatalog(bootstraps).inspect('new-game')!;
    final catalog = mixedCatalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );
    final mixedCheckpoint = catalog.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'career',
    )!;
    final mixedBootstrap = catalog.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'new-game',
    )!;

    expect(mixedCheckpoint.checkpointSummary?.signature,
        directCheckpoint.signature);
    expect(mixedCheckpoint.bootstrapSummary, isNull);
    expect(mixedBootstrap.bootstrapSummary?.signature, directBootstrap.signature);
    expect(mixedBootstrap.checkpointSummary, isNull);

    final names = root
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();
    expect(
      names,
      <String>['career.fbs.json', 'new-game.fbs.bootstrap.json'],
    );
  });
}
