import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart' show settleOwnedSeason;

PlayerPresidentOwnedSeasonApplication _start({
  String clubId = 't1_01',
  int electionInterval = 4,
}) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: clubId,
    electionInterval: electionInterval,
  );
}

(PlayerPresidentOwnedSeasonRunning, PresidentPromise) _play(
    PlayerPresidentOwnedSeasonApplication app,
    {bool lastChoice = false}) {
  final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
  final allowed =
      pending.request.contextAs<PlayerPromiseDecisionContext>().allowedTypes;
  final resolved = app.submitPromise(
      expected: pending, choice: lastChoice ? allowed.last : allowed.first);
  var running = app.continueAfterPromise(expected: resolved);
  for (var round = 1; round <= 30; round++) {
    running = app.advanceRound(expected: running);
  }
  return (running, resolved.consequence.promise);
}

PlayerPresidentOwnedSeasonStep _continue(
    PlayerPresidentOwnedSeasonApplication app,
    PlayerPresidentOwnedSeasonCompletion completed) {
  var step = app.continueToNextSeason(expected: completed);
  if (step is PlayerPresidentOwnedSeasonTransferPending) {
    step = app.submitTransfer(
      expected: step,
      choice: PlayerTransferStrategyChoice.fromProfile(step.context.aiProfile),
    );
  }
  if (step is PlayerPresidentOwnedSeasonManagerReviewPending) {
    step = app.submitManagerReview(
      expected: step,
      choice: step.context.canRetain
          ? PlayerManagerReviewChoice.retain
          : PlayerManagerReviewChoice.replace,
    );
  }
  if (step is PlayerPresidentOwnedSeasonManagerReplacementPending) {
    step = app.submitManagerReplacement(
        expected: step, selected: step.context.candidates.first.manager);
  }
  return step;
}

void main() {
  test(
      'historical Ready retains the exact B2 promise through future activation',
      () {
    final app = _start();
    final (w30, accepted) = _play(app);
    final closed = app.closeSeason(expected: w30);
    final ready =
        _continue(app, closed) as PlayerPresidentOwnedSeasonContinuationReady;
    expect(ready.completedPromise, same(closed.promise));
    expect(ready.completedPromise.promise, same(accepted));
    expect(
        ready.completedPromise.promise.seasonIndex, ready.completedSeasonIndex);
    expect(
        ready.completedPromise.promise.clubId, ready.control.controlledClubId);
    final before = ready.completedPromise.signature;
    app.activateNextSeason(expected: ready);
    expect(ready.completedPromise.signature, before);
    expect(closed.promise, same(ready.completedPromise));
  });

  test(
      'future Ready observes the actual accepted promise after domain completion',
      () {
    final app = _start();
    final historical = app.closeSeason(expected: _play(app).$1);
    final initialReady = _continue(app, historical)
        as PlayerPresidentOwnedSeasonContinuationReady;
    app.activateNextSeason(expected: initialReady);
    final (w30, accepted) = _play(app, lastChoice: true);
    final settled = settleOwnedSeason(app, w30);
    expect(app.currentStep, same(settled));
    final ready =
        _continue(app, settled) as PlayerPresidentOwnedSeasonContinuationReady;
    final snapshot = ready.completedPromise;
    expect(snapshot.promise, same(accepted));
    expect(snapshot.resolution.promise, same(accepted));
    expect(snapshot.context.seasonIndex, 1);
    expect(snapshot.outcome.seasonIndex, 1);
    expect(snapshot.promise.seasonIndex, ready.completedSeasonIndex);
    expect(snapshot.promise.clubId, ready.control.controlledClubId);
    expect(snapshot.outcome.openingDebt, settled.finance.openingDebt);
    expect(snapshot.outcome.closingDebt, settled.finance.closingDebt);
    expect(snapshot.outcome.emergencyBorrowing,
        settled.finance.emergencyBorrowing);
    expect(snapshot.context.clubId, settled.controlledClubId);
    final before = snapshot.signature;

    app.activateNextSeason(expected: ready);
    final (nextW30, nextAccepted) = _play(app);
    final next = _continue(app, settleOwnedSeason(app, nextW30))
        as PlayerPresidentOwnedSeasonContinuationReady;
    expect(next.completedPromise.promise, same(nextAccepted));
    expect(next.completedPromise.promise.seasonIndex, 2);
    expect(next.completedPromise, isNot(same(snapshot)));
    expect(ready.completedPromise, same(snapshot));
    expect(snapshot.signature, before);
    expect(initialReady.completedPromise, same(historical.promise));
  });

  test('historical loss exposes the real closing promise on terminal outcome',
      () {
    final app = _start(clubId: 't1_16', electionInterval: 1);
    final (w30, accepted) = _play(app);
    final closed = app.closeSeason(expected: w30);
    final ended = _continue(app, closed) as PlayerPresidentOwnedCareerEnded;
    expect(ended.control.lost, isTrue);
    expect(ended.completedSeasonIndex, 0);
    expect(ended.completedPromise, same(closed.promise));
    expect(ended.completedPromise.promise, same(accepted));
    expect(
        ended.completedPromise.context.clubId, ended.control.controlledClubId);
    expect(() => app.continueToNextSeason(expected: closed), throwsStateError);
    expect(app.currentStep, same(ended));
    expect(ended.completedPromise, same(closed.promise));
  });

  test('future loss retains the resolved promise for the actual final season',
      () {
    final app = _start(clubId: 't3_16', electionInterval: 1);
    final historical = app.closeSeason(expected: _play(app).$1);
    final initialReady = _continue(app, historical)
        as PlayerPresidentOwnedSeasonContinuationReady;
    app.activateNextSeason(expected: initialReady);
    final (w30, accepted) = _play(app);
    final settled = settleOwnedSeason(app, w30);
    final ended = _continue(app, settled) as PlayerPresidentOwnedCareerEnded;
    expect(ended.control.lost, isTrue);
    expect(ended.completedSeasonIndex, 1);
    expect(ended.completedPromise.promise, same(accepted));
    expect(
        ended.completedPromise.context.seasonIndex, ended.completedSeasonIndex);
    expect(
        ended.completedPromise.context.clubId, ended.control.controlledClubId);
    expect(ended.completedPromise.outcome.closingDebt,
        settled.finance.closingDebt);
    final before = ended.completedPromise.signature;
    expect(() => app.continueToNextSeason(expected: settled), throwsStateError);
    expect(
        () => app.activateNextSeason(expected: initialReady), throwsStateError);
    expect(app.currentStep, same(ended));
    expect(ended.completedPromise.signature, before);
  });
}
