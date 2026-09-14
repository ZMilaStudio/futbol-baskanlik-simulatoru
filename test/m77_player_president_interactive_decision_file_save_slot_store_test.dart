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
    root = Directory.systemTemp.createTempSync('fbs-m77-');
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

  test('M77 file slot survives a fresh store instance at exact pending request',
      () {
    final session = fresh();
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var index = 0; index < 4; index++) {
      step = _answer(session, step);
    }
    final pendingBefore =
        (step as PlayerPresidentInteractiveDecisionPending).request.key;
    final encodedBefore = session.encodePersistenceBundle();

    PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    ).save('career-1', session);

    final restored = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    ).load('career-1')!;
    final pendingAfter =
        restored.advance() as PlayerPresidentInteractiveDecisionPending;

    expect(pendingAfter.request.key, pendingBefore);
    expect(restored.answeredDecisionCount, 4);
    expect(restored.encodePersistenceBundle(), encodedBefore);
  });

  test('M77 overwrite keeps only the latest exact M75 bundle', () {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();
    var step = session.advance();
    step = _answer(session, step);
    store.save('career-1', session);

    step = _answer(session, step);
    store.save('career-1', session);

    final restored = store.load('career-1')!;
    expect(restored.answeredDecisionCount, 2);
    expect(restored.encodePersistenceBundle(), session.encodePersistenceBundle());
    expect(store.listSlotIds(), <String>['career-1']);
  });

  test('M77 rejects path traversal and invalid slot identifiers', () {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();

    for (final slotId in <String>['', '../escape', 'a/b', r'a\b', 'two words']) {
      expect(() => store.save(slotId, session), throwsArgumentError);
      expect(() => store.load(slotId), throwsArgumentError);
    }
    expect(root.listSync(), isEmpty);
  });

  test('M77 recovers a committed backup after interrupted replacement', () {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final session = fresh();
    final step = session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(request: step.request, choice: _choiceFor(step.request));
    store.save('career-1', session);

    final target = File(
      '${root.path}${Platform.pathSeparator}career-1.fbs.json',
    );
    final backup = File('${target.path}.bak');
    target.renameSync(backup.path);
    File('${target.path}.tmp').writeAsStringSync('incomplete');

    final restored = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    ).load('career-1')!;

    expect(restored.answeredDecisionCount, 1);
    expect(target.existsSync(), isTrue);
    expect(backup.existsSync(), isFalse);
  });

  test('M77 corrupted target bundle fails closed through M75 validation', () {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    store.save('career-1', fresh());
    File(
      '${root.path}${Platform.pathSeparator}career-1.fbs.json',
    ).writeAsStringSync('{"corrupt":true}', flush: true);

    expect(() => store.load('career-1'), throwsA(isA<SaveLoadException>()));
  });

  test('M77 lists slots deterministically and delete removes slot state', () {
    final store = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    store.save('z-slot', fresh());
    store.save('a-slot', fresh());

    expect(store.listSlotIds(), <String>['a-slot', 'z-slot']);
    expect(store.contains('a-slot'), isTrue);
    expect(store.delete('a-slot'), isTrue);
    expect(store.contains('a-slot'), isFalse);
    expect(store.load('a-slot'), isNull);
    expect(store.listSlotIds(), <String>['z-slot']);
  });
}
