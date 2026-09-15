import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

Object _choiceFor(PlayerPresidentInteractiveDecisionRequest request) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice.hold;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final context = request.contextAs<PlayerSponsorDecisionContext>();
      return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
    case PlayerPresidentInteractiveDecisionKind.crisis:
      final context = request.contextAs<PlayerCrisisDecisionContext>();
      return PlayerCrisisActionChoice(action: context.aiDecision.action);
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return PlayerManagerReviewChoice.replace;
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      final context = request.contextAs<PlayerManagerReplacementContext>();
      return PlayerManagerReplacementChoice(
        managerId: context.candidates.first.manager.id,
      );
    case PlayerPresidentInteractiveDecisionKind.promise:
      return request.contextAs<PlayerPromiseDecisionContext>().aiPromise.type;
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      return request
          .contextAs<PlayerMediaStatementDecisionContext>()
          .aiStatement
          .stance;
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      final context =
          request.contextAs<PlayerTransferStrategyDecisionContext>();
      return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return request
          .contextAs<PlayerPresidentTicketPricingDecisionContext>()
          .aiChoice;
  }
}

PlayerPresidentInteractiveSessionStep _answer(
  PlayerPresidentInteractiveDecisionApplicationSession session,
  PlayerPresidentInteractiveSessionStep step,
) {
  final pending = step as PlayerPresidentInteractiveDecisionPending;
  return session.submit(
    request: pending.request,
    choice: _choiceFor(pending.request),
  );
}

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final config = SimulationConfig(careerSeed: seed);
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );
  const bootstrapCodec =
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec();
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      );

  final checkpoint =
      const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
          .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(checkpoint)),
        resumeConfig: resumeConfig,
      );

  final root = Directory.systemTemp.createTempSync('fbs-m81-run-');
  try {
    final store =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var index = 0; index < 4; index++) {
      step = _answer(session, step);
    }
    final pendingKey =
        (step as PlayerPresidentInteractiveDecisionPending).request.key;
    final encodedBefore = bootstrapCodec.encode(session.newGameBootstrapSnapshot);

    store.save('new-game-1', session);
    final target = File(
      '${root.path}${Platform.pathSeparator}new-game-1.fbs.bootstrap.json',
    );
    final stableSave = target.readAsStringSync() == encodedBefore;

    final restored =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    ).load(
      slotId: 'new-game-1',
      clubs: world.clubs,
      leagues: world.leagues,
    )!;
    final diskRoundTrip = restored.isNewGame &&
        !restored.canPersist &&
        restored.answeredDecisionCount == 4 &&
        restored.pendingDecision?.key == pendingKey &&
        restored.encodeNewGameBootstrapSnapshot() == encodedBefore;

    final backup = File('${target.path}.bak');
    target.renameSync(backup.path);
    File('${target.path}.tmp').writeAsStringSync('incomplete');
    final recovered =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    ).load(
      slotId: 'new-game-1',
      clubs: world.clubs,
      leagues: world.leagues,
    )!;
    final interruptedRecovery = recovered.answeredDecisionCount == 4 &&
        target.existsSync() &&
        !backup.existsSync();

    var invalidBlocked = false;
    try {
      store.save('checkpoint', checkpointSession());
    } on StateError {
      invalidBlocked = !store.contains('checkpoint');
    }

    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    var worldGuard = false;
    try {
      store.load(
        slotId: 'new-game-1',
        clubs: divergentClubs,
        leagues: world.leagues,
      );
    } on SaveLoadException catch (error) {
      worldGuard = error.failure == SaveLoadFailure.invalidPayload;
    }

    final checkpointStore = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    checkpointStore.save('checkpoint-only', checkpointSession());
    final m77Isolated =
        store.listSlotIds().join(',') == 'new-game-1' &&
            checkpointStore.listSlotIds().join(',') == 'checkpoint-only' &&
            !store.contains('checkpoint-only') &&
            !checkpointStore.contains('new-game-1');

    if (!stableSave ||
        !diskRoundTrip ||
        !interruptedRecovery ||
        !invalidBlocked ||
        !worldGuard ||
        !m77Isolated) {
      throw StateError('M81 bootstrap file save-slot invariant failed.');
    }

    print(
      'M81_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_STORE_PASS '
      'controlled=$controlledClubId savedDecisions=4 '
      'diskRoundTrip=$diskRoundTrip stableSave=$stableSave '
      'interruptedRecovery=$interruptedRecovery invalidBlocked=$invalidBlocked '
      'worldGuard=$worldGuard m77Isolated=$m77Isolated '
      'saveAuthority=M65 replayMetadata=M74 bootstrap=M80 '
      'worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
