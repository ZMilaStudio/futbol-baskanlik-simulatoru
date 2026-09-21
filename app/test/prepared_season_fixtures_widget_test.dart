import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_resolution_panel.dart';
import 'package:futbol_baskanlik_app/reports/president_season_report_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_app/screens/president_prepared_season_fixtures_screen.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m95-fixture-widget-');
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
    throw StateError('M95 widget fixture did not complete.');
  }

  PlayerPresidentPreparedSeasonFixturesSnapshot longSnapshot() =>
      PlayerPresidentPreparedSeasonFixturesSnapshot(
        controlledClubId: 'controlled',
        seasonIndex: 2,
        leagueTier: LeagueTier.first,
        fixtures: List.generate(
          30,
          (index) => PlayerPresidentPreparedSeasonFixture(
            fixtureId: 'fixture-private-${index + 1}',
            round: index + 1,
            opponentClubId: 'opponent-private-${index % 15}',
            isHome: index.isEven,
          ),
        ),
      );

  String longNameResolver(String id) {
    if (id == 'controlled') {
      return 'Çok Uzun İsimli Başkanlık Kulübü Spor ve Dayanışma Derneği';
    }
    return 'Çok Uzun İsimli Rakip Kulüp Futbol Spor ve Dayanışma Derneği ${id}';
  }

  testWidgets('Pending shows sibling squad and fixture actions and opens screen',
      (tester) async {
    final expectedSession =
        PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: composition.world.clubs,
      leagues: composition.world.leagues,
      config: composition.simulationConfig,
      controlledClubId: composition.world.clubs.first.id,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final expected = expectedSession.preparedSeasonFixtures;
    final expectedOpponentName = composition.world.clubs
        .singleWhere(
          (club) => club.id == expected.fixtures.first.opponentClubId,
        )
        .name;

    await pumpNewGame(tester);
    expect(find.byType(DecisionPanel), findsOneWidget);
    expect(
      find.byKey(const Key('prepared-season-fixtures-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('prepared-squad-button')), findsOneWidget);
    expect(find.text('Fikstürü Gör'), findsOneWidget);

    final button =
        find.byKey(const Key('prepared-season-fixtures-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(PresidentPreparedSeasonFixturesScreen), findsOneWidget);
    expect(
      find.byKey(const Key('prepared-season-fixtures-screen')),
      findsOneWidget,
    );
    expect(find.text('Fikstür'), findsOneWidget);
    expect(find.textContaining('Sezon 1 •'), findsOneWidget);
    expect(find.text('1. Hafta'), findsOneWidget);
    expect(find.text(expectedOpponentName), findsOneWidget);
    expect(find.text('Ev'), findsWidgets);
    expect(find.text('Deplasman'), findsWidgets);

    for (final fixture in expected.fixtures) {
      expect(find.text(fixture.fixtureId), findsNothing);
      expect(find.text(fixture.opponentClubId), findsNothing);
    }

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PresidentHomeScreen), findsOneWidget);
    expect(
      find.byKey(const Key('prepared-season-fixtures-button')),
      findsOneWidget,
    );
  });

  testWidgets('Resolution keeps prepared fixture action visible', (tester) async {
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
    expect(
      find.byKey(const Key('prepared-season-fixtures-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('prepared-squad-button')), findsOneWidget);
  });

  testWidgets('Completed active hides fixture action and keeps M91 report',
      (tester) async {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m95_completed',
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

    expect(
      find.byKey(const Key('prepared-season-fixtures-button')),
      findsNothing,
    );
    expect(find.byType(PresidentSeasonReportPanel), findsOneWidget);
  });

  testWidgets('canonical screen configures 30 rows and protects raw IDs',
      (tester) async {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: composition.world.clubs,
      leagues: composition.world.leagues,
      config: composition.simulationConfig,
      controlledClubId: composition.world.clubs.first.id,
      seasonCount: 1,
    );
    final snapshot = session.preparedSeasonFixtures;
    String resolver(String id) =>
        composition.world.clubs.singleWhere((club) => club.id == id).name;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentPreparedSeasonFixturesScreen(
          snapshot: snapshot,
          clubNameForId: resolver,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(snapshot.fixtures, hasLength(30));
    final list = tester.widget<ListView>(
      find.byKey(const Key('prepared-season-fixtures-list')),
    );
    final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.estimatedChildCount, 59);
    expect(find.text('1. Hafta'), findsOneWidget);
    expect(find.text('Ev'), findsWidgets);
    expect(find.text('Deplasman'), findsWidgets);
    expect(
      find.text('Sezon ${snapshot.seasonIndex + 1} • ${resolver(snapshot.controlledClubId)}'),
      findsOneWidget,
    );
    for (final fixture in snapshot.fixtures) {
      expect(find.text(fixture.fixtureId), findsNothing);
      expect(find.text(fixture.opponentClubId), findsNothing);
    }
  });

  testWidgets('real 30-row list scroll reaches 30. Hafta', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: composition.world.clubs,
      leagues: composition.world.leagues,
      config: composition.simulationConfig,
      controlledClubId: composition.world.clubs.first.id,
      seasonCount: 1,
    );
    String resolver(String id) =>
        composition.world.clubs.singleWhere((club) => club.id == id).name;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentPreparedSeasonFixturesScreen(
          snapshot: session.preparedSeasonFixtures,
          clubNameForId: resolver,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('prepared-season-fixtures-list'));
    expect(list, findsOneWidget);
    expect(find.text('30. Hafta'), findsNothing);

    for (var drag = 0;
        drag < 12 && find.text('30. Hafta').evaluate().isEmpty;
        drag++) {
      await tester.drag(list, const Offset(0, -420));
      await tester.pumpAndSettle();
    }

    expect(find.text('30. Hafta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px textScale 2.0 long names do not overflow', (tester) async {
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
        home: PresidentPreparedSeasonFixturesScreen(
          snapshot: longSnapshot(),
          clubNameForId: longNameResolver,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1. Hafta'), findsOneWidget);
    expect(find.textContaining('Çok Uzun İsimli Rakip Kulüp'), findsWidgets);
    expect(find.text('Ev'), findsWidgets);
    expect(tester.takeException(), isNull);

    final list = find.byKey(const Key('prepared-season-fixtures-list'));
    for (var drag = 0;
        drag < 4 && find.text('Deplasman').evaluate().isEmpty;
        drag++) {
      await tester.drag(list, const Offset(0, -280));
      await tester.pumpAndSettle();
    }

    expect(find.text('Deplasman'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bootstrap and checkpoint loaded sessions expose fixture action',
      (tester) async {
    final bootstrap = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m95_bootstrap',
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
    expect(
      find.byKey(const Key('prepared-season-fixtures-button')),
      findsOneWidget,
    );

    final checkpointController = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m95_checkpoint',
    );
    addTearDown(checkpointController.dispose);
    checkpointController.startNewGame(composition.world.clubs.first);
    driveToCompleted(checkpointController);
    expect(checkpointController.continueToNextSeason(), isTrue);
    expect(checkpointController.saveCurrent(), isTrue);
    final checkpointBinding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: checkpointController.saveSummary!,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          key: const ValueKey('m95-checkpoint-home'),
          composition: composition,
          binding: checkpointBinding,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('prepared-season-fixtures-button')),
      findsOneWidget,
    );
  });
}
