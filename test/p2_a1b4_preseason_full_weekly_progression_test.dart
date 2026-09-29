import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:test/test.dart';

class _FailOnWeekNineteen extends MatchEngine {
  const _FailOnWeekNineteen();

  @override
  MatchResult simulate({
    required Fixture fixture,
    required Club home,
    required Club away,
    required SimulationConfig config,
  }) {
    if (fixture.round == 19) {
      throw StateError('Injected real M2 MatchEngine failure at W19.');
    }
    return super.simulate(
      fixture: fixture, home: home, away: away, config: config,
    );
  }
}

class _UnadvancedCandidateCore extends WeeklyWorldFixtureResultCore {
  const _UnadvancedCandidateCore();

  @override
  WeeklyWorldFixtureSnapshot advanceRound({
    required WeeklyWorldFixtureSnapshot snapshot,
    required int expectedRound,
    required List<Club> effectiveClubs,
  }) => snapshot;
}

class _WrongStrengthCandidateCore extends WeeklyWorldFixtureResultCore {
  const _WrongStrengthCandidateCore();

  @override
  WeeklyWorldFixtureSnapshot advanceRound({
    required WeeklyWorldFixtureSnapshot snapshot,
    required int expectedRound,
    required List<Club> effectiveClubs,
  }) => super.advanceRound(
    snapshot: snapshot,
    expectedRound: expectedRound,
    effectiveClubs: [
      for (final club in effectiveClubs)
        if (club.id == 't1_01')
          club.copyWith(strength: club.strength == 40 ? 100 : 40)
        else
          club,
    ],
  );
}

List<Object?> _resultIdentity(WeeklyWorldFixture entry) => [
  entry.globalKey,
  entry.fixture.id,
  entry.fixture.result?.matchSeed,
  entry.fixture.result?.homeGoals,
  entry.fixture.result?.awayGoals,
  entry.fixture.result?.homeExpectedGoals,
  entry.fixture.result?.awayExpectedGoals,
];

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();

  PlayerPresidentInteractiveDecisionApplicationSession app({
    String controlledClubId = 't1_01',
  }) => PlayerPresidentInteractiveDecisionApplicationSession.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );

  PlayerPresidentPreseasonWeeklyState open(
    PlayerPresidentInteractiveDecisionApplicationSession session,
  ) {
    final boundary = session.startPreseasonPromise(
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    final applied = boundary.submit(
      pending: pending,
      choice: pending.context.allowedTypes.first,
    );
    expect(session.appliedPreseasonPromises, same(applied));
    return session.openPreseasonWeeklyHandoff();
  }
