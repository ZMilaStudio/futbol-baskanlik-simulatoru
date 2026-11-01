import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';

import 'support/decision_test_support.dart';

void main() {
  const slotId = 'candidate';
  late Directory directory;
  late AppComposition composition;
  late GameFlowController controller;
  late int slotIdRequests;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fbs-first-save-slot-');
    composition = AppComposition.withSaveDirectory(directory);
    slotIdRequests = 0;
    controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
      slotIdFactory: () {
        slotIdRequests++;
        return slotId;
      },
    );
  });

  tearDown(() {
    controller.dispose();
    directory.deleteSync(recursive: true);
  });

  PlayerPresidentInteractiveDecisionApplicationSession bootstrap(String id) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: composition.world.clubs,
        leagues: composition.world.leagues,
        config: composition.simulationConfig,
        controlledClubId: id,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
      );

  PlayerPresidentInteractiveDecisionApplicationSession checkpoint(String id) {
    final result =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: composition.world.clubs,
      leagues: composition.world.leagues,
      config: composition.simulationConfig,
      controlledClubId: id,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    return PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: result.checkpoint,
      resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      ),
    );
  }

  Map<String, List<int>> bytes() => {
        for (final file
            in directory.listSync(recursive: true).whereType<File>())
          file.path.substring(directory.path.length): file.readAsBytesSync(),
      };

  void expectExistingBytes(Map<String, List<int>> original) {
    final current = bytes();
    for (final entry in original.entries) {
      expect(current[entry.key], entry.value);
    }
  }

  void expectFirstSaveRejected() {
    final before = bytes();
    final session = controller.session;
    final step = controller.currentStep;
    final club = controller.selectedClub;
    expect(controller.binding, isNull);
    expect(controller.saveSummary, isNull);

    expect(controller.saveCurrent(), isFalse);

    expect(controller.session, same(session));
    expect(controller.currentStep, same(step));
    expect(controller.selectedClub, same(club));
    expect(controller.binding, isNull);
    expect(controller.saveSummary, isNull);
    expect(controller.persistenceError, isNotNull);
    expect(controller.persistenceMessage, isNull);
    expect(controller.persistenceBusy, isFalse);
    expect(slotIdRequests, 1);
    expect(bytes(), before);
  }

  void reachUnboundCheckpoint(String id) {
    controller.startNewGame(
        composition.world.clubs.singleWhere((club) => club.id == id));
    for (var guard = 0; guard < 100; guard++) {
      if (controller.awaitingResolution) {
        expect(controller.continueAfterResolution(), isTrue);
        continue;
      }
      final step = controller.currentStep;
      if (step is PlayerPresidentInteractiveSessionCompleted) break;
      final pending = step as PlayerPresidentInteractiveDecisionPending;
      controller.submitChoice(canonicalChoiceForRequest(pending.request));
      expect(controller.errorMessage, isNull);
    }
    expect(controller.currentStep,
        isA<PlayerPresidentInteractiveSessionCompleted>());
    expect(controller.continueToNextSeason(), isTrue);
    expect(controller.session!.origin,
        PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint);
    expect(controller.binding, isNull);
    expect(slotIdRequests, 0);
  }

  test('first bootstrap save does not overwrite another real career', () {
    final existingClub = composition.world.clubs[0];
    final newClub = composition.world.clubs[1];
    final source = composition.saveSlots.save(
      slotId: slotId,
      session: bootstrap(existingClub.id),
    );
    controller.startNewGame(newClub);

    expectFirstSaveRejected();

    expect(
        composition.saveSlots
            .inspect(source: source, slotId: slotId)!
            .controlledClubId,
        existingClub.id);
    expect(controller.session!.preparedSeasonDashboard.controlledClubId,
        newClub.id);
  });

  test(
      'same-club separate career collision preserves existing accepted history',
      () {
    final club = composition.world.clubs.first;
    final existing = bootstrap(club.id);
    final pending =
        existing.advance() as PlayerPresidentInteractiveDecisionPending;
    existing.submit(
        request: pending.request,
        choice: canonicalChoiceForRequest(pending.request));
    final source =
        composition.saveSlots.save(slotId: slotId, session: existing);
    controller.startNewGame(club);
    expect(controller.session!.answeredDecisionCount, 0);

    expectFirstSaveRejected();

    expect(
        composition.saveSlots
            .inspect(source: source, slotId: slotId)!
            .answeredDecisionCount,
        1);
    expect(controller.session!.answeredDecisionCount, 0);
  });

  test('first checkpoint save protects an existing checkpoint typed identity',
      () {
    final first = composition.world.clubs[0];
    final second = composition.world.clubs[1];
    final source = composition.saveSlots
        .save(slotId: slotId, session: checkpoint(first.id));
    expect(source,
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint);
    reachUnboundCheckpoint(second.id);

    expectFirstSaveRejected();

    expect(
        composition.saveSlots
            .inspect(source: source, slotId: slotId)!
            .controlledClubId,
        first.id);
  });

  test('bootstrap first save may share raw ID with a checkpoint sibling', () {
    final first = composition.world.clubs[0];
    final second = composition.world.clubs[1];
    final checkpointSource = composition.saveSlots
        .save(slotId: slotId, session: checkpoint(first.id));
    final original = bytes();
    controller.startNewGame(second);

    expect(controller.saveCurrent(), isTrue);

    expect(controller.binding!.source,
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap);
    expectExistingBytes(original);
    expect(
        composition.saveSlots
            .inspect(source: checkpointSource, slotId: slotId)!
            .controlledClubId,
        first.id);
    expect(composition.saveSlots.list(), hasLength(2));
    expect(controller.preparedSeasonDashboard!.controlledClubId, second.id);
  });

  test('checkpoint first save may share raw ID with a bootstrap sibling', () {
    final first = composition.world.clubs[0];
    final second = composition.world.clubs[1];
    final bootstrapSource = composition.saveSlots
        .save(slotId: slotId, session: bootstrap(first.id));
    final original = bytes();
    reachUnboundCheckpoint(second.id);

    expect(controller.saveCurrent(), isTrue);

    expect(controller.binding!.source,
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint);
    expectExistingBytes(original);
    expect(
        composition.saveSlots
            .inspect(source: bootstrapSource, slotId: slotId)!
            .controlledClubId,
        first.id);
    expect(composition.saveSlots.list(), hasLength(2));
    expect(controller.preparedSeasonDashboard!.controlledClubId, second.id);
  });

  test('bound saveBack still updates its exact existing typed slot', () {
    controller.startNewGame(composition.world.clubs.first);
    expect(controller.saveCurrent(), isTrue);
    final binding = controller.binding!;
    final before = bytes();
    final pending =
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;
    controller.submitChoice(canonicalChoiceForRequest(pending.request));
    final resolution = controller.currentResolution;
    final queued = controller.queuedNextStep;

    expect(controller.saveCurrent(), isTrue);

    expect(controller.binding, same(binding));
    expect(controller.currentResolution, same(resolution));
    expect(controller.queuedNextStep, same(queued));
    expect(binding.inspect()!.answeredDecisionCount, 1);
    expect(bytes(), isNot(before));
    expect(controller.persistenceError, isNull);
    expect(slotIdRequests, 1);
  });

  test('unrelated corrupt slot does not block a fresh valid typed identity',
      () {
    final source = composition.saveSlots.save(
        slotId: 'unrelated',
        session: bootstrap(composition.world.clubs.first.id));
    final file = directory.listSync().whereType<File>().single;
    final corrupt = file.readAsBytesSync();
    corrupt[0] ^= 1;
    file.writeAsBytesSync(corrupt);
    expect(
        () =>
            composition.saveSlots.inspect(source: source, slotId: 'unrelated'),
        throwsException);
    controller.startNewGame(composition.world.clubs[1]);

    expect(controller.saveCurrent(), isTrue);

    expect(controller.binding!.slotId, slotId);
    expect(controller.preparedSeasonDashboard!.controlledClubId,
        composition.world.clubs[1].id);
    expect(file.readAsBytesSync(), corrupt);
    expect(controller.persistenceError, isNull);
  });
}
