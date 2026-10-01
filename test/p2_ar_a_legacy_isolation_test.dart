import 'package:futbol_baskanlik_m0/src/player_president/player_president_future_season_authority.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_b3a_finalization_readiness.dart';
import 'package:futbol_baskanlik_m0/src/manager/manager_postseason_boundary_projection.dart';
import 'package:test/test.dart';
import 'p2_b3a_finance_equivalence_test.dart' show B3AFixture;
import 'p2_ar_a_future_opening_test.dart'
    show futureContractFixture, prepareFixture;

void main() {
  test(
      'detached future fixture leaves real current W0/720/B1/B2/B3-A unchanged',
      () {
    final fixture = B3AFixture();
    final before = fixture.signatures;
    final finances = fixture.b2.finances;
    final contexts = fixture.w0.boundary.contexts;
    final results = fixture.b1.leagueResults;
    final committed = fixture.w30.fixtureSnapshot.fixtures;
    final prior = const PlayerPresidentB3AFinalizationReadiness()
        .inspect(expectedClosingCandidate: fixture.b2);
    for (var i = 0; i < 3; i++) {
      final source = futureContractFixture();
      final candidate = prepareFixture(
          FuturePreseasonBoundary.forContractFixture(source), source);
      expect(candidate.isAuthoritative, isFalse);
      fixture.expectUnchanged(before);
      expect(fixture.w0.boundary.contexts, same(contexts));
      expect(fixture.b2.finances, same(finances));
      for (var j = 0; j < 48; j++) {
        expect(fixture.b2.finances[j], same(finances[j]));
      }
      expect(fixture.b1.leagueResults.map((r) => r.report.toJson()).toList(),
          results.map((r) => r.report.toJson()).toList());
      expect(fixture.w0.fixtureSnapshot.seasonIndex, 0);
      expect(fixture.w0.completedMatchCount, 0);
      expect(fixture.w30.completedMatchCount, 720);
      expect(fixture.w30.fixtureSnapshot.fixtures, same(committed));
      for (var match = 0; match < 720; match++) {
        expect(fixture.w30.fixtureSnapshot.fixtures[match],
            same(committed[match]));
        expect(fixture.w30.fixtureSnapshot.fixtures[match].fixture.result,
            same(committed[match].fixture.result));
      }
      final after = const PlayerPresidentB3AFinalizationReadiness()
          .inspect(expectedClosingCandidate: fixture.b2);
      expect(after.blockers, prior.blockers);
      expect(after.finalizationReady, isFalse);
      expect(after.finance.fullM65Equivalent, isFalse);
      expect(after.manager.status,
          ManagerPostseasonBoundaryStatus.authorityUnavailable);
      expect(after.manager.managerCompletionEvaluated, isFalse);
      expect(after.manager.authoritativeSeason, isNull);
    }
  });
}
