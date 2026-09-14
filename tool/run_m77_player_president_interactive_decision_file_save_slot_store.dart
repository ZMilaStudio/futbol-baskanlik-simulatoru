import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
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

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final checkpoint =
      const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
          .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;
  final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
    checkpoint: checkpoint,
    resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
      crisisActivationThreshold: 0,
      candidateLimit: 5,
    ),
  );

  PlayerPresidentInteractiveSessionStep step = session.advance();
  for (var index = 0; index < 4; index++) {
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    step = session.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
  }
  final pendingBefore =
      (step as PlayerPresidentInteractiveDecisionPending).request.key;

  final root = Directory.systemTemp.createTempSync('fbs-m77-canonical-');
  try {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    store.save('career-1', session);
    final encoded = session.encodePersistenceBundle();

    final freshStore = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final restored = freshStore.load('career-1');
    if (restored == null) {
      throw StateError('M77 saved slot was not found.');
    }
    final restoredPending =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;
    if (restoredPending.request.key != pendingBefore ||
        restored.encodePersistenceBundle() != encoded ||
        restored.answeredDecisionCount != 4) {
      throw StateError('M77 disk round-trip parity failed.');
    }

    final target = File(
      '${root.path}${Platform.pathSeparator}career-1.fbs.json',
    );
    final backup = File('${target.path}.bak');
    target.renameSync(backup.path);
    File('${target.path}.tmp').writeAsStringSync('interrupted');
    final recovered = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    ).load('career-1');
    if (recovered == null ||
        recovered.encodePersistenceBundle() != encoded ||
        !target.existsSync() ||
        backup.existsSync()) {
      throw StateError('M77 interrupted replacement recovery failed.');
    }

    var invalidBlocked = false;
    try {
      store.load('../escape');
    } on ArgumentError {
      invalidBlocked = true;
    }
    if (!invalidBlocked) {
      throw StateError('M77 invalid slot id was accepted.');
    }

    print(
      'M77_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_STORE_PASS '
      'controlled=$controlledClubId savedDecisions=4 diskRoundTrip=true '
      'interruptedRecovery=true invalidBlocked=true stableSave=true '
      'atomicBundle=M75 saveAuthority=M65 worldClubs=${world.clubs.length} '
      'seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
