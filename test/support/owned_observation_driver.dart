import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';

PlayerPresidentOwnedSeasonApplication observationCareer(String clubId,
    {int seed = 20260903, int electionInterval = 100}) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentOwnedSeasonApplication.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: SimulationConfig(careerSeed: seed),
      controlledClubId: clubId,
      electionInterval: electionInterval);
}

/// Real public player submissions; no provider fallback or synthetic boundary.
PlayerPresidentOwnedSeasonStep completeObservedPostseason(
    PlayerPresidentOwnedSeasonApplication app,
    PlayerPresidentOwnedSeasonCompletion completed) {
  var step = app.continueToNextSeason(expected: completed);
  if (step is PlayerPresidentOwnedSeasonTransferPending) {
    step = app.submitTransfer(
        expected: step,
        choice:
            PlayerTransferStrategyChoice.fromProfile(step.context.aiProfile));
  }
  if (step is PlayerPresidentOwnedSeasonManagerReviewPending) {
    step = app.submitManagerReview(
        expected: step,
        choice: step.context.canRetain
            ? PlayerManagerReviewChoice.retain
            : PlayerManagerReviewChoice.replace);
  }
  if (step is PlayerPresidentOwnedSeasonManagerReplacementPending) {
    step = app.submitManagerReplacement(
        expected: step, selected: step.context.candidates.first.manager);
  }
  return step;
}
