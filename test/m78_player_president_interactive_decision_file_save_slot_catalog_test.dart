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
import 'package:test/test.dart';

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

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  late FictionalWorldSetup world;
  late PlayerPresidentTicketPricingRuntimeCheckpoint initial;
  late String controlledClubId;
  late Directory root;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('fbs-m78-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  PlayerPresidentTicketPricingRuntimeCheckpoint cloneCheckpoint() =>
      checkpointCodec.decode(checkpointCodec.encode(initial));

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: cloneCheckpoint(),
        resumeConfig: resumeConfig,
      );

  PlayerPresidentInteractiveDecisionFileSaveSlotStore store() =>
      PlayerPresidentInteractiveDecisionFileSaveSlotStore(
        rootDirectory: root,
      );

  test('M78 inspects a slot into deterministic load-game metadata', () {
    final session = fresh();
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var index = 0; index < 4; index++) {
      step = _answer(session, step);
    }
    final saveStore = store();
    saveStore.save('career-1', session);
    final target = File(
      '${root.path}${Platform.pathSeparator}career-1.fbs.json',
    );
    final encodedBefore = target.readAsStringSync();

    final summary = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: saveStore,
    ).inspect('career-1')!;

    expect(summary.slotId, 'career-1');
    expect(summary.controlledClubId, controlledClubId);
    expect(summary.controlledClubName, world.clubs.first.name);
    expect(summary.completedSeasons, initial.completedSeasons);
    expect(summary.nextSeasonIndex, initial.nextSeasonIndex);
    expect(summary.answeredDecisionCount, 4);
    expect(summary.playerControlActive, isTrue);
    expect(summary.pendingDecisionKind, session.pendingDecision!.kind);
    expect(summary.sessionCompleted, isFalse);
    expect(summary.resumeSeasonCount, 1);
    expect(summary.hasFutureSeasonAfterReport, isTrue);
    expect(target.readAsStringSync(), encodedBefore);
  });

  test('M78 lists summaries in deterministic slot-id order', () {
    final saveStore = store();
    final zSession = fresh();
    var zStep = zSession.advance();
    for (var index = 0; index < 3; index++) {
      zStep = _answer(zSession, zStep);
    }
    saveStore.save('z-slot', zSession);

    final aSession = fresh();
    var aStep = aSession.advance();
    aStep = _answer(aSession, aStep);
    saveStore.save('a-slot', aSession);

    final summaries = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: saveStore,
    ).list();

    expect(summaries.map((item) => item.slotId), <String>['a-slot', 'z-slot']);
    expect(
      summaries.map((item) => item.answeredDecisionCount),
      <int>[1, 3],
    );
    expect(
      summaries.every((item) => item.controlledClubName == world.clubs.first.name),
      isTrue,
    );
  });

  test('M78 summary reflects latest overwrite without metadata sidecar', () {
    final saveStore = store();
    final session = fresh();
    var step = session.advance();
    step = _answer(session, step);
    saveStore.save('career-1', session);
    step = _answer(session, step);
    saveStore.save('career-1', session);

    final summary = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: saveStore,
    ).inspect('career-1')!;
    final names = root
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();

    expect(summary.answeredDecisionCount, 2);
    expect(names, <String>['career-1.fbs.json']);
  });

  test('M78 missing and invalid slot behavior preserves the M77 contract', () {
    final catalog = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: store(),
    );

    expect(catalog.inspect('missing'), isNull);
    expect(() => catalog.inspect('../escape'), throwsArgumentError);
  });

  test('M78 corrupted bundle fails closed instead of exposing stale metadata',
      () {
    final saveStore = store();
    saveStore.save('career-1', fresh());
    File(
      '${root.path}${Platform.pathSeparator}career-1.fbs.json',
    ).writeAsStringSync('{"corrupt":true}', flush: true);

    final catalog = PlayerPresidentInteractiveDecisionFileSaveSlotCatalog(
      store: saveStore,
    );
    expect(
      () => catalog.inspect('career-1'),
      throwsA(isA<SaveLoadException>()),
    );
  });
}
