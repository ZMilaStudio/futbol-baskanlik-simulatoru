import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:test/test.dart';
import 'support/owned_career_driver.dart'
    show playOwnedSeason, settleOwnedSeason;
import 'support/owned_observation_driver.dart';

void main() {
  test('real historical retirement and intake are immutable observations', () {
    final app = observationCareer('t1_01');
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final ready = completeObservedPostseason(app, closed)
        as PlayerPresidentOwnedSeasonContinuationReady;
    final snapshot = ready.completedRoster;
    expect(snapshot.completedSeasonIndex, 0);
    expect(snapshot.targetSeasonIndex, 1);
    expect(snapshot.controlledClubId, 't1_01');
    expect(snapshot.retiredPlayers.single.playerId, 'p_t1_01_03');
    expect(snapshot.youthIntake.single.playerId, 'y_t1_01_s1');
    expect(() => snapshot.retiredPlayers.clear(), throwsUnsupportedError);
    expect(() => snapshot.youthIntake.clear(), throwsUnsupportedError);
    expect(ready.completedManager, isNull);
    expect(ready.completedPromise, same(closed.promise));
  });

  test(
      'empty retirements and moved youth keep event-time playing-club identity',
      () {
    final app = observationCareer('t1_06');
    final ready = completeObservedPostseason(
            app, app.closeSeason(expected: playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final snapshot = ready.completedRoster,
        youth = ready.completedRoster.youthIntake.single;
    final loan = ready.completedTransfers.loans
        .singleWhere((loan) => loan.playerId == youth.playerId);
    expect(snapshot.retiredPlayers, isEmpty);
    expect(loan.parentClubId, snapshot.controlledClubId);
    expect(loan.loanClubId, isNot(snapshot.controlledClubId));
    final signature = snapshot.signature;
    app.activateNextSeason(expected: ready);
    expect(
        app.currentSeasonOpening.squad.players
            .where((row) => row.playerId == youth.playerId),
        isEmpty);
    expect(ready.completedRoster, same(snapshot));
    expect(snapshot.signature, signature);
  });

  test('roster events remain stable through future three and stale events', () {
    final app = observationCareer('t1_01');
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final initial = completeObservedPostseason(app, closed)
        as PlayerPresidentOwnedSeasonContinuationReady;
    final first = initial.completedRoster,
        signature = initial.completedRoster.signature;
    final finance = closed.finance.signature,
        promise = closed.promise.signature;
    app.activateNextSeason(expected: initial);
    final next = completeObservedPostseason(
            app, settleOwnedSeason(app, playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final second = next.completedRoster,
        secondSignature = next.completedRoster.signature;
    expect(second.completedSeasonIndex, 1);
    expect(second.retiredPlayers, isNotEmpty);
    app.activateNextSeason(expected: next);
    final later = completeObservedPostseason(
            app, settleOwnedSeason(app, playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    app.activateNextSeason(expected: later);
    final current = app.currentStep;
    expect(() => app.activateNextSeason(expected: initial), throwsStateError);
    expect(app.currentStep, same(current));
    expect(app.currentSeasonOpening.seasonIndex, 3);
    for (var read = 0; read < 3; read++) {
      expect(initial.completedRoster, same(first));
      expect(first.signature, signature);
      expect(second.signature, secondSignature);
      expect(closed.finance.signature, finance);
      expect(closed.promise.signature, promise);
    }
  });

  test('historical and future career loss retain actual lifecycle events', () {
    for (final future in [false, true]) {
      final id = future ? 't3_16' : 't1_16';
      final app = observationCareer(id, electionInterval: 1);
      PlayerPresidentOwnedSeasonCompletion completed =
          app.closeSeason(expected: playOwnedSeason(app));
      if (future) {
        final ready = completeObservedPostseason(app, completed)
            as PlayerPresidentOwnedSeasonContinuationReady;
        app.activateNextSeason(expected: ready);
        completed = settleOwnedSeason(app, playOwnedSeason(app));
      }
      final ended = completeObservedPostseason(app, completed)
          as PlayerPresidentOwnedCareerEnded;
      final snapshot = ended.completedRoster;
      expect(ended.control.lost, isTrue);
      expect(snapshot.controlledClubId, id);
      expect(snapshot.completedSeasonIndex, future ? 1 : 0);
      expect(snapshot.youthIntake, isNotEmpty);
      expect(ended.completedManager == null, !future);
      final signature = snapshot.signature;
      expect(() => app.continueToNextSeason(expected: completed),
          throwsStateError);
      expect(app.currentStep, same(ended));
      expect(ended.completedRoster, same(snapshot));
      expect(snapshot.signature, signature);
    }
  });
}
