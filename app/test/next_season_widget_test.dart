import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m89-next-season-widget-');
    composition = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveSessionCompleted completeSeason(
    GameFlowController controller,
  ) {
    for (var guard = 0; guard < 100; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) {
        return step;
      }
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
    }
    throw StateError('Interactive season did not complete.');
  }

  testWidgets(
      'Completed view shows authoritative checkpoint progress and next action',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    final completed = completeSeason(controller);

    var continuePressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSessionStateView(
              step: completed,
              onContinueToNextSeason: () {
                continuePressed = true;
              },
            ),
          ),
        ),
      ),
    );

    final checkpoint = completed.result.checkpoint;
    expect(find.text('Sezon tamamlandı'), findsOneWidget);
    expect(
      find.text('Tamamlanan sezon sayısı: ${checkpoint.completedSeasons}'),
      findsOneWidget,
    );
    expect(
      find.text('Sıradaki sezon indeksi: ${checkpoint.nextSeasonIndex}'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('continue-next-season-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-next-season-button')));
    await tester.pump();
    expect(continuePressed, isTrue);
  });

  testWidgets('resumed next-season Pending uses the existing DecisionPanel',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    completeSeason(controller);

    expect(controller.continueToNextSeason(), isTrue);
    final next =
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSessionStateView(
              step: next,
              onSubmit: controller.submitChoice,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Karar bekleniyor'), findsOneWidget);
    expect(find.byType(DecisionPanel), findsOneWidget);
  });
}
