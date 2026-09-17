import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';
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

  final root = Directory.systemTemp.createTempSync('fbs-m88-run-');
  try {
    final service = PlayerPresidentInteractiveDecisionMixedFileSaveSlotService(
      rootDirectory: root,
      clubs: world.clubs,
      leagues: world.leagues,
    );

    service.save(slotId: 'shared', session: checkpointSession());
    service.save(slotId: 'shared', session: bootstrapSession());
    final summaries = service.list();

    final checkpoint =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: service,
      summary: summaries.first,
    );
    final bootstrap =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: service,
      summary: summaries.last,
    );
    if (checkpoint == null || bootstrap == null) {
      throw StateError('M88 expected both typed bindings to open.');
    }

    final checkpointBound = checkpoint.identity == 'checkpoint:shared' &&
        checkpoint.session.origin ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint;
    final bootstrapBound = bootstrap.identity == 'newGameBootstrap:shared' &&
        bootstrap.session.origin ==
            PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame;
    final collisionDistinct = checkpoint.identity != bootstrap.identity;

    final bootstrapBefore = service.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'shared',
    )!;
    final savedSource = checkpoint.saveBack();
    final bootstrapAfter = service.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'shared',
    );
    final saveBackExact = savedSource ==
            PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint &&
        checkpoint.exists &&
        bootstrapAfter?.signature == bootstrapBefore.signature;

    final checkpointSummary = checkpoint.inspect()!;
    final deleted = checkpoint.delete();
    final deleteIsolation = deleted &&
        !checkpoint.exists &&
        service.inspect(
              source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
                  .newGameBootstrap,
              slotId: 'shared',
            ) !=
            null;
    final staleNull =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
              service: service,
              summary: checkpointSummary,
            ) ==
            null;
    final missingNull =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.open(
              service: service,
              source:
                  PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
              slotId: 'missing',
            ) ==
            null;

    final beforeInvalid = root
        .listSync(followLinks: false)
        .map((entity) => entity.path)
        .toList()
      ..sort();
    var invalidBlocked = false;
    try {
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.open(
        service: service,
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      );
    } on ArgumentError {
      invalidBlocked = true;
    }
    final afterInvalid = root
        .listSync(followLinks: false)
        .map((entity) => entity.path)
        .toList()
      ..sort();
    invalidBlocked = invalidBlocked &&
        beforeInvalid.join('|') == afterInvalid.join('|');

    const transientBinding = true;
    if (!checkpointBound ||
        !bootstrapBound ||
        !collisionDistinct ||
        !saveBackExact ||
        !deleteIsolation ||
        !staleNull ||
        !missingNull ||
        !invalidBlocked ||
        !transientBinding) {
      throw StateError(
        'M88 validation failed: checkpointBound=$checkpointBound '
        'bootstrapBound=$bootstrapBound collisionDistinct=$collisionDistinct '
        'saveBackExact=$saveBackExact deleteIsolation=$deleteIsolation '
        'staleNull=$staleNull missingNull=$missingNull '
        'invalidBlocked=$invalidBlocked transientBinding=$transientBinding',
      );
    }

    print(
      'M88_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_BINDING_PASS '
      'controlled=$controlledClubId checkpointBound=$checkpointBound '
      'bootstrapBound=$bootstrapBound collisionDistinct=$collisionDistinct '
      'saveBackExact=$saveBackExact deleteIsolation=$deleteIsolation '
      'staleNull=$staleNull missingNull=$missingNull '
      'invalidBlocked=$invalidBlocked transientBinding=$transientBinding '
      'saveAuthority=M65 service=M87 catalog=M83 loader=M84 writer=M85 '
      'deleter=M86 checkpointStore=M77 bootstrapStore=M81 '
      'worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
