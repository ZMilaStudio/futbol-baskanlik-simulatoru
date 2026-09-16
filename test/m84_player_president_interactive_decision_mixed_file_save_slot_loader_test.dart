import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_loader.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
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
    root = Directory.systemTemp.createTempSync('fbs-m84-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: initial,
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

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader loader({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpoints,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstraps,
    List<Club>? clubs,
  }) =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader(
        checkpointStore: checkpoints,
        bootstrapStore: bootstraps,
        clubs: clubs ?? world.clubs,
        leagues: world.leagues,
      );

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog catalog({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpoints,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstraps,
  }) =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog(
        checkpointCatalog: PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
          store: checkpoints,
        ),
        bootstrapCatalog:
            PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
          store: bootstraps,
          clubs: world.clubs,
          leagues: world.leagues,
        ),
      );

  test('M84 routes checkpoint and bootstrap loads to the correct child store',
      () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('career', checkpointSession());
    bootstraps.save('new-game', bootstrapSession());
    final mixedLoader = loader(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    final checkpoint = mixedLoader.load(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'career',
    );
    final bootstrap = mixedLoader.load(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'new-game',
    );

    expect(checkpoint, isNotNull);
    expect(checkpoint!.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint);
    expect(checkpoint.canPersist, isTrue);
    expect(checkpoint.isNewGame, isFalse);

    expect(bootstrap, isNotNull);
    expect(bootstrap!.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame);
    expect(bootstrap.canPersist, isFalse);
    expect(bootstrap.canPersistBootstrap, isTrue);
    expect(bootstrap.newGameBootstrapSnapshot.controlledClubId, controlledClubId);
  });

  test('M84 loads M83 same-id summaries without collapsing namespaces', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('shared', checkpointSession());
    bootstraps.save('shared', bootstrapSession());

    final checkpointFile =
        File('${root.path}${Platform.pathSeparator}shared.fbs.json');
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json',
    );
    final checkpointBefore = checkpointFile.readAsStringSync();
    final bootstrapBefore = bootstrapFile.readAsStringSync();

    final summaries = catalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    ).list();
    final mixedLoader = loader(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );
    final sessions = summaries.map(mixedLoader.loadSummary).toList();

    expect(
      summaries.map((summary) => summary.identity),
      <String>['checkpoint:shared', 'newGameBootstrap:shared'],
    );
    expect(
      sessions.map((session) => session?.origin),
      <PlayerPresidentInteractiveDecisionApplicationSessionOrigin?>[
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
      ],
    );
    expect(checkpointFile.readAsStringSync(), checkpointBefore);
    expect(bootstrapFile.readAsStringSync(), bootstrapBefore);
  });

  test('M84 preserves child missing and slot validation contracts', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('checkpoint-only', checkpointSession());
    final mixedLoader = loader(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    expect(
      mixedLoader.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'missing',
      ),
      isNull,
    );
    expect(
      mixedLoader.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'checkpoint-only',
      ),
      isNull,
    );
    expect(
      () => mixedLoader.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
    expect(
      () => mixedLoader.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
  });

  test('M84 delegates corrupt checkpoint decoding fail closed', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    checkpoints.save('career', checkpointSession());
    File('${root.path}${Platform.pathSeparator}career.fbs.json')
        .writeAsStringSync('{"corrupt":true}', flush: true);
    final mixedLoader = loader(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    expect(
      () => mixedLoader.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'career',
      ),
      throwsA(isA<SaveLoadException>()),
    );
  });

  test('M84 delegates bootstrap world guard and creates no new save files', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    bootstraps.save('new-game', bootstrapSession());
    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    final mixedLoader = loader(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
      clubs: divergentClubs,
    );

    expect(
      () => mixedLoader.load(
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

    final names = root
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();
    expect(names, <String>['new-game.fbs.bootstrap.json']);
  });
}
