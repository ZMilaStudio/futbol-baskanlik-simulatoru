import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
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
  final initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(initial)),
        resumeConfig: resumeConfig,
      );

  PlayerPresidentInteractiveDecisionApplicationSession bootstrapSession() =>
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

  final root = Directory.systemTemp.createTempSync('fbs-m83-canonical-');
  try {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );

    final checkpoint = checkpointSession();
    var checkpointStep = checkpoint.advance();
    checkpointStep = _answer(checkpoint, checkpointStep);
    checkpointStep = _answer(checkpoint, checkpointStep);
    checkpoints.save('shared', checkpoint);

    final bootstrap = bootstrapSession();
    var bootstrapStep = bootstrap.advance();
    for (var index = 0; index < 3; index++) {
      bootstrapStep = _answer(bootstrap, bootstrapStep);
    }
    bootstraps.save('shared', bootstrap);

    final secondaryBootstrap = bootstrapSession();
    var secondaryStep = secondaryBootstrap.advance();
    secondaryStep = _answer(secondaryBootstrap, secondaryStep);
    bootstraps.save('z-slot', secondaryBootstrap);

    final checkpointFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.json',
    );
    final bootstrapFile = File(
      '${root.path}${Platform.pathSeparator}shared.fbs.bootstrap.json',
    );
    final checkpointBefore = checkpointFile.readAsStringSync();
    final bootstrapBefore = bootstrapFile.readAsStringSync();

    final checkpointCatalog = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: checkpoints,
    );
    final bootstrapCatalog =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
      store: bootstraps,
      clubs: world.clubs,
      leagues: world.leagues,
    );
    final catalog = PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog(
      checkpointCatalog: checkpointCatalog,
      bootstrapCatalog: bootstrapCatalog,
    );
    final summaries = catalog.list();

    final deterministicOrder = summaries.map((item) => item.identity).join(',') ==
        'checkpoint:shared,newGameBootstrap:shared,newGameBootstrap:z-slot';
    final collisionPreserved = summaries.length == 3 &&
        summaries.where((item) => item.slotId == 'shared').length == 2;
    final readOnly = checkpointFile.readAsStringSync() == checkpointBefore &&
        bootstrapFile.readAsStringSync() == bootstrapBefore;

    final mixedCheckpoint = catalog.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'shared',
    )!;
    final mixedBootstrap = catalog.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'shared',
    )!;
    final metadataExact = mixedCheckpoint.answeredDecisionCount == 2 &&
        mixedBootstrap.answeredDecisionCount == 3 &&
        mixedCheckpoint.checkpointSummary?.signature ==
            checkpointCatalog.inspect('shared')?.signature &&
        mixedBootstrap.bootstrapSummary?.signature ==
            bootstrapCatalog.inspect('shared')?.signature &&
        mixedCheckpoint.controlledClubId == controlledClubId &&
        mixedBootstrap.controlledClubId == controlledClubId;

    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    final divergentCatalog = PlayerPresidentInteractiveDecisionMixedFileSaveSlotCatalog(
      checkpointCatalog: checkpointCatalog,
      bootstrapCatalog:
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
        store: bootstraps,
        clubs: divergentClubs,
        leagues: world.leagues,
      ),
    );
    var worldGuard = false;
    try {
      divergentCatalog.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      );
    } on SaveLoadException catch (error) {
      worldGuard = error.failure == SaveLoadFailure.invalidPayload;
    }

    final names = root
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();
    final namespacesSeparate = checkpoints.contains('shared') &&
        bootstraps.contains('shared') &&
        names.join(',') ==
            'shared.fbs.bootstrap.json,shared.fbs.json,z-slot.fbs.bootstrap.json';

    if (!deterministicOrder ||
        !collisionPreserved ||
        !readOnly ||
        !metadataExact ||
        !worldGuard ||
        !namespacesSeparate) {
      throw StateError('M83 mixed file save-slot catalog invariant failed.');
    }

    print(
      'M83_PLAYER_PRESIDENT_INTERACTIVE_DECISION_MIXED_FILE_SAVE_SLOT_CATALOG_PASS '
      'controlled=$controlledClubId summaries=${summaries.length} '
      'collisionPreserved=$collisionPreserved deterministicOrder=$deterministicOrder '
      'readOnly=$readOnly metadataExact=$metadataExact worldGuard=$worldGuard '
      'namespacesSeparate=$namespacesSeparate saveAuthority=M65 '
      'checkpointCatalog=M78 bootstrapCatalog=M82 worldClubs=${world.clubs.length} '
      'seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
