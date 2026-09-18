import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_resolution_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fbs-m90-resolution-');
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

  Map<PlayerPresidentInteractiveDecisionKind,
          PlayerPresidentInteractiveDecisionResolution>
      collectResolutions() {
    final world = composition.world;
    final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: composition.simulationConfig,
      controlledClubId: world.clubs.first.id,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
      crisisActivationThreshold: 0,
    );
    final resolutions = <PlayerPresidentInteractiveDecisionKind,
        PlayerPresidentInteractiveDecisionResolution>{};
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var guard = 0; guard < 250; guard++) {
      if (step is PlayerPresidentInteractiveSessionCompleted) break;
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      final submission = session.submitWithResolution(
        request: pending.request,
        choice: canonicalChoiceForRequest(pending.request),
      );
      resolutions.putIfAbsent(
        submission.resolution.kind,
        () => submission.resolution,
      );
      step = submission.nextStep;
      if (resolutions.length ==
          PlayerPresidentInteractiveDecisionKind.values.length) {
        break;
      }
    }
    return resolutions;
  }

  testWidgets('all nine authoritative consequence subtypes render', (tester) async {
    final resolutions = collectResolutions();
    expect(
      resolutions.keys.toSet(),
      PlayerPresidentInteractiveDecisionKind.values.toSet(),
    );

    for (final kind in PlayerPresidentInteractiveDecisionKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DecisionResolutionPanel(
                resolution: resolutions[kind]!,
                busy: false,
                onContinue: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('decision-resolution-panel')), findsOneWidget);
      expect(find.byKey(const Key('decision-resolution-kind')), findsOneWidget);
      expect(find.byKey(const Key('decision-resolution-choice')), findsOneWidget);
      expect(find.byKey(const Key('decision-resolution-result')), findsOneWidget);
      expect(
        (tester.widget<Text>(
          find.byKey(const Key('decision-resolution-choice')),
        )).data,
        isNotEmpty,
      );
      expect(
        (tester.widget<Text>(
          find.byKey(const Key('decision-resolution-result')),
        )).data,
        isNotEmpty,
      );
    }
  });

  testWidgets('busy resolution state disables Continue', (tester) async {
    final resolution = collectResolutions().values.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionResolutionPanel(
            resolution: resolution,
            busy: true,
            onContinue: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('decision-resolution-continue-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('final resolution hides Completed until Continue', (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);

    for (var guard = 0; guard < 100; guard++) {
      final pending =
          controller.currentStep as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      if (controller.queuedNextStep
          is PlayerPresidentInteractiveSessionCompleted) {
        break;
      }
      expect(controller.continueAfterResolution(), isTrue);
    }
    expect(
      controller.queuedNextStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final resolution = controller.currentResolution;
              if (resolution != null) {
                return DecisionResolutionPanel(
                  resolution: resolution,
                  busy: false,
                  onContinue: controller.continueAfterResolution,
                );
              }
              return PresidentSessionStateView(step: controller.currentStep!);
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('decision-resolution-panel')), findsOneWidget);
    expect(find.text('Sezon tamamlandı'), findsNothing);

    await tester.tap(
      find.byKey(const Key('decision-resolution-continue-button')),
    );
    await tester.pump();

    expect(find.byKey(const Key('decision-resolution-panel')), findsNothing);
    expect(find.text('Sezon tamamlandı'), findsOneWidget);
  });
}
