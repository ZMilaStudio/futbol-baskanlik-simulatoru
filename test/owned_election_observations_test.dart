import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:test/test.dart';
import 'support/owned_career_driver.dart'
    show playOwnedSeason, settleOwnedSeason;
import 'support/owned_observation_driver.dart';

// Independent genuine application producer. No election/checkpoint is invented.
PresidentElectionSnapshot _graphElection(String clubId, bool future) {
  final world = const FictionalWorldFactory().build();
  final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      controlledClubId: clubId,
      electionInterval: 1,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true);
  final boundary = app.startPreseasonPromise(
      sourceClubs: world.clubs, sourceLeagues: world.leagues);
  boundary.submit(
      pending: boundary.pending!,
      choice: boundary.pending!.context.allowedTypes.first);
  var weekly = app.openPreseasonWeeklyHandoff();
  for (var round = 1; round <= 30; round++) {
    weekly =
        app.advancePreseasonWeek(expectedState: weekly, expectedRound: round);
  }
  final b1 = app.projectCommittedSeason(expectedState: weekly);
  final closing = app.closeAcceptedPromises(expectedResultCandidate: b1);
  LosslessPostOffseasonRuntimeGraph publish(
      SinglePassPostseasonRuntimeTransition transition, bool isFuture) {
    final transfer = transition.prepareTransfer()!;
    transition.submitTransfer(
        expectedPending: transfer,
        choice: PlayerTransferStrategyChoice.fromProfile(
            transfer.context.aiProfile));
    transition.prepareDomain();
    transition.prepareOuterSuccessor();
    final manager = transition.managerPending;
    if (manager != null) {
      if (manager.review.canRetain) {
        transition.submitManagerReview(
            expectedPending: manager, choice: PlayerManagerReviewChoice.retain);
      } else {
        final replacement = transition.submitManagerReview(
            expectedPending: manager,
            choice: PlayerManagerReviewChoice.replace)!;
        transition.submitManagerReplacement(
            expectedPending: replacement,
            selected: replacement.replacement!.candidates.first.manager);
      }
    }
    return isFuture
        ? app.publishFuturePostseasonContinuation(
            expectedTransition: transition)
        : app.publishPostseasonContinuation(expectedTransition: transition);
  }

  var graph =
      publish(app.startPostseasonTransition(expectedSource: closing), false);
  if (future) {
    final entry = app.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: graph.origin,
        expectedTargetSeason: graph.targetSeasonIndex);
    final prepared = app.prepareFutureRuntime(expectedEntry: entry);
    final opening = app.openFutureSeason(
        expectedAdmission: app.futureRuntimeAdmission!,
        expectedPrepared: prepared);
    app.acceptFuturePromise(
        expectedOpening: opening,
        expectedPending: opening.promisePending,
        choice: opening.controlledPromiseContext.allowedTypes.first);
    for (var round = 1; round <= 30; round++) {
      app.advanceFutureWeek(
          expectedState: app.futureWeeklyState!, expectedRound: round);
    }
    final committed =
        app.commitFutureSeason(expectedW30: app.futureWeeklyState!);
    final economy = app.handoffFutureEconomy(expectedCommitted: committed);
    if (economy.prepareSettlement(committed.capability) ==
        RuntimeEconomyState.awaitingTicketDecision) {
      economy.submitTicket(economy.pending!,
          const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
          expectedRevision: economy.revision);
    }
    final settled =
        economy.executeSettlement(expectedCommitted: committed.capability);
    graph = publish(
        app.startFuturePostseasonTransition(
            expectedSettlement: settled, hasNextSeason: true),
        true);
  }
  return graph.domainEvidence.elections.map((row) => row.election).singleWhere(
      (row) => row.clubId == clubId && row.seasonIndex == (future ? 1 : 0));
}

void main() {
  test(
      'no historical or future election is fabricated before the term boundary',
      () {
    final app = observationCareer('t1_01');
    final first = completeObservedPostseason(
            app, app.closeSeason(expected: playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    expect(first.completedElection, isNull);
    app.activateNextSeason(expected: first);
    final second = completeObservedPostseason(
            app, settleOwnedSeason(app, playOwnedSeason(app)))
        as PlayerPresidentOwnedSeasonContinuationReady;
    expect(second.completedElection, isNull);
    expect(first.completedElection, isNull);
  });

  for (final future in [false, true]) {
    for (final lost in [false, true]) {
      test(
          '${future ? 'future' : 'historical'} ${lost ? 'loss' : 'reelection'} keeps exact graph election',
          () {
        final id = lost ? (future ? 't3_16' : 't1_16') : 't1_01';
        final app = observationCareer(id, electionInterval: 1);
        PlayerPresidentOwnedSeasonCompletion completed =
            app.closeSeason(expected: playOwnedSeason(app));
        PlayerPresidentOwnedSeasonContinuationReady? previous;
        PresidentElectionSnapshot? previousElection;
        String? previousSignature;
        if (future) {
          previous = completeObservedPostseason(app, completed)
              as PlayerPresidentOwnedSeasonContinuationReady;
          previousElection = previous.completedElection!;
          previousSignature = previousElection.signature;
          app.activateNextSeason(expected: previous);
          completed = settleOwnedSeason(app, playOwnedSeason(app));
        }
        final result = completeObservedPostseason(app, completed);
        final election = switch (result) {
          PlayerPresidentOwnedSeasonContinuationReady() =>
            result.completedElection!,
          PlayerPresidentOwnedCareerEnded() => result.completedElection!,
          _ => throw StateError('Actual postseason did not publish'),
        };
        final oracle = _graphElection(id, future);
        expect(election.signature, oracle.signature);
        expect(election.clubId, id);
        expect(election.seasonIndex, future ? 1 : 0);
        expect(
            election.outcome,
            lost
                ? PresidentElectionOutcome.lost
                : PresidentElectionOutcome.reelected);
        expect(election.contributions, isNotEmpty);
        expect(election.contributions.map((row) => row.signature),
            oracle.contributions.map((row) => row.signature));
        expect(() => election.contributions.clear(), throwsUnsupportedError);
        final signature = election.signature;
        if (result is PlayerPresidentOwnedSeasonContinuationReady) {
          expect(result.control.active, isTrue);
          if (previous != null) {
            expect(() => app.activateNextSeason(expected: previous!),
                throwsStateError);
            expect(app.currentStep, same(result));
          }
          app.activateNextSeason(expected: result);
          expect(result.completedElection, same(election));
        } else {
          final ended = result as PlayerPresidentOwnedCareerEnded;
          expect(ended.control.lost, isTrue);
          expect(() => app.continueToNextSeason(expected: completed),
              throwsStateError);
          expect(ended.completedElection, same(election));
        }
        expect(election.signature, signature);
        if (previous != null) {
          expect(previous.completedElection, same(previousElection));
          expect(previousElection!.signature, previousSignature);
        }
      });
    }
  }
}
