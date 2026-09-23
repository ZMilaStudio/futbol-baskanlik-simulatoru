import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/reports/financial_health_label.dart';
import 'package:futbol_baskanlik_app/reports/president_season_report_panel.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m91-season-report-');
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

  String clubNameForId(String id) => composition.world.clubs
      .singleWhere((club) => club.id == id)
      .name;

  PlayerPresidentInteractiveSessionCompleted completedSeason() {
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
        return step;
      }
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.currentResolution, isNotNull);
      expect(controller.continueAfterResolution(), isTrue);
    }
    throw StateError('Interactive season did not complete.');
  }

  testWidgets('panel renders authoritative sporting finance manager and promise',
      (tester) async {
    final completed = completedSeason();
    final report = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
    final standing = report.standing;
    final finance = report.finance;
    var continued = false;
    var openedLeagueTable = false;
    var openedMatchResults = false;
    var openedFinanceStatement = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSeasonReportPanel(
              report: report,
              clubNameForId: clubNameForId,
              onOpenLeagueTable: () {
                openedLeagueTable = true;
              },
              onOpenMatchResults: () {
                openedMatchResults = true;
              },
              onOpenFinanceStatement: () {
                openedFinanceStatement = true;
              },
              onContinueToNextSeason: () {
                continued = true;
              },
              decisionCount: completed.decisionCount,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    expect(find.text('Başkanlık Sezon Raporu'), findsOneWidget);
    expect(
      find.text(
        '${clubNameForId(report.controlledClubId)} • ${report.leagueName}',
      ),
      findsOneWidget,
    );
    expect(
      find.text('${report.finalPosition}. sıra'),
      findsOneWidget,
    );
    expect(
      find.text(
        '${standing.played} maç • ${standing.wins}G / ${standing.draws}B / ${standing.losses}M',
      ),
      findsOneWidget,
    );
    final goalDifference =
        standing.goalDifference > 0 ? '+${standing.goalDifference}' : '${standing.goalDifference}';
    expect(
      find.text(
        '${standing.goalsFor}-${standing.goalsAgainst} gol • $goalDifference averaj',
      ),
      findsOneWidget,
    );
    expect(find.text('${standing.points} puan'), findsOneWidget);
    expect(
      find.text('Şampiyon: ${clubNameForId(report.championClubId)}'),
      findsOneWidget,
    );

    if (report.movement == null) {
      expect(find.byKey(const Key('season-report-movement')), findsNothing);
    } else {
      expect(
        find.text(
          'Lig hareketi: ${report.movement!.from.displayName} → ${report.movement!.to.displayName}',
        ),
        findsOneWidget,
      );
    }

    expect(find.text('Sezon sonu kasa: ${finance.closingCash}'), findsOneWidget);
    expect(find.text('Sezon sonu borç: ${finance.closingDebt}'), findsOneWidget);
    expect(find.text('Toplam gelir: ${finance.totalRevenue}'), findsOneWidget);
    expect(
      find.text('Faaliyet sonucu: ${finance.operatingResult}'),
      findsOneWidget,
    );
    expect(
      find.text('Sponsor geliri: ${finance.sponsorRevenue}'),
      findsOneWidget,
    );
    expect(
      find.text('Maç günü geliri: ${finance.matchdayRevenue}'),
      findsOneWidget,
    );
    expect(
      find.text('Finansal durum: ${financialHealthLabel(finance.health)}'),
      findsOneWidget,
    );
    final financeButton =
        find.byKey(const Key('completed-season-finance-statement-button'));
    expect(
      find.descendant(
        of: find.byKey(const Key('season-report-finance')),
        matching: financeButton,
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(financeButton);
    await tester.tap(financeButton);
    await tester.pump();
    expect(openedFinanceStatement, isTrue);

    expect(find.text(report.manager.name), findsOneWidget);
    expect(
      find.text('Beklenti: ${report.managerSeason.expectedPosition}. sıra'),
      findsOneWidget,
    );
    expect(
      find.text('Gerçekleşen: ${report.managerSeason.actualPosition}. sıra'),
      findsOneWidget,
    );

    final promise = report.promise;
    expect(promise, isNotNull);
    expect(find.byKey(const Key('season-report-promise')), findsOneWidget);
    expect(
      find.text('Sonuç: ${_promiseStatusLabel(promise!.resolution.status)}'),
      findsOneWidget,
    );

    expect(
      find.text('Bu sezon ${completed.decisionCount} başkanlık kararı verdin.'),
      findsOneWidget,
    );
    final tableButton =
        find.byKey(const Key('completed-season-league-table-button'));
    expect(tableButton, findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('season-report-champion'))).dy,
      lessThan(tester.getTopLeft(tableButton).dy),
    );
    expect(
      tester.getTopLeft(tableButton).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('season-report-finance'))).dy),
    );
    final matchButton =
        find.byKey(const Key('completed-season-match-results-button'));
    expect(matchButton, findsOneWidget);
    expect(
      tester.getTopLeft(tableButton).dy,
      lessThan(tester.getTopLeft(matchButton).dy),
    );
    expect(
      tester.getTopLeft(matchButton).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('season-report-finance'))).dy),
    );

    await tester.ensureVisible(tableButton);
    await tester.tap(tableButton);
    await tester.pump();
    expect(openedLeagueTable, isTrue);

    await tester.ensureVisible(matchButton);
    await tester.tap(matchButton);
    await tester.pump();
    expect(openedMatchResults, isTrue);

    expect(find.byKey(const Key('continue-next-season-button')), findsOneWidget);

    final continueButton =
        find.byKey(const Key('continue-next-season-button'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    expect(continued, isTrue);
  });

  testWidgets('career-ended report omits next-season action', (tester) async {
    final completed = completedSeason();
    final report = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSeasonReportPanel(
              report: report,
              clubNameForId: clubNameForId,
              onOpenLeagueTable: () {},
              onOpenMatchResults: () {},
              onOpenFinanceStatement: () {},
              onContinueToNextSeason: () {},
              canContinueToNextSeason: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    expect(
      find.byKey(const Key('completed-season-league-table-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('completed-season-match-results-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('completed-season-finance-statement-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('continue-next-season-button')), findsNothing);
  });

  testWidgets('busy active report keeps next-season action disabled',
      (tester) async {
    final completed = completedSeason();
    final report = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSeasonReportPanel(
              report: report,
              clubNameForId: clubNameForId,
              onOpenLeagueTable: () {},
              onOpenMatchResults: () {},
              onOpenFinanceStatement: () {},
              onContinueToNextSeason: () {},
              busy: true,
            ),
          ),
        ),
      ),
    );

    final finder = find.byKey(const Key('continue-next-season-button'));
    expect(finder, findsOneWidget);
    expect(tester.widget<FilledButton>(finder).onPressed, isNull);
    final tableFinder =
        find.byKey(const Key('completed-season-league-table-button'));
    expect(tableFinder, findsOneWidget);
    expect(tester.widget<OutlinedButton>(tableFinder).onPressed, isNull);
    final matchFinder =
        find.byKey(const Key('completed-season-match-results-button'));
    expect(matchFinder, findsOneWidget);
    expect(tester.widget<OutlinedButton>(matchFinder).onPressed, isNull);
    final financeFinder =
        find.byKey(const Key('completed-season-finance-statement-button'));
    expect(financeFinder, findsOneWidget);
    expect(tester.widget<OutlinedButton>(financeFinder).onPressed, isNull);
  });

  testWidgets('M96-only malformed table preserves M91 and hides table action',
      (tester) async {
    final completed = completedSeason();
    final boundary = completed.result.boundaries.single;
    final worldSeason = boundary
        .source
        .source
        .source
        .sponsor
        .report
        .sourceReport
        .advancedTransferReport
        .worldReport
        .seasons
        .single;
    final controlledClubId = completed.result.checkpoint.controlledClubId;
    final league = worldSeason.leaguesBeforeSeason
        .singleWhere((item) => item.clubIds.contains(controlledClubId));
    final seasonReport = worldSeason.leagueResults
        .singleWhere((item) => item.tier == league.tier)
        .report;
    final duplicate = seasonReport.table
        .firstWhere((row) => row.clubId != controlledClubId);
    seasonReport.table.add(StandingRow(clubId: duplicate.clubId));

    final report = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
    expect(report.leagueTable, isNull);
    expect(report.matchResults, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSeasonReportPanel(
              report: report,
              clubNameForId: clubNameForId,
              onOpenLeagueTable: null,
              onOpenMatchResults: () {},
              onOpenFinanceStatement: () {},
              onContinueToNextSeason: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    expect(find.byKey(const Key('season-report-title')), findsOneWidget);
    expect(
      find.byKey(const Key('completed-season-league-table-button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('completed-season-match-results-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('continue-next-season-button')), findsOneWidget);
  });

  testWidgets('M97-only malformed fixture preserves M91 and M96',
      (tester) async {
    final completed = completedSeason();
    final boundary = completed.result.boundaries.single;
    final worldSeason = boundary
        .source
        .source
        .source
        .sponsor
        .report
        .sourceReport
        .advancedTransferReport
        .worldReport
        .seasons
        .single;
    final controlledClubId = completed.result.checkpoint.controlledClubId;
    final league = worldSeason.leaguesBeforeSeason
        .singleWhere((item) => item.clubIds.contains(controlledClubId));
    final seasonReport = worldSeason.leagueResults
        .singleWhere((item) => item.tier == league.tier)
        .report;
    final fixtureIndex = seasonReport.fixtures.indexWhere(
      (fixture) =>
          fixture.homeClubId == controlledClubId ||
          fixture.awayClubId == controlledClubId,
    );
    final original = seasonReport.fixtures[fixtureIndex];
    seasonReport.fixtures[fixtureIndex] = Fixture(
      id: original.id,
      seasonIndex: original.seasonIndex,
      round: original.round,
      homeClubId: original.homeClubId,
      awayClubId: original.awayClubId,
    );

    final report = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
    expect(report.leagueTable, isNotNull);
    expect(report.matchResults, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentSeasonReportPanel(
              report: report,
              clubNameForId: clubNameForId,
              onOpenLeagueTable: () {},
              onOpenMatchResults: null,
              onOpenFinanceStatement: () {},
              onContinueToNextSeason: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('president-season-report-panel')), findsOneWidget);
    expect(
      find.byKey(const Key('completed-season-league-table-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('completed-season-match-results-button')),
      findsNothing,
    );
    expect(find.byKey(const Key('continue-next-season-button')), findsOneWidget);
  });

  testWidgets('nullable promise section shows no fake promise result',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PresidentSeasonPromiseSection(promise: null),
        ),
      ),
    );

    expect(
      find.text('Bu sezon değerlendirilen başkanlık vaadi yok.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('season-report-promise')), findsOneWidget);
  });
}

String _promiseStatusLabel(PromiseStatus status) => switch (status) {
      PromiseStatus.fulfilled => 'Gerçekleşti',
      PromiseStatus.partial => 'Kısmen gerçekleşti',
      PromiseStatus.broken => 'Gerçekleşmedi',
    };
