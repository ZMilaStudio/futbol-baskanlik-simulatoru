import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_resolution_panel.dart';
import 'package:futbol_baskanlik_app/reports/president_season_report_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void _submitCurrent(GameFlowController controller) {
  final pending =
      controller.currentStep as PlayerPresidentInteractiveDecisionPending;
  controller.submitPendingChoice(
      pending, canonicalChoiceForRequest(pending.request));
}

PlayerPresidentInteractiveSessionCompleted _finishController(
    GameFlowController controller) {
  for (var guard = 0; guard < 100; guard++) {
    if (controller.awaitingResolution) {
      expect(controller.continueAfterResolution(), isTrue);
    } else if (controller.currentStep
        is PlayerPresidentInteractiveDecisionPending) {
      _submitCurrent(controller);
    } else {
      return controller.currentStep
          as PlayerPresidentInteractiveSessionCompleted;
    }
  }
  throw StateError('Real controller career did not finish its season.');
}

Future<void> _mountHome(WidgetTester tester) async {
  final directory =
      Directory.systemTemp.createTempSync('fbs-bound-home-events-');
  addTearDown(() => directory.deleteSync(recursive: true));
  final composition = AppComposition.withSaveDirectory(directory);
  await tester.pumpWidget(MaterialApp(
      home: PresidentHomeScreen(
    composition: composition,
    club: composition.world.clubs.first,
  )));
}

Future<void> _finishRenderedSeason(WidgetTester tester) async {
  for (var guard = 0; guard < 100; guard++) {
    if (find.byType(DecisionPanel).evaluate().isNotEmpty) {
      final panel = tester.widget<DecisionPanel>(find.byType(DecisionPanel));
      panel.onSubmit!(canonicalChoiceForRequest(panel.pending.request));
    } else if (find.byType(DecisionResolutionPanel).evaluate().isNotEmpty) {
      tester
          .widget<DecisionResolutionPanel>(find.byType(DecisionResolutionPanel))
          .onContinue!();
    } else if (find.byType(PresidentSeasonReportPanel).evaluate().isNotEmpty) {
      return;
    } else {
      throw StateError('Real HomeScreen has no career boundary.');
    }
    await tester.pump();
  }
  throw StateError('Real HomeScreen did not finish its season.');
}

void main() {
  group('bound lifecycle commands', () {
    late Directory directory;
    late AppComposition composition;
    late GameFlowController controller;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('fbs-bound-lifecycle-');
      composition = AppComposition.withSaveDirectory(directory);
      controller = GameFlowController(
        world: composition.world,
        config: composition.simulationConfig,
        saveSlots: composition.saveSlots,
      );
      controller.startNewGame(composition.world.clubs.first);
    });

    tearDown(() {
      controller.dispose();
      directory.deleteSync(recursive: true);
    });

    test('current resolution is acknowledged once; its duplicate is inert', () {
      _submitCurrent(controller);
      final resolution = controller.currentResolution!;
      final queued = controller.queuedNextStep;
      final answered = controller.session!.answeredDecisionCount;

      expect(controller.continueAfterResolution(expectedResolution: resolution),
          isTrue);
      expect(controller.currentStep, same(queued));
      expect(controller.currentResolution, isNull);
      expect(controller.continueAfterResolution(expectedResolution: resolution),
          isFalse);
      expect(controller.currentStep, same(queued));
      expect(controller.session!.answeredDecisionCount, answered);
      expect(controller.errorMessage, isNull);
    });

    test('foreign equal-key resolution cannot dismiss the displayed result',
        () {
      final foreign = GameFlowController(
        world: composition.world,
        config: composition.simulationConfig,
        saveSlots: composition.saveSlots,
      );
      addTearDown(foreign.dispose);
      foreign.startNewGame(composition.world.clubs.first);
      _submitCurrent(controller);
      _submitCurrent(foreign);
      final resolution = controller.currentResolution!;
      final other = foreign.currentResolution!;
      final queued = controller.queuedNextStep;
      expect(other.requestKey, resolution.requestKey);
      expect(other, isNot(same(resolution)));

      expect(controller.continueAfterResolution(expectedResolution: other),
          isFalse);
      expect(controller.currentResolution, same(resolution));
      expect(controller.queuedNextStep, same(queued));
      expect(controller.currentStep, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.continueAfterResolution(expectedResolution: resolution),
          isTrue);
    });

    test('old resolution cannot acknowledge a later real accepted choice', () {
      _submitCurrent(controller);
      final first = controller.currentResolution!;
      expect(controller.continueAfterResolution(), isTrue);
      _submitCurrent(controller);
      final second = controller.currentResolution!;
      final queued = controller.queuedNextStep;
      final answered = controller.session!.answeredDecisionCount;

      expect(controller.continueAfterResolution(expectedResolution: first),
          isFalse);
      expect(controller.currentResolution, same(second));
      expect(controller.queuedNextStep, same(queued));
      expect(controller.session!.answeredDecisionCount, answered);
      expect(controller.errorMessage, isNull);
      expect(controller.continueAfterResolution(expectedResolution: second),
          isTrue);
      expect(controller.currentStep, same(queued));
    });

    test('visible resolution remains bound after save rebinds its queued step',
        () {
      _submitCurrent(controller);
      final resolution = controller.currentResolution!;
      final originalQueued = controller.queuedNextStep;

      expect(controller.saveCurrent(), isTrue);

      final reboundQueued = controller.queuedNextStep;
      expect(controller.currentResolution, same(resolution));
      expect(reboundQueued, isNot(same(originalQueued)));
      expect(controller.currentStep, isNull);
      expect(controller.session!.answeredDecisionCount, 1);
      expect(controller.continueAfterResolution(expectedResolution: resolution),
          isTrue);
      expect(controller.currentStep, same(reboundQueued));
      expect(controller.currentResolution, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('first-save Completed rebind invalidates the old season event only',
        () {
      final original = _finishController(controller);

      expect(controller.saveCurrent(), isTrue);

      final rebound =
          controller.currentStep as PlayerPresidentInteractiveSessionCompleted;
      final binding = controller.binding;
      final session = controller.session;
      final summary = controller.saveSummary;
      expect(rebound, isNot(same(original)));
      expect(rebound.result.checkpoint.signature,
          original.result.checkpoint.signature);
      expect(controller.continueToNextSeason(expectedCompleted: original),
          isFalse);
      expect(controller.currentStep, same(rebound));
      expect(controller.binding, same(binding));
      expect(controller.session, same(session));
      expect(controller.saveSummary, same(summary));
      expect(controller.errorMessage, isNull);
      expect(
          controller.continueToNextSeason(expectedCompleted: rebound), isTrue);
      expect(controller.binding, isNull);
      expect(controller.saveSummary, isNull);
      expect(composition.saveSlots.list(), hasLength(1));
    });

    test(
        'foreign, duplicate and older Completed events preserve the real season',
        () {
      final completed = _finishController(controller);
      final foreign = GameFlowController(
        world: composition.world,
        config: composition.simulationConfig,
        saveSlots: composition.saveSlots,
      );
      addTearDown(foreign.dispose);
      foreign.startNewGame(composition.world.clubs.first);
      final foreignCompleted = _finishController(foreign);
      final originalSession = controller.session;
      expect(foreignCompleted.result.checkpoint.signature,
          completed.result.checkpoint.signature);

      expect(
          controller.continueToNextSeason(expectedCompleted: foreignCompleted),
          isFalse);
      expect(controller.currentStep, same(completed));
      expect(controller.session, same(originalSession));
      expect(controller.errorMessage, isNull);
      expect(controller.continueToNextSeason(expectedCompleted: completed),
          isTrue);
      final firstPending = controller.currentStep;
      expect(controller.continueToNextSeason(expectedCompleted: completed),
          isFalse);
      expect(controller.currentStep, same(firstPending));
      expect(controller.errorMessage, isNull);

      final later = _finishController(controller);
      final laterSession = controller.session;
      expect(later, isNot(same(completed)));
      expect(controller.continueToNextSeason(expectedCompleted: completed),
          isFalse);
      expect(controller.currentStep, same(later));
      expect(controller.session, same(laterSession));
      expect(controller.errorMessage, isNull);
      expect(controller.continueToNextSeason(expectedCompleted: later), isTrue);
    });
  });

  testWidgets(
      'old rendered resolution callback cannot dismiss the later result',
      (tester) async {
    await _mountHome(tester);
    final firstPending =
        tester.widget<DecisionPanel>(find.byType(DecisionPanel));
    firstPending
        .onSubmit!(canonicalChoiceForRequest(firstPending.pending.request));
    await tester.pump();
    final first = tester
        .widget<DecisionResolutionPanel>(find.byType(DecisionResolutionPanel));
    first.onContinue!();
    await tester.pump();
    final secondPending =
        tester.widget<DecisionPanel>(find.byType(DecisionPanel));
    secondPending
        .onSubmit!(canonicalChoiceForRequest(secondPending.pending.request));
    await tester.pump();
    final second = tester
        .widget<DecisionResolutionPanel>(find.byType(DecisionResolutionPanel));

    first.onContinue!();
    await tester.pump();

    expect(find.byType(DecisionResolutionPanel), findsOneWidget);
    expect(
        tester
            .widget<DecisionResolutionPanel>(
                find.byType(DecisionResolutionPanel))
            .resolution,
        same(second.resolution));
    second.onContinue!();
    await tester.pump();
    expect(find.byType(DecisionResolutionPanel), findsNothing);
    expect(find.byType(DecisionPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('old rendered season callback cannot advance a later Completed',
      (tester) async {
    await _mountHome(tester);
    await _finishRenderedSeason(tester);
    final first = tester.widget<PresidentSeasonReportPanel>(
        find.byType(PresidentSeasonReportPanel));
    first.onContinueToNextSeason!();
    await tester.pump();
    await _finishRenderedSeason(tester);
    final second = tester.widget<PresidentSeasonReportPanel>(
        find.byType(PresidentSeasonReportPanel));
    expect(second.report.seasonIndex, first.report.seasonIndex + 1);

    first.onContinueToNextSeason!();
    await tester.pump();

    expect(find.byType(PresidentSeasonReportPanel), findsOneWidget);
    expect(
        tester
            .widget<PresidentSeasonReportPanel>(
                find.byType(PresidentSeasonReportPanel))
            .report
            .seasonIndex,
        second.report.seasonIndex);
    second.onContinueToNextSeason!();
    await tester.pump();
    expect(find.byType(PresidentSeasonReportPanel), findsNothing);
    expect(find.byType(DecisionPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
