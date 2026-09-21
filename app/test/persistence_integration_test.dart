import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fbs-m89-persist-');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  AppComposition composition() => AppComposition.withSaveDirectory(
        Directory(
          '${tempDirectory.path}${Platform.pathSeparator}save_slots',
        ),
      );


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
    throw StateError('Interactive season did not complete.');
  }

  void expectReportParity(
    PlayerPresidentCompletedSeasonReport actual,
    PlayerPresidentCompletedSeasonReport expected,
  ) {
    expect(actual.seasonIndex, expected.seasonIndex);
    expect(actual.controlledClubId, expected.controlledClubId);
    expect(actual.leagueTier, expected.leagueTier);
    expect(actual.finalPosition, expected.finalPosition);
    expect(actual.standing.points, expected.standing.points);
    expect(actual.championClubId, expected.championClubId);
    expect(actual.finance.signature, expected.finance.signature);
    expect(actual.manager.id, expected.manager.id);
    expect(actual.managerSeason.signature, expected.managerSeason.signature);
    expect(actual.promise?.signature, expected.promise?.signature);
    expect(actual.leagueTable, isNotNull);
    expect(expected.leagueTable, isNotNull);
    expect(actual.leagueTable!.signature, expected.leagueTable!.signature);
    expect(
      actual.leagueTable!.rows.map((row) => row.clubId).toList(growable: false),
      expected.leagueTable!.rows
          .map((row) => row.clubId)
          .toList(growable: false),
    );
  }

  test(
      'fresh new-game save survives app recreation with exact pending parity',
      () {
    final compositionA = composition();
    final club = compositionA.world.clubs.first;
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => 'career_recreate',
    );
    addTearDown(controllerA.dispose);

    controllerA.startNewGame(club);
    final first =
        controllerA.currentStep as PlayerPresidentInteractiveDecisionPending;
    controllerA.submitChoice(canonicalChoiceForRequest(first.request));
    final visibleResolution = controllerA.currentResolution;
    final queuedBefore =
        controllerA.queuedNextStep as PlayerPresidentInteractiveDecisionPending;
    final answeredBefore = controllerA.session!.answeredDecisionCount;
    expect(controllerA.currentStep, isNull);
    expect(visibleResolution, isNotNull);

    expect(controllerA.saveCurrent(), isTrue);
    expect(controllerA.binding, isNotNull);
    expect(controllerA.currentResolution, same(visibleResolution));
    expect(controllerA.currentStep, isNull);
    final reboundQueued =
        controllerA.queuedNextStep as PlayerPresidentInteractiveDecisionPending;
    expect(reboundQueued.request.key, queuedBefore.request.key);
    expect(controllerA.continueAfterResolution(), isTrue);
    final pendingBefore =
        controllerA.currentStep as PlayerPresidentInteractiveDecisionPending;

    final initialList = compositionA.saveSlots.list();
    expect(initialList, hasLength(1));
    expect(initialList.single.isNewGameBootstrap, isTrue);
    expect(initialList.single.controlledClubId, club.id);

    final compositionB = composition();
    final recreatedList = compositionB.saveSlots.list();
    expect(recreatedList, hasLength(1));
    final summary = recreatedList.single;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: summary,
    );
    expect(binding, isNotNull);

    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);
    expect(controllerB.loadBoundSave(binding!), isTrue);

    expect(controllerB.selectedClub!.id, club.id);
    expect(controllerB.session!.answeredDecisionCount, answeredBefore);
    expect(controllerB.currentResolution, isNull);
    expect(controllerB.queuedNextStep, isNull);
    final restored =
        controllerB.currentStep as PlayerPresidentInteractiveDecisionPending;
    expect(restored.request.kind, pendingBefore.request.kind);
    expect(restored.request.key, pendingBefore.request.key);
    expect(restored.request.contextSignature, pendingBefore.request.contextSignature);
  });

  test('loaded submit saveBack survives a second app recreation', () {
    final compositionA = composition();
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => 'career_saveback',
    );
    addTearDown(controllerA.dispose);
    controllerA.startNewGame(compositionA.world.clubs.first);
    expect(controllerA.saveCurrent(), isTrue);

    final compositionB = composition();
    final summaryB = compositionB.saveSlots.list().single;
    final bindingB =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: summaryB,
    )!;
    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);
    expect(controllerB.loadBoundSave(bindingB), isTrue);

    final answeredBefore = controllerB.session!.answeredDecisionCount;
    final pending =
        controllerB.currentStep as PlayerPresidentInteractiveDecisionPending;
    controllerB.submitChoice(canonicalChoiceForRequest(pending.request));
    final visibleResolution = controllerB.currentResolution;
    final authoritativeAfterSubmit = controllerB.queuedNextStep;
    expect(controllerB.currentStep, isNull);
    expect(visibleResolution, isNotNull);
    expect(controllerB.session!.answeredDecisionCount, answeredBefore + 1);
    expect(controllerB.saveCurrent(), isTrue);
    expect(controllerB.binding!.identity, bindingB.identity);
    expect(controllerB.currentResolution, same(visibleResolution));
    expect(controllerB.queuedNextStep, same(authoritativeAfterSubmit));

    final compositionC = composition();
    final summaryC = compositionC.saveSlots.list().single;
    final bindingC =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionC.saveSlots,
      summary: summaryC,
    )!;
    final controllerC = GameFlowController(
      world: compositionC.world,
      config: compositionC.simulationConfig,
      saveSlots: compositionC.saveSlots,
    );
    addTearDown(controllerC.dispose);
    expect(controllerC.loadBoundSave(bindingC), isTrue);

    expect(
      controllerC.session!.answeredDecisionCount,
      answeredBefore + 1,
    );
    expect(controllerC.currentResolution, isNull);
    expect(controllerC.queuedNextStep, isNull);
    if (authoritativeAfterSubmit is PlayerPresidentInteractiveDecisionPending) {
      final restored =
          controllerC.currentStep as PlayerPresidentInteractiveDecisionPending;
      expect(restored.request.key, authoritativeAfterSubmit.request.key);
    } else {
      expect(
        controllerC.currentStep,
        isA<PlayerPresidentInteractiveSessionCompleted>(),
      );
    }
  });

  test('deleteSummary removes only the exact typed source for same raw slot',
      () {
    final c = composition();
    const slotId = 'career_same_id';

    final newGame =
        PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: c.world.clubs,
      leagues: c.world.leagues,
      config: c.simulationConfig,
      controlledClubId: c.world.clubs.first.id,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    newGame.advance();
    final bootstrapSource =
        c.saveSlots.save(slotId: slotId, session: newGame);
    expect(
      bootstrapSource,
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap,
    );

    final result =
        const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: c.world.clubs,
      leagues: c.world.leagues,
      config: c.simulationConfig,
      controlledClubId: c.world.clubs.first.id,
      seasonCount: 1,
      hasFutureSeasonAfterReport: false,
    );
    final checkpointSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: result.checkpoint,
      resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
        seasonCount: 1,
      ),
    );
    final checkpointSource =
        c.saveSlots.save(slotId: slotId, session: checkpointSession);
    expect(
      checkpointSource,
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
    );

    final siblings =
        c.saveSlots.list().where((summary) => summary.slotId == slotId).toList();
    expect(siblings, hasLength(2));

    final bootstrap =
        siblings.singleWhere((summary) => summary.isNewGameBootstrap);
    final checkpoint =
        siblings.singleWhere((summary) => summary.isCheckpoint);
    expect(c.saveSlots.deleteSummary(bootstrap), isTrue);

    final remaining =
        c.saveSlots.list().where((summary) => summary.slotId == slotId).toList();
    expect(remaining, hasLength(1));
    expect(remaining.single.identity, checkpoint.identity);
    expect(
      c.saveSlots.inspect(source: checkpoint.source, slotId: slotId),
      isNotNull,
    );
  });

  test('stale summary open returns null and does not invent a loaded session',
      () {
    final c = composition();
    final session =
        PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: c.world.clubs,
      leagues: c.world.leagues,
      config: c.simulationConfig,
      controlledClubId: c.world.clubs.first.id,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    session.advance();
    final source = c.saveSlots.save(slotId: 'career_stale', session: session);
    final summary =
        c.saveSlots.inspect(source: source, slotId: 'career_stale')!;
    expect(c.saveSlots.deleteSummary(summary), isTrue);

    final staleBinding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: c.saveSlots,
      summary: summary,
    );
    expect(staleBinding, isNull);
    expect(c.saveSlots.list(), isEmpty);
  });

  test('fresh bootstrap Completed save rebounds and reloads the same report', () {
    final compositionA = composition();
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => 'career_m91_completed_bootstrap',
    );
    addTearDown(controllerA.dispose);
    controllerA.startNewGame(compositionA.world.clubs.first);

    final completedBefore = driveToCompleted(controllerA);
    final reportBefore =
        PlayerPresidentCompletedSeasonReport.fromCompleted(completedBefore);

    expect(controllerA.saveCurrent(), isTrue);
    expect(
      controllerA.currentStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );
    expect(controllerA.saveSummary!.isNewGameBootstrap, isTrue);
    final reboundReport = PlayerPresidentCompletedSeasonReport.fromCompleted(
      controllerA.currentStep as PlayerPresidentInteractiveSessionCompleted,
    );
    expectReportParity(reboundReport, reportBefore);

    final compositionB = composition();
    final summaryB = compositionB.saveSlots.list().single;
    final bindingB =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: summaryB,
    )!;
    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);

    expect(controllerB.loadBoundSave(bindingB), isTrue);
    expect(
      controllerB.currentStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );
    final reportAfter = PlayerPresidentCompletedSeasonReport.fromCompleted(
      controllerB.currentStep as PlayerPresidentInteractiveSessionCompleted,
    );
    expectReportParity(reportAfter, reportBefore);
    expect(controllerB.currentResolution, isNull);
    expect(controllerB.queuedNextStep, isNull);
  });

  test('bound Completed saveBack preserves and reloads the same report', () {
    final compositionA = composition();
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => 'career_m91_completed_saveback',
    );
    addTearDown(controllerA.dispose);
    controllerA.startNewGame(compositionA.world.clubs.first);
    expect(controllerA.saveCurrent(), isTrue);
    final bindingIdentity = controllerA.binding!.identity;

    final completed = driveToCompleted(controllerA);
    final reportBefore =
        PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
    expect(controllerA.saveCurrent(), isTrue);
    expect(controllerA.binding!.identity, bindingIdentity);
    expect(
      controllerA.currentStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );

    final compositionB = composition();
    final summaryB = compositionB.saveSlots.list().single;
    final bindingB =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: summaryB,
    )!;
    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);
    expect(controllerB.loadBoundSave(bindingB), isTrue);

    final reportAfter = PlayerPresidentCompletedSeasonReport.fromCompleted(
      controllerB.currentStep as PlayerPresidentInteractiveSessionCompleted,
    );
    expectReportParity(reportAfter, reportBefore);
  });

  test('checkpoint-origin Completed reloads the same authoritative report', () {
    final compositionA = composition();
    final slotIds = <String>[
      'career_m91_first_season',
      'career_m91_checkpoint_completed',
    ];
    var slotIndex = 0;
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => slotIds[slotIndex++],
    );
    addTearDown(controllerA.dispose);
    controllerA.startNewGame(compositionA.world.clubs.first);

    driveToCompleted(controllerA);
    expect(controllerA.continueToNextSeason(), isTrue);
    expect(
      controllerA.session!.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );

    final secondCompleted = driveToCompleted(controllerA);
    final reportBefore =
        PlayerPresidentCompletedSeasonReport.fromCompleted(secondCompleted);
    expect(controllerA.saveCurrent(), isTrue);
    expect(controllerA.saveSummary!.isCheckpoint, isTrue);

    final compositionB = composition();
    final checkpointSummary = compositionB.saveSlots
        .list()
        .singleWhere((summary) => summary.isCheckpoint);
    final bindingB =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: checkpointSummary,
    )!;
    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);

    expect(controllerB.loadBoundSave(bindingB), isTrue);
    expect(
      controllerB.currentStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );
    final reportAfter = PlayerPresidentCompletedSeasonReport.fromCompleted(
      controllerB.currentStep as PlayerPresidentInteractiveSessionCompleted,
    );
    expectReportParity(reportAfter, reportBefore);
  });

  test('next-season save reload does not restore the previous season report', () {
    final compositionA = composition();
    final controllerA = GameFlowController(
      world: compositionA.world,
      config: compositionA.simulationConfig,
      saveSlots: compositionA.saveSlots,
      slotIdFactory: () => 'career_m91_next_boundary',
    );
    addTearDown(controllerA.dispose);
    controllerA.startNewGame(compositionA.world.clubs.first);

    final completed = driveToCompleted(controllerA);
    final oldReport =
        PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
    expect(controllerA.continueToNextSeason(), isTrue);
    expect(
      controllerA.currentStep,
      isA<PlayerPresidentInteractiveDecisionPending>(),
    );
    expect(controllerA.saveCurrent(), isTrue);

    final compositionB = composition();
    final summaryB = compositionB.saveSlots.list().single;
    final bindingB =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: compositionB.saveSlots,
      summary: summaryB,
    )!;
    final controllerB = GameFlowController(
      world: compositionB.world,
      config: compositionB.simulationConfig,
      saveSlots: compositionB.saveSlots,
    );
    addTearDown(controllerB.dispose);
    expect(controllerB.loadBoundSave(bindingB), isTrue);

    expect(
      controllerB.currentStep,
      isA<PlayerPresidentInteractiveDecisionPending>(),
    );
    expect(controllerB.currentResolution, isNull);
    expect(controllerB.queuedNextStep, isNull);
    expect(
      controllerB.session!.checkpointOrNull!.nextSeasonIndex,
      greaterThan(oldReport.seasonIndex),
    );
  });

}
