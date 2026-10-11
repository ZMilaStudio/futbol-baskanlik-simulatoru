import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/manager/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'p2_ar_d_future_weekly_runtime_test.dart' show completedFutureApp;

/// Complete the genuine full-M65 future closing, then retain the same
/// application and original production lineage for the next season.
PlayerPresidentActiveFutureSeasonOpening continueOwnedFuture(
    PlayerPresidentInteractiveDecisionApplicationSession app) {
  final oldOpening = app.activeFutureSeasonOpening!;
  final w30 = app.futureWeeklyState!;
  expect(w30.isComplete, isTrue);
  expect(w30.completedMatchCount, 720);
  final committed = app.commitFutureSeason(expectedW30: w30);
  final economy = app.handoffFutureEconomy(expectedCommitted: committed);
  final state = economy.prepareSettlement(committed.capability);
  if (state == RuntimeEconomyState.awaitingTicketDecision) {
    economy.submitTicket(
      economy.pending!,
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
      expectedRevision: economy.revision,
    );
  }
  expect(economy.state, RuntimeEconomyState.ready);
  final settled = economy.executeSettlement(
    expectedCommitted: committed.capability,
  );
  expect(() => economy.executeSettlement(
    expectedCommitted: committed.capability,
  ), throwsStateError);

  final transition = app.startFuturePostseasonTransition(
      expectedSettlement: settled, hasNextSeason: true);
  expect(app.startFuturePostseasonTransition(
      expectedSettlement: settled, hasNextSeason: true), same(transition));
  expect(() => app.startFuturePostseasonTransition(
      expectedSettlement: settled, hasNextSeason: false), throwsStateError);
  final transfer = transition.prepareTransfer();
  if (transfer != null) {
    expect(transition.prepareTransfer(), same(transfer));
    transition.submitTransfer(
      expectedPending: transfer,
      choice: PlayerTransferStrategyChoice.fromProfile(
        transfer.context.aiProfile,
      ),
    );
  }
  transition.prepareDomain();
  transition.prepareOuterSuccessor();
  final manager = transition.managerPending;
  if (manager != null) {
    if (manager.review.canRetain) {
      transition.submitManagerReview(
        expectedPending: manager,
        choice: PlayerManagerReviewChoice.retain,
      );
    } else {
      final replacement = transition.submitManagerReview(
        expectedPending: manager,
        choice: PlayerManagerReviewChoice.replace,
      )!;
      transition.submitManagerReplacement(
        expectedPending: replacement,
        selected: replacement.replacement!.candidates.first.manager,
      );
    }
  }
  final graph = app.publishFuturePostseasonContinuation(
      expectedTransition: transition);
  expect(app.publishFuturePostseasonContinuation(
      expectedTransition: transition), same(graph));
  expect(graph.origin, PostoffseasonRuntimeOrigin.postOffseasonContinuation);
  expect(graph.targetSeasonIndex, oldOpening.targetSeasonIndex + 1);
  expect(graph.managerEvidence.completedSeasons.length,
      oldOpening.managerAuthority.seasons.length + 1);
  expect(graph.worldSuccessor.nextSeasonPlayers, isNotEmpty);
  final oldTransfers = oldOpening.prepared.transferEvidence;
  final oldManagerHistory = oldOpening.managerAuthority.seasons;
  final oldApplication = oldOpening.application;

  app.activateNextFutureSeason(expectedContinuation: graph);
  expect(() => app.activateNextFutureSeason(expectedContinuation: graph),
      throwsStateError);
  expect(app.activeFutureSeasonOpening, isNull);
  expect(app.futureCommittedSeason, isNull);
  expect(app.futureEconomyAuthority, isNull);
  expect(app.preseasonWeeklyState!.completedMatchCount, 720);
  expect(oldOpening.application, same(oldApplication));
  expect(oldOpening.managerAuthority.seasons, same(oldManagerHistory));

  final entry = app.claimFutureRuntimeEntry(
    expectedSource: graph,
    expectedSourceRevision: graph.revision,
    expectedOrigin: graph.origin,
    expectedTargetSeason: graph.targetSeasonIndex,
  );
  final prepared = app.prepareFutureRuntime(expectedEntry: entry);
  expect(app.prepareFutureRuntime(expectedEntry: entry), same(prepared));
  expect(prepared.owner, same(app));
  expect(prepared.opening.seasonIndex, oldOpening.targetSeasonIndex + 1);
  expect(prepared.managerAuthority!.seasons.length,
      oldManagerHistory.length + 1);
  expect(prepared.transferEvidence.activeContracts.any(
      (c) => oldTransfers.activeContracts.any((old) => identical(old, c))),
      isTrue);
  expect(() => app.advanceFutureWeek(
    expectedState: w30, expectedRound: 1,
  ), throwsStateError);
  expect(() => app.openFutureSeason(
    expectedAdmission: oldOpening.admission,
    expectedPrepared: oldOpening.prepared,
  ), throwsStateError);
  final opening = app.openFutureSeason(
    expectedAdmission: app.futureRuntimeAdmission!,
    expectedPrepared: prepared,
  );
  expect(opening.targetSeasonIndex, oldOpening.targetSeasonIndex + 1);
  expect(opening.origin, PostoffseasonRuntimeOrigin.postOffseasonContinuation);
  expect(opening.application, same(app));
  final choice = opening.controlledPromiseContext.allowedTypes.first;
  app.acceptFuturePromise(
    expectedOpening: opening,
    expectedPending: opening.promisePending,
    choice: choice,
  );
  expect(app.futureWeeklyState!.nextRound, 1);
  return opening;
}

void finishFutureWeeks(
    PlayerPresidentInteractiveDecisionApplicationSession app) {
  for (var round = 1; round <= 30; round++) {
    app.advanceFutureWeek(
      expectedState: app.futureWeeklyState!,
      expectedRound: round,
    );
  }
  expect(app.futureWeeklyState!.completedMatchCount, 720);
}

void main() {
  test('original application advances through two genuine future seasons '
      'and re-enters a third without replaying season zero', () {
    final app = completedFutureApp();
    final initial = app.activeFutureSeasonOpening!;
    final legacyB2 = app.acceptedPromiseClosingCandidate!;
    final legacySeason0 = app.preseasonWeeklyState!;
    expect(initial.targetSeasonIndex, 1);
    final second = continueOwnedFuture(app);
    expect(second.targetSeasonIndex, 2);
    expect(app.acceptedPromiseClosingCandidate, same(legacyB2));
    expect(app.preseasonWeeklyState, same(legacySeason0));
    finishFutureWeeks(app);
    final third = continueOwnedFuture(app);
    expect(third.targetSeasonIndex, 3);
    expect(third.managerAuthority.seasons.length, 2);
    expect(third.application, same(app));
    expect(app.acceptedPromiseClosingCandidate, same(legacyB2));
    expect(app.preseasonWeeklyState, same(legacySeason0));
  });
}
