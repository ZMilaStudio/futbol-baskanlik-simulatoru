import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_resolution_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  group('bound controller submission', () {
    late Directory directory;
    late AppComposition composition;
    late GameFlowController controller;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('fbs-pending-command-');
      composition = AppComposition.withSaveDirectory(directory);
      controller = GameFlowController(
        world: composition.world,
        config: composition.simulationConfig,
        saveSlots: composition.saveSlots,
        slotIdFactory: () => 'bound_decision',
      );
      controller.startNewGame(composition.world.clubs.first);
    });

    tearDown(() {
      controller.dispose();
      directory.deleteSync(recursive: true);
    });

    PlayerPresidentInteractiveDecisionPending pending() =>
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;

    test('exact current Pending submits once through the existing resolution',
        () {
      final current = pending();
      controller.submitPendingChoice(
          current, canonicalChoiceForRequest(current.request));
      expect(controller.session!.answeredDecisionCount, 1);
      expect(controller.currentResolution, isNotNull);
      expect(controller.currentStep, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('foreign Pending cannot answer an equal-kind current decision', () {
      final foreign = GameFlowController(
        world: composition.world,
        config: composition.simulationConfig,
        saveSlots: composition.saveSlots,
      );
      addTearDown(foreign.dispose);
      foreign.startNewGame(composition.world.clubs.first);
      final other =
          foreign.currentStep as PlayerPresidentInteractiveDecisionPending;
      final current = pending();
      expect(other.request.kind, current.request.kind);

      controller.submitPendingChoice(
          other, canonicalChoiceForRequest(other.request));

      expect(controller.currentStep, same(current));
      expect(controller.session!.answeredDecisionCount, 0);
      expect(controller.currentResolution, isNull);
      expect(controller.errorMessage, isNull);
      expect(foreign.session!.answeredDecisionCount, 0);
    });

    test('previous-session event cannot answer the replacement session', () {
      final oldPending = pending();
      final original = controller.session!;
      controller.startNewGame(composition.world.clubs.first);
      final current = pending();

      controller.submitPendingChoice(
          oldPending, canonicalChoiceForRequest(oldPending.request));

      expect(controller.currentStep, same(current));
      expect(controller.session!.answeredDecisionCount, 0);
      expect(original.answeredDecisionCount, 0);
      expect(controller.errorMessage, isNull);
    });

    test('duplicate and conflicting old events preserve queued resolution', () {
      final current = pending();
      final choice = canonicalChoiceForRequest(current.request);
      controller.submitPendingChoice(current, choice);
      final resolution = controller.currentResolution;
      final queued = controller.queuedNextStep;

      controller.submitPendingChoice(current, choice);
      controller.submitPendingChoice(current, Object());

      expect(controller.currentResolution, same(resolution));
      expect(controller.queuedNextStep, same(queued));
      expect(controller.session!.answeredDecisionCount, 1);
      expect(controller.errorMessage, isNull);

      expect(controller.continueAfterResolution(), isTrue);
      controller.submitPendingChoice(current, choice);
      controller.submitPendingChoice(current, Object());
      expect(controller.currentStep, same(queued));
      expect(controller.currentResolution, isNull);
      expect(controller.session!.answeredDecisionCount, 1);
      expect(controller.errorMessage, isNull);
    });

    test(
        'first-save rebound invalidates the old event without poisoning current',
        () {
      final oldPending = pending();
      expect(controller.saveCurrent(), isTrue);
      final current = pending();
      expect(current, isNot(same(oldPending)));

      controller.submitPendingChoice(
          oldPending, canonicalChoiceForRequest(oldPending.request));

      expect(controller.currentStep, same(current));
      expect(controller.session!.answeredDecisionCount, 0);
      expect(controller.saveSummary!.answeredDecisionCount, 0);
      controller.submitPendingChoice(
          current, canonicalChoiceForRequest(current.request));
      expect(controller.session!.answeredDecisionCount, 1);
      expect(controller.currentResolution, isNotNull);
      expect(controller.errorMessage, isNull);
    });
  });

  testWidgets('old rendered callback cannot answer the rebound saved session',
      (tester) async {
    final directory = Directory.systemTemp.createTempSync('fbs-bound-event-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final composition = AppComposition.withSaveDirectory(directory);
    await tester.pumpWidget(MaterialApp(
      home: PresidentHomeScreen(
        composition: composition,
        club: composition.world.clubs.first,
      ),
    ));
    final original = tester.widget<DecisionPanel>(find.byType(DecisionPanel));
    final originalRequest = original.pending.request;

    await tester.tap(find.byKey(const Key('save-game-button')));
    await tester.pumpAndSettle();
    final rebound = tester.widget<DecisionPanel>(find.byType(DecisionPanel));
    expect(rebound.pending.request, isNot(same(originalRequest)));
    expect(rebound.pending.request.kind, originalRequest.kind);
    expect(composition.saveSlots.list(), hasLength(1));

    original.onSubmit!(canonicalChoiceForRequest(originalRequest));
    await tester.pump();

    expect(find.byType(DecisionResolutionPanel), findsNothing);
    expect(tester.widget<DecisionPanel>(find.byType(DecisionPanel)).pending,
        same(rebound.pending));
    expect(composition.saveSlots.list().single.answeredDecisionCount, 0);

    rebound.onSubmit!(canonicalChoiceForRequest(rebound.pending.request));
    await tester.pump();
    expect(find.byType(DecisionResolutionPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
