import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:test/test.dart';
import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_ar_d0t_future_runtime_admission_test.dart' show firstGraph;
import 'p2_ar_d0t_lossless_continuation_handoff_test.dart'
    show laterGraph, receivingApplication;

PlayerPresidentInteractiveDecisionApplicationSession firstPrepared() {
  final fixture = B3B1ApplicationFixture();
  final graph = firstGraph(fixture);
  final entry = fixture.application.claimFutureRuntimeEntry(
      expectedSource: graph,
      expectedSourceRevision: graph.revision,
      expectedOrigin: graph.origin,
      expectedTargetSeason: graph.targetSeasonIndex);
  fixture.application.prepareFutureRuntime(expectedEntry: entry);
  return fixture.application;
}

PlayerPresidentInteractiveDecisionApplicationSession laterPrepared(
    B3B1LegacyClosing fixture) {
  final graph = laterGraph(fixture, replace: true);
  final app = receivingApplication();
  final entry = app.claimFutureRuntimeEntry(
      expectedSource: graph,
      expectedSourceRevision: graph.revision,
      expectedOrigin: graph.origin,
      expectedTargetSeason: graph.targetSeasonIndex);
  app.prepareFutureRuntime(expectedEntry: entry);
  return app;
}

PlayerPresidentActiveFutureSeasonOpening open(
        PlayerPresidentInteractiveDecisionApplicationSession app) =>
    app.openFutureSeason(
        expectedAdmission: app.futureRuntimeAdmission!,
        expectedPrepared: app.futureRuntimeAdmission!.prepared);

void verifyOpening(PlayerPresidentInteractiveDecisionApplicationSession app) {
  final admission = app.futureRuntimeAdmission!;
  final prepared = admission.prepared;
  final manager = prepared.managerAuthority;
  final sponsor = prepared.openingSponsor;
  final sourceB2 = app.acceptedPromiseClosingCandidate;
  final currentWeekly = app.preseasonWeeklyState;
  final answered = app.answeredDecisionCount;
  final opening = open(app);
  expect(app.activeFutureSeasonOpening, same(opening));
  expect(opening.admission, same(admission));
  expect(opening.prepared, same(prepared));
  expect(opening.managerAuthority, same(manager));
  expect(opening.opening, same(prepared.opening));
  expect(opening.managerAuthority.effectiveClubs,
      same(opening.opening.effectiveClubs));
  expect(opening.targetSeasonIndex, 1);
  expect(opening.origin, admission.origin);
  expect(opening.control, same(prepared.tenureControl));
  expect(prepared.state, PreparedExecutionState.prepared);
  expect(prepared.origin, PreparedRuntimeOrigin.futureContinuation);
  expect(opening.promiseContexts.length, 48);
  expect(opening.promiseContexts.map((c) => c.clubId).toSet().length, 48);
  expect(opening.promiseContexts.every((c) => c.seasonIndex == 1), isTrue);
  final request = opening.promisePending.request;
  expect(request.kind.name, 'promise');
  expect(request.phase, 'preseasonPromise');
  expect(request.sequence, 1);
  expect(request.clubId, opening.controlledClubId);
  expect(request.context, same(opening.controlledPromiseContext));
  expect(request.contextSignature, opening.controlledPromiseContext.signature);
  expect(request.keyNamespace, startsWith('future-preseason-promise/v1:s1:'));
  expect(app.answeredDecisionCount, answered);
  expect(app.acceptedPromiseClosingCandidate, same(sourceB2));
  expect(app.preseasonWeeklyState, same(currentWeekly));
  expect(prepared.openingSponsor, same(sponsor));
  expect(prepared.sponsorProcessedClubCount, 0);
  expect(prepared.sponsorSeasonRevenue, Money.zero);
  expect(prepared.ticketDecisionCount, 0);
  expect(() => opening.promiseContexts.clear(), throwsUnsupportedError);
  expect(open(app), same(opening));
  expect(open(app).w0, same(opening.w0));
  expect(open(app).promisePending, same(opening.promisePending));
}

void main() {
  test(
      'genuine application B2/B3-B1/D0-T first opening, no acceptance or replay',
      () {
    final app = firstPrepared();
    verifyOpening(app);
    expect(app.activeFutureSeasonOpening!.origin.name, 'firstFutureBootstrap');
    expect(app.activeFutureSeasonOpening!.managerAuthority.seasons, isEmpty);
    expect(app.acceptedPromiseClosingCandidate!.sourceState.completedMatchCount,
        720);
  });
  test('genuine annual capture/B3-B1/D0-T later opening preserves continuation',
      () {
    final app = laterPrepared(B3B1LegacyClosing());
    final prepared = app.futureRuntimeAdmission!.prepared;
    final evidence = prepared.transferEvidence;
    final facilities = prepared.facilities;
    final history = prepared.managerAuthority!.seasons;
    final managers = prepared.managerAuthority!.assignments;
    final sponsorPaid = prepared.openingSponsor.totalRevenuePaid;
    verifyOpening(app);
    final opening = app.activeFutureSeasonOpening!;
    expect(opening.origin.name, 'postOffseasonContinuation');
    expect(opening.managerAuthority.seasons, same(history));
    expect(opening.managerAuthority.assignments, same(managers));
    expect(history, isNotEmpty);
    expect(prepared.facilities, same(facilities));
    expect(prepared.openingSponsor.totalRevenuePaid, sponsorPaid);
    expect(sponsorPaid.units, greaterThan(0));
    expect(prepared.transferEvidence.activeContracts.first,
        same(evidence.activeContracts.first));
  });
}
