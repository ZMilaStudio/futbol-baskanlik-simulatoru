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
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final config = SimulationConfig(careerSeed: seed);
  final initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

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

  final root = Directory.systemTemp.createTempSync('fbs-m84-canonical-');
  try {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    checkpoints.save('shared', checkpointSession());
    bootstraps.save('shared', bootstrapSession());

    final checkpointFile =
        File('${root.path}${Platform.pathSeparator}shared.fbs.json');
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json',
    );
    final checkpointBefore = checkpointFile.readAsStringSync();
    final bootstrapBefore = bootstrapFile.readAsStringSync();

    final catalog = PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog(
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
    final summaries = catalog.list();
    final loader = PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader(
      checkpointStore: checkpoints,
      bootstrapStore: bootstraps,
      clubs: world.clubs,
      leagues: world.leagues,
    );

    final checkpointSummary = summaries.singleWhere((item) => item.isCheckpoint);
    final bootstrapSummary =
        summaries.singleWhere((item) => item.isNewGameBootstrap);
    final checkpoint = loader.loadSummary(checkpointSummary);
    final bootstrap = loader.loadSummary(bootstrapSummary);

    final checkpointLoaded = checkpoint != null &&
        checkpoint.origin ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint &&
        checkpoint.canPersist &&
        !checkpoint.isNewGame;
    final bootstrapLoaded = bootstrap != null &&
        bootstrap.origin ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame &&
        bootstrap.canPersistBootstrap &&
        !bootstrap.canPersist &&
        bootstrap.newGameBootstrapSnapshot.controlledClubId == controlledClubId;
    final collisionRouted = summaries.length == 2 &&
        summaries.map((item) => item.identity).join(',') ==
            'checkpoint:shared,newGameBootstrap:shared';
    final missingNull = loader.load(
              source:
                  PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
              slotId: 'missing',
            ) ==
            null &&
        loader.load(
              source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
                  .newGameBootstrap,
              slotId: 'missing',
            ) ==
            null;
    final bytesPreserved = checkpointFile.readAsStringSync() == checkpointBefore &&
        bootstrapFile.readAsStringSync() == bootstrapBefore;

    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    final divergentLoader =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader(
      checkpointStore: checkpoints,
      bootstrapStore: bootstraps,
      clubs: divergentClubs,
      leagues: world.leagues,
    );
    var worldGuard = false;
    try {
      divergentLoader.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      );
    } on SaveLoadException catch (error) {
      worldGuard = error.failure == SaveLoadFailure.invalidPayload;
    }

    final names = root
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();
    final namespacesSeparate = names.join(',') ==
        'shared.fbs.bootstrap.json,shared.fbs.json';

    if (!checkpointLoaded ||
        !bootstrapLoaded ||
        !collisionRouted ||
        !missingNull ||
        !bytesPreserved ||
        !worldGuard ||
        !namespacesSeparate) {
      throw StateError('M84 mixed file save-slot loader invariant failed.');
    }

    print(
      'M84_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_LOADER_PASS '
      'controlled=$controlledClubId checkpointLoaded=$checkpointLoaded '
      'bootstrapLoaded=$bootstrapLoaded collisionRouted=$collisionRouted '
      'missingNull=$missingNull bytesPreserved=$bytesPreserved '
      'worldGuard=$worldGuard namespacesSeparate=$namespacesSeparate '
      'saveAuthority=M65 catalog=M83 checkpointStore=M77 bootstrapStore=M81 '
      'worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
