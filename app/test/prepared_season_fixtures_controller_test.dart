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
        Directory.systemTemp.createTempSync('fbs-m95-fixture-controller-');
    composition = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
    controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m95_fixture',
    );
  });

  tearDown(() {
    controller.dispose();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveSessionCompleted driveToCompleted(
    GameFlowController target,
  ) {
    for (var guard = 0; guard < 100; guard++) {
      final step = target.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) return step;
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      target.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(target.currentResolution, isNotNull);
      expect(target.continueAfterResolution(), isTrue);
    }
    throw StateError('M95 controller fixture did not complete.');
  }

  test('forwards session prepared fixtures without controller re-derivation', () {
    controller.startNewGame(composition.world.clubs.first);
    final snapshot = controller.preparedSeasonFixtures;
    expect(snapshot, isNotNull);
    expect(snapshot, same(controller.session!.preparedSeasonFixtures));

    final pending =
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;
    controller.submitChoice(canonicalChoiceForRequest(pending.request));
    expect(controller.currentResolution, isNotNull);
    expect(controller.preparedSeasonFixtures, same(snapshot));
    expect(controller.continueAfterResolution(), isTrue);
    expect(controller.preparedSeasonFixtures, same(snapshot));
  });

  test('first save rebounds with semantic parity then saveBack keeps object', () {
    controller.startNewGame(composition.world.clubs.first);
    final before = controller.preparedSeasonFixtures!;
    final signature = before.signature;
    final seasonIndex = before.seasonIndex;

    expect(controller.saveCurrent(), isTrue);
    expect(controller.saveSummary!.isNewGameBootstrap, isTrue);
    expect(controller.preparedSeasonFixtures, isNot(same(before)));
    expect(controller.preparedSeasonFixtures!.signature, signature);
    expect(controller.preparedSeasonFixtures!.seasonIndex, seasonIndex);

    final rebound = controller.preparedSeasonFixtures;
    expect(controller.saveCurrent(), isTrue);
    expect(controller.preparedSeasonFixtures, same(rebound));
    expect(controller.preparedSeasonFixtures!.signature, signature);
  });

  test('bootstrap reopen exposes the same prepared fixture signature', () {
    controller.startNewGame(composition.world.clubs.first);
    final signature = controller.preparedSeasonFixtures!.signature;
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
    expect(loaded.preparedSeasonFixtures!.signature, signature);
  });

  test('next season is fresh and checkpoint first save/reopen preserves parity',
      () {
    controller.startNewGame(composition.world.clubs.first);
    final first = controller.preparedSeasonFixtures!;
    driveToCompleted(controller);

    expect(controller.continueToNextSeason(), isTrue);
    final next = controller.preparedSeasonFixtures!;
    expect(next, isNot(same(first)));
    expect(next.seasonIndex, first.seasonIndex + 1);
    expect(next, same(controller.session!.preparedSeasonFixtures));

    expect(controller.saveCurrent(), isTrue);
    expect(controller.saveSummary!.isCheckpoint, isTrue);
    final signature = next.signature;

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
    expect(loaded.preparedSeasonFixtures!.signature, signature);
  });
}
