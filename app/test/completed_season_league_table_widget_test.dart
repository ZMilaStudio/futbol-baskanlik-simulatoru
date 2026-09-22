import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/screens/president_completed_season_league_table_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m96-league-table-widget-');
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

  PlayerPresidentCompletedSeasonReport completedReport() {
    final controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
    );
    addTearDown(controller.dispose);
    controller.startNewGame(composition.world.clubs.first);

    for (var guard = 0; guard < 100; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) {
        return PlayerPresidentCompletedSeasonReport.fromCompleted(step);
      }
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.continueAfterResolution(), isTrue);
    }
    throw StateError('M96 widget fixture did not complete.');
  }

  String canonicalName(String clubId) => composition.world.clubs
      .singleWhere((club) => club.id == clubId)
      .name;

  testWidgets('renders canonical 16-row final table in authoritative order',
      (tester) async {
    final report = completedReport();
    final snapshot = report.leagueTable!;
    final controlledName = canonicalName(snapshot.controlledClubId);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentCompletedSeasonLeagueTableScreen(
          snapshot: snapshot,
          clubNameForId: canonicalName,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Puan Durumu'), findsOneWidget);
    expect(
      find.text('Sezon ${snapshot.seasonIndex + 1} • ${snapshot.leagueName}'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('completed-season-league-data-table')), findsOneWidget);
    for (var position = 1; position <= 16; position++) {
      expect(
        find.byKey(ValueKey('completed-season-table-position-$position')),
        findsOneWidget,
      );
    }
    expect(canonicalName(snapshot.rows.first.clubId), canonicalName(snapshot.championClubId));
    expect(
      find.bySemanticsLabel('Senin Kulübün: $controlledName'),
      findsOneWidget,
    );

    final first = snapshot.rows.first;
    expect(
      tester.widget<Text>(
        find.byKey(const ValueKey('completed-season-table-points-1')),
      ).data,
      '${first.points}',
    );

    for (final row in snapshot.rows) {
      expect(find.text(row.clubId), findsNothing);
      expect(find.text(canonicalName(row.clubId)), findsWidgets);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
      '320px textScale 2 long names support real vertical and horizontal scroll',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final report = completedReport();
    final snapshot = report.leagueTable!;
    final secondId = snapshot.rows[1].clubId;
    final controlledName =
        'ZMila Başkanlık Spor Kulübü Çok Uzun Kontrollü Takım Adı';
    final otherLongName =
        'Anadolu Birleşik Futbol Kulübü Çok Uzun Rakip Takım Adı';

    String longName(String clubId) {
      if (clubId == snapshot.controlledClubId) return controlledName;
      if (clubId == secondId) return otherLongName;
      return canonicalName(clubId);
    }

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2.0),
          ),
          child: PresidentCompletedSeasonLeagueTableScreen(
            snapshot: snapshot,
            clubNameForId: longName,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(controlledName), findsOneWidget);
    expect(find.text(otherLongName), findsOneWidget);
    expect(
      find.bySemanticsLabel('Senin Kulübün: $controlledName'),
      findsOneWidget,
    );

    final lastPosition =
        find.byKey(const ValueKey('completed-season-table-position-16'));
    final farRight =
        find.byKey(const ValueKey('completed-season-table-points-1'));
    expect(tester.getRect(lastPosition).top, greaterThan(480));
    expect(tester.getRect(farRight).left, greaterThan(320));

    final horizontalFinder =
        find.byKey(const Key('completed-season-table-horizontal-scroll'));
    final horizontalTopLeft = tester.getTopLeft(horizontalFinder);
    await tester.dragFrom(
      Offset(300, horizontalTopLeft.dy + 100),
      const Offset(-4000, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(farRight).left, lessThan(320));

    await tester.drag(
      find.byKey(const Key('completed-season-table-vertical-scroll')),
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(lastPosition).top, lessThan(480));

    expect(
      find.byKey(const Key('completed-season-table-header-points')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
