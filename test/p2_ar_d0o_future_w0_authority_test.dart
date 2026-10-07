import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_ar_d0o_active_future_opening_test.dart' show laterPrepared, open;

class D0OFixtureProbe extends FixtureGenerator {
  int calls = 0;
  bool fail = false;
  @override
  List<Fixture> generateDoubleRoundRobin(
      {required List<Club> clubs, required int seasonIndex}) {
    calls++;
    if (fail) throw StateError('Injected original fixture-policy failure');
    return super
        .generateDoubleRoundRobin(clubs: clubs, seasonIndex: seasonIndex);
  }
}

class D0OMatchProbe extends MatchEngine {
  int calls = 0;
  @override
  MatchResult simulate(
      {required Fixture fixture,
      required Club home,
      required Club away,
      required SimulationConfig config}) {
    calls++;
    return super
        .simulate(fixture: fixture, home: home, away: away, config: config);
  }
}

void main() {
  test('W0 uses exact original fixture policy once, pristine target season',
      () {
    final probe = D0OFixtureProbe();
    final match = D0OMatchProbe();
    final app = laterPrepared(B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(
            seasonEngine:
                SeasonEngine(fixtureGenerator: probe, matchEngine: match))));
    final before = probe.calls;
    final matchBefore = match.calls;
    final result = open(app);
    expect(probe.calls, before + 3);
    expect(match.calls, matchBefore);
    final w0 = result.w0;
    expect(w0.seasonIndex, result.targetSeasonIndex);
    expect(w0.nextRound, 1);
    expect(w0.completedMatchCount, 0);
    expect(w0.isComplete, isFalse);
    expect(w0.fixtures.length, 720);
    expect(w0.fixtures.map((f) => f.globalKey).toSet().length, 720);
    expect(w0.fixtures.every((f) => !f.isPlayed && f.fixture.result == null),
        isTrue);
    expect(w0.tables.length, 3);
    expect(
        w0.tables.values
            .every((t) => t.length == 16 && t.every((r) => r.played == 0)),
        isTrue);
    expect(open(app), same(result));
    expect(probe.calls, before + 3);
  });
  test(
      'fixture failure publishes/reserves nothing; correct retry remains possible',
      () {
    final probe = D0OFixtureProbe();
    final app = laterPrepared(B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(
            seasonEngine: SeasonEngine(fixtureGenerator: probe))));
    final prepared = app.futureRuntimeAdmission!.prepared;
    probe.fail = true;
    expect(() => open(app), throwsStateError);
    expect(app.activeFutureSeasonOpening, isNull);
    expect(prepared.state, PreparedExecutionState.prepared);
    probe.fail = false;
    expect(open(app).prepared, same(prepared));
  });
}
