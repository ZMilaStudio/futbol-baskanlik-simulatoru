import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/screens/president_completed_season_match_results_screen.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_match_results_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m97-match-results-widget-');
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
    throw StateError('M97 widget fixture did not complete.');
  }

  String canonicalName(String clubId) => composition.world.clubs
      .singleWhere((club) => club.id == clubId)
      .name;

  testWidgets('renders authoritative 30-match completed results in source order',
      (tester) async {
    final snapshot = completedReport().matchResults!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentCompletedSeasonMatchResultsScreen(
          snapshot: snapshot,
          clubNameForId: canonicalName,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maç Sonuçları'), findsOneWidget);
    expect(
      find.text('Sezon ${snapshot.seasonIndex + 1} • ${snapshot.leagueName}'),
      findsOneWidget,
    );
    expect(snapshot.matches, hasLength(30));

    final first = snapshot.matches.first;
    expect(
      find.byKey(const ValueKey('completed-season-match-result-row-1')),
      findsOneWidget,
    );
    expect(find.text('${first.round}. Hafta'), findsOneWidget);
    expect(find.text(canonicalName(first.opponentClubId)), findsOneWidget);
    expect(
      tester.widget<Text>(
        find.byKey(
          const ValueKey('completed-season-match-result-score-1'),
        ),
      ).data,
      '${first.goalsFor} - ${first.goalsAgainst}',
    );

    for (final match in snapshot.matches) {
      expect(find.text(match.fixtureId), findsNothing);
      expect(find.text(match.opponentClubId), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px textScale 2 long names support real row-30 scroll',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final snapshot = completedReport().matchResults!;
    final firstOpponent = snapshot.matches.first.opponentClubId;
    const longName =
        'Anadolu Birleşik Başkanlık Futbol Kulübü Çok Uzun Rakip Takım Adı';

    String longResolver(String clubId) {
      if (clubId == firstOpponent) return longName;
      return canonicalName(clubId);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2.0),
          ),
          child: PresidentCompletedSeasonMatchResultsScreen(
            snapshot: snapshot,
            clubNameForId: longResolver,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(longName), findsOneWidget);
    final lastRow =
        find.byKey(const ValueKey('completed-season-match-result-row-30'));
    expect(lastRow, findsNothing);

    final list =
        find.byKey(const Key('completed-season-match-results-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      lastRow,
      800,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(lastRow, findsOneWidget);
    expect(tester.getRect(lastRow).top, lessThan(480));
    final last = snapshot.matches.last;
    expect(find.text('${last.round}. Hafta'), findsOneWidget);
    expect(
      find.text('${last.goalsFor} - ${last.goalsAgainst}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('presentation derives win draw and loss labels from copied score',
      (tester) async {
    PlayerPresidentCompletedSeasonMatchResultsSnapshot snapshot(
      int homeGoals,
      int awayGoals,
    ) {
      final fixtures = <Fixture>[
        Fixture(
          id: 'S0_F0',
          seasonIndex: 0,
          round: 1,
          homeClubId: 'a',
          awayClubId: 'b',
          result: MatchResult(
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            homeExpectedGoals: 0,
            awayExpectedGoals: 0,
            matchSeed: 1,
          ),
        ),
        Fixture(
          id: 'S0_F1',
          seasonIndex: 0,
          round: 2,
          homeClubId: 'b',
          awayClubId: 'a',
          result: MatchResult(
            homeGoals: awayGoals,
            awayGoals: homeGoals,
            homeExpectedGoals: 0,
            awayExpectedGoals: 0,
            matchSeed: 2,
          ),
        ),
      ];
      return PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
        controlledClubId: 'a',
        completedLeague: WorldLeague(
          tier: LeagueTier.first,
          clubIds: const ['a', 'b'],
        ),
        report: SeasonReport(
          seasonIndex: 0,
          seed: 1,
          championClubId: 'a',
          table: const [],
          fixtures: fixtures,
          homeWins: 0,
          draws: 0,
          awayWins: 0,
          totalGoals: 0,
        ),
      );
    }

    Future<void> expectOutcome(
      PlayerPresidentCompletedSeasonMatchResultsSnapshot data,
      String label,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PresidentCompletedSeasonMatchResultsScreen(
            snapshot: data,
            clubNameForId: (id) => id == 'a' ? 'Takım A' : 'Takım B',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(label), findsWidgets);
    }

    await expectOutcome(snapshot(2, 0), 'Galibiyet');
    await expectOutcome(snapshot(1, 1), 'Beraberlik');
    await expectOutcome(snapshot(0, 2), 'Mağlubiyet');
  });
}
