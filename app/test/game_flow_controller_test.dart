import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;
  late FictionalWorldSetup world;
  late GameFlowController controller;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fbs-m90-flow-');
    composition = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
    world = composition.world;
    controller = GameFlowController(
      world: world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () => 'career_controller_test',
    );
  });

  tearDown(() {
    controller.dispose();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveDecisionPending currentPending() =>
      controller.currentStep as PlayerPresidentInteractiveDecisionPending;

  void submitCurrent() {
    final pending = currentPending();
    controller.submitChoice(canonicalChoiceForRequest(pending.request));
    expect(controller.errorMessage, isNull);
  }

  PlayerPresidentTicketPricingRuntimeCheckpoint realLostCheckpoint() {
    const domainEngine = PresidentDomainCareerEngine();
    final beforeElection = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: composition.simulationConfig,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final afterElection = domainEngine.resume(
      checkpoint: beforeElection.checkpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final beforeByClub = {
      for (final state in beforeElection.checkpoint.presidentRuntime.clubs)
        state.clubId: state.tenure.president.id,
    };
    final afterByClub = {
      for (final state in afterElection.checkpoint.presidentRuntime.clubs)
        state.clubId: state.tenure.president.id,
    };
    final turnoverClubId = beforeByClub.keys.firstWhere(
      (clubId) => beforeByClub[clubId] != afterByClub[clubId],
    );

    final checkpoint =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: composition.simulationConfig,
      controlledClubId: turnoverClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
    expect(checkpoint.tenureControl.lost, isTrue);
    expect(checkpoint.tenureControl.lostAtCompletedSeason, 4);
    return checkpoint;
  }

  void continueResolution() {
    expect(controller.awaitingResolution, isTrue);
    expect(controller.continueAfterResolution(), isTrue);
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
  }

  test('starts a real new-game application session for a canonical Club', () {
    final club = world.clubs.first;
    controller.startNewGame(club);

    expect(controller.errorMessage, isNull);
    expect(controller.loading, isFalse);
    expect(controller.selectedClub, same(club));
    expect(
      controller.session,
      isA<PlayerPresidentInteractiveDecisionApplicationSession>(),
    );
    expect(controller.session!.isNewGame, isTrue);
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
  });

  test('valid submit exposes resolution and queues the next boundary', () {
    controller.startNewGame(world.clubs.first);
    final first = currentPending();

    controller.submitChoice(canonicalChoiceForRequest(first.request));

    expect(controller.errorMessage, isNull);
    expect(controller.currentStep, isNull);
    expect(controller.currentResolution, isNotNull);
    expect(controller.currentResolution!.requestKey, first.request.key);
    expect(controller.currentResolution!.kind, first.request.kind);
    expect(controller.queuedNextStep, isNotNull);
    expect(controller.awaitingResolution, isTrue);
    expect(controller.session!.answeredDecisionCount, 1);
  });

  test('continueAfterResolution adopts the already-produced next Pending', () {
    controller.startNewGame(world.clubs.first);
    submitCurrent();
    final queued = controller.queuedNextStep;
    expect(queued, isA<PlayerPresidentInteractiveDecisionPending>());

    expect(controller.continueAfterResolution(), isTrue);

    expect(controller.currentStep, same(queued));
    expect(controller.currentStep, isA<PlayerPresidentInteractiveDecisionPending>());
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
  });

  test('final submit shows resolution before authoritative Completed', () {
    controller.startNewGame(world.clubs.first);

    for (var guard = 0; guard < 100; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) {
        fail('Completed became visible without final resolution.');
      }
      submitCurrent();
      final queued = controller.queuedNextStep;
      if (queued is PlayerPresidentInteractiveSessionCompleted) {
        expect(controller.currentStep, isNull);
        expect(controller.currentResolution, isNotNull);
        expect(controller.session!.completed, same(queued));
        expect(controller.continueAfterResolution(), isTrue);
        expect(controller.currentStep, same(queued));
        return;
      }
      continueResolution();
    }
    fail('Interactive season did not reach a final resolution.');
  });

  test('invalid submit preserves Pending and creates no feedback', () {
    controller.startNewGame(world.clubs.first);
    final before = controller.currentStep;
    final answeredBefore = controller.session!.answeredDecisionCount;

    controller.submitChoice(Object());

    expect(controller.errorMessage, isNotNull);
    expect(controller.currentStep, same(before));
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
    expect(controller.session!.answeredDecisionCount, answeredBefore);
  });

  test('second submit while resolution is visible is blocked', () {
    controller.startNewGame(world.clubs.first);
    final first = currentPending();
    final choice = canonicalChoiceForRequest(first.request);
    controller.submitChoice(choice);
    final resolution = controller.currentResolution;
    final queued = controller.queuedNextStep;
    final answered = controller.session!.answeredDecisionCount;

    controller.submitChoice(choice);

    expect(controller.session!.answeredDecisionCount, answered);
    expect(controller.currentResolution, same(resolution));
    expect(controller.queuedNextStep, same(queued));
    expect(controller.currentStep, isNull);
  });

  test('stale direct core response cannot disturb queued presentation state', () {
    controller.startNewGame(world.clubs.first);
    final first = currentPending();
    final choice = canonicalChoiceForRequest(first.request);
    controller.submitChoice(choice);
    final resolution = controller.currentResolution;
    final queued = controller.queuedNextStep;

    expect(
      () => controller.session!.submitWithResolution(
        request: first.request,
        choice: choice,
      ),
      throwsStateError,
    );
    expect(controller.currentResolution, same(resolution));
    expect(controller.queuedNextStep, same(queued));
    expect(controller.currentStep, isNull);
  });

  test('nine-kind drive yields matching non-null resolution on every submit', () {
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
    session.advance();
    final source = composition.saveSlots.save(
      slotId: 'career_nine_kind',
      session: session,
    );
    final summary = composition.saveSlots.inspect(
      source: source,
      slotId: 'career_nine_kind',
    )!;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: summary,
    )!;
    expect(controller.loadBoundSave(binding), isTrue);

    final seen = <PlayerPresidentInteractiveDecisionKind>{};
    for (var guard = 0; guard < 250; guard++) {
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) break;
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      final resolution = controller.currentResolution;
      expect(resolution, isNotNull);
      expect(resolution!.requestKey, pending.request.key);
      expect(resolution.kind, pending.request.kind);
      expect(resolution.consequence.kind, pending.request.kind);
      seen.add(resolution.kind);
      expect(controller.currentStep, isNull);
      expect(controller.queuedNextStep, isNotNull);
      continueResolution();
      if (seen.length == PlayerPresidentInteractiveDecisionKind.values.length) {
        break;
      }
    }

    expect(seen, PlayerPresidentInteractiveDecisionKind.values.toSet());
  });

  test('startNewGame clears transient resolution feedback', () {
    controller.startNewGame(world.clubs.first);
    submitCurrent();
    expect(controller.awaitingResolution, isTrue);

    controller.startNewGame(world.clubs.last);

    expect(controller.selectedClub, same(world.clubs.last));
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
    expect(controller.currentStep, isA<PlayerPresidentInteractiveDecisionPending>());
  });

  test('loadBoundSave clears transient resolution feedback', () {
    controller.startNewGame(world.clubs.first);
    expect(controller.saveCurrent(), isTrue);
    final binding = controller.binding!;
    submitCurrent();
    expect(controller.awaitingResolution, isTrue);

    expect(controller.loadBoundSave(binding), isTrue);

    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
    expect(
      controller.currentStep,
      anyOf(
        isA<PlayerPresidentInteractiveDecisionPending>(),
        isA<PlayerPresidentInteractiveSessionCompleted>(),
      ),
    );
  });

  test('lost Completed blocks player continuation and preserves controller state',
      () {
    final lostSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: realLostCheckpoint(),
      resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      ),
    );
    expect(
      lostSession.advance(),
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );

    const slotId = 'career_m93_lost_controller';
    final source = composition.saveSlots.save(
      slotId: slotId,
      session: lostSession,
    );
    final summary = composition.saveSlots.inspect(
      source: source,
      slotId: slotId,
    )!;
    final binding =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: composition.saveSlots,
      summary: summary,
    )!;

    expect(controller.loadBoundSave(binding), isTrue);
    expect(controller.completedTenureControl!.lost, isTrue);
    expect(controller.completedTenureControl!.lostAtCompletedSeason, 4);

    final stepBefore = controller.currentStep;
    final bindingBefore = controller.binding;
    final summaryBefore = controller.saveSummary!.signature;

    expect(controller.continueToNextSeason(), isFalse);
    expect(controller.currentStep, same(stepBefore));
    expect(controller.binding, same(bindingBefore));
    expect(controller.saveSummary!.signature, summaryBefore);
    expect(
      controller.errorMessage,
      'Başkanlık görevin sona erdi. Bu kariyerde sonraki sezona geçilemez.',
    );
  });

  test('next-season handoff keeps the existing lifecycle and clears feedback', () {
    controller.startNewGame(world.clubs.first);
    for (var guard = 0; guard < 100; guard++) {
      submitCurrent();
      final queued = controller.queuedNextStep;
      continueResolution();
      if (queued is PlayerPresidentInteractiveSessionCompleted) break;
    }
    expect(
      controller.currentStep,
      isA<PlayerPresidentInteractiveSessionCompleted>(),
    );

    expect(controller.continueToNextSeason(), isTrue);
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
    expect(
      controller.currentStep,
      anyOf(
        isA<PlayerPresidentInteractiveDecisionPending>(),
        isA<PlayerPresidentInteractiveSessionCompleted>(),
      ),
    );
  });
}
