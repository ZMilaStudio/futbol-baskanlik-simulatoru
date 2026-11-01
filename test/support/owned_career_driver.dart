import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

PlayerPresidentOwnedSeasonApplication startOwnedCareer(
    {String clubId = 't1_01'}) {
  final world = const FictionalWorldFactory().build();
  return PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: clubId,
    electionInterval: 100,
  );
}

PlayerPresidentOwnedSeasonRunning playOwnedSeason(
  PlayerPresidentOwnedSeasonApplication app,
) {
  final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
  final resolved = app.submitPromise(
    expected: pending,
    choice: pending.request
        .contextAs<PlayerPromiseDecisionContext>()
        .allowedTypes
        .first,
  );
  var running = app.continueAfterPromise(expected: resolved);
  for (var round = 1; round <= 30; round++) {
    running = app.advanceRound(expected: running);
  }
  return running;
}

PlayerPresidentOwnedFutureSeasonSettled settleOwnedSeason(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonRunning w30, {
  MatchdayTicketPriceTier ticketTier = MatchdayTicketPriceTier.balanced,
}) {
  final step = app.completeFutureSeason(expected: w30);
  return step is PlayerPresidentOwnedSeasonTicketPending
      ? app.submitTicket(
          expected: step, choice: MatchdayTicketPricingChoice(ticketTier))
      : step as PlayerPresidentOwnedFutureSeasonSettled;
}

void enterNextOwnedSeason(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonCompletion completed,
) {
  var step = app.continueToNextSeason(expected: completed);
  while (true) {
    switch (step) {
      case PlayerPresidentOwnedSeasonTransferPending():
        step = app.submitTransfer(
          expected: step,
          choice: const PlayerTransferStrategyChoice(
            financialDiscipline: 50,
            transferAmbition: 50,
            riskAppetite: 50,
            youthOrientation: 50,
          ),
        );
      case PlayerPresidentOwnedSeasonManagerReviewPending():
        step = app.submitManagerReview(
          expected: step,
          choice: step.context.canRetain
              ? PlayerManagerReviewChoice.retain
              : PlayerManagerReviewChoice.replace,
        );
      case PlayerPresidentOwnedSeasonManagerReplacementPending():
        step = app.submitManagerReplacement(
          expected: step,
          selected: step.context.candidates.first.manager,
        );
      case PlayerPresidentOwnedSeasonContinuationReady():
        app.activateNextSeason(expected: step);
        return;
      default:
        throw StateError('Fixture cannot continue from ${step.runtimeType}.');
    }
  }
}

PlayerPresidentOwnedSeasonApplication firstFutureCareer(
    {String clubId = 't1_01'}) {
  final app = startOwnedCareer(clubId: clubId);
  enterNextOwnedSeason(app, app.closeSeason(expected: playOwnedSeason(app)));
  return app;
}
