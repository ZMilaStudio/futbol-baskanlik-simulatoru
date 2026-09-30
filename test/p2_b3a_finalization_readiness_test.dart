import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_b3a_finalization_readiness.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_b3a_finance_equivalence.dart';
import 'package:test/test.dart';
import 'p2_b3a_finance_equivalence_test.dart' show B3AFixture;

class _FailingFinance extends PlayerPresidentB3AFinanceEquivalence {
  @override
  PlayerPresidentB3AFinanceEquivalenceResult inspect(
      PlayerPresidentAcceptedPromiseClosingCandidate source) {
    throw StateError('detached diagnostic failure');
  }
}

void main() {
  late B3AFixture fixture;
  setUpAll(() => fixture = B3AFixture());
  test('exact B2/W30/applied-48 ownership aggregates all fail-closed blockers',
      () {
    final before = fixture.signatures;
    expect(fixture.b2.sourceResultCandidate, same(fixture.b1));
    expect(fixture.b2.sourceState, same(fixture.w30));
    expect(fixture.b2.applied, same(fixture.w0.applied));
    expect(fixture.b2.activePromises.length, 48);
    for (var i = 0; i < 3; i++) {
      final result = const PlayerPresidentB3AFinalizationReadiness()
          .inspect(expectedClosingCandidate: fixture.b2);
      expect(result.source, same(fixture.b2));
      expect(result.finance.source, same(fixture.b2));
      expect(result.manager.source, same(fixture.b1));
      expect(result.finalizationReady, isFalse);
      expect(result.offseasonEligibility,
          PlayerPresidentB3AOffseasonEligibility.sourceAuthorityBlocked);
      expect(result.blockers, [
        PlayerPresidentB3AFinalizationReadinessStatus.financeEquivalenceBlocked,
        PlayerPresidentB3AFinalizationReadinessStatus
            .managerAuthorityUnavailable,
        PlayerPresidentB3AFinalizationReadinessStatus
            .decisionContractUnavailable,
      ]);
      expect(() => result.blockers.clear(), throwsUnsupportedError);
      expect(fixture.application.pendingDecision, isNull);
    }
    fixture.expectUnchanged(before);
  });
  test('unpublished value-equal B2 is sourceMismatch, never a silent adoption',
      () {
    final before = fixture.signatures;
    final detached = const PlayerPresidentAcceptedPromiseClosingProjection()
        .project(source: fixture.b1);
    final result = const PlayerPresidentB3AFinalizationReadiness()
        .inspect(expectedClosingCandidate: detached);
    expect(result.status,
        PlayerPresidentB3AFinalizationReadinessStatus.sourceMismatch);
    expect(result.blockers,
        contains(PlayerPresidentB3AFinalizationReadinessStatus.sourceMismatch));
    expect(result.finalizationReady, isFalse);
    fixture.expectUnchanged(before);
  });
  test(
      'detached diagnostic exception and retry cannot mutate B2 or world state',
      () {
    final before = fixture.signatures;
    for (var i = 0; i < 2; i++) {
      expect(
          () => PlayerPresidentB3AFinalizationReadiness(
                  finance: _FailingFinance())
              .inspect(expectedClosingCandidate: fixture.b2),
          throwsStateError);
      fixture.expectUnchanged(before);
    }
    final result = const PlayerPresidentB3AFinalizationReadiness()
        .inspect(expectedClosingCandidate: fixture.b2);
    expect(result.finalizationReady, isFalse);
    fixture.expectUnchanged(before);
  });
  test(
      'terminal report remains terminal: blockers do not silently advance season',
      () {
    final terminal = B3AFixture(future: false);
    final before = terminal.signatures;
    final result = const PlayerPresidentB3AFinalizationReadiness()
        .inspect(expectedClosingCandidate: terminal.b2);
    expect(result.source.hasNextSeason, isFalse);
    expect(result.offseasonEligibility,
        PlayerPresidentB3AOffseasonEligibility.terminalNoWork);
    expect(result.source.movements, isEmpty);
    expect(result.blockers, [
      PlayerPresidentB3AFinalizationReadinessStatus.financeEquivalenceBlocked,
      PlayerPresidentB3AFinalizationReadinessStatus.managerAuthorityUnavailable,
    ]);
    expect(result.finalizationReady, isFalse);
    terminal.expectUnchanged(before);
  });
}
