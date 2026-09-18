import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/main.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fbs-m89-widget-');
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(FutbolBaskanlikApp(composition: composition));
  }

  Future<void> openClubSelection(WidgetTester tester) async {
    await tester.tap(find.text('Yeni Oyun'));
    await tester.pumpAndSettle();
  }

  GameFlowController saveOneGame(String slotId) {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => slotId,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);
    expect(controller.saveCurrent(), isTrue);
    return controller;
  }

  testWidgets('opening screen exposes the two primary actions', (tester) async {
    await pumpApp(tester);

    expect(find.text('Futbol Başkanlık Simülatörü'), findsOneWidget);
    expect(find.text('Yeni Oyun'), findsOneWidget);
    expect(find.text('Kayıt Yükle'), findsOneWidget);

    final loadButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Kayıt Yükle'),
    );
    expect(loadButton.onPressed, isNotNull);
  });

  testWidgets('Kayıt Yükle opens the real mixed save list', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Kayıt Yükle'));
    await tester.pumpAndSettle();

    expect(find.text('Kayıtlar'), findsOneWidget);
    expect(find.byKey(const Key('empty-save-list')), findsOneWidget);
  });

  testWidgets('Yeni Oyun opens canonical club selection', (tester) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    expect(find.text('Kulüp Seçimi'), findsOneWidget);
    expect(find.text('48 kulüp'), findsOneWidget);
  });

  testWidgets('club selection exposes the canonical 48-club world', (
    tester,
  ) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    final clubs = composition.world.clubs;
    expect(clubs, hasLength(48));
    expect(find.text(clubs.first.name), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(clubs.last.name),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text(clubs.last.name), findsOneWidget);
  });

  testWidgets('selected club opens the real President Home lifecycle', (
    tester,
  ) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    final selectedClub = composition.world.clubs.first;
    await tester.tap(find.text(selectedClub.name));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected-club-name')), findsOneWidget);
    expect(find.text(selectedClub.name), findsOneWidget);
    expect(find.text('Başkanlık Merkezi'), findsNWidgets(2));
    expect(
      find.text('Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('session-lifecycle-state')), findsOneWidget);
    expect(find.byKey(const Key('save-game-button')), findsOneWidget);
  });

  testWidgets('saved bootstrap appears and Continue opens the exact save',
      (tester) async {
    final controller = saveOneGame('career_widget_load');
    final summary = controller.saveSummary!;

    await pumpApp(tester);
    await tester.tap(find.text('Kayıt Yükle'));
    await tester.pumpAndSettle();

    expect(find.text(composition.world.clubs.first.name), findsOneWidget);
    expect(find.textContaining('Yeni oyun kaydı'), findsOneWidget);
    expect(
      find.byKey(Key('continue-${summary.identity}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(Key('continue-${summary.identity}')));
    await tester.pumpAndSettle();

    expect(find.text('Başkanlık Merkezi'), findsNWidgets(2));
    expect(find.byKey(const Key('bound-save-status')), findsOneWidget);
    expect(find.text(composition.world.clubs.first.name), findsOneWidget);
  });

  testWidgets('load screen deletes the exact listed typed save', (tester) async {
    final controller = saveOneGame('career_widget_delete');
    final summary = controller.saveSummary!;

    await pumpApp(tester);
    await tester.tap(find.text('Kayıt Yükle'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('delete-${summary.identity}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-save-list')), findsOneWidget);
    expect(composition.saveSlots.list(), isEmpty);
  });

  testWidgets('a real Pending step renders a readable decision kind', (
    tester,
  ) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);

    final step = controller.currentStep;
    expect(step, isA<PlayerPresidentInteractiveDecisionPending>());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSessionStateView(step: step!),
          ),
        ),
      ),
    );

    expect(find.text('Karar bekleniyor'), findsOneWidget);
    expect(find.byKey(const Key('decision-kind-label')), findsOneWidget);
    final kindText = tester.widget<Text>(
      find.byKey(const Key('decision-kind-label')),
    );
    expect(kindText.data, isNotEmpty);
  });

  testWidgets('an authoritative Completed step renders safely', (tester) async {
    final world = composition.world;
    final result =
        const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: composition.simulationConfig,
      controlledClubId: world.clubs.first.id,
      seasonCount: 1,
      hasFutureSeasonAfterReport: false,
    );
    final completed = PlayerPresidentInteractiveSessionCompleted(
      result: result,
      decisionCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PresidentSessionStateView(step: completed),
        ),
      ),
    );

    expect(find.text('Sezon tamamlandı'), findsOneWidget);
    expect(find.byKey(const Key('completed-season-info')), findsOneWidget);
  });

  testWidgets('back navigation returns through the Stage 5 flow', (
    tester,
  ) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    final selectedClub = composition.world.clubs.first;
    await tester.tap(find.text(selectedClub.name));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Kulüp Seçimi'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Yeni Oyun'), findsOneWidget);
  });
}
