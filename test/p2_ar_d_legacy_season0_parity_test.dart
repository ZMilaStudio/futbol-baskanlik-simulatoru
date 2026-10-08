import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:test/test.dart';
import 'p2_ar_d0o_active_future_opening_test.dart' show firstPrepared, open;

void main() {
  test('AR-D pointers are additive and leave season-0 authorities unchanged',
      () {
    final app = firstPrepared();
    final b1 = app.committedSeasonResultCandidate;
    final b2 = app.acceptedPromiseClosingCandidate;
    final season0 = app.preseasonWeeklyState;
    final answered = app.answeredDecisionCount;
    final opening = open(app);
    app.acceptFuturePromise(
      expectedOpening: opening,
      expectedPending: opening.promisePending,
      choice: opening.controlledPromiseContext.allowedTypes.first,
    );
    expect(app.committedSeasonResultCandidate, same(b1));
    expect(app.acceptedPromiseClosingCandidate, same(b2));
    expect(app.preseasonWeeklyState, same(season0));
    expect(app.answeredDecisionCount, answered);
    expect(season0!.completedMatchCount, 720);
    expect(b2!.sourceResultCandidate, same(b1));
  });
}
