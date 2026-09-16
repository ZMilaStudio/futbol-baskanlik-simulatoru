import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_loader.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_writer.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;

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

  final root = Directory.systemTemp.createTempSync('fbs-m85-run-');
  final directRoot = Directory.systemTemp.createTempSync('fbs-m85-direct-');
  try {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final writer = PlayerPresidentInteractiveDecisionMixedFileSaveSlotWriter(
      checkpointStore: checkpoints,
      bootstrapStore: bootstraps,
    );
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
    final loader = PlayerPresidentInteractiveDecisionMixedFileSaveSlotLoader(
      checkpointStore: checkpoints,
      bootstrapStore: bootstraps,
      clubs: world.clubs,
      leagues: world.leagues,
    );

    final checkpointSource = writer.save(
      slotId: 'shared',
      session: checkpointSession(),
    );
    final checkpointFile =
        File('${root.path}${Platform.pathSeparator}shared.fbs.json');
    final checkpointBefore = checkpointFile.readAsStringSync();

    final bootstrapSource = writer.save(
      slotId: 'shared',
      session: bootstrapSession(),
    );
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json',
    );
    final bootstrapBefore = bootstrapFile.readAsStringSync();

    final summaries = catalog.list();
    final collisionPreserved = summaries.map((summary) => summary.identity).join(',') ==
        'checkpoint:shared,newGameBootstrap:shared';
    final loadedOrigins = summaries
        .map(loader.loadSummary)
        .map((session) => session?.origin)
        .toList();
    final loadRoundTrip = loadedOrigins.length == 2 &&
        loadedOrigins[0] ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint &&
        loadedOrigins[1] ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame;

    writer.save(
      slotId: 'shared',
      session: checkpointSession(seasonCount: 2),
    );
    final checkpointAfter = checkpointFile.readAsStringSync();
    final bootstrapUntouched = bootstrapFile.readAsStringSync() == bootstrapBefore;
    final checkpointChanged = checkpointAfter != checkpointBefore;

    writer.save(
      slotId: 'shared',
      session: bootstrapSession(seasonCount: 2),
    );
    final bootstrapChanged = bootstrapFile.readAsStringSync() != bootstrapBefore;
    final checkpointUntouched = checkpointFile.readAsStringSync() == checkpointAfter;
    final namespaceIsolation = bootstrapUntouched &&
        checkpointChanged &&
        bootstrapChanged &&
        checkpointUntouched;

    final directCheckpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: directRoot,
    );
    final directBootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: directRoot,
    );
    directCheckpoints.save('career', checkpointSession());
    directBootstraps.save('new-game', bootstrapSession());
    writer.save(slotId: 'career', session: checkpointSession());
    writer.save(slotId: 'new-game', session: bootstrapSession());
    final bytesDelegated =
        File('${root.path}${Platform.pathSeparator}career.fbs.json')
                .readAsStringSync() ==
            File('${directRoot.path}${Platform.pathSeparator}career.fbs.json')
                .readAsStringSync() &&
        File(
              '${root.path}${Platform.pathSeparator}'
              'new-game.fbs.bootstrap.json',
            ).readAsStringSync() ==
            File(
              '${directRoot.path}${Platform.pathSeparator}'
              'new-game.fbs.bootstrap.json',
            ).readAsStringSync();

    var invalidBlocked = false;
    try {
      writer.save(slotId: '../escape', session: checkpointSession());
    } on ArgumentError {
      invalidBlocked = true;
    }

    final checkpointRouted = checkpointSource ==
            PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint &&
        checkpoints.contains('shared');
    final bootstrapRouted = bootstrapSource ==
            PlayerPresidentInteractiveDecisionMixedSaveSlotSource
                .newGameBootstrap &&
        bootstraps.contains('shared');

    if (!checkpointRouted ||
        !bootstrapRouted ||
        !collisionPreserved ||
        !loadRoundTrip ||
        !namespaceIsolation ||
        !bytesDelegated ||
        !invalidBlocked) {
      throw StateError(
        'M85 validation failed: '
        'checkpointRouted=$checkpointRouted '
        'bootstrapRouted=$bootstrapRouted '
        'collisionPreserved=$collisionPreserved '
        'loadRoundTrip=$loadRoundTrip '
        'namespaceIsolation=$namespaceIsolation '
        'bytesDelegated=$bytesDelegated '
        'invalidBlocked=$invalidBlocked',
      );
    }

    print(
      'M85_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_WRITER_PASS '
      'controlled=$controlledClubId '
      'checkpointRouted=$checkpointRouted '
      'bootstrapRouted=$bootstrapRouted '
      'collisionPreserved=$collisionPreserved '
      'loadRoundTrip=$loadRoundTrip '
      'namespaceIsolation=$namespaceIsolation '
      'bytesDelegated=$bytesDelegated '
      'invalidBlocked=$invalidBlocked '
      'saveAuthority=M65 catalog=M83 loader=M84 checkpointStore=M77 '
      'bootstrapStore=M81 worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
    if (directRoot.existsSync()) {
      directRoot.deleteSync(recursive: true);
    }
  }
}
