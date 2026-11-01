import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'p2_ar_d0o_active_future_opening_test.dart'
    show firstPrepared, laterPrepared, open;
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_ar_d_future_weekly_runtime_test.dart' show completedFutureApp;

PlayerPresidentOwnedSeasonApplication _start({String clubId = 't1_01'}) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: clubId,
  );
}

PlayerPresidentOwnedSeasonRunning _openWeeks(
    PlayerPresidentOwnedSeasonApplication app) {
  final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
  final choice = pending.request
      .contextAs<PlayerPromiseDecisionContext>()
      .allowedTypes
      .first;
  final resolved = app.submitPromise(expected: pending, choice: choice);
  return app.continueAfterPromise(expected: resolved);
}

PlayerPresidentOwnedSeasonRunning _play(
    PlayerPresidentOwnedSeasonApplication app) {
  var running = _openWeeks(app);
  for (var round = 1; round <= 30; round++) {
    running = app.advanceRound(expected: running);
  }
  return running;
}

PlayerPresidentOwnedSeasonContinuationReady _continue(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonCompletion completed, {
  void Function(PlayerPresidentOwnedSeasonStep)? observe,
  bool replaceManager = false,
}) {
  var step = app.continueToNextSeason(expected: completed);
  observe?.call(step);
  if (step is PlayerPresidentOwnedSeasonTransferPending) {
    step = app.submitTransfer(
      expected: step,
      choice: PlayerTransferStrategyChoice.fromProfile(step.context.aiProfile),
    );
    observe?.call(step);
  }
  if (step is PlayerPresidentOwnedSeasonManagerReviewPending) {
    step = app.submitManagerReview(
      expected: step,
      choice: replaceManager || !step.context.canRetain
          ? PlayerManagerReviewChoice.replace
          : PlayerManagerReviewChoice.retain,
    );
    observe?.call(step);
  }
  if (step is PlayerPresidentOwnedSeasonManagerReplacementPending) {
    step = app.submitManagerReplacement(
      expected: step,
      selected: step.context.candidates.first.manager,
    );
    observe?.call(step);
  }
  return step as PlayerPresidentOwnedSeasonContinuationReady;
}

PlayerPresidentOwnedSeasonApplication _firstFuture() {
  final app = _start();
  final historical = app.closeSeason(expected: _play(app));
  app.activateNextSeason(expected: _continue(app, historical));
  return app;
}

PlayerPresidentOwnedFutureSeasonSettled _settle(
    PlayerPresidentOwnedSeasonApplication app,
    PlayerPresidentOwnedSeasonRunning w30) {
  final step = app.completeFutureSeason(expected: w30);
  if (step is PlayerPresidentOwnedSeasonTicketPending) {
    return app.submitTicket(
      expected: step,
      choice:
          const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
    );
  }
  return step as PlayerPresidentOwnedFutureSeasonSettled;
}

void _expectOracle(PlayerPresidentInteractiveDecisionApplicationSession app) {
  final source = open(app);
  final snapshot = app.preparedSeasonOpening;
  final world = source.opening;
  final prepared = source.prepared;
  final id = source.controlledClubId;
  final dashboard = snapshot.dashboard;
  final president = source.admission.sourceGraph.crisisEvidence.presidentClubs
      .singleWhere((club) => club.clubId == id);
  final assignment = source.managerAuthority.assignments[id]!;
  final sponsors = prepared.openingSponsor.activeContracts.where((contract) =>
      contract.offer.clubId == id && contract.isActiveAt(world.seasonIndex));

  expect(snapshot, same(source.preparedSeasonOpening));
  expect(snapshot.controlledClubId, id);
  expect(snapshot.seasonIndex, world.seasonIndex);
  expect(dashboard.league,
      same(world.leagues.singleWhere((league) => league.clubIds.contains(id))));
  expect(dashboard.finance,
      same(world.financeStates.singleWhere((state) => state.clubId == id)));
  expect(dashboard.presidentTenure, same(president.tenure));
  expect(dashboard.playerControl, same(source.control));
  expect(dashboard.fanOverallTrust, president.fanReputation.overallTrust);
  expect(dashboard.managerAssignment, same(assignment));
  expect(
      dashboard.manager,
      same(source.managerAuthority.managers
          .singleWhere((manager) => manager.id == assignment.managerId)));
  expect(
      dashboard.academyFacility,
      same(prepared.facilities.academyFacilities
          .singleWhere((state) => state.clubId == id)));
  expect(
      dashboard.stadiumFacility,
      same(prepared.facilities.stadiumFacilities
          .singleWhere((state) => state.clubId == id)));
  expect(
      dashboard.trainingGroundFacility,
      same(prepared.facilities.trainingGroundFacilities
          .singleWhere((state) => state.clubId == id)));
  expect(dashboard.activeSponsor,
      sponsors.isEmpty ? isNull : same(sponsors.single));

  final actualPlayers =
      world.players.where((player) => player.clubId == id).toList();
  expect(snapshot.squad.players.map((player) => player.playerId).toSet(),
      actualPlayers.map((player) => player.id).toSet());
  for (final row in snapshot.squad.players) {
    final actual =
        actualPlayers.singleWhere((player) => player.id == row.playerId);
    expect(row.name, actual.name);
    expect(row.position, actual.position);
    expect(row.age, actual.age);
    expect(row.ability, actual.ability);
    expect(row.potential, actual.potential);
    expect(row.isAcademyGraduate, actual.isAcademyGraduate);
  }
  final actualFixtures = source.w0.fixtures.where((entry) =>
      entry.tier == dashboard.leagueTier &&
      (entry.fixture.homeClubId == id || entry.fixture.awayClubId == id));
  expect(snapshot.fixtures.fixtures, hasLength(30));
  expect(snapshot.fixtures.leagueTier, dashboard.leagueTier);
  expect(snapshot.fixtures.fixtures.where((row) => row.isHome), hasLength(15));
  for (final row in snapshot.fixtures.fixtures) {
    final actual = actualFixtures
        .singleWhere((entry) => entry.fixture.id == row.fixtureId)
        .fixture;
    final home = actual.homeClubId == id;
    expect(row.round, actual.round);
    expect(row.isHome, home);
    expect(row.opponentClubId, home ? actual.awayClubId : actual.homeClubId);
  }
  expect(snapshot.fixtures.fixtures.map((row) => row.round),
      List<int>.generate(30, (index) => index + 1));
}

void main() {
  test('initial composite preserves the exact existing prepared observations',
      () {
    for (final id in ['t1_01', 't2_01', 't3_01']) {
      final app = _start(clubId: id);
      final snapshot = app.currentSeasonOpening;
      expect(snapshot.seasonIndex, 0);
      expect(snapshot.controlledClubId, id);
      expect(snapshot.dashboard, same(app.preparedSeasonDashboard));
      expect(snapshot.squad, same(app.preparedSquad));
      expect(snapshot.fixtures, same(app.preparedSeasonFixtures));
      expect(snapshot.squad.seasonIndex, snapshot.seasonIndex);
      expect(snapshot.fixtures.seasonIndex, snapshot.seasonIndex);
      expect(snapshot.fixtures.leagueTier, snapshot.dashboard.leagueTier);
      expect(app.currentSeasonOpening, same(snapshot));
      expect(snapshot.signature,
          '${snapshot.dashboard.signature}||${snapshot.squad.signature}||${snapshot.fixtures.signature}');
    }
  });

  test('future opening selects exact admitted dashboard, squad and W0 fixtures',
      () {
    _expectOracle(firstPrepared());
  });

  test('later origin selects its actual continued sponsor and manager sources',
      () {
    final app = laterPrepared(B3B1LegacyClosing());
    _expectOracle(app);
    expect(
        app.futureRuntimeAdmission!.prepared.openingSponsor.totalRevenuePaid
            .units,
        greaterThan(0));
    expect(app.activeFutureSeasonOpening!.managerAuthority.seasons, isNotEmpty);
  });

  test(
      'reading and reopening observations does not execute sponsor, ticket or a round',
      () {
    final app = firstPrepared();
    final prepared = app.futureRuntimeAdmission!.prepared;
    final opening = open(app);
    final snapshot = app.preparedSeasonOpening;
    final signature = snapshot.signature;
    final sponsor = prepared.openingSponsor;
    final w0 = opening.w0;
    final pending = opening.promisePending;
    for (var read = 0; read < 10; read++) {
      expect(app.preparedSeasonOpening, same(snapshot));
      expect(open(app).preparedSeasonOpening, same(snapshot));
      expect(snapshot.signature, signature);
    }
    expect(prepared.openingSponsor, same(sponsor));
    expect(prepared.openingSponsor.totalRevenuePaid, Money.zero);
    expect(prepared.sponsorProcessedClubCount, 0);
    expect(prepared.sponsorSeasonRevenue, Money.zero);
    expect(prepared.ticketDecisionCount, 0);
    expect(app.activeFutureSeasonOpening!.w0, same(w0));
    expect(w0.nextRound, 1);
    expect(w0.completedMatchCount, 0);
    expect(app.activeFutureSeasonOpening!.promisePending, same(pending));
    expect(app.futureWeeklyState, isNull);
    expect(app.futureEconomyAuthority, isNull);
    expect(app.answeredDecisionCount, 0);
  });

  test(
      'public opening stays fixed through acceptance, weeks, settlement and postseason',
      () {
    final app = _firstFuture();
    final snapshot = app.currentSeasonOpening;
    final signature = snapshot.signature;
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final resolved = app.submitPromise(
      expected: pending,
      choice: pending.request
          .contextAs<PlayerPromiseDecisionContext>()
          .allowedTypes
          .first,
    );
    expect(app.currentSeasonOpening, same(snapshot));
    var running = app.continueAfterPromise(expected: resolved);
    for (var round = 1; round <= 30; round++) {
      running = app.advanceRound(expected: running);
      expect(app.currentSeasonOpening, same(snapshot));
      expect(snapshot.signature, signature);
    }
    final completion = app.completeFutureSeason(expected: running);
    expect(app.currentSeasonOpening, same(snapshot));
    final settled = completion is PlayerPresidentOwnedSeasonTicketPending
        ? app.submitTicket(
            expected: completion,
            choice: const MatchdayTicketPricingChoice(
                MatchdayTicketPriceTier.balanced))
        : completion as PlayerPresidentOwnedFutureSeasonSettled;
    expect(app.currentSeasonOpening, same(snapshot));
    final ready = _continue(app, settled, replaceManager: true, observe: (_) {
      expect(app.currentSeasonOpening, same(snapshot));
      expect(snapshot.signature, signature);
    });
    expect(app.currentSeasonOpening, same(snapshot));
    app.activateNextSeason(expected: ready);
    expect(app.currentSeasonOpening.seasonIndex, 2);
    expect(app.currentSeasonOpening, isNot(same(snapshot)));
    expect(snapshot.signature, signature);
    expect(snapshot.seasonIndex, 1);
  });

  test('future two reflects the exact explicitly selected replacement manager',
      () {
    final app = _firstFuture();
    final first = app.currentSeasonOpening;
    final firstSignature = first.signature;
    final settled = _settle(app, _play(app));
    var step = app.continueToNextSeason(expected: settled);
    if (step is PlayerPresidentOwnedSeasonTransferPending) {
      step = app.submitTransfer(
          expected: step,
          choice:
              PlayerTransferStrategyChoice.fromProfile(step.context.aiProfile));
    }
    final review = step as PlayerPresidentOwnedSeasonManagerReviewPending;
    expect(review.context.currentManager.id, first.dashboard.manager.id);
    final replacement = app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.replace)
        as PlayerPresidentOwnedSeasonManagerReplacementPending;
    final selected = replacement.context.candidates.first.manager;
    final ready = app.submitManagerReplacement(
        expected: replacement,
        selected: selected) as PlayerPresidentOwnedSeasonContinuationReady;
    expect(app.currentSeasonOpening, same(first));
    app.activateNextSeason(expected: ready);
    final second = app.currentSeasonOpening;
    expect(second.seasonIndex, 2);
    expect(second.dashboard.manager, same(selected));
    expect(second.dashboard.managerAssignment.managerId, selected.id);
    expect(second.squad.seasonIndex, 2);
    expect(second.fixtures.seasonIndex, 2);
    expect(first.signature, firstSignature);
    expect(first.dashboard.manager.id, isNot(selected.id));
    final w0 = _openWeeks(app);
    final id = second.controlledClubId;
    for (final row in second.fixtures.fixtures) {
      final actual = w0.fixtures.fixtures.singleWhere((fixture) =>
          fixture.tier == second.dashboard.leagueTier &&
          fixture.fixture.id == row.fixtureId);
      expect(actual.round, row.round);
      expect(actual.fixture.homeClubId == id, row.isHome);
      expect(row.opponentClubId,
          row.isHome ? actual.fixture.awayClubId : actual.fixture.homeClubId);
    }
  });

  test('old initial getters remain historical while current opening advances',
      () {
    final app = _start();
    final initial = app.currentSeasonOpening;
    final signature = initial.signature;
    final historical = app.closeSeason(expected: _play(app));
    expect(app.currentSeasonOpening, same(initial));
    app.activateNextSeason(expected: _continue(app, historical));
    final first = app.currentSeasonOpening;
    expect(first.seasonIndex, 1);
    expect(first.squad.signature, isNot(initial.squad.signature));
    expect(first.squad.players.map((player) => player.playerId).toList(),
        isNot(initial.squad.players.map((player) => player.playerId).toList()));
    app.activateNextSeason(expected: _continue(app, _settle(app, _play(app))));
    expect(app.currentSeasonOpening.seasonIndex, 2);
    expect(app.preparedSeasonDashboard, same(initial.dashboard));
    expect(app.preparedSquad, same(initial.squad));
    expect(app.preparedSeasonFixtures, same(initial.fixtures));
    expect(initial.signature, signature);
    expect(initial.seasonIndex, 0);
  });

  test('opening component collections cannot mutate the current observation',
      () {
    final app = _firstFuture();
    final snapshot = app.currentSeasonOpening;
    final signature = snapshot.signature;
    expect(() => snapshot.squad.players.clear(), throwsUnsupportedError);
    expect(() => snapshot.fixtures.fixtures.clear(), throwsUnsupportedError);
    expect(() => snapshot.dashboard.league.clubIds.clear(),
        throwsUnsupportedError);
    expect(app.currentSeasonOpening.signature, signature);
    expect(app.currentSeasonOpening, same(snapshot));
    expect(_openWeeks(app).completedMatchCount, 0);
    expect(app.currentSeasonOpening.signature, signature);
  });

  test('same accepted career choices produce the same opening observations',
      () {
    final first = _firstFuture();
    final second = _firstFuture();
    expect(first.currentSeasonOpening.signature,
        second.currentSeasonOpening.signature);
    expect(
        first.currentSeasonOpening, isNot(same(second.currentSeasonOpening)));
    expect(first.currentSeasonOpening.seasonIndex, 1);
  });

  test(
      'between-epoch activation retains last opening until a new one publishes',
      () {
    final app = completedFutureApp();
    final oldOpening = app.activeFutureSeasonOpening!;
    final oldSnapshot = app.preparedSeasonOpening;
    final oldSignature = oldSnapshot.signature;
    expect(oldSnapshot.seasonIndex, 1);

    // Genuine settled W30 and its original annual graph authorize the epoch.
    // No restored controller or reconstructed continuation is used here.
    final committed =
        app.commitFutureSeason(expectedW30: app.futureWeeklyState!);
    final economy = app.handoffFutureEconomy(expectedCommitted: committed);
    if (economy.prepareSettlement(committed.capability) ==
        RuntimeEconomyState.awaitingTicketDecision) {
      economy.submitTicket(
        economy.pending!,
        const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
        expectedRevision: economy.revision,
      );
    }
    final settlement =
        economy.executeSettlement(expectedCommitted: committed.capability);
    final transition = app.startFuturePostseasonTransition(
      expectedSettlement: settlement,
      hasNextSeason: true,
    );
    final transfer = transition.prepareTransfer();
    if (transfer != null) {
      transition.submitTransfer(
        expectedPending: transfer,
        choice: PlayerTransferStrategyChoice.fromProfile(
            transfer.context.aiProfile),
      );
    }
    transition.prepareDomain();
    transition.prepareOuterSuccessor();
    final manager = transition.managerPending;
    if (manager != null) {
      final replacement = manager.replacement != null
          ? manager
          : transition.submitManagerReview(
              expectedPending: manager,
              choice: manager.review.canRetain
                  ? PlayerManagerReviewChoice.retain
                  : PlayerManagerReviewChoice.replace,
            );
      if (replacement != null) {
        transition.submitManagerReplacement(
          expectedPending: replacement,
          selected: replacement.replacement!.candidates.first.manager,
        );
      }
    }
    final graph =
        app.publishFuturePostseasonContinuation(expectedTransition: transition);
    app.activateNextFutureSeason(expectedContinuation: graph);
    expect(app.activeFutureSeasonOpening, isNull);
    expect(app.preparedSeasonOpening, same(oldSnapshot));
    expect(app.preparedSeasonOpening.seasonIndex, 1);
    expect(app.preparedSeasonOpening.signature, oldSignature);

    expect(
        () => app.openFutureSeason(
              expectedAdmission: oldOpening.admission,
              expectedPrepared: oldOpening.prepared,
            ),
        throwsStateError);
    expect(app.activeFutureSeasonOpening, isNull);
    expect(app.preparedSeasonOpening, same(oldSnapshot));

    final entry = app.claimFutureRuntimeEntry(
      expectedSource: graph,
      expectedSourceRevision: graph.revision,
      expectedOrigin: graph.origin,
      expectedTargetSeason: graph.targetSeasonIndex,
    );
    final prepared = app.prepareFutureRuntime(expectedEntry: entry);
    expect(app.preparedSeasonOpening, same(oldSnapshot));
    final foreignApp = firstPrepared();
    final foreignAdmission = foreignApp.futureRuntimeAdmission!;
    expect(
        () => app.openFutureSeason(
              expectedAdmission: foreignAdmission,
              expectedPrepared: foreignAdmission.prepared,
            ),
        throwsStateError);
    expect(app.preparedSeasonOpening, same(oldSnapshot));
    expect(app.activeFutureSeasonOpening, isNull);

    final opening = app.openFutureSeason(
      expectedAdmission: app.futureRuntimeAdmission!,
      expectedPrepared: prepared,
    );
    expect(app.preparedSeasonOpening, same(opening.preparedSeasonOpening));
    expect(app.preparedSeasonOpening.seasonIndex, 2);
    expect(app.preparedSeasonOpening, isNot(same(oldSnapshot)));
    expect(oldSnapshot.signature, oldSignature);
    expect(oldSnapshot.seasonIndex, 1);
  });
}
