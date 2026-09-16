import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_deleter.dart';
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

  final root = Directory.systemTemp.createTempSync('fbs-m86-run-');
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
    final deleter = PlayerPresidentInteractiveDecisionMixedFileSaveSlotDeleter(
      checkpointStore: checkpoints,
      bootstrapStore: bootstraps,
    );

    writer.save(slotId: 'shared', session: checkpointSession());
    writer.save(slotId: 'shared', session: bootstrapSession());
    final summaries = catalog.list();
    final collisionPreserved = summaries.map((summary) => summary.identity).join(',') ==
        'checkpoint:shared,newGameBootstrap:shared';

    final checkpointDeleted = deleter.deleteSummary(summaries.first) &&
        !checkpoints.contains('shared');
    final siblingPreserved = bootstraps.contains('shared');
    final summaryRouted = checkpointDeleted && siblingPreserved;

    final bootstrapDeleted = deleter.delete(
          source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
              .newGameBootstrap,
          slotId: 'shared',
        ) &&
        !bootstraps.contains('shared');
    final namespaceIsolation = summaryRouted && bootstrapDeleted;

    writer.save(slotId: 'shared', session: bootstrapSession());
    final missingFalse = !deleter.delete(
          source:
              PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
          slotId: 'shared',
        ) &&
        bootstraps.contains('shared');

    final checkpointCleanupFiles = <File>[
      File('${root.path}${Platform.pathSeparator}cleanup.fbs.json'),
      File('${root.path}${Platform.pathSeparator}cleanup.fbs.json.tmp'),
      File('${root.path}${Platform.pathSeparator}cleanup.fbs.json.bak'),
    ];
    final bootstrapCleanupFiles = <File>[
      File('${root.path}${Platform.pathSeparator}cleanup.fbs.bootstrap.json'),
      File('${root.path}${Platform.pathSeparator}cleanup.fbs.bootstrap.json.tmp'),
      File('${root.path}${Platform.pathSeparator}cleanup.fbs.bootstrap.json.bak'),
    ];
    for (final file in [...checkpointCleanupFiles, ...bootstrapCleanupFiles]) {
      file.writeAsStringSync('sentinel');
    }
    final checkpointCleanupDeleted = deleter.delete(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'cleanup',
    );
    final checkpointCleanupExact =
        checkpointCleanupFiles.every((file) => !file.existsSync()) &&
            bootstrapCleanupFiles.every((file) => file.existsSync());
    final bootstrapCleanupDeleted = deleter.delete(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'cleanup',
    );
    final cleanupDelegated = checkpointCleanupDeleted &&
        checkpointCleanupExact &&
        bootstrapCleanupDeleted &&
        bootstrapCleanupFiles.every((file) => !file.existsSync());

    final beforeInvalid = root
        .listSync(followLinks: false)
        .map((entity) => entity.path)
        .toList()
      ..sort();
    var checkpointInvalidBlocked = false;
    var bootstrapInvalidBlocked = false;
    try {
      deleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      );
    } on ArgumentError {
      checkpointInvalidBlocked = true;
    }
    try {
      deleter.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: '../escape',
      );
    } on ArgumentError {
      bootstrapInvalidBlocked = true;
    }
    final afterInvalid = root
        .listSync(followLinks: false)
        .map((entity) => entity.path)
        .toList()
      ..sort();
    final invalidBlocked = checkpointInvalidBlocked &&
        bootstrapInvalidBlocked &&
        beforeInvalid.join('|') == afterInvalid.join('|');

    if (!collisionPreserved ||
        !checkpointDeleted ||
        !bootstrapDeleted ||
        !summaryRouted ||
        !namespaceIsolation ||
        !missingFalse ||
        !cleanupDelegated ||
        !invalidBlocked) {
      throw StateError(
        'M86 validation failed: '
        'collisionPreserved=$collisionPreserved '
        'checkpointDeleted=$checkpointDeleted '
        'bootstrapDeleted=$bootstrapDeleted '
        'summaryRouted=$summaryRouted '
        'namespaceIsolation=$namespaceIsolation '
        'missingFalse=$missingFalse '
        'cleanupDelegated=$cleanupDelegated '
        'invalidBlocked=$invalidBlocked',
      );
    }

    print(
      'M86_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_DELETER_PASS '
      'controlled=$controlledClubId '
      'checkpointDeleted=$checkpointDeleted '
      'bootstrapDeleted=$bootstrapDeleted '
      'collisionPreserved=$collisionPreserved '
      'summaryRouted=$summaryRouted '
      'namespaceIsolation=$namespaceIsolation '
      'missingFalse=$missingFalse '
      'cleanupDelegated=$cleanupDelegated '
      'invalidBlocked=$invalidBlocked '
      'saveAuthority=M65 catalog=M83 loader=M84 writer=M85 checkpointStore=M77 '
      'bootstrapStore=M81 worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
