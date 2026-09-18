import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fbs-m89-next-season-');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  AppComposition composition() => AppComposition.withSaveDirectory(
        Directory(
          '${tempDirectory.path}${Platform.pathSeparator}save_slots',
        ),
      );

  void driveToCompleted(GameFlowController controller) {
    for (var guard = 0; guard < 100; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) {
        return;
      }
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.errorMessage, isNull);
    }
    fail('Interactive season did not reach Completed within the guard.');
  }

  test(
      'Completed handoff uses official checkpoint resume and detaches old binding',
      () {
    final c = composition();
    final slotIds = <String>[
      'career_stage6_bootstrap',
      'career_stage6_checkpoint',
    ];
    var slotIndex = 0;
    final controller = GameFlowController(
      world: c.world,
      config: c.simulationConfig,
      saveSlots: c.saveSlots,
      slotIdFactory: () => slotIds[slotIndex++],
    );
    addTearDown(controller.dispose);

    controller.startNewGame(c.world.clubs.first);
    expect(controller.saveCurrent(), isTrue);
    final bootstrapSummary = controller.saveSummary!;
    expect(bootstrapSummary.isNewGameBootstrap, isTrue);
    expect(controller.binding, isNotNull);

    driveToCompleted(controller);
    final completed =
        controller.currentStep as PlayerPresidentInteractiveSessionCompleted;
    final checkpoint = completed.result.checkpoint;
    final oldBindingIdentity = controller.binding!.identity;

    expect(checkpoint.completedSeasons, greaterThan(0));
    expect(checkpoint.nextSeasonIndex, checkpoint.completedSeasons);
    expect(controller.continueToNextSeason(), isTrue);

    expect(
      controller.session!.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(controller.session!.checkpointOrNull, same(checkpoint));
    expect(controller.selectedClub!.id, checkpoint.controlledClubId);
    expect(controller.binding, isNull);
    expect(controller.saveSummary, isNull);
    expect(
      controller.currentStep,
      anyOf(
        isA<PlayerPresidentInteractiveDecisionPending>(),
        isA<PlayerPresidentInteractiveSessionCompleted>(),
      ),
    );

    final preservedBootstrap = c.saveSlots.inspect(
      source: bootstrapSummary.source,
      slotId: bootstrapSummary.slotId,
    );
    expect(preservedBootstrap, isNotNull);
    expect(preservedBootstrap!.identity, oldBindingIdentity);
  });

  test(
      'checkpoint next season survives recreation and coexists with bootstrap',
      () {
    final compositionA = composition();
    final slotIds = <String>[
      'career_stage6_bootstrap',
      'career_stage6_checkpoint',
    ];
    var slotIndex = 0;
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => slotIds[slotIndex++],
    );
    addTearDown(controllerA.dispose);

    final club = compositionA.world.clubs.first;
    controllerA.startNewGame(club);
    expect(controllerA.saveCurrent(), isTrue);

    final bootstrapSummaryA = controllerA.saveSummary!;
    final bootstrapStepA =
        controllerA.currentStep as PlayerPresidentInteractiveDecisionPending;
    final bootstrapKey = bootstrapStepA.request.key;
    final bootstrapAnswered = controllerA.session!.answeredDecisionCount;

    driveToCompleted(controllerA);
    final completed =
        controllerA.currentStep as PlayerPresidentInteractiveSessionCompleted;
    final checkpoint = completed.result.checkpoint;

    expect(controllerA.continueToNextSeason(), isTrue);
    expect(
      controllerA.session!.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(controllerA.session!.checkpointOrNull, same(checkpoint));
    expect(controllerA.binding, isNull);

    final nextPending =
        controllerA.currentStep as PlayerPresidentInteractiveDecisionPending;
    final nextPendingKey = nextPending.request.key;
    final nextAnswered = controllerA.session!.answeredDecisionCount;
    expect(nextAnswered, 0);

    expect(controllerA.saveCurrent(), isTrue);
    final checkpointSummaryA = controllerA.saveSummary!;
    expect(checkpointSummaryA.isCheckpoint, isTrue);
    expect(controllerA.binding!.source,
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint);

    final listA = compositionA.saveSlots.list();
    expect(listA, hasLength(2));
    expect(listA.where((summary) => summary.isNewGameBootstrap), hasLength(1));
    expect(listA.where((summary) => summary.isCheckpoint), hasLength(1));
    expect(bootstrapSummaryA.identity, isNot(checkpointSummaryA.identity));

    final compositionB = composition();
    final listB = compositionB.saveSlots.list();
    expect(listB, hasLength(2));

    final bootstrapSummaryB =
        listB.singleWhere((summary) => summary.isNewGameBootstrap);
    final checkpointSummaryB =
        listB.singleWhere((summary) => summary.isCheckpoint);
    final bootstrapSignatureBefore = bootstrapSummaryB.signature;

    final checkpointBindingB =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: checkpointSummaryB,
    );
    expect(checkpointBindingB, isNotNull);

    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);
    expect(controllerB.loadBoundSave(checkpointBindingB!), isTrue);

    expect(controllerB.selectedClub!.id, club.id);
    expect(
      controllerB.session!.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(controllerB.session!.answeredDecisionCount, nextAnswered);
    final restoredNext =
        controllerB.currentStep as PlayerPresidentInteractiveDecisionPending;
    expect(restoredNext.request.key, nextPendingKey);
    expect(restoredNext.request.kind, nextPending.request.kind);
    expect(
      restoredNext.request.contextSignature,
      nextPending.request.contextSignature,
    );

    controllerB.submitChoice(
      canonicalChoiceForRequest(restoredNext.request),
    );
    expect(controllerB.errorMessage, isNull);
    final answeredAfterSubmit = controllerB.session!.answeredDecisionCount;
    final stepAfterSubmit = controllerB.currentStep;
    final checkpointBindingIdentity = controllerB.binding!.identity;
    expect(answeredAfterSubmit, nextAnswered + 1);

    expect(controllerB.saveCurrent(), isTrue);
    expect(controllerB.binding!.identity, checkpointBindingIdentity);

    final compositionC = composition();
    final listC = compositionC.saveSlots.list();
    expect(listC, hasLength(2));
    final checkpointSummaryC =
        listC.singleWhere((summary) => summary.isCheckpoint);
    final bootstrapSummaryC =
        listC.singleWhere((summary) => summary.isNewGameBootstrap);
    expect(bootstrapSummaryC.signature, bootstrapSignatureBefore);

    final checkpointBindingC =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionC.saveSlots,
      summary: checkpointSummaryC,
    )!;
    final controllerC = GameFlowController(
      world: compositionC.world,
      config: compositionC.simulationConfig,
      saveSlots: compositionC.saveSlots,
    );
    addTearDown(controllerC.dispose);
    expect(controllerC.loadBoundSave(checkpointBindingC), isTrue);
    expect(controllerC.session!.answeredDecisionCount, answeredAfterSubmit);

    if (stepAfterSubmit is PlayerPresidentInteractiveDecisionPending) {
      final restoredAfterSaveBack =
          controllerC.currentStep as PlayerPresidentInteractiveDecisionPending;
      expect(restoredAfterSaveBack.request.key, stepAfterSubmit.request.key);
      expect(
        restoredAfterSaveBack.request.contextSignature,
        stepAfterSubmit.request.contextSignature,
      );
    } else {
      expect(
        controllerC.currentStep,
        isA<PlayerPresidentInteractiveSessionCompleted>(),
      );
    }

    final bootstrapBindingC =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionC.saveSlots,
      summary: bootstrapSummaryC,
    )!;
    final bootstrapController = GameFlowController(
      world: compositionC.world,
      config: compositionC.simulationConfig,
      saveSlots: compositionC.saveSlots,
    );
    addTearDown(bootstrapController.dispose);
    expect(bootstrapController.loadBoundSave(bootstrapBindingC), isTrue);
    expect(
      bootstrapController.session!.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
    );
    expect(
      bootstrapController.session!.answeredDecisionCount,
      bootstrapAnswered,
    );
    final restoredBootstrap = bootstrapController.currentStep
        as PlayerPresidentInteractiveDecisionPending;
    expect(restoredBootstrap.request.key, bootstrapKey);
  });
}
