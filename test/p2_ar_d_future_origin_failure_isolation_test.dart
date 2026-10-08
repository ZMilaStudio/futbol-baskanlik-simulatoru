import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:test/test.dart';
import 'p2_ar_d0o_active_future_opening_test.dart' show laterPrepared, open;
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_ar_d_future_committed_economy_handoff_test.dart'
    show completeAnnualTransition, admitNextRuntime, expectIdentityOverlap;

void main() {
  test('later origin preserves manager/runtime lineage through first week', () {
    final app = laterPrepared(B3B1LegacyClosing());
    final opening = open(app);
    final manager = opening.managerAuthority;
    final prepared = opening.prepared;
    final applied = app.acceptFuturePromise(
      expectedOpening: opening,
      expectedPending: opening.promisePending,
      choice: opening.controlledPromiseContext.allowedTypes.first,
    );
    final w1 = app.advanceFutureWeek(
      expectedState: app.futureWeeklyState!,
      expectedRound: 1,
    );
    expect(applied.origin.name, 'postOffseasonContinuation');
    expect(w1.managerAuthority, same(manager));
    expect(w1.prepared, same(prepared));
    expect(manager.seasons, isNotEmpty);
    expect(prepared.sponsorProcessedClubCount, 0);
  });

  test('W1 before acceptance is impossible and does not alter opening', () {
    final app = laterPrepared(B3B1LegacyClosing());
    final opening = open(app);
    expect(app.futureWeeklyState, isNull);
    expect(app.futureCommittedSeason, isNull);
    expect(app.activeFutureSeasonOpening, same(opening));
  });

  test('later-origin annual closing restages the same transfer objects', () {
    final app = laterPrepared(B3B1LegacyClosing());
    final opening = open(app);
    app.acceptFuturePromise(
      expectedOpening: opening,
      expectedPending: opening.promisePending,
      choice: opening.controlledPromiseContext.allowedTypes.first,
    );
    for (var round = 1; round <= 30; round++) {
      app.advanceFutureWeek(
        expectedState: app.futureWeeklyState!,
        expectedRound: round,
      );
    }
    final evidence = opening.prepared.transferEvidence;
    final committed = app.commitFutureSeason(
      expectedW30: app.futureWeeklyState!,
    );
    final economy = app.handoffFutureEconomy(expectedCommitted: committed);
    final state = economy.prepareSettlement(committed.capability);
    if (state.name == 'awaitingTicketDecision') {
      economy.submitTicket(
        economy.pending!,
        const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
        expectedRevision: economy.revision,
      );
    }
    final settled = economy.executeSettlement(
      expectedCommitted: committed.capability,
    );
    final transition = SinglePassPostseasonRuntimeTransition.fromSettledEconomy(
      authority: economy,
      expectedResult: settled,
      expectedOwner: economy.owner,
      expectedRevision: economy.revision,
      expectedProvenance: economy.provenance,
      expectedExecution: economy.executionIdentity,
      hasNextSeason: true,
    );
    final prepared = admitNextRuntime(completeAnnualTransition(transition));
    expectIdentityOverlap(
      evidence.activeContracts.cast<Object>(),
      prepared.transferEvidence.activeContracts.cast<Object>(),
    );
    expectIdentityOverlap(
      evidence.contractEvents.cast<Object>(),
      prepared.transferEvidence.contractEvents.cast<Object>(),
    );
  });
}
