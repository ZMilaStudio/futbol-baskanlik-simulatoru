import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:test/test.dart';

const _config = SimulationConfig(careerSeed: 20260903);

PlayerPresidentOwnedSeasonApplication _start({String clubId = 't1_01'}) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: _config,
    controlledClubId: clubId,
  );
}

PlayerPresidentOwnedSeasonPromiseResolved _accept(
  PlayerPresidentOwnedSeasonApplication application,
) {
  final pending =
      application.currentStep as PlayerPresidentOwnedSeasonPromisePending;
  final context = pending.request.contextAs<PlayerPromiseDecisionContext>();
  return application.submitPromise(
    expected: pending,
    choice: context.allowedTypes.first,
  );
}

PlayerPresidentOwnedSeasonRunning _open(
  PlayerPresidentOwnedSeasonApplication application,
) =>
    application.continueAfterPromise(expected: _accept(application));

PlayerPresidentOwnedSeasonRunning _finish(
  PlayerPresidentOwnedSeasonApplication application,
) {
  var running = _open(application);
  for (var round = 1; round <= 30; round++) {
    running = application.advanceRound(expected: running);
  }
  return running;
}

List<Object> _results(List<LeagueSeasonSnapshot> leagues) => [
      for (final league in leagues)
        [
          league.tier.level,
          league.report.toJson(),
          [
            for (final fixture in league.report.fixtures)
              [
                fixture.id,
                fixture.homeClubId,
                fixture.awayClubId,
                fixture.result!.matchSeed,
                fixture.result!.homeGoals,
                fixture.result!.awayGoals,
                fixture.result!.homeExpectedGoals,
                fixture.result!.awayExpectedGoals,
              ],
          ],
        ],
    ];

void main() {
  test('public entry exposes the real preseason Pending and prepared views',
      () {
    final application = _start();
    final pending =
        application.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(pending.request.phase, 'preseasonPromise');
    expect(pending.request.sequence, 1);
    expect(
        pending.request.kind, PlayerPresidentInteractiveDecisionKind.promise);
    expect(pending.request.clubId, 't1_01');
    expect(pending.request.keyNamespace, startsWith('preseason-promise/v1:'));
    expect(application.preparedSeasonDashboard.controlledClubId, 't1_01');
    expect(application.preparedSeasonDashboard.seasonIndex, 0);
    expect(application.preparedSquad.controlledClubId, 't1_01');
    expect(application.preparedSquad.players, hasLength(18));
    expect(application.preparedSeasonFixtures.seasonIndex, 0);
    expect(application.currentStep, same(pending));
  });

  test('acceptance publishes the authoritative consequence before W0', () {
    final application = _start();
    final pending =
        application.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final context = pending.request.contextAs<PlayerPromiseDecisionContext>();
    final resolved = _accept(application);
    expect(application.currentStep, same(resolved));
    expect(resolved.consequence.context.signature, context.signature);
    expect(resolved.consequence.promise.type, context.allowedTypes.first);
    expect(resolved.consequence.promise.clubId, pending.request.clubId);
    expect(resolved.consequence.promise.seasonIndex, 0);
    expect(resolved.consequence.promise.id, 'promise_t1_01_s0');
    final running = application.continueAfterPromise(expected: resolved);
    expect(application.currentStep, same(running));
    expect(running.seasonIndex, 0);
    expect(running.nextRound, 1);
    expect(running.completedMatchCount, 0);
    expect(running.fixtures.fixtures, hasLength(720));
    expect(running.fixtures.fixtures.every((fixture) => !fixture.isPlayed),
        isTrue);
  });

  test('foreign and already consumed Pending cannot accept another answer', () {
    final application = _start();
    final foreign =
        _start().currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final own =
        application.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final choice = own.request
        .contextAs<PlayerPromiseDecisionContext>()
        .allowedTypes
        .first;
    expect(() => application.submitPromise(expected: foreign, choice: choice),
        throwsStateError);
    expect(application.currentStep, same(own));
    final resolved = application.submitPromise(expected: own, choice: choice);
    expect(() => application.submitPromise(expected: own, choice: choice),
        throwsStateError);
    expect(application.currentStep, same(resolved));
  });

  test('invalid promise is rejected without consuming the real Pending', () {
    final application = _start();
    final pending =
        application.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final allowed =
        pending.request.contextAs<PlayerPromiseDecisionContext>().allowedTypes;
    final invalid = PresidentPromiseType.values
        .firstWhere((choice) => !allowed.contains(choice));
    expect(() => application.submitPromise(expected: pending, choice: invalid),
        throwsArgumentError);
    expect(application.currentStep, same(pending));
    expect(
        _accept(application), isA<PlayerPresidentOwnedSeasonPromiseResolved>());
  });

  test('foreign and acknowledged Resolution cannot open another W0', () {
    final application = _start();
    final resolved = _accept(application);
    final foreign = _accept(_start());
    expect(() => application.continueAfterPromise(expected: foreign),
        throwsStateError);
    expect(application.currentStep, same(resolved));
    final running = application.continueAfterPromise(expected: resolved);
    expect(() => application.continueAfterPromise(expected: resolved),
        throwsStateError);
    expect(application.currentStep, same(running));
  });

  test('foreign and stale Running observations cannot advance a round', () {
    final application = _start();
    final w0 = _open(application);
    final foreign = _open(_start());
    expect(() => application.advanceRound(expected: foreign), throwsStateError);
    expect(application.currentStep, same(w0));
    final w1 = application.advanceRound(expected: w0);
    expect(w1.nextRound, 2);
    expect(w1.completedMatchCount, 24);
    expect(() => application.advanceRound(expected: w0), throwsStateError);
    expect(application.currentStep, same(w1));
    expect(w0.completedMatchCount, 0);
  });

  test('public progression preserves committed history through exactly W30',
      () {
    final application = _start();
    var running = _open(application);
    for (var round = 1; round <= 30; round++) {
      final previous = running;
      running = application.advanceRound(expected: previous);
      expect(running.completedMatchCount, round * 24);
      expect(running.nextRound, round + 1);
      expect(running.isComplete, round == 30);
      for (var i = 0; i < previous.fixtures.fixtures.length; i++) {
        final old = previous.fixtures.fixtures[i];
        if (old.round != round) {
          expect(running.fixtures.fixtures[i], same(old));
        }
      }
    }
    expect(
        running.fixtures.fixtures.every((fixture) => fixture.isPlayed), isTrue);
    expect(() => application.advanceRound(expected: running), throwsStateError);
    expect(application.currentStep, same(running));
  });

  test('premature and foreign closing preserve the current weekly boundary',
      () {
    final application = _start();
    final w0 = _open(application);
    expect(() => application.closeSeason(expected: w0), throwsStateError);
    expect(application.currentStep, same(w0));
    final foreign = _finish(_start());
    expect(() => application.closeSeason(expected: foreign), throwsStateError);
    expect(application.currentStep, same(w0));
    expect(application.advanceRound(expected: w0).completedMatchCount, 24);
  });

  test('closed observation delegates exact genuine B1/B2 output', () {
    final application = _start();
    final w30 = _finish(application);
    final closed = application.closeSeason(expected: w30);

    // Independent genuine production-owner path, without constructing any
    // closing authority, replaying history, or fabricating a checkpoint.
    final world = const FictionalWorldFactory().build();
    final lowLevel = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      controlledClubId: 't1_01',
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final boundary = lowLevel.startPreseasonPromise(
        sourceClubs: world.clubs, sourceLeagues: world.leagues);
    final pending = boundary.pending!;
    boundary.submit(
        pending: pending, choice: pending.context.allowedTypes.first);
    var state = lowLevel.openPreseasonWeeklyHandoff();
    for (var round = 1; round <= 30; round++) {
      state = lowLevel.advancePreseasonWeek(
          expectedState: state, expectedRound: round);
    }
    final b1 = lowLevel.projectCommittedSeason(expectedState: state);
    final b2 = lowLevel.closeAcceptedPromises(expectedResultCandidate: b1);
    expect(closed.seasonIndex, b2.seasonIndex);
    expect(closed.controlledClubId, b2.controlledClubId);
    expect(closed.finance.signature, b2.financeFor('t1_01').signature);
    expect(closed.promise.signature, b2.promiseFor('t1_01').signature);
    expect(_results(closed.leagueResults), _results(b2.leagueResults));
    expect(closed.leagueResults, hasLength(3));
    expect(
        closed.leagueResults
            .fold<int>(0, (count, league) => count + league.report.matchCount),
        720);
    expect(lowLevel.canPersist, isFalse);
    expect(lowLevel.canPersistBootstrap, isFalse);
    expect(() => lowLevel.encodePersistenceBundle(), throwsStateError);
    expect(() => lowLevel.encodeNewGameBootstrapSnapshot(), throwsStateError);
    expect(() => application.closeSeason(expected: w30), throwsStateError);
    expect(() => application.advanceRound(expected: w30), throwsStateError);
    expect(application.currentStep, same(closed));
  });

  test('fixture observations are immutable and closing rows are defensive', () {
    final application = _start();
    final w30 = _finish(application);
    expect(() => w30.fixtures.fixtures.clear(), throwsUnsupportedError);
    expect(() => w30.fixtures.tables.clear(), throwsUnsupportedError);
    expect(
        () => w30.fixtures.tables.values.first.clear(), throwsUnsupportedError);
    final closed = application.closeSeason(expected: w30);
    final before = jsonEncode(_results(closed.leagueResults));
    final observed = closed.leagueResults;
    expect(() => observed.clear(), throwsUnsupportedError);
    observed.first.report.table.first.record(scored: 1000, conceded: 0);
    expect(jsonEncode(_results(closed.leagueResults)), before);
    expect(w30.fixtures.tables.values.first.every((row) => row.played == 30),
        isTrue);
  });

  test('same public inputs and accepted choice produce deterministic closing',
      () {
    final first = _start(clubId: 't2_01');
    final second = _start(clubId: 't2_01');
    expect(first.preparedSeasonDashboard.signature,
        second.preparedSeasonDashboard.signature);
    expect(first.preparedSquad.signature, second.preparedSquad.signature);
    final firstClosed = first.closeSeason(expected: _finish(first));
    final secondClosed = second.closeSeason(expected: _finish(second));
    expect(firstClosed.finance.signature, secondClosed.finance.signature);
    expect(firstClosed.promise.signature, secondClosed.promise.signature);
    expect(_results(firstClosed.leagueResults),
        _results(secondClosed.leagueResults));
  });
}
