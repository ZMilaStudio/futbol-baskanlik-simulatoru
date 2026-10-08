import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/manager/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';
import 'p2_ar_d_future_weekly_runtime_test.dart' show completedFutureApp;
import 'p2_ar_d0t_lossless_continuation_handoff_test.dart'
    show receivingApplication;

LosslessPostOffseasonRuntimeGraph completeAnnualTransition(
    SinglePassPostseasonRuntimeTransition transition) {
  final transfer = transition.prepareTransfer()!;
  transition.submitTransfer(
    expectedPending: transfer,
    choice: PlayerTransferStrategyChoice.fromProfile(
      transfer.context.aiProfile,
    ),
  );
  transition.prepareDomain();
  transition.prepareOuterSuccessor();
  final manager = transition.managerPending!;
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
  return transition.moveOwnedAnnualContinuation();
}

PreparedTicketRuntimeSeason admitNextRuntime(
    LosslessPostOffseasonRuntimeGraph graph) {
  expect(graph.admissionState, FutureRuntimeAdmissionState.available);
  expect(graph.managerEvidence.seasonIndex, graph.targetSeasonIndex);
  expect(graph.managerEvidence.owner, same(graph.owner));
  expect(graph.managerEvidence.revision, same(graph.revision));
  final app =
      receivingApplication(seed: graph.worldSuccessor.config.careerSeed);
  final entry = app.claimFutureRuntimeEntry(
    expectedSource: graph,
    expectedSourceRevision: graph.revision,
    expectedOrigin: graph.origin,
    expectedTargetSeason: graph.targetSeasonIndex,
  );
  return app.prepareFutureRuntime(expectedEntry: entry);
}

void expectIdenticalRows(List<Object> before, List<Object> after) {
  expect(after.length, before.length);
  for (var i = 0; i < before.length; i++) {
    expect(after[i], same(before[i]));
  }
}

void expectIdentityOverlap(List<Object> before, List<Object> after) {
  expect(before, isNotEmpty);
  expect(
      after.any((next) => before.any((old) => identical(old, next))), isTrue);
}

void main() {
  test('genuine W30 mints capability and hands reserved graph to D0-E once',
      () {
    final app = completedFutureApp();
    final committed = app.commitFutureSeason(
      expectedW30: app.futureWeeklyState!,
    );
    expect(committed.w30.completedMatchCount, 720);
    expect(committed.reports.length, 3);
    expect(committed.reports.every((r) => r.report.matchCount == 240), isTrue);
    expect(committed.capability.completedSource, same(committed));
    expect(
      app.commitFutureSeason(expectedW30: app.futureWeeklyState!),
      same(committed),
    );
    final authority = app.handoffFutureEconomy(expectedCommitted: committed);
    expect(app.futureEconomyAuthority, same(authority));
    expect(authority.state, RuntimeEconomyState.awaitingCommittedSeason);
    final state = authority.prepareSettlement(committed.capability);
    expect(
      state == RuntimeEconomyState.awaitingTicketDecision ||
          state == RuntimeEconomyState.ready ||
          state == RuntimeEconomyState.decisionContractUnavailable,
      isTrue,
    );
    expect(
      app.handoffFutureEconomy(expectedCommitted: committed),
      same(authority),
    );
  });

  test('economy handoff is unavailable before exact W30 publication', () {
    final app = completedFutureApp();
    expect(app.futureCommittedSeason, isNull);
    expect(app.futureEconomyAuthority, isNull);
  });

  test('future accepted promise identities survive settlement and release', () {
    final app = completedFutureApp();
    final originalTransfer =
        app.activeFutureSeasonOpening!.prepared.transferEvidence;
    final committed = app.commitFutureSeason(
      expectedW30: app.futureWeeklyState!,
    );
    final authority = app.handoffFutureEconomy(expectedCommitted: committed);
    final state = authority.prepareSettlement(committed.capability);
    if (state == RuntimeEconomyState.awaitingTicketDecision) {
      authority.submitTicket(
        authority.pending!,
        const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
        expectedRevision: authority.revision,
      );
    }
    expect(authority.state, RuntimeEconomyState.ready);
    final settled = authority.executeSettlement(
      expectedCommitted: committed.capability,
    );
    final transition = SinglePassPostseasonRuntimeTransition.fromSettledEconomy(
      authority: authority,
      expectedResult: settled,
      expectedOwner: authority.owner,
      expectedRevision: authority.revision,
      expectedProvenance: authority.provenance,
      expectedExecution: authority.executionIdentity,
      hasNextSeason: true,
    );
    expect(authority.releasedPromiseContexts,
        same(committed.opening.promiseContexts));
    expect(authority.releasedPromises, same(committed.applied.activePromises));
    final controlled = committed.applied.consequence.promise;
    expect(
      authority.releasedPromises!
          .singleWhere((p) => p.clubId == committed.opening.controlledClubId),
      same(controlled),
    );
    final graph = completeAnnualTransition(transition);
    final nextPrepared = admitNextRuntime(graph);
    expectIdentityOverlap(
      originalTransfer.activeContracts.cast<Object>(),
      nextPrepared.transferEvidence.activeContracts.cast<Object>(),
    );
    expectIdentityOverlap(
      originalTransfer.contractEvents.cast<Object>(),
      nextPrepared.transferEvidence.contractEvents.cast<Object>(),
    );
  });
}
