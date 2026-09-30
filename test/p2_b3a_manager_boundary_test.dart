import 'dart:io';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/manager/manager_opening_state_initializer.dart';
import 'package:futbol_baskanlik_m0/src/manager/manager_postseason_boundary_projection.dart';
import 'package:test/test.dart';
import 'p2_b3a_finance_equivalence_test.dart' show B3AFixture;

void main() {
  late B3AFixture fixture;
  setUpAll(() => fixture = B3AFixture());
  test(
      'real pristine B1 has no original manager authority or completion publication',
      () {
    final before = fixture.signatures;
    for (var i = 0; i < 3; i++) {
      final result =
          const ManagerPostseasonBoundaryProjection().inspect(fixture.b1);
      expect(result.source, same(fixture.b1));
      expect(result.source.sourceState, same(fixture.w30));
      expect(
          result.status, ManagerPostseasonBoundaryStatus.authorityUnavailable);
      expect(result.managerCompletionEvaluated, isFalse);
      expect(result.authoritativeSeason, isNull);
      expect(result.authoritativeAssignments, isEmpty);
      expect(
          () => result.authoritativeAssignments
              .add(const ManagerOpeningStateInitializer()
                  .prepare(
                    careerSeed: 20260903,
                    simulationVersion: 1,
                    initialSeasonIndex: 0,
                    clubs: fixture.w30.effectiveClubs,
                    players: fixture.w30.boundary.opening.players,
                    leagues: fixture.w30.boundary.opening.leagues,
                    financeStates: fixture.w30.boundary.opening.financeStates,
                  )
                  .assignments
                  .first),
          throwsUnsupportedError);
      fixture.expectUnchanged(before);
    }
  });
  test(
      'deterministic reconstructed opening does not establish original ownership',
      () {
    final before = fixture.signatures;
    final opening = fixture.w30.boundary.opening;
    final config = fixture.w30.boundary.proof.seasonOpening.config;
    ManagerOpeningState reconstruct() =>
        const ManagerOpeningStateInitializer().prepare(
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
          initialSeasonIndex: config.seasonIndex,
          clubs: fixture.w30.effectiveClubs,
          players: opening.players,
          leagues: opening.leagues,
          financeStates: opening.financeStates,
        );
    final a = reconstruct(), b = reconstruct();
    expect(a.assignments.length, 48);
    expect(a.assignments.map((s) => s.signature),
        b.assignments.map((s) => s.signature));
    expect(identical(a, b), isFalse);
    final detached = ManagerCareerController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      managers: a.managers,
      assignments: a.assignments,
      seasons: const [],
    );
    final assignments =
        detached.finalAssignments.map((s) => s.signature).toList();
    // No controller/opening injection API: this detached illustration is NEVER
    // passed as original source authority, even when its numbers match.
    final result =
        const ManagerPostseasonBoundaryProjection().inspect(fixture.b1);
    expect(result.status, ManagerPostseasonBoundaryStatus.authorityUnavailable);
    expect(detached.seasons, isEmpty);
    expect(detached.finalAssignments.map((s) => s.signature), assignments);
    expect(result.authoritativeSeason, isNull);
    fixture.expectUnchanged(before);
  });
  test('architecture guard: missing authority cannot invoke manager lifecycle',
      () {
    // There is no original controller to spy on. Complement runtime absence
    // assertions with the exact diagnostic call-surface guard, not a fabricated
    // conditional-success controller.
    final source =
        File('lib/src/manager/manager_postseason_boundary_projection.dart')
            .readAsStringSync();
    expect(source, isNot(contains('onSeasonCompleted(')));
    expect(source, isNot(contains('ManagerCareerController')));
    expect(source, isNot(contains('ManagerOpeningStateInitializer')));
    expect(source, isNot(contains('ManagerCareerSeason(')));
  });
}
