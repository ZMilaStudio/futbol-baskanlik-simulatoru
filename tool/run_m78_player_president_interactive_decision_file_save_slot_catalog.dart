import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_catalog.dart';
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
  final initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
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

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpointCodec.decode(checkpointCodec.encode(initial)),
        resumeConfig: resumeConfig,
      );

  final root = Directory.systemTemp.createTempSync('fbs-m78-canonical-');
  try {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );

    final aSession = fresh();
    var aStep = aSession.advance();
    aStep = _answer(aSession, aStep);
    store.save('career-a', aSession);
    aStep = _answer(aSession, aStep);
    store.save('career-a', aSession);

    final bSession = fresh();
    PlayerPresidentInteractiveSessionStep bStep = bSession.advance();
    for (var index = 0; index < 4; index++) {
      bStep = _answer(bSession, bStep);
    }
    store.save('career-b', bSession);

    final bTarget = File(
      '${root.path}${Platform.pathSeparator}career-b.fbs.json',
    );
    final bBytesBefore = bTarget.readAsStringSync();
    final catalog = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: store,
    );
    final summaries = catalog.list();
    final bSummary = catalog.inspect('career-b');

    final ordered = summaries.length == 2 &&
        summaries[0].slotId == 'career-a' &&
        summaries[1].slotId == 'career-b';
    final metadata = ordered &&
        summaries[0].controlledClubId == controlledClubId &&
        summaries[0].controlledClubName == world.clubs.first.name &&
        summaries[0].completedSeasons == initial.completedSeasons &&
        summaries[1].answeredDecisionCount == 4 &&
        summaries.every((item) => item.playerControlActive);
    final latestBundle = summaries[0].answeredDecisionCount == 2;
    final nonMutating = bSummary != null &&
        bSummary.answeredDecisionCount == 4 &&
        bTarget.readAsStringSync() == bBytesBefore;
    final missingNull = catalog.inspect('missing') == null;

    if (!ordered ||
        !metadata ||
        !latestBundle ||
        !nonMutating ||
        !missingNull) {
      throw StateError('M78 save-slot catalog acceptance failed.');
    }

    print(
      'M78_PLAYER_PRESIDENT_INTERACTIVE_DECISION_FILE_SAVE_SLOT_CATALOG_PASS '
      'controlled=$controlledClubId slots=2 ordered=true metadata=true '
      'latestBundle=true nonMutating=true missingNull=true '
      'atomicBundle=M75 saveAuthority=M65 worldClubs=${world.clubs.length} '
      'seed=$seed',
    );
  } finally {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
