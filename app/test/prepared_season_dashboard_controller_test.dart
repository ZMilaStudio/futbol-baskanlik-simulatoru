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
        Directory.systemTemp.createTempSync('fbs-m92-dashboard-controller-');
    composition = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
    controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m92_dashboard',
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
      if (step is PlayerPresidentInteractiveSessionCompleted) {
        return step;
      }
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.currentResolution, isNotNull);
      expect(controller.continueAfterResolution(), isTrue);
    }
    throw StateError('M92 controller session did not complete.');
  }

  test('forwards the session prepared snapshot without duplicate state', () {
    controller.startNewGame(composition.world.clubs.first);

    final snapshot = controller.preparedSeasonDashboard;
    expect(snapshot, isNotNull);
    expect(snapshot, same(controller.session!.preparedSeasonDashboard));

    final pending =
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;
    controller.submitChoice(canonicalChoiceForRequest(pending.request));

    expect(controller.preparedSeasonDashboard, same(snapshot));
    expect(controller.currentResolution, isNotNull);
    expect(controller.continueAfterResolution(), isTrue);
    expect(controller.preparedSeasonDashboard, same(snapshot));
  });

  test('first save rebound and saveBack preserve prepared snapshot semantics',
      () {
    controller.startNewGame(composition.world.clubs.first);
    final before = controller.preparedSeasonDashboard!;
    final signature = before.signature;

    expect(controller.saveCurrent(), isTrue);
    expect(controller.preparedSeasonDashboard, isNotNull);
    expect(controller.preparedSeasonDashboard!.signature, signature);
    expect(controller.preparedSeasonDashboard, isNot(same(before)));

    final reboundSnapshot = controller.preparedSeasonDashboard;
    expect(controller.saveCurrent(), isTrue);
    expect(controller.preparedSeasonDashboard, same(reboundSnapshot));
    expect(controller.preparedSeasonDashboard!.signature, signature);

    final summary = controller.saveSummary!;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: summary,
    )!;
    final loaded = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(loaded.dispose);

    expect(loaded.loadBoundSave(binding), isTrue);
    expect(loaded.preparedSeasonDashboard, isNotNull);
    expect(loaded.preparedSeasonDashboard!.signature, signature);
  });

  test('next season exposes a new prepared snapshot and checkpoint load parity',
      () {
    controller.startNewGame(composition.world.clubs.first);
    final first = controller.preparedSeasonDashboard!;
    final completed = driveToCompleted();

    expect(controller.continueToNextSeason(), isTrue);
    final next = controller.preparedSeasonDashboard!;
    expect(next.seasonIndex, first.seasonIndex + 1);
    expect(next, isNot(same(first)));
    expect(
      next.signature,
      controller.session!.preparedSeasonDashboard.signature,
    );

    expect(controller.saveCurrent(), isTrue);
    expect(controller.saveSummary!.isCheckpoint, isTrue);
    final summary = controller.saveSummary!;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: summary,
    )!;

    final loaded = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(loaded.dispose);
    expect(loaded.loadBoundSave(binding), isTrue);
    expect(
      loaded.preparedSeasonDashboard!.signature,
      next.signature,
    );
    expect(
      loaded.preparedSeasonDashboard!.seasonIndex,
      completed.result.checkpoint.nextSeasonIndex,
    );
  });
}
