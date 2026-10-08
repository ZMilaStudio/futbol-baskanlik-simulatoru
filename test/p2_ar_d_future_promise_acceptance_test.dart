import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:test/test.dart';
import 'p2_ar_d0o_active_future_opening_test.dart' show firstPrepared, open;

PlayerPresidentInteractiveDecisionApplicationSession acceptedFutureApp() {
  final app = firstPrepared();
  final opening = open(app);
  app.acceptFuturePromise(
    expectedOpening: opening,
    expectedPending: opening.promisePending,
    choice: opening.controlledPromiseContext.allowedTypes.first,
  );
  return app;
}

void main() {
  test('exact future Pending produces one authoritative 48-promise owner', () {
    final app = firstPrepared();
    final opening = open(app);
    final choice = opening.controlledPromiseContext.allowedTypes.first;
    final applied = app.acceptFuturePromise(
      expectedOpening: opening,
      expectedPending: opening.promisePending,
      choice: choice,
    );
    expect(app.futurePromiseApplied, same(applied));
    expect(app.futureWeeklyState!.fixtureSnapshot, same(opening.w0));
    expect(applied.activePromises.length, 48);
    expect(applied.activePromises.map((p) => p.clubId).toSet().length, 48);
    expect(applied.activePromises.map((p) => p.id).toSet().length, 48);
    expect(
        applied.activePromises
            .every((p) => p.seasonIndex == opening.targetSeasonIndex),
        isTrue);
    expect(
      applied.activePromises
          .singleWhere((p) => p.clubId == opening.controlledClubId),
      same(applied.consequence.promise),
    );
    expect(
      app.acceptFuturePromise(
        expectedOpening: opening,
        expectedPending: opening.promisePending,
        choice: choice,
      ),
      same(applied),
    );
  });

  test('foreign Pending and conflicting duplicate fail closed', () {
    final app = firstPrepared(), foreign = firstPrepared();
    final opening = open(app), other = open(foreign);
    expect(
      () => app.acceptFuturePromise(
        expectedOpening: opening,
        expectedPending: other.promisePending,
        choice: opening.controlledPromiseContext.allowedTypes.first,
      ),
      throwsStateError,
    );
    expect(app.futurePromiseApplied, isNull);
    final choices = opening.controlledPromiseContext.allowedTypes;
    final applied = app.acceptFuturePromise(
      expectedOpening: opening,
      expectedPending: opening.promisePending,
      choice: choices.first,
    );
    if (choices.length > 1) {
      expect(
        () => app.acceptFuturePromise(
          expectedOpening: opening,
          expectedPending: opening.promisePending,
          choice: choices.last,
        ),
        throwsStateError,
      );
    }
    expect(app.futurePromiseApplied, same(applied));
  });
}
