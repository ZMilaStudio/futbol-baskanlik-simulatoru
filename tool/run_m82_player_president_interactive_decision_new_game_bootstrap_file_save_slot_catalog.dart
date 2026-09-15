import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

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

  final root = Directory.systemTemp.createTempSync('fbs-m82-run-');
  try {
    final store =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );

    final primary = fresh();
    PlayerPresidentInteractiveSessionStep step = primary.advance();
    for (var index = 0; index < 4; index++) {
      step = _answer(primary, step);
    }
    store.save('new-game-1', primary);
    final primaryFile = File(
      '${root.path}${Platform.pathSeparator}new-game-1.fbs.bootstrap.json',
    );
    final bytesBefore = primaryFile.readAsStringSync();

    final secondary = fresh();
    var secondaryStep = secondary.advance();
    secondaryStep = _answer(secondary, secondaryStep);
    store.save('z-slot', secondary);

    final checkpointFile = File(
      '${root.path}${Platform.pathSeparator}checkpoint-only.fbs.json',
    )..writeAsStringSync('checkpoint-bytes-must-stay-untouched', flush: true);
    final checkpointBefore = checkpointFile.readAsStringSync();

    final catalog =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
      store: store,
      clubs: world.clubs,
      leagues: world.leagues,
    );
    final summaries = catalog.list();
    final primarySummary = catalog.inspect('new-game-1')!;

    final deterministicOrder =
        summaries.map((item) => item.slotId).join(',') == 'new-game-1,z-slot';
    final readOnly = primaryFile.readAsStringSync() == bytesBefore &&
        checkpointFile.readAsStringSync() == checkpointBefore;
    final metadataExact = primarySummary.controlledClubId == controlledClubId &&
        primarySummary.controlledClubName == world.clubs.first.name &&
        primarySummary.careerSeed == seed &&
        primarySummary.answeredDecisionCount == 4 &&
        primarySummary.pendingDecisionKind == primary.pendingDecision?.kind &&
        primarySummary.resumeSeasonCount == 1 &&
        primarySummary.electionInterval == 4;

    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    var worldGuard = false;
    try {
      PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
        store: store,
        clubs: divergentClubs,
        leagues: world.leagues,
      ).inspect('new-game-1');
    } on SaveLoadException catch (error) {
      worldGuard = error.failure == SaveLoadFailure.invalidPayload;
    }

    final m77Isolated = !store.contains('checkpoint-only') &&
        checkpointFile.readAsStringSync() == checkpointBefore;

    if (!deterministicOrder ||
        !readOnly ||
        !metadataExact ||
        !worldGuard ||
        !m77Isolated) {
      throw StateError('M82 bootstrap file save-slot catalog invariant failed.');
    }

    print(
      'M82_PLAYER_PRESIDENT_INTERACTIVE_DECISION_NEW_GAME_BOOTSTRAP_FILE_SAVE_SLOT_CATALOG_PASS '
      'controlled=$controlledClubId summaries=${summaries.length} '
      'primaryAnswers=${primarySummary.answeredDecisionCount} '
      'deterministicOrder=$deterministicOrder readOnly=$readOnly '
      'metadataExact=$metadataExact worldGuard=$worldGuard '
      'm77Isolated=$m77Isolated saveAuthority=M65 replayMetadata=M74 '
      'bootstrap=M80 store=M81 worldClubs=${world.clubs.length} seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
