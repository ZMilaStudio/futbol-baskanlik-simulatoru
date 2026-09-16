import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_deleter.dart';
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
    root = Directory.systemTemp.createTempSync('fbs-m86-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: initial,
        resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
          seasonCount: 1,
          hasFutureSeasonAfterReport: true,
          crisisActivationThreshold: 0,
          candidateLimit: 5,
        ),
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
      PlayerPresidentInteractiveDecisionFileSaveSlotStore(
        rootDirectory: root,
      );

  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
      bootstrapStore() =>
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
            rootDirectory: root,
          );

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter deleter({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpoints,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstraps,
  }) =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter(
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

  test('M86 routes deletes by source and preserves same-id sibling namespace', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    final mixedDeleter = deleter(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    checkpoints.save('shared', checkpointSession());
    bootstraps.save('shared', bootstrapSession());

    expect(
      mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'shared',
      ),
      isTrue,
    );
    expect(checkpoints.contains('shared'), isFalse);
    expect(bootstraps.contains('shared'), isTrue);

    expect(
      mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      ),
      isTrue,
    );
    expect(bootstraps.contains('shared'), isFalse);
  });

  test('M86 deleteSummary consumes the exact M83 typed source identity', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    final mixedDeleter = deleter(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    checkpoints.save('shared', checkpointSession());
    bootstraps.save('shared', bootstrapSession());
    final summaries = catalog(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    ).list();

    expect(
      summaries.map((summary) => summary.identity),
      <String>['checkpoint:shared', 'newGameBootstrap:shared'],
    );
    expect(mixedDeleter.deleteSummary(summaries.first), isTrue);
    expect(checkpoints.contains('shared'), isFalse);
    expect(bootstraps.contains('shared'), isTrue);
    expect(mixedDeleter.deleteSummary(summaries.last), isTrue);
    expect(bootstraps.contains('shared'), isFalse);
  });

  test('M86 missing source returns false without touching sibling namespace', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    final mixedDeleter = deleter(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    bootstraps.save('shared', bootstrapSession());

    expect(
      mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'shared',
      ),
      isFalse,
    );
    expect(bootstraps.contains('shared'), isTrue);
  });

  test('M86 delegates target temporary and backup cleanup to child stores', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    final mixedDeleter = deleter(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    root.createSync(recursive: true);
    final checkpointFiles = <File>[
      File('${root.path}${Platform.pathSeparator}shared.fbs.json'),
      File('${root.path}${Platform.pathSeparator}shared.fbs.json.tmp'),
      File('${root.path}${Platform.pathSeparator}shared.fbs.json.bak'),
    ];
    final bootstrapFiles = <File>[
      File('${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json'),
      File('${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json.tmp'),
      File('${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json.bak'),
    ];
    for (final file in [...checkpointFiles, ...bootstrapFiles]) {
      file.writeAsStringSync('sentinel');
    }

    expect(
      mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'shared',
      ),
      isTrue,
    );
    expect(checkpointFiles.every((file) => !file.existsSync()), isTrue);
    expect(bootstrapFiles.every((file) => file.existsSync()), isTrue);

    expect(
      mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      ),
      isTrue,
    );
    expect(bootstrapFiles.every((file) => !file.existsSync()), isTrue);
  });

  test('M86 delegates invalid slot validation without disk mutation', () {
    final checkpoints = checkpointStore();
    final bootstraps = bootstrapStore();
    final mixedDeleter = deleter(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    checkpoints.save('keep', checkpointSession());
    bootstraps.save('keep', bootstrapSession());
    final before = root.listSync(followLinks: false).map((e) => e.path).toSet();

    expect(
      () => mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
    expect(
      () => mixedDeleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );

    final after = root.listSync(followLinks: false).map((e) => e.path).toSet();
    expect(after, before);
  });
}
