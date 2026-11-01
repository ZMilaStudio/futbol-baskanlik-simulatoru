import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:test/test.dart';

import 'p2_ar_d0o_active_future_opening_test.dart'
    show firstPrepared, laterPrepared;
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;

(
  PlayerPresidentInteractiveDecisionApplicationSession,
  LosslessPostOffseasonRuntimeGraph
) _historicalGraph(String clubId) {
  final world = const FictionalWorldFactory().build();
  final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: clubId,
    seasonCount: 1,
    electionInterval: 1,
    hasFutureSeasonAfterReport: true,
  );
  final boundary = app.startPreseasonPromise(
      sourceClubs: world.clubs, sourceLeagues: world.leagues);
  final pending = boundary.pending!;
  boundary.submit(pending: pending, choice: pending.context.allowedTypes.first);
  var weekly = app.openPreseasonWeeklyHandoff();
  for (var round = 1; round <= 30; round++) {
    weekly =
        app.advancePreseasonWeek(expectedState: weekly, expectedRound: round);
  }
  final b1 = app.projectCommittedSeason(expectedState: weekly);
  final b2 = app.closeAcceptedPromises(expectedResultCandidate: b1);
  final transition = app.startPostseasonTransition(expectedSource: b2);
  _completePostseason(transition);
  return (
    app,
    app.publishPostseasonContinuation(expectedTransition: transition)
  );
}

void _completePostseason(SinglePassPostseasonRuntimeTransition transition) {
  final transfer = transition.prepareTransfer();
  if (transfer != null) {
    transition.submitTransfer(
      expectedPending: transfer,
      choice:
          PlayerTransferStrategyChoice.fromProfile(transfer.context.aiProfile),
    );
  }
  transition.prepareDomain();
  transition.prepareOuterSuccessor();
  final review = transition.managerPending;
  if (review == null) return;
  var replacement = review.replacement == null ? null : review;
  if (replacement == null) {
    replacement = transition.submitManagerReview(
      expectedPending: review,
      choice: review.review.canRetain
          ? PlayerManagerReviewChoice.retain
          : PlayerManagerReviewChoice.replace,
    );
  }
  if (replacement != null) {
    transition.submitManagerReplacement(
      expectedPending: replacement,
      selected: replacement.replacement!.candidates.first.manager,
    );
  }
}

PreparedTicketRuntimeSeason _admit(
    PlayerPresidentInteractiveDecisionApplicationSession app,
    LosslessPostOffseasonRuntimeGraph graph) {
  final entry = app.claimFutureRuntimeEntry(
    expectedSource: graph,
    expectedSourceRevision: graph.revision,
    expectedOrigin: graph.origin,
    expectedTargetSeason: graph.targetSeasonIndex,
  );
  return app.prepareFutureRuntime(expectedEntry: entry);
}

void _expectLostOpeningRejected(
    PlayerPresidentInteractiveDecisionApplicationSession app,
    LosslessPostOffseasonRuntimeGraph graph) {
  expect(graph.control.lost, isTrue);
  final incumbent = graph.crisisEvidence.presidentClubs
      .singleWhere((club) => club.clubId == graph.control.controlledClubId);
  expect(incumbent.tenure.president.id, graph.control.successorPresidentId);
  expect(incumbent.tenure.president.id, isNot(graph.control.playerPresidentId));
  final observed = app.preparedSeasonOpening;
  final observedSignature = observed.signature;
  final historical = app.acceptedPromiseClosingCandidate;
  final historicalWeeks = app.preseasonWeeklyState;

  // Genuine uncontrolled runtime preparation remains available after loss.
  final prepared = _admit(app, graph);
  final admission = app.futureRuntimeAdmission!;
  final sponsor = prepared.openingSponsor;
  expect(prepared.tenureControl, same(graph.control));
  expect(prepared.state, PreparedExecutionState.prepared);
  for (var attempt = 0; attempt < 2; attempt++) {
    expect(
        () => app.openFutureSeason(
              expectedAdmission: admission,
              expectedPrepared: prepared,
            ),
        throwsStateError);
    expect(app.activeFutureSeasonOpening, isNull);
    expect(app.futurePromiseApplied, isNull);
    expect(app.futureWeeklyState, isNull);
    expect(app.futureCommittedSeason, isNull);
    expect(app.futureEconomyAuthority, isNull);
    expect(app.preparedSeasonOpening, same(observed));
    expect(observed.signature, observedSignature);
    expect(app.acceptedPromiseClosingCandidate, same(historical));
    expect(app.preseasonWeeklyState, same(historicalWeeks));
    expect(prepared.openingSponsor, same(sponsor));
    expect(prepared.sponsorProcessedClubCount, 0);
    expect(prepared.sponsorSeasonRevenue, Money.zero);
    expect(prepared.ticketDecisionCount, 0);
    expect(prepared.state, PreparedExecutionState.prepared);
    expect(app.futureRuntimeAdmission, same(admission));
    expect(graph.admissionState, FutureRuntimeAdmissionState.prepared);
  }
}

void main() {
  test(
      'real historical presidency loss cannot mint a first-future player Pending',
      () {
    final (app, graph) = _historicalGraph('t1_16');
    expect(graph.origin, PostoffseasonRuntimeOrigin.firstFutureBootstrap);
    expect(graph.managerEvidence.completedSeasons, isEmpty);
    _expectLostOpeningRejected(app, graph);
  });

  test('real future turnover cannot reopen player control in a later epoch',
      () {
    final (app, firstGraph) = _historicalGraph('t3_16');
    expect(firstGraph.control.active, isTrue);
    final prepared = _admit(app, firstGraph);
    final opening = app.openFutureSeason(
        expectedAdmission: app.futureRuntimeAdmission!,
        expectedPrepared: prepared);
    app.acceptFuturePromise(
      expectedOpening: opening,
      expectedPending: opening.promisePending,
      choice: opening.controlledPromiseContext.allowedTypes.first,
    );
    for (var round = 1; round <= 30; round++) {
      app.advanceFutureWeek(
          expectedState: app.futureWeeklyState!, expectedRound: round);
    }
    final committed =
        app.commitFutureSeason(expectedW30: app.futureWeeklyState!);
    final economy = app.handoffFutureEconomy(expectedCommitted: committed);
    economy.prepareSettlement(committed.capability);
    economy.submitTicket(
      economy.pending!,
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
      expectedRevision: economy.revision,
    );
    final settled =
        economy.executeSettlement(expectedCommitted: committed.capability);
    final transition = app.startFuturePostseasonTransition(
        expectedSettlement: settled, hasNextSeason: true);
    _completePostseason(transition);
    final graph =
        app.publishFuturePostseasonContinuation(expectedTransition: transition);
    expect(graph.origin, PostoffseasonRuntimeOrigin.postOffseasonContinuation);
    expect(graph.control.lost, isTrue);
    expect(
        graph.managerEvidence.completedSeasons
            .map((season) => season.seasonIndex),
        [1]);
    final lastOpening = app.preparedSeasonOpening;
    app.activateNextFutureSeason(expectedContinuation: graph);
    expect(app.preparedSeasonOpening, same(lastOpening));
    _expectLostOpeningRejected(app, graph);
    expect(
        () => app.acceptFuturePromise(
              expectedOpening: opening,
              expectedPending: opening.promisePending,
              choice: opening.controlledPromiseContext.allowedTypes.first,
            ),
        throwsStateError);
    expect(app.futurePromiseApplied, isNull);
    expect(app.futureWeeklyState, isNull);
  });

  for (final origin in ['first future', 'later continuation']) {
    test('active $origin keeps genuine player opening and acceptance', () {
      final app = origin == 'first future'
          ? firstPrepared()
          : laterPrepared(B3B1LegacyClosing());
      final admission = app.futureRuntimeAdmission!;
      final opening = app.openFutureSeason(
          expectedAdmission: admission, expectedPrepared: admission.prepared);
      final incumbent = admission.sourceGraph.crisisEvidence.presidentClubs
          .singleWhere((club) => club.clubId == opening.controlledClubId);
      expect(opening.control.active, isTrue);
      expect(incumbent.tenure.president.id, opening.control.playerPresidentId);
      final accepted = app.acceptFuturePromise(
        expectedOpening: opening,
        expectedPending: opening.promisePending,
        choice: opening.controlledPromiseContext.allowedTypes.first,
      );
      expect(app.futurePromiseApplied, same(accepted));
      expect(app.futureWeeklyState!.completedMatchCount, 0);
      final w1 = app.advanceFutureWeek(
          expectedState: app.futureWeeklyState!, expectedRound: 1);
      expect(w1.completedMatchCount, 24);
      expect(w1.managerAuthority, same(opening.managerAuthority));
    });
  }
}
