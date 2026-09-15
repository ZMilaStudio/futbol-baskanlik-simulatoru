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

  late FictionalWorldSetup world;
  late String controlledClubId;
  late Directory root;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('fbs-m82-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

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

  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore store() =>
      PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
        rootDirectory: root,
      );

  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog
      catalog(
    PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore store,
  ) =>
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
            store: store,
            clubs: world.clubs,
            leagues: world.leagues,
          );

  test('M82 inspects a bootstrap slot into deterministic load-game metadata',
      () {
    final session = fresh();
    PlayerPresidentInteractiveSessionStep step = session.advance();
    for (var index = 0; index < 4; index++) {
      step = _answer(session, step);
    }
    final saveStore = store();
    saveStore.save('new-game-1', session);
    final target = File(
      '${root.path}${Platform.pathSeparator}new-game-1.fbs.bootstrap.json',
    );
    final encodedBefore = target.readAsStringSync();

    final summary = catalog(saveStore).inspect('new-game-1')!;

    expect(summary.slotId, 'new-game-1');
    expect(summary.controlledClubId, controlledClubId);
    expect(summary.controlledClubName, world.clubs.first.name);
    expect(summary.initialSeasonIndex, config.seasonIndex);
    expect(summary.careerSeed, seed);
    expect(summary.simulationVersion, config.simulationVersion);
    expect(summary.answeredDecisionCount, 4);
    expect(summary.pendingDecisionKind, session.pendingDecision!.kind);
    expect(summary.sessionCompleted, isFalse);
    expect(summary.resumeSeasonCount, 1);
    expect(summary.hasFutureSeasonAfterReport, isTrue);
    expect(summary.electionInterval, 4);
    expect(target.readAsStringSync(), encodedBefore);
  });

  test('M82 lists summaries in deterministic order and reflects overwrite', () {
    final saveStore = store();

    final zSession = fresh();
    var zStep = zSession.advance();
    zStep = _answer(zSession, zStep);
    zStep = _answer(zSession, zStep);
    saveStore.save('z-slot', zSession);

    final aSession = fresh();
    var aStep = aSession.advance();
    aStep = _answer(aSession, aStep);
    saveStore.save('a-slot', aSession);

    zStep = _answer(zSession, zStep);
    saveStore.save('z-slot', zSession);

    final summaries = catalog(saveStore).list();
    final names = root
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList()
      ..sort();

    expect(summaries.map((item) => item.slotId), <String>['a-slot', 'z-slot']);
    expect(summaries.map((item) => item.answeredDecisionCount), <int>[1, 3]);
    expect(
      names,
      <String>[
        'a-slot.fbs.bootstrap.json',
        'z-slot.fbs.bootstrap.json',
      ],
    );
  });

  test('M82 missing and invalid slot behavior preserves the M81 contract', () {
    final saveStore = store();
    final loadCatalog = catalog(saveStore);

    expect(loadCatalog.inspect('missing'), isNull);
    expect(() => loadCatalog.inspect('../escape'), throwsArgumentError);
  });

  test('M82 corrupt bytes and divergent supplied world both fail closed', () {
    final saveStore = store();
    saveStore.save('new-game-1', fresh());
    final target = File(
      '${root.path}${Platform.pathSeparator}new-game-1.fbs.bootstrap.json',
    );
    target.writeAsStringSync('{"corrupt":true}', flush: true);

    expect(
      () => catalog(saveStore).inspect('new-game-1'),
      throwsA(isA<SaveLoadException>()),
    );

    saveStore.save('new-game-1', fresh());
    final divergentClubs = List<Club>.of(world.clubs);
    divergentClubs[0] = divergentClubs[0].copyWith(
      strength: divergentClubs[0].strength + 0.5,
    );
    final divergentCatalog =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotCatalog(
      store: saveStore,
      clubs: divergentClubs,
      leagues: world.leagues,
    );
    expect(
      () => divergentCatalog.inspect('new-game-1'),
      throwsA(
        predicate<SaveLoadException>(
          (error) => error.failure == SaveLoadFailure.invalidPayload,
        ),
      ),
    );
  });

  test('M82 catalog stays isolated from the M77 checkpoint namespace', () {
    final saveStore = store();
    saveStore.save('bootstrap-only', fresh());
    final checkpointFile = File(
      '${root.path}${Platform.pathSeparator}checkpoint-only.fbs.json',
    )..writeAsStringSync('checkpoint-bytes-must-stay-untouched', flush: true);
    final checkpointBefore = checkpointFile.readAsStringSync();

    final summaries = catalog(saveStore).list();

    expect(summaries.map((item) => item.slotId), <String>['bootstrap-only']);
    expect(saveStore.contains('checkpoint-only'), isFalse);
    expect(checkpointFile.readAsStringSync(), checkpointBefore);
  });
}
