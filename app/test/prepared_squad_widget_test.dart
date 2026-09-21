import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_resolution_panel.dart';
import 'package:futbol_baskanlik_app/reports/president_season_report_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_app/screens/president_prepared_squad_screen.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_squad_snapshot.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m94-squad-widget-');
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

  Future<void> pumpNewGame(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen(
          composition: composition,
          club: composition.world.clubs.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  PlayerPresidentInteractiveSessionCompleted driveToCompleted(
    GameFlowController controller,
  ) {
    for (var guard = 0; guard < 100; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) return step;
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.currentResolution, isNotNull);
      expect(controller.continueAfterResolution(), isTrue);
    }
    throw StateError('M94 widget fixture did not complete.');
  }

  PlayerPresidentPreparedSquadSnapshot sampleSnapshot() =>
      PlayerPresidentPreparedSquadSnapshot(
        controlledClubId: 'club',
        seasonIndex: 2,
        players: const [
          PlayerPresidentPreparedSquadPlayer(
            playerId: 'forward-private-id',
            name: 'Çok Uzun İsimli Forvet Oyuncusu Deneme Soyadı',
            position: PlayerPosition.forward,
            age: 27,
            ability: 81.6,
            potential: 86.4,
            isAcademyGraduate: false,
          ),
          PlayerPresidentPreparedSquadPlayer(
            playerId: 'academy-private-id',
            name: 'Akademi Kalecisi',
            position: PlayerPosition.goalkeeper,
            age: 18,
            ability: 68.4,
            potential: 90.6,
            isAcademyGraduate: true,
          ),
          PlayerPresidentPreparedSquadPlayer(
            playerId: 'defender-private-id',
            name: 'Defans Oyuncusu',
            position: PlayerPosition.defender,
            age: 24,
            ability: 74.4,
            potential: 80.4,
            isAcademyGraduate: false,
          ),
          PlayerPresidentPreparedSquadPlayer(
            playerId: 'mid-private-id',
            name: 'Orta Saha Oyuncusu',
            position: PlayerPosition.midfielder,
            age: 23,
            ability: 78.4,
            potential: 84.4,
            isAcademyGraduate: false,
          ),
        ],
      );

  PlayerPresidentPreparedSquadSnapshot longListSnapshot() {
    const positions = PlayerPosition.values;
    return PlayerPresidentPreparedSquadSnapshot(
      controlledClubId: 'club',
      seasonIndex: 2,
      players: List.generate(28, (index) {
        final padded = index.toString().padLeft(2, '0');
        return PlayerPresidentPreparedSquadPlayer(
          playerId: 'scroll-player-$padded',
          name: 'Oyuncu $padded Uzun Test Soyadı',
          position: positions[index % positions.length],
          age: 18 + (index % 16),
          ability: 60 + (index % 24).toDouble(),
          potential: 70 + (index % 25).toDouble(),
          isAcademyGraduate: index % 7 == 0,
        );
      }),
    );
  }

  testWidgets('Pending shows Kadroyu Gör and opens read-only squad screen',
      (tester) async {
    await pumpNewGame(tester);
    expect(find.byType(DecisionPanel), findsOneWidget);
    final button = find.byKey(const Key('prepared-squad-button'));
    expect(button, findsOneWidget);
    expect(find.text('Kadroyu Gör'), findsOneWidget);

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(PresidentPreparedSquadScreen), findsOneWidget);
    expect(find.byKey(const Key('prepared-squad-screen')), findsOneWidget);
    expect(find.text('Kadro'), findsOneWidget);
    expect(find.textContaining('Sezon 1 •'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PresidentHomeScreen), findsOneWidget);
  });

  testWidgets('Resolution keeps Kadroyu Gör visible', (tester) async {
    await pumpNewGame(tester);
    final action = find
        .descendant(
          of: find.byType(DecisionPanel),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton && widget.onPressed != null,
          ),
        )
        .first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();

    expect(find.byType(DecisionResolutionPanel), findsOneWidget);
    expect(find.byKey(const Key('prepared-squad-button')), findsOneWidget);
  });

  testWidgets('Completed hides prepared squad entry and keeps M91 report',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m94_completed',
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    driveToCompleted(controller);
    expect(controller.saveCurrent(), isTrue);
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: controller.saveSummary!,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          composition: composition,
          binding: binding,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prepared-squad-button')), findsNothing);
    expect(find.byType(PresidentSeasonReportPanel), findsOneWidget);
  });

  testWidgets('screen renders fields, Turkish labels and no raw player IDs',
      (tester) async {
    final snapshot = sampleSnapshot();
    await tester.pumpWidget(
      MaterialApp(
        home: PresidentPreparedSquadScreen(
          snapshot: snapshot,
          clubName: 'Test Kulübü',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sezon 3 • Test Kulübü'), findsOneWidget);
    expect(find.text('Akademi Kalecisi'), findsOneWidget);
    expect(find.text('Kaleci • 18 yaş'), findsOneWidget);
    expect(find.text('Defans • 24 yaş'), findsOneWidget);
    expect(find.text('Orta Saha • 23 yaş'), findsOneWidget);
    expect(find.text('Forvet • 27 yaş'), findsOneWidget);
    expect(find.text('Güç 68 • Potansiyel 91'), findsOneWidget);
    expect(find.text('Güç 82 • Potansiyel 86'), findsOneWidget);
    expect(find.text('Akademi'), findsOneWidget);
    for (final player in snapshot.players) {
      expect(find.text(player.playerId), findsNothing);
    }
  });

  testWidgets('snapshot deterministic ordering is the rendered row ordering',
      (tester) async {
    final snapshot = sampleSnapshot();
    await tester.pumpWidget(
      MaterialApp(
        home: PresidentPreparedSquadScreen(
          snapshot: snapshot,
          clubName: 'Test Kulübü',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final names = snapshot.players.map((player) => player.name).toList();
    for (var i = 1; i < names.length; i++) {
      expect(
        tester.getTopLeft(find.text(names[i - 1])).dy,
        lessThan(tester.getTopLeft(find.text(names[i])).dy),
      );
    }
  });

  testWidgets('320px and textScale 2.0 render without horizontal overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: child!,
        ),
        home: PresidentPreparedSquadScreen(
          snapshot: sampleSnapshot(),
          clubName: 'Çok Uzun Test Kulübü Gösterim Adı',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px renders the long-name squad list without exception',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: PresidentPreparedSquadScreen(
          snapshot: sampleSnapshot(),
          clubName: 'Test Kulübü',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('prepared-squad-list')), findsOneWidget);
  });

  testWidgets('long prepared squad scroll reaches the final player',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final snapshot = longListSnapshot();
    expect(snapshot.players, hasLength(28));
    final finalPlayerName = snapshot.players.last.name;
    await tester.pumpWidget(
      MaterialApp(
        home: PresidentPreparedSquadScreen(
          snapshot: snapshot,
          clubName: 'Test Kulübü',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('prepared-squad-list'));
    expect(list, findsOneWidget);
    expect(find.text(finalPlayerName), findsNothing);

    for (var drag = 0;
        drag < 10 && find.text(finalPlayerName).evaluate().isEmpty;
        drag++) {
      await tester.drag(list, const Offset(0, -420));
      await tester.pumpAndSettle();
    }

    expect(find.text(finalPlayerName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bootstrap and checkpoint loads expose prepared squad entry',
      (tester) async {
    final bootstrap = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m94_bootstrap',
    );
    addTearDown(bootstrap.dispose);
    bootstrap.startNewGame(composition.world.clubs.first);
    expect(bootstrap.saveCurrent(), isTrue);
    final bootstrapBinding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: bootstrap.saveSummary!,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          composition: composition,
          binding: bootstrapBinding,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prepared-squad-button')), findsOneWidget);

    final checkpoint = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m94_checkpoint',
    );
    addTearDown(checkpoint.dispose);
    checkpoint.startNewGame(composition.world.clubs.first);
    driveToCompleted(checkpoint);
    expect(checkpoint.continueToNextSeason(), isTrue);
    expect(checkpoint.saveCurrent(), isTrue);
    final checkpointBinding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: checkpoint.saveSummary!,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          key: const ValueKey('m94-checkpoint-home'),
          composition: composition,
          binding: checkpointBinding,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prepared-squad-button')), findsOneWidget);
  });
}
