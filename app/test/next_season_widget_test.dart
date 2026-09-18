import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/reports/president_season_report_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
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
      expect(controller.currentResolution, isNotNull);
      expect(controller.continueAfterResolution(), isTrue);
    }
    throw StateError('Interactive season did not complete.');
  }

  String clubNameForId(String id) => composition.world.clubs
      .singleWhere((club) => club.id == id)
      .name;


  testWidgets(
      'Completed view renders authoritative President Season Report and next action',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    final completed = completeSeason(controller);
    final report = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);

    var continuePressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSessionStateView(
              step: completed,
              clubNameForId: clubNameForId,
              onContinueToNextSeason: () {
                continuePressed = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PresidentSeasonReportPanel), findsOneWidget);
    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    expect(find.byKey(const Key('season-report-title')), findsOneWidget);
    expect(
      find.text(
        '${clubNameForId(report.controlledClubId)} • ${report.leagueName}',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('completed-season-count')), findsNothing);
    expect(find.byKey(const Key('next-season-index')), findsNothing);
    expect(find.byKey(const Key('continue-next-season-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-next-season-button')));
    await tester.pump();
    expect(continuePressed, isTrue);
  });


  testWidgets('bootstrap Completed reload renders report and keeps Save enabled',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m91_widget_bootstrap_completed',
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    completeSeason(controller);
    expect(controller.saveCurrent(), isTrue);
    expect(controller.saveSummary!.isNewGameBootstrap, isTrue);

    final recreated = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
    final summary = recreated.saveSlots.list().single;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: recreated.saveSlots,
      summary: summary,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          composition: recreated,
          binding: binding,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    final saveButton = tester.widget<IconButton>(
      find.byKey(const Key('save-game-button')),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('checkpoint Completed reload renders the same report boundary',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m91_widget_checkpoint_completed',
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    completeSeason(controller);
    expect(controller.continueToNextSeason(), isTrue);
    final secondCompleted = completeSeason(controller);
    final expected =
        PlayerPresidentCompletedSeasonReport.fromCompleted(secondCompleted);
    expect(controller.saveCurrent(), isTrue);
    expect(controller.saveSummary!.isCheckpoint, isTrue);

    final recreated = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
    final summary = recreated.saveSlots.list().single;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: recreated.saveSlots,
      summary: summary,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          composition: recreated,
          binding: binding,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    expect(
      find.text('Sezon ${expected.seasonIndex + 1} tamamlandı'),
      findsOneWidget,
    );
    expect(
      find.text('${expected.finalPosition}. sıra'),
      findsOneWidget,
    );
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
