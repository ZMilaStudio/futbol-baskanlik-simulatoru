import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;
  late GameFlowController controller;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m94-squad-controller-');
    composition = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
    controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m94_squad',
    );
  });

  tearDown(() {
    controller.dispose();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveSessionCompleted driveToCompleted() {
    for (var guard = 0; guard < 100; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) return step;
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.currentResolution, isNotNull);
      expect(controller.continueAfterResolution(), isTrue);
    }
    throw StateError('M94 controller fixture did not complete.');
  }

  test('forwards session prepared squad without duplicate controller state', () {
    controller.startNewGame(composition.world.clubs.first);
    final snapshot = controller.preparedSquad;
    expect(snapshot, isNotNull);
    expect(snapshot, same(controller.session!.preparedSquad));

    final pending =
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;
    controller.submitChoice(canonicalChoiceForRequest(pending.request));
    expect(controller.preparedSquad, same(snapshot));
    expect(controller.currentResolution, isNotNull);
    expect(controller.continueAfterResolution(), isTrue);
    expect(controller.preparedSquad, same(snapshot));
  });

  test('first save rebound and M88 saveBack preserve squad semantic parity', () {
    controller.startNewGame(composition.world.clubs.first);
    final before = controller.preparedSquad!;
    final signature = before.signature;
    final openingSeasonIndex = before.seasonIndex;
    expect(controller.session!.isNewGame, isTrue);

    expect(controller.saveCurrent(), isTrue);
    expect(controller.session!.isNewGame, isTrue);
    expect(controller.saveSummary!.isNewGameBootstrap, isTrue);
    expect(controller.preparedSquad!.seasonIndex, openingSeasonIndex);
    expect(controller.preparedSquad!.signature, signature);
    expect(controller.preparedSquad, isNot(same(before)));

    final rebound = controller.preparedSquad;
    expect(controller.saveCurrent(), isTrue);
    expect(controller.session!.isNewGame, isTrue);
    expect(controller.saveSummary!.isNewGameBootstrap, isTrue);
    expect(controller.preparedSquad, same(rebound));
    expect(controller.preparedSquad!.signature, signature);
    expect(controller.preparedSquad!.seasonIndex, openingSeasonIndex);
  });

  test('bootstrap reopen preserves prepared squad semantic', () {
    controller.startNewGame(composition.world.clubs.first);
    final signature = controller.preparedSquad!.signature;
    expect(controller.saveCurrent(), isTrue);
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: controller.saveSummary!,
    )!;
    final loaded = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(loaded.dispose);
    expect(loaded.loadBoundSave(binding), isTrue);
    expect(loaded.preparedSquad!.signature, signature);
  });

  test('next season exposes new session authority and checkpoint load parity', () {
    controller.startNewGame(composition.world.clubs.first);
    final first = controller.preparedSquad!;
    driveToCompleted();

    expect(controller.continueToNextSeason(), isTrue);
    final next = controller.preparedSquad!;
    expect(next, isNot(same(first)));
    expect(next, same(controller.session!.preparedSquad));
    expect(next.seasonIndex, first.seasonIndex + 1);

    expect(controller.saveCurrent(), isTrue);
    expect(controller.saveSummary!.isCheckpoint, isTrue);
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: controller.saveSummary!,
    )!;
    final loaded = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(loaded.dispose);
    expect(loaded.loadBoundSave(binding), isTrue);
    expect(loaded.preparedSquad!.signature, next.signature);
  });
}
