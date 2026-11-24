import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:test/test.dart';
import 'support/owned_career_driver.dart'
    show playOwnedSeason, settleOwnedSeason;
import 'support/owned_observation_driver.dart';

void main() {
  test('genuine empty historical transfer window retains the actual closing',
      () {
    final app = observationCareer('t1_01');
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final ready = completeObservedPostseason(app, closed)
        as PlayerPresidentOwnedSeasonContinuationReady;
    expect(ready.completedTransfers.completedSeasonIndex, 0);
    expect(ready.completedTransfers.targetSeasonIndex, 1);
    expect(ready.completedTransfers.controlledClubId, 't1_01');
    expect(ready.completedTransfers.transfers, isEmpty);
    expect(ready.completedTransfers.loans, isEmpty);
    expect(ready.completedPromise, same(closed.promise));
    expect(ready.completedManager, isNull);
  });

  test('real permanent deals survive activation with immutable installments',
      () {
    final app = observationCareer('t1_01', seed: 42002);
    final initial = completeObservedPostseason(
            app, app.closeSeason(expected: playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    app.activateNextSeason(expected: initial);
    final ready = completeObservedPostseason(
            app, settleOwnedSeason(app, playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final snapshot = ready.completedTransfers;
    expect(snapshot.completedSeasonIndex, 1);
    expect(snapshot.targetSeasonIndex, 2);
    expect(snapshot.transfers, isNotEmpty);
    expect(
        snapshot.transfers.every(
            (row) => row.fromClubId == 't1_01' || row.toClubId == 't1_01'),
        isTrue);
    expect(() => snapshot.transfers.clear(), throwsUnsupportedError);
    for (final row in snapshot.transfers) {
      expect(() => row.installments.clear(), throwsUnsupportedError);
    }
    final signature = snapshot.signature;
    app.activateNextSeason(expected: ready);
    expect(ready.completedTransfers, same(snapshot));
    expect(snapshot.signature, signature);
  });

  test('only new loans are retained across genuine future seasons', () {
    final app = observationCareer('t1_06');
    final initial = completeObservedPostseason(
            app, app.closeSeason(expected: playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final first = initial.completedTransfers;
    expect(first.loans, isNotEmpty);
    expect(first.loans.every((row) => row.startSeasonIndex == 1), isTrue);
    expect(() => first.loans.clear(), throwsUnsupportedError);
    final signature = first.signature;
    app.activateNextSeason(expected: initial);
    final ready = completeObservedPostseason(
            app, settleOwnedSeason(app, playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final second = ready.completedTransfers;
    expect(second.loans, isNotEmpty);
    expect(second.loans.every((row) => row.startSeasonIndex == 2), isTrue);
    final secondSignature = second.signature;
    app.activateNextSeason(expected: ready);
    final later = completeObservedPostseason(
            app, settleOwnedSeason(app, playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    app.activateNextSeason(expected: later);
    expect(app.currentSeasonOpening.seasonIndex, 3);
    expect(initial.completedTransfers, same(first));
    expect(first.signature, signature);
    expect(second.signature, secondSignature);
  });

  test('real historical and future losses retain the actual executed window',
      () {
    for (final future in [false, true]) {
      final id = future ? 't3_16' : 't1_16';
      final app = observationCareer(id, electionInterval: 1);
      PlayerPresidentOwnedSeasonCompletion completed =
          app.closeSeason(expected: playOwnedSeason(app));
      if (future) {
        final first = completeObservedPostseason(app, completed)
            as PlayerPresidentOwnedSeasonContinuationReady;
        app.activateNextSeason(expected: first);
        completed = settleOwnedSeason(app, playOwnedSeason(app));
      }
      final ended = completeObservedPostseason(app, completed)
          as PlayerPresidentOwnedCareerEnded;
      final snapshot = ended.completedTransfers;
      expect(ended.control.lost, isTrue);
      expect(snapshot.controlledClubId, id);
      expect(snapshot.completedSeasonIndex, future ? 1 : 0);
      expect(snapshot.loans, isNotEmpty);
      final signature = snapshot.signature;
      expect(() => app.continueToNextSeason(expected: completed),
          throwsStateError);
      expect(app.currentStep, same(ended));
      expect(ended.completedTransfers, same(snapshot));
      expect(snapshot.signature, signature);
    }
  });

  test('foreign and duplicate activation cannot rewrite a completed window',
      () {
    final app = observationCareer('t1_06'), other = observationCareer('t1_06');
    final ready = completeObservedPostseason(
            app, app.closeSeason(expected: playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final foreign = completeObservedPostseason(
            other, other.closeSeason(expected: playOwnedSeason(other)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    final snapshot = ready.completedTransfers,
        signature = ready.completedTransfers.signature;
    expect(() => app.activateNextSeason(expected: foreign), throwsStateError);
    expect(app.currentStep, same(ready));
    app.activateNextSeason(expected: ready);
    expect(() => app.activateNextSeason(expected: ready), throwsStateError);
    expect(snapshot.signature, signature);
  });
}
