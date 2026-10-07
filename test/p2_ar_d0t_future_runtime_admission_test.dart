import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';
import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;

LosslessPostOffseasonRuntimeGraph firstGraph(B3B1ApplicationFixture fixture) {
  final transition = fixture.application
      .startPostseasonTransition(expectedSource: fixture.source);
  final pending = transition.prepareTransfer()!;
  transition.submitTransfer(
      expectedPending: pending,
      choice:
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile));
  transition.prepareDomain();
  transition.prepareOuterSuccessor();
  return fixture.application
      .publishPostseasonContinuation(expectedTransition: transition);
}

void expectSameRows(List<Object> before, List<Object> after) {
  expect(after.length, before.length);
  for (var index = 0; index < before.length; index++) {
    expect(after[index], same(before[index]));
  }
}

void main() {
  test('genuine application B2 successor admits once without history retrofit',
      () {
    final fixture = B3B1ApplicationFixture();
    final source = fixture.source;
    final signatures = fixture.signatures;
    final graph = firstGraph(fixture);
    final transfer = graph.transferEvidence;
    final managers = graph.managerEvidence.managers;
    final entry = fixture.application.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: PostoffseasonRuntimeOrigin.firstFutureBootstrap,
        expectedTargetSeason: 1);
    expect(graph.admissionState, FutureRuntimeAdmissionState.available);
    final prepared =
        fixture.application.prepareFutureRuntime(expectedEntry: entry);
    final admission = fixture.application.futureRuntimeAdmission!;
    expect(admission.origin, PostoffseasonRuntimeOrigin.firstFutureBootstrap);
    expect(admission.sourceOwner, same(fixture.application));
    expect(admission.sourceRevision, same(graph.revision));
    expect(admission.sourceExecutionIdentity, same(graph.executionIdentity));
    expect(admission.applicationEntryIdentity, same(entry));
    expect(prepared.owner, same(fixture.application));
    expect(prepared.revision, same(entry.revision));
    expect(prepared.executionIdentity, same(entry.executionIdentity));
    expect(prepared.origin, PreparedRuntimeOrigin.futureContinuation);
    expect(prepared.state, PreparedExecutionState.prepared);
    expect(graph.admissionState, FutureRuntimeAdmissionState.prepared);
    expect(prepared.opening.seasonIndex, 1);
    expect(
        prepared.opening.players, same(graph.worldSuccessor.nextSeasonPlayers));
    expect(prepared.opening.financeStates,
        same(graph.worldSuccessor.nextSeasonFinanceStates));
    expect(
        prepared.opening.leagues, same(graph.worldSuccessor.nextSeasonLeagues));
    expect(prepared.facilities, same(graph.facilities));
    expect(prepared.tenureControl, same(graph.control));
    final authority = prepared.managerAuthority!;
    expect(authority.owner, same(fixture.application));
    expect(authority.sourceRevision, same(entry.revision));
    expect(authority.effectiveClubs, same(prepared.opening.effectiveClubs));
    expect(authority.seasons, isEmpty);
    expectSameRows(managers, authority.managers);
    expectSameRows(
        transfer.activeContracts, prepared.transferEvidence.activeContracts);
    expectSameRows(
        transfer.contractEvents, prepared.transferEvidence.contractEvents);
    expectSameRows(transfer.loanHistory, prepared.transferEvidence.loanHistory);
    expectSameRows(transfer.installmentObligations,
        prepared.transferEvidence.installmentObligations);
    expect(prepared.sponsorProcessedClubCount, 0);
    expect(prepared.sponsorSeasonRevenue, Money.zero);
    expect(prepared.ticketDecisionCount, 0);
    expect(prepared.openingSponsor.totalRevenuePaid, Money.zero);
    expect(fixture.application.prepareFutureRuntime(expectedEntry: entry),
        same(prepared));
    expect(() => graph.admitFutureRuntime(entry), throwsStateError);
    expect(fixture.application.acceptedPromiseClosingCandidate, same(source));
    expect(source.sourceState.completedMatchCount, 720);
    expect(fixture.signatures, signatures);
  });
}
