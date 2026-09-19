import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_app/dashboard/president_prepared_season_dashboard_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_resolution_panel.dart';
import 'package:futbol_baskanlik_app/reports/president_season_report_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('fbs-m92-dashboard-widget-');
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

  PlayerPresidentPreparedSeasonDashboardSnapshot expectedOpening() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: composition.world.clubs,
        leagues: composition.world.leagues,
        config: composition.simulationConfig,
        controlledClubId: composition.world.clubs.first.id,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
      ).preparedSeasonDashboard;

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

  String valueFor(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  PlayerPresidentInteractiveSessionCompleted driveToCompleted(
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
    throw StateError('M92 widget fixture did not complete.');
  }

  testWidgets('new game shows prepared dashboard before the Pending decision',
      (tester) async {
    final snapshot = expectedOpening();
    await pumpNewGame(tester);

    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('prepared-season-title')), findsOneWidget);
    expect(valueFor(tester, 'prepared-season-title'), 'Sezona Hazırlık');
    expect(
      valueFor(tester, 'prepared-season-league'),
      'Sezon ${snapshot.seasonIndex + 1} • ${snapshot.league.name}',
    );
    expect(valueFor(tester, 'prepared-season-cash'), snapshot.cash.toString());
    expect(valueFor(tester, 'prepared-season-debt'), snapshot.debt.toString());
    expect(
      valueFor(tester, 'prepared-season-fan-trust'),
      '${snapshot.fanOverallTrust} / 100',
    );
    expect(valueFor(tester, 'prepared-season-manager'), snapshot.manager.name);
    expect(
      valueFor(tester, 'prepared-season-board-relationship'),
      '${snapshot.boardRelationship.round()} / 100',
    );
    expect(
      valueFor(tester, 'prepared-season-academy'),
      'Seviye ${snapshot.academyLevel}',
    );
    expect(
      valueFor(tester, 'prepared-season-stadium'),
      'Seviye ${snapshot.stadiumLevel}',
    );
    expect(
      valueFor(tester, 'prepared-season-training-ground'),
      'Seviye ${snapshot.trainingGroundLevel}',
    );
    expect(valueFor(tester, 'prepared-season-sponsor'), 'Aktif sponsor yok');
    expect(valueFor(tester, 'prepared-season-player-control'), 'Aktif');
    expect(find.byType(DecisionPanel), findsOneWidget);
  });

  testWidgets(
      'resolution keeps the same prepared values and save/rebind does not hide it',
      (tester) async {
    await pumpNewGame(tester);
    final before = <String, String>{
      for (final key in [
        'prepared-season-league',
        'prepared-season-cash',
        'prepared-season-debt',
        'prepared-season-fan-trust',
        'prepared-season-manager',
        'prepared-season-board-relationship',
        'prepared-season-academy',
        'prepared-season-stadium',
        'prepared-season-training-ground',
        'prepared-season-sponsor',
        'prepared-season-player-control',
      ])
        key: valueFor(tester, key),
    };

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

    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    expect(find.byType(DecisionPanel), findsNothing);
    expect(find.byType(DecisionResolutionPanel), findsOneWidget);
    for (final entry in before.entries) {
      expect(valueFor(tester, entry.key), entry.value);
    }

    await tester.tap(find.byKey(const Key('save-game-button')));
    await tester.pump();
    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    for (final entry in before.entries) {
      expect(valueFor(tester, entry.key), entry.value);
    }

    await tester.tap(find.byKey(const Key('save-game-button')));
    await tester.pump();
    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    for (final entry in before.entries) {
      expect(valueFor(tester, entry.key), entry.value);
    }
  });

  testWidgets('completed hides prepared dashboard and next season creates a new one',
      (tester) async {
    final fixture = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m92_completed_widget',
    );
    addTearDown(fixture.dispose);
    fixture.startNewGame(composition.world.clubs.first);
    final firstSeasonIndex = fixture.preparedSeasonDashboard!.seasonIndex;
    final completed = driveToCompleted(fixture);
    final expectedNext =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: completed.result.checkpoint,
      resumeConfig: fixture.session!.resumeConfig,
    ).preparedSeasonDashboard;

    expect(fixture.saveCurrent(), isTrue);
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: fixture.saveSummary!,
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

    expect(find.byKey(const Key('prepared-season-dashboard')), findsNothing);
    expect(find.byType(PresidentSeasonReportPanel), findsOneWidget);
    expect(find.byKey(const Key('season-report-title')), findsOneWidget);
    expect(find.byKey(const Key('continue-next-season-button')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('continue-next-season-button')),
    );
    await tester.tap(find.byKey(const Key('continue-next-season-button')));
    await tester.pumpAndSettle();

    expect(find.byType(PresidentSeasonReportPanel), findsNothing);
    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    expect(find.byType(DecisionPanel), findsOneWidget);
    expect(
      valueFor(tester, 'prepared-season-league'),
      'Sezon ${expectedNext.seasonIndex + 1} • ${expectedNext.league.name}',
    );
    expect(expectedNext.seasonIndex, firstSeasonIndex + 1);
  });

  testWidgets('bootstrap and checkpoint loads both render the same dashboard seam',
      (tester) async {
    final bootstrapController = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m92_bootstrap_load',
    );
    addTearDown(bootstrapController.dispose);
    bootstrapController.startNewGame(composition.world.clubs.first);
    final bootstrapSignature =
        bootstrapController.preparedSeasonDashboard!.signature;
    expect(bootstrapController.saveCurrent(), isTrue);
    final bootstrapBinding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: bootstrapController.saveSummary!,
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
    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    expect(bootstrapBinding.session.preparedSeasonDashboard.signature,
        bootstrapSignature);

    final checkpointController = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_m92_checkpoint_load',
    );
    addTearDown(checkpointController.dispose);
    checkpointController.startNewGame(composition.world.clubs.first);
    driveToCompleted(checkpointController);
    expect(checkpointController.continueToNextSeason(), isTrue);
    final checkpointSnapshot = checkpointController.preparedSeasonDashboard!;
    expect(checkpointController.saveCurrent(), isTrue);
    expect(checkpointController.saveSummary!.isCheckpoint, isTrue);
    final checkpointBinding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: checkpointController.saveSummary!,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentHomeScreen.loaded(
          composition: composition,
          binding: checkpointBinding,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prepared-season-dashboard')), findsOneWidget);
    expect(
      valueFor(tester, 'prepared-season-league'),
      'Sezon ${checkpointSnapshot.seasonIndex + 1} • '
      '${checkpointSnapshot.league.name}',
    );
    expect(
      valueFor(tester, 'prepared-season-sponsor'),
      checkpointSnapshot.activeSponsor?.offer.sponsorName ??
          'Aktif sponsor yok',
    );
  });

  testWidgets('panel renders non-null sponsor and lost player control',
      (tester) async {
    final base = expectedOpening();
    final successor = PresidentProfile(
      id: 'president_${base.controlledClubId}_successor-test',
      name: 'Yeni Başkan',
    );
    final tenure = PresidentTenureState(
      clubId: base.controlledClubId,
      president: successor,
      tenureNumber: base.presidentTenure.tenureNumber + 1,
      startedSeasonIndex: base.seasonIndex,
      reelectionsWon: 0,
    );
    final lostControl = PlayerPresidentTenureControlState(
      controlledClubId: base.controlledClubId,
      playerPresidentId: base.playerControl.playerPresidentId,
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: base.seasonIndex,
      successorPresidentId: successor.id,
    );
    final sponsor = SponsorContract(
      offer: SponsorOffer(
        id: 'm92-test-sponsor',
        sponsorName: 'Nova Enerji Uzun Kurumsal Sponsor Adı',
        clubId: base.controlledClubId,
        annualGuaranteed: const Money.fromUnits(1000000),
        performanceBonus: const Money.fromUnits(100000),
        termSeasons: 1,
        bonusTarget: SponsorBonusTarget.topHalf,
      ),
      startSeasonIndex: base.seasonIndex,
      acceptedByPresidentId: successor.id,
    );
    final originalManager = base.manager;
    final longManager = Manager(
      id: originalManager.id,
      name: 'Çok Uzun İsimli Teknik Direktör Test Kullanıcısı',
      profile: originalManager.profile,
      startAge: originalManager.startAge,
      retirementAge: originalManager.retirementAge,
      reputation: originalManager.reputation,
      coaching: originalManager.coaching,
      youthDevelopment: originalManager.youthDevelopment,
      manManagement: originalManager.manManagement,
      boardCooperation: originalManager.boardCooperation,
      budgetDemand: originalManager.budgetDemand,
    );
    final snapshot = PlayerPresidentPreparedSeasonDashboardSnapshot(
      controlledClubId: base.controlledClubId,
      seasonIndex: base.seasonIndex,
      league: base.league,
      finance: base.finance,
      fanOverallTrust: base.fanOverallTrust,
      presidentTenure: tenure,
      playerControl: lostControl,
      manager: longManager,
      managerAssignment: base.managerAssignment,
      academyFacility: base.academyFacility,
      stadiumFacility: base.stadiumFacility,
      trainingGroundFacility: base.trainingGroundFacility,
      activeSponsor: sponsor,
    );

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
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PresidentPreparedSeasonDashboardPanel(snapshot: snapshot),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      valueFor(tester, 'prepared-season-sponsor'),
      sponsor.offer.sponsorName,
    );
    expect(valueFor(tester, 'prepared-season-player-control'), 'Kaybedildi');
    expect(valueFor(tester, 'prepared-season-manager'), longManager.name);
  });
}
