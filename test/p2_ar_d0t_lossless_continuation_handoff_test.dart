import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/manager/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:test/test.dart';
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_b3b1_manager_preparation_continuation_test.dart' show readyManager;
import 'p2_ar_d0t_future_runtime_admission_test.dart' show expectSameRows;

PlayerPresidentInteractiveDecisionApplicationSession receivingApplication(
    {int seed = 42002, String club = 't1_01'}) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: SimulationConfig(careerSeed: seed),
      controlledClubId: club,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true);
}

LosslessPostOffseasonRuntimeGraph laterGraph(B3B1LegacyClosing fixture,
    {bool replace = false}) {
  final transition = readyManager(fixture);
  final pending = transition.managerPending!;
  if (replace || !pending.review.canRetain) {
    final replacement = transition.submitManagerReview(
        expectedPending: pending, choice: PlayerManagerReviewChoice.replace)!;
    transition.submitManagerReplacement(
        expectedPending: replacement,
        selected: replacement.replacement!.candidates.last.manager);
  } else {
    transition.submitManagerReview(
        expectedPending: pending, choice: PlayerManagerReviewChoice.retain);
  }
  return transition.moveOwnedAnnualContinuation();
}

void main() {
  test(
      'real annual graph retains transfer/history/control with no second settlement',
      () {
    final fixture = B3B1LegacyClosing();
    final receipt = fixture.closing.receipt;
    final finances = fixture.closing.advanced.world.finances;
    final graph = laterGraph(fixture, replace: true);
    final state = graph.transferEvidence;
    final history = graph.managerEvidence.completedSeasons;
    final assignment = graph.managerEvidence.assignments
        .singleWhere((value) => value.clubId == 't1_01');
    final sourceSponsor = graph.facilities; // Genuine successor, not defaults.
    final app = receivingApplication();
    final entry = app.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: PostoffseasonRuntimeOrigin.postOffseasonContinuation,
        expectedTargetSeason: 1);
    final prepared = app.prepareFutureRuntime(expectedEntry: entry);
    final admission = app.futureRuntimeAdmission!;
    expect(admission.sourceOwner, same(fixture.closing.owner));
    expect(admission.applicationOwner, same(app));
    expect(admission.sourceRevision, same(fixture.closing.revision));
    expect(admission.sourceExecutionIdentity,
        same(fixture.closing.executionIdentity));
    expect(prepared.origin, PreparedRuntimeOrigin.futureContinuation);
    expect(
        prepared.opening.players, same(graph.worldSuccessor.nextSeasonPlayers));
    expect(prepared.opening.financeStates,
        same(graph.worldSuccessor.nextSeasonFinanceStates));
    expect(
        prepared.opening.leagues, same(graph.worldSuccessor.nextSeasonLeagues));
    expect(prepared.facilities, same(sourceSponsor));
    expect(prepared.tenureControl, same(graph.control));
    expect(prepared.transferLineage, same(graph.transferLineageIdentity));
    expect(prepared.managerLineage, same(graph.managerEvidence));
    expectSameRows(
        state.activeContracts, prepared.transferEvidence.activeContracts);
    expectSameRows(
        state.contractEvents, prepared.transferEvidence.contractEvents);
    expectSameRows(state.activeLoans, prepared.transferEvidence.activeLoans);
    expectSameRows(state.loanHistory, prepared.transferEvidence.loanHistory);
    expectSameRows(state.installmentObligations,
        prepared.transferEvidence.installmentObligations);
    expectSameRows(history, prepared.managerAuthority!.seasons);
    expect(prepared.managerAuthority!.assignments['t1_01'], same(assignment));
    for (final club in graph.crisisEvidence.presidentClubs) {
      expect(prepared.pricingFanStates[club.clubId], same(club.fanReputation));
      expect(
          prepared.pricingProfiles[club.clubId], same(club.managementProfile));
      expect(prepared.sponsorFanStates[club.clubId], same(club.fanReputation));
    }
    expect(prepared.openingSponsor.totalRevenuePaid.minorUnits, greaterThan(0));
    expect(prepared.openingSponsor.nextSeasonIndex, 1);
    expect(prepared.sponsorProcessedClubCount, 0);
    expect(prepared.sponsorSeasonRevenue, Money.zero);
    expect(prepared.ticketDecisionCount, 0);
    expect(fixture.closing.receipt, same(receipt));
    expect(fixture.closing.advanced.world.finances, same(finances));
    expect(graph.admissionState, FutureRuntimeAdmissionState.prepared);
    expect(app.prepareFutureRuntime(expectedEntry: entry), same(prepared));
    expect(() => graph.admitFutureRuntime(entry), throwsStateError);
  });
}
