import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart'
    show startOwnedCareer, playOwnedSeason, settleOwnedSeason;

({
  PlayerPresidentOwnedSeasonStep step,
  ManagerClubSeason? assessment,
  Manager? selected
}) _continue(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonCompletion completed, {
  bool replaceManager = false,
  void Function(PlayerPresidentOwnedSeasonStep)? observe,
}) {
  var step = app.continueToNextSeason(expected: completed);
  observe?.call(step);
  if (step is PlayerPresidentOwnedSeasonTransferPending) {
    step = app.submitTransfer(
      expected: step,
      choice: PlayerTransferStrategyChoice.fromProfile(step.context.aiProfile),
    );
    observe?.call(step);
  }
  ManagerClubSeason? assessment;
  if (step is PlayerPresidentOwnedSeasonManagerReviewPending) {
    assessment = step.context.season;
    step = app.submitManagerReview(
      expected: step,
      choice: replaceManager || !step.context.canRetain
          ? PlayerManagerReviewChoice.replace
          : PlayerManagerReviewChoice.retain,
    );
    observe?.call(step);
  }
  Manager? selected;
  if (step is PlayerPresidentOwnedSeasonManagerReplacementPending) {
    selected = step.context.candidates.first.manager;
    step = app.submitManagerReplacement(expected: step, selected: selected);
    observe?.call(step);
  }
  return (step: step, assessment: assessment, selected: selected);
}

PlayerPresidentOwnedSeasonApplication _firstFuture() {
  final app = startOwnedCareer();
  final closed = app.closeSeason(expected: playOwnedSeason(app));
  final ready = _continue(app, closed).step
      as PlayerPresidentOwnedSeasonContinuationReady;
  app.activateNextSeason(expected: ready);
  return app;
}

PlayerPresidentOwnedSeasonApplication _electionCareer(String clubId) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: clubId,
    electionInterval: 1,
  );
}

void main() {
  test('historical Ready has no fabricated closed manager assessment', () {
    final app = startOwnedCareer();
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final ready = _continue(app, closed).step
        as PlayerPresidentOwnedSeasonContinuationReady;

    expect(ready.completedSeasonIndex, 0);
    expect(ready.managerHistorySeasonIndices, isEmpty);
    expect(ready.completedManager, isNull);
    app.activateNextSeason(expected: ready);
    expect(ready.completedManager, isNull);
  });

  test('genuine historical loss still has no season-zero manager authority',
      () {
    final app = _electionCareer('t1_16');
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final ended =
        _continue(app, closed).step as PlayerPresidentOwnedCareerEnded;

    expect(ended.control.lost, isTrue);
    expect(ended.completedSeasonIndex, 0);
    expect(ended.completedManager, isNull);
  });

  test('future Ready retains the exact actual manager review assessment', () {
    final app = _firstFuture();
    final opening = app.currentSeasonOpening;
    final settled = settleOwnedSeason(app, playOwnedSeason(app));
    expect(settled.managerHistorySeasonIndices, isEmpty);
    final closing = _continue(app, settled);
    final ready = closing.step as PlayerPresidentOwnedSeasonContinuationReady;
    final assessment = ready.completedManager!;
    final standing = settled.leagueTable.rows
        .singleWhere((row) => row.clubId == opening.controlledClubId);

    expect(closing.assessment, isNotNull);
    expect(assessment, same(closing.assessment));
    expect(ready.completedSeasonIndex, 1);
    expect(assessment.clubId, ready.control.controlledClubId);
    expect(assessment.managerId, opening.dashboard.manager.id);
    expect(assessment.actualPosition, standing.position);
    expect(ready.managerHistorySeasonIndices, [1]);
    expect(app.currentStep, same(ready));
    expect(ready.completedManager, same(assessment));
  });

  test('future two assessment survives future three replacement and activation',
      () {
    final app = _firstFuture();
    final firstSettled = settleOwnedSeason(app, playOwnedSeason(app));
    final firstReady = _continue(app, firstSettled).step
        as PlayerPresidentOwnedSeasonContinuationReady;
    final firstAssessment = firstReady.completedManager!;
    final firstSignature = firstAssessment.signature;
    app.activateNextSeason(expected: firstReady);
    final secondOpening = app.currentSeasonOpening;
    final secondSettled = settleOwnedSeason(app, playOwnedSeason(app));
    final secondClosing = _continue(app, secondSettled, replaceManager: true);
    final secondReady =
        secondClosing.step as PlayerPresidentOwnedSeasonContinuationReady;
    final secondAssessment = secondReady.completedManager!;
    final secondSignature = secondAssessment.signature;
    final selected = secondClosing.selected!;

    expect(secondAssessment, same(secondClosing.assessment));
    expect(secondReady.completedSeasonIndex, 2);
    expect(secondAssessment.managerId, secondOpening.dashboard.manager.id);
    expect(selected.id, isNot(secondAssessment.managerId));
    expect(
        secondAssessment.actualPosition,
        secondSettled.leagueTable.rows
            .singleWhere((row) => row.clubId == secondOpening.controlledClubId)
            .position);
    expect(secondReady.managerHistorySeasonIndices, [1, 2]);
    app.activateNextSeason(expected: secondReady);

    expect(app.currentSeasonOpening.seasonIndex, 3);
    expect(app.currentSeasonOpening.dashboard.manager.id, selected.id);
    expect(firstReady.completedManager, same(firstAssessment));
    expect(firstAssessment.signature, firstSignature);
    expect(secondReady.completedManager, same(secondAssessment));
    expect(secondAssessment.signature, secondSignature);
  });

  test('future loss exposes actual closed assessment without a manager Pending',
      () {
    final app = _electionCareer('t3_16');
    final historical = app.closeSeason(expected: playOwnedSeason(app));
    final initialReady = _continue(app, historical).step
        as PlayerPresidentOwnedSeasonContinuationReady;
    app.activateNextSeason(expected: initialReady);
    final opening = app.currentSeasonOpening;
    final settled = settleOwnedSeason(app, playOwnedSeason(app));
    final observed = <PlayerPresidentOwnedSeasonStep>[];
    final ended = _continue(app, settled, observe: observed.add).step
        as PlayerPresidentOwnedCareerEnded;
    final assessment = ended.completedManager!;

    expect(ended.control.lost, isTrue);
    expect(ended.completedSeasonIndex, 1);
    expect(observed.whereType<PlayerPresidentOwnedSeasonManagerReviewPending>(),
        isEmpty);
    expect(
        observed
            .whereType<PlayerPresidentOwnedSeasonManagerReplacementPending>(),
        isEmpty);
    expect(assessment.managerId, opening.dashboard.manager.id);
    expect(assessment.clubId, ended.control.controlledClubId);
    expect(
        assessment.actualPosition,
        settled.leagueTable.rows
            .singleWhere((row) => row.clubId == ended.control.controlledClubId)
            .position);
    final before = assessment.signature;
    expect(() => app.continueToNextSeason(expected: settled), throwsStateError);
    expect(app.currentStep, same(ended));
    expect(ended.completedManager, same(assessment));
    expect(assessment.signature, before);
  });

  test('foreign and stale events cannot rewrite a published closed assessment',
      () {
    final app = _firstFuture();
    final settled = settleOwnedSeason(app, playOwnedSeason(app));
    final ready = _continue(app, settled).step
        as PlayerPresidentOwnedSeasonContinuationReady;
    final assessment = ready.completedManager!;
    final other = _firstFuture();
    final foreignSettled = settleOwnedSeason(other, playOwnedSeason(other));
    final foreignReady = _continue(other, foreignSettled).step
        as PlayerPresidentOwnedSeasonContinuationReady;
    expect(foreignReady.completedManager!.signature, assessment.signature);
    expect(foreignReady.completedManager, isNot(same(assessment)));

    expect(
        () => app.activateNextSeason(expected: foreignReady), throwsStateError);
    expect(() => app.continueToNextSeason(expected: foreignSettled),
        throwsStateError);
    expect(app.currentStep, same(ready));
    expect(ready.completedManager, same(assessment));
    app.activateNextSeason(expected: ready);
    final current = app.currentStep;
    expect(() => app.activateNextSeason(expected: ready), throwsStateError);
    expect(() => app.continueToNextSeason(expected: settled), throwsStateError);
    expect(app.currentStep, same(current));
    expect(ready.completedManager, same(assessment));
  });
}
