import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
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
    final pendingBefore =
        controllerA.currentStep as PlayerPresidentInteractiveDecisionPending;
    final answeredBefore = controllerA.session!.answeredDecisionCount;

    expect(controllerA.saveCurrent(), isTrue);
    expect(controllerA.binding, isNotNull);

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
    final authoritativeAfterSubmit = controllerB.currentStep;
    expect(controllerB.session!.answeredDecisionCount, answeredBefore + 1);
    expect(controllerB.saveCurrent(), isTrue);
    expect(controllerB.binding!.identity, bindingB.identity);

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
}
