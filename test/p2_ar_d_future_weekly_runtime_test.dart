import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:test/test.dart';
import 'p2_ar_d_future_promise_acceptance_test.dart' show acceptedFutureApp;

PlayerPresidentInteractiveDecisionApplicationSession completedFutureApp() {
  final app = acceptedFutureApp();
  for (var round = 1; round <= 30; round++) {
    app.advanceFutureWeek(
      expectedState: app.futureWeeklyState!,
      expectedRound: round,
    );
  }
  return app;
}

void main() {
  test('application owns W0 through W30 using original prepared policy', () {
    final app = acceptedFutureApp();
    final w0 = app.futureWeeklyState!;
    expect(w0.completedMatchCount, 0);
    for (var round = 1; round <= 30; round++) {
      final before = app.futureWeeklyState!;
      final untouched = before.fixtureSnapshot.fixtures
          .where((f) => f.round != round)
          .toList();
      final next = app.advanceFutureWeek(
        expectedState: before,
        expectedRound: round,
      );
      expect(next.completedMatchCount, round * 24);
      expect(next.nextRound, round + 1);
      for (final old in untouched) {
        final index = before.fixtureSnapshot.fixtures.indexOf(old);
        expect(next.fixtureSnapshot.fixtures[index], same(old));
      }
      expect(
        app.advanceFutureWeek(expectedState: before, expectedRound: round),
        same(next),
      );
    }
    final w30 = app.futureWeeklyState!;
    expect(w30.isComplete, isTrue);
    expect(w30.completedMatchCount, 720);
    expect(w30.fixtureSnapshot.fixtures.every((f) => f.isPlayed), isTrue);
    expect(w30.activePromises, same(w0.activePromises));
    expect(w30.managerAuthority, same(w0.managerAuthority));
  });

  test('wrong round and stale predecessor preserve current pointer', () {
    final app = acceptedFutureApp();
    final w0 = app.futureWeeklyState!;
    expect(
      () => app.advanceFutureWeek(expectedState: w0, expectedRound: 2),
      throwsStateError,
    );
    expect(app.futureWeeklyState, same(w0));
    final w1 = app.advanceFutureWeek(expectedState: w0, expectedRound: 1);
    expect(
      () => app.advanceFutureWeek(expectedState: w0, expectedRound: 2),
      throwsStateError,
    );
    expect(app.futureWeeklyState, same(w1));
  });
}
