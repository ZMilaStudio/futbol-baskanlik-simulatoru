import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_preseason_weekly_handoff.dart';
import 'package:test/test.dart';

class _FailAtThirty extends MatchEngine {
  const _FailAtThirty();
  @override
  MatchResult simulate({
    required Fixture fixture,
    required Club home,
    required Club away,
    required SimulationConfig config,
  }) {
    if (fixture.round == 30) throw StateError('Injected W30 failure.');
    return super.simulate(
      fixture: fixture, home: home, away: away, config: config,
    );
  }
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();

  PlayerPresidentInteractiveDecisionApplicationSession start({
    String controlledClubId = 't1_01',
  }) => PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs, leagues: world.leagues, config: config,
        controlledClubId: controlledClubId, seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      );

  PlayerPresidentPreseasonWeeklyState opening(
      PlayerPresidentInteractiveDecisionApplicationSession application) {
    final boundary = application.startPreseasonPromise(
      sourceClubs: world.clubs, sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    final applied = boundary.submit(
      pending: pending, choice: pending.context.allowedTypes.first,
    );
    expect(application.appliedPreseasonPromises, same(applied));
    return application.openPreseasonWeeklyHandoff();
  }

  late PlayerPresidentInteractiveDecisionApplicationSession app;
  late PlayerPresidentPreseasonWeeklyState w0;
  late PlayerPresidentPreseasonWeeklyState w29;
  late PlayerPresidentPreseasonWeeklyState w30;
  late PlayerPresidentCommittedSeasonResultCandidate candidate;

  setUpAll(() {
    app = start();
    var state = opening(app);
    w0 = state;
    for (var round = 1; round <= 30; round++) {
      if (round == 30) w29 = state;
      state = app.advancePreseasonWeek(
        expectedState: state, expectedRound: round,
      );
    }
    w30 = state;
    expect(() => app.projectCommittedSeason(expectedState: w29), throwsStateError);
    expect(app.committedSeasonResultCandidate, isNull);
    candidate = app.projectCommittedSeason(expectedState: w30);
  });

  test('owned W29 is rejected without any result publication', () {
    final before = app.committedSeasonResultCandidate;
    expect(() => app.projectCommittedSeason(expectedState: w29), throwsStateError);
    expect(app.committedSeasonResultCandidate, same(before));
    expect(app.preseasonWeeklyState, same(w30));
    expect(w29.completedMatchCount, 696);
    expect(w29.nextRound, 30);
  });

  test('real W30 produces three season reports and retains one accepted promise set', () {
    expect(app.projectCommittedSeason(expectedState: w30), same(candidate));
    expect(app.committedSeasonResultCandidate, same(candidate));
    expect(app.preseasonWeeklyState, same(w30));
    expect(candidate.sourceState, same(w30));
    expect(candidate.applied, same(w30.applied));
    expect(candidate.activePromises, same(w30.applied.activePromises));
    expect(candidate.activePromises.length, 48);
    expect(candidate.acceptedRequestKey, w30.applied.acceptedRequestKey);
    expect(candidate.acceptedChoice, w30.applied.acceptedChoice);
    expect(candidate.sourceIdentity, w30.sourceIdentity);
    expect(candidate.controlledClubId, w30.applied.controlledClubId);
    expect(candidate.controlledPresidentId, w30.applied.controlledPresidentId);
    expect(w30.nextRound, 31);
    expect(w30.fixtureSnapshot.isComplete, isTrue);
    expect(w30.completedMatchCount, 720);
    expect(candidate.leagueResults.map((value) => value.tier).toList(),
        LeagueTier.values);
    expect(candidate.leagueResults.length, 3);
    final all = candidate.leagueResults.expand((item) => item.report.fixtures);
    expect(all.length, 720);
    for (final league in world.leagues) {
      final report = candidate.reportFor(league.tier);
      expect(report.seasonIndex, config.seasonIndex);
      expect(report.seed, config.careerSeed);
      expect(report.fixtures.length, 240);
      expect(report.matchCount, 240);
      expect(report.table.length, 16);
      expect(report.table.every((row) => row.played == 30), isTrue);
      expect(report.championClubId, report.table.first.clubId);
      expect(report.homeWins + report.draws + report.awayWins, 240);
      expect(report.totalGoals, report.fixtures.fold<int>(0, (sum, fixture) =>
          sum + fixture.result!.homeGoals + fixture.result!.awayGoals));
      expect(const SeasonValidator().validate(report), isEmpty);
      expect(report.table.map((row) => row.toJson()).toList(),
          w30.fixtureSnapshot.tableFor(league.tier).map((row) => row.toJson()).toList());
      final source = w30.fixtureSnapshot.fixtures
          .where((entry) => entry.tier == league.tier)
          .map((entry) => entry.fixture).toList();
      for (var index = 0; index < 240; index++) {
        expect(report.fixtures[index], same(source[index]));
      }
    }
  });

  test('independent legacy oracle matches 720 real scores, xG, seed and standings', () {
    for (final league in world.leagues) {
      final clubs = [
        for (final id in league.clubIds)
          w30.effectiveClubs.singleWhere((club) => club.id == id),
      ];
      final legacy = const SeasonEngine().simulate(clubs: clubs, config: config);
      final result = candidate.reportFor(league.tier);
      expect(result.fixtures.length, legacy.fixtures.length);
      expect(result.championClubId, legacy.championClubId);
      expect(result.homeWins, legacy.homeWins);
      expect(result.draws, legacy.draws);
      expect(result.awayWins, legacy.awayWins);
      expect(result.totalGoals, legacy.totalGoals);
      expect(result.table.map((row) => row.toJson()).toList(),
          legacy.table.map((row) => row.toJson()).toList());
      for (var i = 0; i < 240; i++) {
        final a = result.fixtures[i];
        final b = legacy.fixtures[i];
        expect(a.id, b.id);
        expect(a.seasonIndex, b.seasonIndex);
        expect(a.round, b.round);
        expect(a.homeClubId, b.homeClubId);
        expect(a.awayClubId, b.awayClubId);
        expect(a.result!.matchSeed, b.result!.matchSeed);
        expect(a.result!.homeGoals, b.result!.homeGoals);
        expect(a.result!.awayGoals, b.result!.awayGoals);
        expect(a.result!.homeExpectedGoals, b.result!.homeExpectedGoals);
        expect(a.result!.awayExpectedGoals, b.result!.awayExpectedGoals);
      }
    }
  });

  test('mutable legacy report views cannot alter immutable candidate, fixtures, or W30', () {
    final before = candidate.reportFor(LeagueTier.first);
    final original = before.table.first.toJson();
    final originalFixture = before.fixtures.first;
    before.table.first
      ..points = -999
      ..wins = -1
      ..goalsFor = 12345;
    final after = candidate.reportFor(LeagueTier.first);
    expect(after.table.first.toJson(), original);
    expect(after.fixtures.first, same(originalFixture));
    expect(after.table.first.toJson(),
        w30.fixtureSnapshot.tableFor(LeagueTier.first).first.toJson());
    expect(() => before.table.clear(), throwsUnsupportedError);
    expect(() => before.fixtures.clear(), throwsUnsupportedError);
    expect(() => candidate.leagueResults.clear(), throwsUnsupportedError);
    expect(() => candidate.activePromises.clear(), throwsUnsupportedError);
    final observed = candidate.leagueResults.first.report;
    observed.table.first.points = -100;
    expect(candidate.leagueResults.first.report.table.first.toJson(), original);
    expect(app.preseasonWeeklyState, same(w30));
    expect(w0.fixtureSnapshot.completedMatchCount, 0);
    expect(w29.fixtureSnapshot.completedMatchCount, 696);
  });

  test('same W30 duplicate returns identical candidate; foreign/stale states rejected', () {
    expect(app.projectCommittedSeason(expectedState: w30), same(candidate));
    expect(app.committedSeasonResultCandidate, same(candidate));
    expect(() => app.projectCommittedSeason(expectedState: w29), throwsStateError);
    final foreign = start(controlledClubId: 't1_02');
    final foreignW0 = opening(foreign);
    expect(() => app.projectCommittedSeason(expectedState: foreignW0), throwsStateError);
    expect(() => const PlayerPresidentCommittedSeasonResultProjection()
        .project(state: foreignW0), throwsStateError);
    expect(app.committedSeasonResultCandidate, same(candidate));
    expect(app.preseasonWeeklyState, same(w30));
    expect(() => app.advancePreseasonWeek(expectedState: w30, expectedRound: 31),
        throwsStateError);
    expect(app.canPersist, isFalse);
    expect(app.canPersistBootstrap, isFalse);
    expect(() => app.persistenceBundle, throwsStateError);
    expect(() => app.newGameBootstrapSnapshot, throwsStateError);
  });

  test('existing M2 W30 exception retains W29, then same state retries successfully', () {
    final another = start();
    var state = opening(another);
    for (var round = 1; round <= 29; round++) {
      state = another.advancePreseasonWeek(expectedState: state, expectedRound: round);
    }
    final before = state;
    final history = before.fixtureSnapshot.fixtures.toList();
    expect(() => another.advancePreseasonWeek(
      expectedState: before, expectedRound: 30,
      core: const WeeklyWorldFixtureResultCore(matchEngine: _FailAtThirty()),
    ), throwsStateError);
    expect(another.preseasonWeeklyState, same(before));
    expect(another.committedSeasonResultCandidate, isNull);
    expect(() => another.projectCommittedSeason(expectedState: before), throwsStateError);
    for (var i = 0; i < 720; i++) {
      expect(before.fixtureSnapshot.fixtures[i], same(history[i]));
    }
    final next = another.advancePreseasonWeek(
      expectedState: before, expectedRound: 30,
    );
    expect(next.completedMatchCount, 720);
    final projected = another.projectCommittedSeason(expectedState: next);
    expect(projected.leagueResults.length, 3);
    expect(another.preseasonWeeklyState, same(next));
    expect(before.fixtureSnapshot.completedMatchCount, 696);
  });
}
