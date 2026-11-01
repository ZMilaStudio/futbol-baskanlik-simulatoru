import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory directory;
  late AppComposition composition;
  late GameFlowController controller;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fbs-bound-club-');
    composition = AppComposition.withSaveDirectory(directory);
    controller = GameFlowController(
      world: composition.world,
      config: composition.simulationConfig,
      saveSlots: composition.saveSlots,
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

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding saveAndOpen(
    String id, {
    String slotId = 'shared',
  }) {
    final source = composition.saveSlots.save(
      slotId: slotId,
      session: bootstrap(id),
    );
    return PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.open(
      service: composition.saveSlots,
      source: source,
      slotId: slotId,
    )!;
  }

  Map<String, List<int>> saveBytes() => {
        for (final file
            in directory.listSync(recursive: true).whereType<File>())
          file.path.substring(directory.path.length): file.readAsBytesSync(),
      };

  void expectNoAdoptedSession() {
    expect(controller.selectedClub, isNull);
    expect(controller.session, isNull);
    expect(controller.currentStep, isNull);
    expect(controller.currentResolution, isNull);
    expect(controller.queuedNextStep, isNull);
    expect(controller.binding, isNull);
    expect(controller.saveSummary, isNull);
    expect(controller.loading, isFalse);
    expect(controller.persistenceBusy, isFalse);
    expect(controller.errorMessage, isNotNull);
  }

  test(
      'rejects a bound session when its exact typed slot now names another club',
      () {
    final first = composition.world.clubs[0];
    final second = composition.world.clubs[1];
    final binding = saveAndOpen(first.id);
    final session = binding.session;
    final pending = session.pendingDecision;
    final originalSessionBytes = session.encodeNewGameBootstrapSnapshot();
    expect(
        composition.saveSlots.save(
          slotId: binding.slotId,
          session: bootstrap(second.id),
        ),
        binding.source);
    expect(binding.inspect()!.controlledClubId, second.id);
    expect(session.preparedSeasonDashboard.controlledClubId, first.id);
    final bytesBefore = saveBytes();

    expect(controller.loadBoundSave(binding), isFalse);

    expectNoAdoptedSession();
    expect(binding.session, same(session));
    expect(session.pendingDecision, same(pending));
    expect(session.encodeNewGameBootstrapSnapshot(), originalSessionBytes);
    expect(saveBytes(), bytesBefore);
    expect(binding.inspect()!.controlledClubId, second.id);
  });

  test('rejected overwritten binding clears existing transient presentation',
      () {
    final first = composition.world.clubs[0];
    final second = composition.world.clubs[1];
    final binding = saveAndOpen(first.id);
    composition.saveSlots
        .save(slotId: binding.slotId, session: bootstrap(second.id));
    controller.startNewGame(composition.world.clubs.last);
    final pending =
        controller.currentStep as PlayerPresidentInteractiveDecisionPending;
    controller.submitChoice(canonicalChoiceForRequest(pending.request));
    expect(controller.awaitingResolution, isTrue);

    expect(controller.loadBoundSave(binding), isFalse);

    expectNoAdoptedSession();
    expect(controller.awaitingResolution, isFalse);
  });

  test(
      'matching real binding adopts the authoritative session and canonical club',
      () {
    final club = composition.world.clubs.first;
    final binding = saveAndOpen(club.id);

    expect(controller.loadBoundSave(binding), isTrue);

    expect(controller.selectedClub, same(club));
    expect(controller.session, same(binding.session));
    expect(controller.preparedSeasonDashboard!.controlledClubId, club.id);
    expect(controller.saveSummary!.controlledClubId, club.id);
    expect(
        (controller.currentStep as PlayerPresidentInteractiveDecisionPending)
            .request
            .clubId,
        club.id);
    expect(controller.binding, same(binding));
    expect(controller.errorMessage, isNull);
  });

  test('same-club overwrite retains the existing M88 bound-session contract',
      () {
    final club = composition.world.clubs.first;
    final binding = saveAndOpen(club.id);
    final boundSession = binding.session;
    final replacement = bootstrap(club.id);
    final pending =
        replacement.advance() as PlayerPresidentInteractiveDecisionPending;
    replacement.submit(
        request: pending.request,
        choice: canonicalChoiceForRequest(pending.request));
    composition.saveSlots.save(slotId: binding.slotId, session: replacement);
    expect(binding.inspect()!.answeredDecisionCount, 1);
    expect(boundSession.answeredDecisionCount, 0);

    expect(controller.loadBoundSave(binding), isTrue);

    expect(controller.session, same(boundSession));
    expect(controller.selectedClub, same(club));
    expect(controller.errorMessage, isNull);
    expect(controller.saveSummary!.controlledClubId, club.id);
  });

  test('rejection leaves same-id checkpoint sibling and unrelated slot intact',
      () {
    final first = composition.world.clubs[0];
    final second = composition.world.clubs[1];
    final binding = saveAndOpen(first.id);
    final checkpoint =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine()
            .simulateWithCheckpoint(
              clubs: composition.world.clubs,
              leagues: composition.world.leagues,
              config: composition.simulationConfig,
              controlledClubId: first.id,
              seasonCount: 1,
              electionInterval: 4,
              hasFutureSeasonAfterReport: true,
            )
            .checkpoint;
    final siblingSource = composition.saveSlots.save(
      slotId: binding.slotId,
      session: PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpoint,
        resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
          seasonCount: 1,
          hasFutureSeasonAfterReport: true,
        ),
      ),
    );
    expect(siblingSource,
        PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint);
    expect(siblingSource, isNot(binding.source));
    final unrelated =
        saveAndOpen(composition.world.clubs.last.id, slotId: 'unrelated');
    composition.saveSlots
        .save(slotId: binding.slotId, session: bootstrap(second.id));
    final before = saveBytes();

    expect(controller.loadBoundSave(binding), isFalse);

    expect(saveBytes(), before);
    expect(
        composition.saveSlots
            .inspect(source: siblingSource, slotId: binding.slotId)!
            .controlledClubId,
        first.id);
    expect(
        unrelated.inspect()!.controlledClubId, composition.world.clubs.last.id);
    expect(binding.inspect()!.controlledClubId, second.id);
    expect(composition.saveSlots.list(), hasLength(3));
  });
}
