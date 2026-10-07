import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:test/test.dart';
import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_ar_d0t_future_runtime_admission_test.dart' show firstGraph;
import 'p2_ar_d0t_lossless_continuation_handoff_test.dart'
    show laterGraph, receivingApplication;

class D0TStrengthProbe extends TeamStrengthCalculator {
  int calls = 0;
  bool fail = false;
  @override
  List<Club> deriveClubs(
      {required List<Club> baseClubs, required List<Player> players}) {
    calls++;
    if (fail) throw StateError('Injected genuine target preparation failure');
    return super.deriveClubs(baseClubs: baseClubs, players: players);
  }
}

void main() {
  test('wrong revision/season/origin/seed/app reject without consuming source',
      () {
    final graph = laterGraph(B3B1LegacyClosing());
    final app = receivingApplication();
    expect(
        () => app.claimFutureRuntimeEntry(
            expectedSource: graph,
            expectedSourceRevision: Object(),
            expectedOrigin: graph.origin,
            expectedTargetSeason: 1),
        throwsStateError);
    expect(
        () => app.claimFutureRuntimeEntry(
            expectedSource: graph,
            expectedSourceRevision: graph.revision,
            expectedOrigin: graph.origin,
            expectedTargetSeason: 2),
        throwsStateError);
    expect(
        () => app.claimFutureRuntimeEntry(
            expectedSource: graph,
            expectedSourceRevision: graph.revision,
            expectedOrigin: PostoffseasonRuntimeOrigin.firstFutureBootstrap,
            expectedTargetSeason: 1),
        throwsStateError);
    expect(
        () => receivingApplication(seed: 999).claimFutureRuntimeEntry(
            expectedSource: graph,
            expectedSourceRevision: graph.revision,
            expectedOrigin: graph.origin,
            expectedTargetSeason: 1),
        throwsStateError);
    expect(
        () => receivingApplication(club: 't1_02').claimFutureRuntimeEntry(
            expectedSource: graph,
            expectedSourceRevision: graph.revision,
            expectedOrigin: graph.origin,
            expectedTargetSeason: 1),
        throwsStateError);
    expect(graph.admissionState, FutureRuntimeAdmissionState.available);
    expect(app.futureRuntimeAdmission, isNull);
    final entry = app.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: graph.origin,
        expectedTargetSeason: 1);
    expect(() => graph.admitFutureRuntime(entry), throwsStateError);
    expect(graph.admissionState, FutureRuntimeAdmissionState.available);
    final other = receivingApplication();
    final foreignEntry = other.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: graph.origin,
        expectedTargetSeason: 1);
    expect(() => app.prepareFutureRuntime(expectedEntry: foreignEntry),
        throwsStateError);
    expect(graph.admissionState, FutureRuntimeAdmissionState.available);
    final accepted = app.prepareFutureRuntime(expectedEntry: entry);
    expect(app.futureRuntimeAdmission!.prepared, same(accepted));
    expect(() => other.prepareFutureRuntime(expectedEntry: foreignEntry),
        throwsStateError);
    expect(other.futureRuntimeAdmission, isNull);
    expect(graph.admissionState, FutureRuntimeAdmissionState.prepared);
  });

  test('foreign first graph never becomes an application-owned source', () {
    final fixture = B3B1ApplicationFixture();
    final graph = firstGraph(fixture);
    final foreign = B3B1ApplicationFixture();
    expect(
        () => foreign.application.claimFutureRuntimeEntry(
            expectedSource: graph,
            expectedSourceRevision: graph.revision,
            expectedOrigin: graph.origin,
            expectedTargetSeason: 1),
        throwsStateError);
    expect(graph.admissionState, FutureRuntimeAdmissionState.available);
    expect(foreign.application.futureRuntimeAdmission, isNull);
  });

  test(
      'post-claim engine failure is terminal, no prepared publication or retry',
      () {
    final strength = D0TStrengthProbe();
    final fixture = B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(strengthCalculator: strength));
    final graph = laterGraph(fixture);
    final app = receivingApplication();
    final entry = app.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: graph.origin,
        expectedTargetSeason: 1);
    final before = strength.calls;
    strength.fail = true;
    expect(
        () => app.prepareFutureRuntime(expectedEntry: entry), throwsStateError);
    expect(strength.calls, before + 1);
    expect(graph.admissionState, FutureRuntimeAdmissionState.failed);
    expect(app.futureRuntimeAdmission, isNull);
    strength.fail = false;
    expect(
        () => app.prepareFutureRuntime(expectedEntry: entry), throwsStateError);
    expect(strength.calls, before + 1);
    expect(app.futureRuntimeAdmission, isNull);
  });

  test(
      'success prepares once; same application request returns the same result',
      () {
    final strength = D0TStrengthProbe();
    final graph = laterGraph(B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(strengthCalculator: strength)));
    final app = receivingApplication();
    final entry = app.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: graph.origin,
        expectedTargetSeason: 1);
    final before = strength.calls;
    final result = app.prepareFutureRuntime(expectedEntry: entry);
    final authority = result.managerAuthority;
    expect(strength.calls, before + 1);
    expect(app.prepareFutureRuntime(expectedEntry: entry), same(result));
    expect(result.managerAuthority, same(authority));
    expect(strength.calls, before + 1);
  });
}
