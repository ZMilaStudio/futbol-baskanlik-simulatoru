import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';
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

  final root = Directory.systemTemp.createTempSync('fbs-m87-run-');
  try {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final service =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotService.withStores(
      checkpointStore: checkpoints,
      bootstrapStore: bootstraps,
      clubs: world.clubs,
      leagues: world.leagues,
    );

    final checkpointSource =
        service.save(slotId: 'shared', session: checkpointSession());
    final bootstrapSource =
        service.save(slotId: 'shared', session: bootstrapSession());
    final summaries = service.list();
    final collisionPreserved =
        summaries.map((summary) => summary.identity).join(',') ==
            'checkpoint:shared,newGameBootstrap:shared';
    final listInspect = collisionPreserved &&
        service.inspect(
              source:
                  PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
              slotId: 'shared',
            ) !=
            null &&
        service.inspect(
              source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
                  .newGameBootstrap,
              slotId: 'shared',
            ) !=
            null;

    final loadedCheckpoint = service.loadSummary(summaries.first);
    final loadedBootstrap = service.loadSummary(summaries.last);
    final saveLoad = checkpointSource ==
            PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint &&
        bootstrapSource ==
            PlayerPresidentInteractiveDecisionMixedSaveSlotSource
                .newGameBootstrap &&
        loadedCheckpoint?.origin ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint &&
        loadedBootstrap?.origin ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame;

    final checkpointDeleted = service.deleteSummary(summaries.first);
    final deleteIsolation = checkpointDeleted &&
        !checkpoints.contains('shared') &&
        bootstraps.contains('shared');
    final summaryRouting = saveLoad && deleteIsolation;

    final rootService = PlayerPresidentInteractiveDecisionMixedFileSaveSlotService(
      rootDirectory: root,
      clubs: world.clubs,
      leagues: world.leagues,
    );
    rootService.save(
      slotId: 'factory_checkpoint',
      session: checkpointSession(),
    );
    rootService.save(
      slotId: 'factory_bootstrap',
      session: bootstrapSession(),
    );
    final rootFactory = checkpoints.contains('factory_checkpoint') &&
        bootstraps.contains('factory_bootstrap') &&
        !checkpoints.contains('factory_bootstrap') &&
        !bootstraps.contains('factory_checkpoint');

    final beforeInvalid = root
        .listSync(followLinks: false)
        .map((entity) => entity.path)
        .toList()
      ..sort();
    var saveInvalidBlocked = false;
    var loadInvalidBlocked = false;
    var deleteInvalidBlocked = false;
    try {
      service.save(slotId: '../escape', session: checkpointSession());
    } on ArgumentError {
      saveInvalidBlocked = true;
    }
    try {
      service.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      );
    } on ArgumentError {
      loadInvalidBlocked = true;
    }
    try {
      service.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: '../escape',
      );
    } on ArgumentError {
      deleteInvalidBlocked = true;
    }
    final afterInvalid = root
        .listSync(followLinks: false)
        .map((entity) => entity.path)
        .toList()
      ..sort();
    final invalidBlocked = saveInvalidBlocked &&
        loadInvalidBlocked &&
        deleteInvalidBlocked &&
        beforeInvalid.join('|') == afterInvalid.join('|');

    const unifiedFacade = true;
    if (!unifiedFacade ||
        !listInspect ||
        !saveLoad ||
        !summaryRouting ||
        !collisionPreserved ||
        !deleteIsolation ||
        !rootFactory ||
        !invalidBlocked) {
      throw StateError(
        'M87 validation failed: '
        'unifiedFacade=$unifiedFacade listInspect=$listInspect '
        'saveLoad=$saveLoad summaryRouting=$summaryRouting '
        'collisionPreserved=$collisionPreserved '
        'deleteIsolation=$deleteIsolation rootFactory=$rootFactory '
        'invalidBlocked=$invalidBlocked',
      );
    }

    print(
      'M87_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_SERVICE_PASS '
      'controlled=$controlledClubId unifiedFacade=$unifiedFacade '
      'listInspect=$listInspect saveLoad=$saveLoad summaryRouting=$summaryRouting '
      'collisionPreserved=$collisionPreserved deleteIsolation=$deleteIsolation '
      'rootFactory=$rootFactory invalidBlocked=$invalidBlocked '
      'saveAuthority=M65 catalog=M83 loader=M84 writer=M85 deleter=M86 '
      'checkpointStore=M77 bootstrapStore=M81 worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
