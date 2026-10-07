import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';
import 'p2_ar_d0o_active_future_opening_test.dart' show firstPrepared, open;

void main() {
  test('foreign application/admission/prepared rejected before reservation',
      () {
    final app = firstPrepared();
    final foreign = firstPrepared();
    final admission = app.futureRuntimeAdmission!;
    final other = foreign.futureRuntimeAdmission!;
    expect(
        () => app.openFutureSeason(
            expectedAdmission: other, expectedPrepared: other.prepared),
        throwsStateError);
    expect(
        () => app.openFutureSeason(
            expectedAdmission: admission, expectedPrepared: other.prepared),
        throwsStateError);
    expect(app.activeFutureSeasonOpening, isNull);
    expect(foreign.activeFutureSeasonOpening, isNull);
    expect(admission.prepared.state, PreparedExecutionState.prepared);
    final accepted = open(app);
    expect(
        () => foreign.openFutureSeason(
            expectedAdmission: admission, expectedPrepared: admission.prepared),
        throwsStateError);
    expect(app.activeFutureSeasonOpening, same(accepted));
  });
  test('published reservation blocks every independent consumption path', () {
    final app = firstPrepared();
    final opening = open(app);
    final prepared = opening.prepared;
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    expect(
        () => prepared.move(
            expectedOwner: prepared.owner,
            expectedRevision: prepared.revision,
            expectedProvenance: prepared.provenance),
        throwsStateError);
    expect(
        () => engine.executePrepared(prepared,
            expectedOwner: prepared.owner,
            expectedRevision: prepared.revision,
            expectedProvenance: prepared.provenance),
        throwsStateError);
    expect(
        () => engine.captureAnnualClosing(prepared,
            expectedOwner: prepared.owner,
            expectedRevision: prepared.revision,
            expectedProvenance: prepared.provenance,
            hasNextSeason: true),
        throwsStateError);
    expect(
        () => FullM65RuntimeEconomyContinuationAuthority.claim(prepared,
            expectedOwner: prepared.owner,
            expectedRevision: prepared.revision,
            expectedProvenance: prepared.provenance,
            expectedExecution: prepared.executionIdentity),
        throwsStateError);
    expect(prepared.state, PreparedExecutionState.prepared);
    expect(prepared.sponsorProcessedClubCount, 0);
    expect(prepared.ticketDecisionCount, 0);
    final answers = app.answeredDecisionCount;
    expect(
        () => app.submit(
            request: opening.promisePending.request,
            choice: opening.controlledPromiseContext.allowedTypes.first),
        throwsStateError);
    expect(app.answeredDecisionCount, answers);
    expect(opening.promisePending.request.context,
        same(opening.controlledPromiseContext));
    expect(open(app), same(opening));
  });
  test('prepared moved before publication is stale, no opening', () {
    final app = firstPrepared();
    final prepared = app.futureRuntimeAdmission!.prepared;
    prepared.move(
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance);
    expect(() => open(app), throwsStateError);
    expect(app.activeFutureSeasonOpening, isNull);
  });
}
