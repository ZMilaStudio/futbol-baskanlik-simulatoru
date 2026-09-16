import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_writer.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);

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
    root = Directory.systemTemp.createTempSync('fbs-m85-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession({
    int seasonCount = 1,
  }) =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: initial,
        resumeConfig: PlayerPresidentInteractiveDecisionResumeConfig(
          seasonCount: seasonCount,
          hasFutureSeasonAfterReport: true,
          crisisActivationThreshold: 0,
          candidateLimit: 5,
        ),
      );

  PlayerPresidentInteractiveDecisionApplicationSession bootstrapSession({
    int seasonCount = 1,
  }) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: seasonCount,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      );

  PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpointStore(
    Directory directory,
  ) =>
      PlayerPresidentInteractiveDecisionFileSaveSlotStore(
        rootDirectory: directory,
      );

  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      bootstrapStore(Directory directory) =>
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
            rootDirectory: directory,
          );

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter writer({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpoints,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstraps,
  }) =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter(
        checkpointStore: checkpoints,
        bootstrapStore: bootstraps,
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

  test('M85 routes checkpoint and bootstrap saves by session origin', () {
    final checkpoints = checkpointStore(root);
    final bootstraps = bootstrapStore(root);
    final mixedWriter = writer(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    final checkpointSource = mixedWriter.save(
      slotId: 'career',
      session: checkpointSession(),
    );
    final bootstrapSource = mixedWriter.save(
      slotId: 'new-game',
      session: bootstrapSession(),
    );

    expect(
      checkpointSource,
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
    );
    expect(
      bootstrapSource,
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap,
    );
    expect(checkpoints.contains('career'), isTrue);
    expect(bootstraps.contains('career'), isFalse);
    expect(checkpoints.contains('new-game'), isFalse);
    expect(bootstraps.contains('new-game'), isTrue);

    expect(
      checkpoints.load('career')!.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(
      bootstraps
          .load(
            slotId: 'new-game',
            clubs: world.clubs,
            leagues: world.leagues,
          )!
          .origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
    );
  });

  test('M85 writes the exact bytes of the delegated child stores', () {
    final routedRoot = Directory('${root.path}${Platform.pathSeparator}routed');
    final directRoot = Directory('${root.path}${Platform.pathSeparator}direct');
    final routedCheckpoints = checkpointStore(routedRoot);
    final routedBootstraps = bootstrapStore(routedRoot);
    final directCheckpoints = checkpointStore(directRoot);
    final directBootstraps = bootstrapStore(directRoot);
    final mixedWriter = writer(
      checkpoints: routedCheckpoints,
      bootstraps: routedBootstraps,
    );
    final checkpoint = checkpointSession();
    final bootstrap = bootstrapSession();

    mixedWriter.save(slotId: 'career', session: checkpoint);
    directCheckpoints.save('career', checkpoint);
    mixedWriter.save(slotId: 'new-game', session: bootstrap);
    directBootstraps.save('new-game', bootstrap);

    expect(
      File('${routedRoot.path}${Platform.pathSeparator}career.fbs.json')
          .readAsStringSync(),
      File('${directRoot.path}${Platform.pathSeparator}career.fbs.json')
          .readAsStringSync(),
    );
    expect(
      File(
        '${routedRoot.path}${Platform.pathSeparator}'
        'new-game.fbs.bootstrap.json',
      ).readAsStringSync(),
      File(
        '${directRoot.path}${Platform.pathSeparator}'
        'new-game.fbs.bootstrap.json',
      ).readAsStringSync(),
    );
  });

  test('M85 preserves same-id entries in separate physical namespaces', () {
    final checkpoints = checkpointStore(root);
    final bootstraps = bootstrapStore(root);
    final mixedWriter = writer(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    mixedWriter.save(slotId: 'shared', session: bootstrapSession());
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json',
    );
    final bootstrapBefore = bootstrapFile.readAsStringSync();
    mixedWriter.save(slotId: 'shared', session: checkpointSession());

    final identities = catalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    ).list().map((summary) => summary.identity).toList();

    expect(
      identities,
      <String>['checkpoint:shared', 'newGameBootstrap:shared'],
    );
    expect(bootstrapFile.readAsStringSync(), bootstrapBefore);
    expect(
      File('${root.path}${Platform.pathSeparator}shared.fbs.json').existsSync(),
      isTrue,
    );
  });

  test('M85 overwrites only the routed namespace for a same-id collision', () {
    final checkpoints = checkpointStore(root);
    final bootstraps = bootstrapStore(root);
    final mixedWriter = writer(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );
    final checkpointFile =
        File('${root.path}${Platform.pathSeparator}shared.fbs.json');
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json',
    );

    mixedWriter.save(slotId: 'shared', session: checkpointSession());
    mixedWriter.save(slotId: 'shared', session: bootstrapSession());
    final checkpointBefore = checkpointFile.readAsStringSync();
    final bootstrapBefore = bootstrapFile.readAsStringSync();

    mixedWriter.save(
      slotId: 'shared',
      session: checkpointSession(seasonCount: 2),
    );
    final checkpointAfter = checkpointFile.readAsStringSync();
    expect(checkpointAfter, isNot(checkpointBefore));
    expect(bootstrapFile.readAsStringSync(), bootstrapBefore);

    mixedWriter.save(
      slotId: 'shared',
      session: bootstrapSession(seasonCount: 2),
    );
    expect(bootstrapFile.readAsStringSync(), isNot(bootstrapBefore));
    expect(checkpointFile.readAsStringSync(), checkpointAfter);
  });

  test('M85 delegates invalid slot validation without disk mutation', () {
    final checkpoints = checkpointStore(root);
    final bootstraps = bootstrapStore(root);
    final mixedWriter = writer(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    expect(
      () => mixedWriter.save(
        slotId: '../escape',
        session: checkpointSession(),
      ),
      throwsArgumentError,
    );
    expect(
      () => mixedWriter.save(
        slotId: '../escape',
        session: bootstrapSession(),
      ),
      throwsArgumentError,
    );

    expect(
      root.listSync(followLinks: false).whereType<File>(),
      isEmpty,
    );
  });
}
