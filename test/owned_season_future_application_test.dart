import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart' show playOwnedSeason;

// A value-compatible caller object is not a production ticket choice.
class _CallerTicketChoice extends MatchdayTicketPricingChoice {
  const _CallerTicketChoice() : super(MatchdayTicketPriceTier.balanced);
}

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

PlayerPresidentOwnedSeasonRunning _open(
  PlayerPresidentOwnedSeasonApplication app,
) {
  final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
  final context = pending.request.contextAs<PlayerPromiseDecisionContext>();
  final resolved = app.submitPromise(
    expected: pending,
    choice: context.allowedTypes.first,
  );
  return app.continueAfterPromise(expected: resolved);
}

PlayerPresidentOwnedSeasonClosed _historicalClose(
  PlayerPresidentOwnedSeasonApplication app,
) =>
    app.closeSeason(expected: playOwnedSeason(app));

PlayerPresidentOwnedSeasonStep _answerTransfer(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonStep step,
) {
  if (step is PlayerPresidentOwnedSeasonTransferPending) {
    return app.submitTransfer(
      expected: step,
      choice: PlayerTransferStrategyChoice.fromProfile(step.context.aiProfile),
    );
  }
  return step;
}

PlayerPresidentOwnedSeasonStep _continue(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonCompletion completed, {
  bool replaceManager = false,
}) {
  var step = _answerTransfer(
    app,
    app.continueToNextSeason(expected: completed),
  );
  if (step is PlayerPresidentOwnedSeasonManagerReviewPending) {
    step = app.submitManagerReview(
      expected: step,
      choice: replaceManager || !step.context.canRetain
          ? PlayerManagerReviewChoice.replace
          : PlayerManagerReviewChoice.retain,
    );
  }
  if (step is PlayerPresidentOwnedSeasonManagerReplacementPending) {
    step = app.submitManagerReplacement(
      expected: step,
      selected: step.context.candidates.first.manager,
    );
  }
  return step;
}

PlayerPresidentOwnedSeasonContinuationReady _ready(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonCompletion completed, {
  bool replaceManager = false,
}) {
  final step = _continue(app, completed, replaceManager: replaceManager);
  expect(step, isA<PlayerPresidentOwnedSeasonContinuationReady>());
  return step as PlayerPresidentOwnedSeasonContinuationReady;
}

PlayerPresidentOwnedSeasonApplication _futureApp() {
  final app = _start();
  final ready = _ready(app, _historicalClose(app));
  app.activateNextSeason(expected: ready);
  return app;
}

PlayerPresidentOwnedFutureSeasonSettled _settle(
  PlayerPresidentOwnedSeasonApplication app,
  PlayerPresidentOwnedSeasonRunning w30,
) {
  final step = app.completeFutureSeason(expected: w30);
  if (step is PlayerPresidentOwnedSeasonTicketPending) {
    return app.submitTicket(
      expected: step,
      choice:
          const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
    );
  }
  expect(step, isA<PlayerPresidentOwnedFutureSeasonSettled>());
  return step as PlayerPresidentOwnedFutureSeasonSettled;
}

Manager _cloneManager(Manager manager) => Manager(
      id: manager.id,
      name: manager.name,
      profile: manager.profile,
      startAge: manager.startAge,
      retirementAge: manager.retirementAge,
      reputation: manager.reputation,
      coaching: manager.coaching,
      youthDevelopment: manager.youthDevelopment,
      manManagement: manager.manManagement,
      boardCooperation: manager.boardCooperation,
      budgetDemand: manager.budgetDemand,
    );

void main() {
  test('historical opening and closing do not claim manager season authority',
      () {
    final app = _start();
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(pending.seasonIndex, 0);
    expect(pending.hasManagerSeasonAuthority, isFalse);
    expect(pending.managerHistorySeasonIndices, isEmpty);
    final ready = _ready(app, _historicalClose(app));
    expect(ready.completedSeasonIndex, 0);
    expect(ready.nextSeasonIndex, 1);
    expect(ready.managerHistorySeasonIndices, isEmpty);
    expect(ready.control.active, isTrue);
    expect(
        () => ready.managerHistorySeasonIndices.add(0), throwsUnsupportedError);
  });

  test('historical continuation uses an explicit real transfer choice', () {
    final app = _start();
    final completed = _historicalClose(app);
    final transfer = app.continueToNextSeason(expected: completed)
        as PlayerPresidentOwnedSeasonTransferPending;
    expect(transfer.context.controlledClubId, 't1_01');
    expect(transfer.context.seasonIndex, 0);
    expect(transfer.context.decisionSeasonIndex, 1);
    expect(app.currentStep, same(transfer));
    final ready = app.submitTransfer(
      expected: transfer,
      choice:
          PlayerTransferStrategyChoice.fromProfile(transfer.context.aiProfile),
    );
    expect(ready, isA<PlayerPresidentOwnedSeasonContinuationReady>());
    expect(
        () => app.continueToNextSeason(expected: completed), throwsStateError);
    expect(app.currentStep, same(ready));
  });

  test('foreign completion cannot reserve another application continuation',
      () {
    final app = _start();
    final completed = _historicalClose(app);
    final foreign = _historicalClose(_start());
    expect(() => app.continueToNextSeason(expected: foreign), throwsStateError);
    expect(app.currentStep, same(completed));
    expect(app.continueToNextSeason(expected: completed),
        isA<PlayerPresidentOwnedSeasonTransferPending>());
  });

  test('invalid transfer and foreign Pending preserve the real decision', () {
    final app = _start();
    final pending = app.continueToNextSeason(expected: _historicalClose(app))
        as PlayerPresidentOwnedSeasonTransferPending;
    final other = _start();
    final foreign =
        other.continueToNextSeason(expected: _historicalClose(other))
            as PlayerPresidentOwnedSeasonTransferPending;
    final choice =
        PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
    expect(() => app.submitTransfer(expected: foreign, choice: choice),
        throwsStateError);
    expect(
        () => app.submitTransfer(
            expected: pending,
            choice: const PlayerTransferStrategyChoice(
              financialDiscipline: 0,
              transferAmbition: 50,
              riskAppetite: 50,
              youthOrientation: 50,
            )),
        throwsArgumentError);
    expect(app.currentStep, same(pending));
    expect(app.submitTransfer(expected: pending, choice: choice),
        isA<PlayerPresidentOwnedSeasonContinuationReady>());
  });

  test('consumed transfer rejects duplicate and conflicting answers', () {
    final app = _start();
    final pending = app.continueToNextSeason(expected: _historicalClose(app))
        as PlayerPresidentOwnedSeasonTransferPending;
    final choice =
        PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
    final ready = app.submitTransfer(expected: pending, choice: choice);
    expect(() => app.submitTransfer(expected: pending, choice: choice),
        throwsStateError);
    expect(
        () => app.submitTransfer(
            expected: pending,
            choice: const PlayerTransferStrategyChoice(
              financialDiscipline: 20,
              transferAmbition: 90,
              riskAppetite: 20,
              youthOrientation: 90,
            )),
        throwsStateError);
    expect(app.currentStep, same(ready));
  });

  test('foreign and already consumed Ready cannot activate another season', () {
    final app = _start();
    final ready = _ready(app, _historicalClose(app));
    final other = _start();
    final foreign = _ready(other, _historicalClose(other));
    expect(() => app.activateNextSeason(expected: foreign), throwsStateError);
    expect(app.currentStep, same(ready));
    final pending = app.activateNextSeason(expected: ready);
    expect(pending.seasonIndex, 1);
    expect(pending.hasManagerSeasonAuthority, isTrue);
    expect(pending.managerHistorySeasonIndices, isEmpty);
    expect(() => pending.managerHistorySeasonIndices.add(0),
        throwsUnsupportedError);
    expect(pending.request.clubId, 't1_01');
    expect(
        pending.request
            .contextAs<PlayerPromiseDecisionContext>()
            .context
            .seasonIndex,
        1);
    expect(() => app.activateNextSeason(expected: ready), throwsStateError);
    expect(app.currentStep, same(pending));
  });

  test('future promise rejects old season, foreign and invalid choices', () {
    final app = _start();
    final historical =
        app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final ready = _ready(app, _historicalClose(app));
    final pending = app.activateNextSeason(expected: ready);
    final foreign =
        _futureApp().currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final allowed =
        pending.request.contextAs<PlayerPromiseDecisionContext>().allowedTypes;
    for (final stale in [historical, foreign]) {
      expect(() => app.submitPromise(expected: stale, choice: allowed.first),
          throwsStateError);
    }
    final forbidden = PresidentPromiseType.values
        .firstWhere((choice) => !allowed.contains(choice));
    expect(() => app.submitPromise(expected: pending, choice: forbidden),
        throwsArgumentError);
    expect(app.currentStep, same(pending));
    final resolved =
        app.submitPromise(expected: pending, choice: allowed.first);
    expect(resolved.consequence.promise.seasonIndex, 1);
    expect(resolved.consequence.promise.type, allowed.first);
    expect(() => app.submitPromise(expected: pending, choice: allowed.first),
        throwsStateError);
    expect(app.currentStep, same(resolved));
  });

  test('future Resolution acknowledgement opens W0 once and rejects foreign',
      () {
    final app = _futureApp();
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final choice = pending.request
        .contextAs<PlayerPromiseDecisionContext>()
        .allowedTypes
        .first;
    final resolved = app.submitPromise(expected: pending, choice: choice);
    final other = _futureApp();
    final otherPending =
        other.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final foreign = other.submitPromise(expected: otherPending, choice: choice);
    expect(() => app.continueAfterPromise(expected: foreign), throwsStateError);
    expect(app.currentStep, same(resolved));
    final w0 = app.continueAfterPromise(expected: resolved);
    expect(w0.seasonIndex, 1);
    expect(w0.completedMatchCount, 0);
    expect(w0.nextRound, 1);
    expect(
        () => app.continueAfterPromise(expected: resolved), throwsStateError);
    expect(app.currentStep, same(w0));
  });

  test('future weekly guards reject foreign, stale, W31 and premature closing',
      () {
    final app = _futureApp();
    final w0 = _open(app);
    final foreign = _open(_futureApp());
    expect(() => app.advanceRound(expected: foreign), throwsStateError);
    expect(() => app.completeFutureSeason(expected: w0), throwsStateError);
    expect(() => app.closeSeason(expected: w0), throwsStateError);
    expect(app.currentStep, same(w0));
    var running = app.advanceRound(expected: w0);
    expect(() => app.advanceRound(expected: w0), throwsStateError);
    for (var round = 2; round <= 30; round++) {
      final previous = running;
      running = app.advanceRound(expected: running);
      expect(running.completedMatchCount, round * 24);
      final priorHistory =
          previous.fixtures.fixtures.where((fixture) => fixture.round < round);
      for (final old in priorHistory) {
        expect(
            running.fixtures.fixtures
                .firstWhere((fixture) => fixture.globalKey == old.globalKey),
            same(old));
      }
    }
    expect(running.isComplete, isTrue);
    expect(() => app.advanceRound(expected: running), throwsStateError);
    expect(() => app.closeSeason(expected: running), throwsStateError);
    expect(app.currentStep, same(running));
  });

  test(
      'future ticket is explicit and consumed ticket rejects duplicate choices',
      () {
    final app = _futureApp();
    final w30 = playOwnedSeason(app);
    final pending = app.completeFutureSeason(expected: w30)
        as PlayerPresidentOwnedSeasonTicketPending;
    expect(app.currentStep, same(pending));
    expect(() => app.completeFutureSeason(expected: w30), throwsStateError);
    final other = _futureApp();
    final foreign = other.completeFutureSeason(expected: playOwnedSeason(other))
        as PlayerPresidentOwnedSeasonTicketPending;
    const choice =
        MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced);
    expect(() => app.submitTicket(expected: foreign, choice: choice),
        throwsStateError);
    expect(app.currentStep, same(pending));
    final settled = app.submitTicket(expected: pending, choice: choice);
    expect(settled.seasonIndex, 1);
    expect(settled.controlledClubId, 't1_01');
    expect(settled.fixtures.completedMatchCount, 720);
    expect(settled.managerHistorySeasonIndices, isEmpty);
    expect(() => app.submitTicket(expected: pending, choice: choice),
        throwsStateError);
    expect(
        () => app.submitTicket(
            expected: pending,
            choice: const MatchdayTicketPricingChoice(
                MatchdayTicketPriceTier.premium)),
        throwsStateError);
    expect(app.currentStep, same(settled));
  });

  test(
      'future settlement and continuation keep immutable completed observations',
      () {
    final app = _futureApp();
    final settled = _settle(app, playOwnedSeason(app));
    final finance = settled.finance.signature;
    final before = settled.fixtures.fixtures
        .map((fixture) => fixture.fixture.result!.matchSeed)
        .toList();
    expect(() => settled.managerHistorySeasonIndices.add(0),
        throwsUnsupportedError);
    expect(() => settled.fixtures.fixtures.clear(), throwsUnsupportedError);
    expect(() => settled.fixtures.tables.clear(), throwsUnsupportedError);
    final ready = _ready(app, settled);
    expect(ready.completedSeasonIndex, 1);
    expect(ready.nextSeasonIndex, 2);
    expect(ready.managerHistorySeasonIndices, [1]);
    // Settlement precedes manager closing; the old observation never acquires
    // the season that was completed later during postseason.
    expect(settled.managerHistorySeasonIndices, isEmpty);
    app.activateNextSeason(expected: ready);
    expect(settled.finance.signature, finance);
    expect(
        settled.fixtures.fixtures
            .map((fixture) => fixture.fixture.result!.matchSeed),
        before);
  });

  test('caller ticket subtype is rejected before consuming the real Pending',
      () {
    final app = _futureApp();
    final pending = app.completeFutureSeason(expected: playOwnedSeason(app))
        as PlayerPresidentOwnedSeasonTicketPending;
    expect(
      () => app.submitTicket(
          expected: pending, choice: const _CallerTicketChoice()),
      throwsStateError,
    );
    expect(app.currentStep, same(pending));
    final settled = app.submitTicket(
      expected: pending,
      choice:
          const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
    );
    expect(settled.seasonIndex, 1);
    expect(settled.fixtures.completedMatchCount, 720);
    expect(app.currentStep, same(settled));
  });

  test(
      'real manager review can retain without fabricating historical manager seasons',
      () {
    final app = _futureApp();
    final settled = _settle(app, playOwnedSeason(app));
    final review =
        _answerTransfer(app, app.continueToNextSeason(expected: settled))
            as PlayerPresidentOwnedSeasonManagerReviewPending;
    expect(review.context.clubId, 't1_01');
    expect(review.context.seasonIndex, 1);
    expect(review.context.canRetain, isTrue);
    final ready = app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.retain)
        as PlayerPresidentOwnedSeasonContinuationReady;
    expect(ready.managerHistorySeasonIndices, [1]);
    expect(
        () => app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.retain),
        throwsStateError);
    expect(
        () => app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.replace),
        throwsStateError);
    expect(app.currentStep, same(ready));
  });

  test(
      'real manager replacement requires exact offered identity and a single answer',
      () {
    final app = _futureApp();
    final settled = _settle(app, playOwnedSeason(app));
    final review =
        _answerTransfer(app, app.continueToNextSeason(expected: settled))
            as PlayerPresidentOwnedSeasonManagerReviewPending;
    final replacement = app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.replace)
        as PlayerPresidentOwnedSeasonManagerReplacementPending;
    final selected = replacement.context.candidates.first.manager;
    final clone = _cloneManager(selected);
    expect(clone.signature, selected.signature);
    expect(
        () => app.submitManagerReplacement(
            expected: replacement, selected: clone),
        throwsArgumentError);
    expect(app.currentStep, same(replacement));
    expect(
        () => replacement.context.candidates.clear(), throwsUnsupportedError);
    final ready = app.submitManagerReplacement(
        expected: replacement,
        selected: selected) as PlayerPresidentOwnedSeasonContinuationReady;
    expect(ready.managerHistorySeasonIndices, [1]);
    expect(
        () => app.submitManagerReplacement(
            expected: replacement, selected: selected),
        throwsStateError);
    expect(app.currentStep, same(ready));
  });

  test('foreign manager reviews and replacements preserve the current owner',
      () {
    final app = _futureApp();
    final settled = _settle(app, playOwnedSeason(app));
    final review =
        _answerTransfer(app, app.continueToNextSeason(expected: settled))
            as PlayerPresidentOwnedSeasonManagerReviewPending;
    final other = _futureApp();
    final otherSettled = _settle(other, playOwnedSeason(other));
    final otherReview = _answerTransfer(
            other, other.continueToNextSeason(expected: otherSettled))
        as PlayerPresidentOwnedSeasonManagerReviewPending;
    expect(
        () => app.submitManagerReview(
            expected: otherReview, choice: PlayerManagerReviewChoice.retain),
        throwsStateError);
    expect(app.currentStep, same(review));
    final replacement = app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.replace)
        as PlayerPresidentOwnedSeasonManagerReplacementPending;
    final otherReplacement = other.submitManagerReview(
            expected: otherReview, choice: PlayerManagerReviewChoice.replace)
        as PlayerPresidentOwnedSeasonManagerReplacementPending;
    expect(
        () => app.submitManagerReplacement(
            expected: otherReplacement,
            selected: otherReplacement.context.candidates.first.manager),
        throwsStateError);
    expect(app.currentStep, same(replacement));
  });

  test(
      'one public application runs two genuine future seasons and enters third',
      () {
    final app = _start();
    final historical = _historicalClose(app);
    final historicalFinance = historical.finance.signature;
    final firstReady = _ready(app, historical);
    app.activateNextSeason(expected: firstReady);
    PlayerPresidentOwnedSeasonRunning? oldSeason;
    for (var season = 1; season <= 2; season++) {
      final opening =
          app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
      expect(opening.seasonIndex, season);
      expect(opening.hasManagerSeasonAuthority, isTrue);
      expect(opening.managerHistorySeasonIndices,
          [for (var i = 1; i < season; i++) i]);
      final w30 = playOwnedSeason(app);
      if (oldSeason != null) {
        expect(() => app.advanceRound(expected: oldSeason!), throwsStateError);
        expect(() => app.completeFutureSeason(expected: oldSeason!),
            throwsStateError);
      }
      final settled = _settle(app, w30);
      expect(settled.seasonIndex, season);
      expect(settled.fixtures.completedMatchCount, 720);
      expect(settled.managerHistorySeasonIndices,
          [for (var i = 1; i < season; i++) i]);
      final ready = _ready(app, settled, replaceManager: season == 2);
      app.activateNextSeason(expected: ready);
      expect(
        () => app.submitPromise(
          expected: opening,
          choice: opening.request
              .contextAs<PlayerPromiseDecisionContext>()
              .allowedTypes
              .first,
        ),
        throwsStateError,
      );
      expect(
          () => app.continueToNextSeason(expected: settled), throwsStateError);
      expect(() => app.activateNextSeason(expected: ready), throwsStateError);
      oldSeason = w30;
    }
    final third = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(third.seasonIndex, 3);
    expect(third.managerHistorySeasonIndices, [1, 2]);
    final w0 = _open(app);
    expect(w0.seasonIndex, 3);
    expect(w0.completedMatchCount, 0);
    expect(w0.nextRound, 1);
    expect(historical.finance.signature, historicalFinance);
  });

  test(
      'prepared getters remain explicit initial snapshots after future activation',
      () {
    final app = _start();
    final dashboard = app.preparedSeasonDashboard;
    final squad = app.preparedSquad;
    final fixtures = app.preparedSeasonFixtures;
    app.activateNextSeason(expected: _ready(app, _historicalClose(app)));
    expect(app.preparedSeasonDashboard, same(dashboard));
    expect(app.preparedSquad, same(squad));
    expect(app.preparedSeasonFixtures, same(fixtures));
    expect(dashboard.seasonIndex, 0);
    expect(squad.seasonIndex, 0);
    expect(fixtures.seasonIndex, 0);
    expect(
        (app.currentStep as PlayerPresidentOwnedSeasonPromisePending)
            .seasonIndex,
        1);
  });

  test('same public choices produce deterministic genuine future settlement',
      () {
    final first = _futureApp();
    final second = _futureApp();
    final firstSettled = _settle(first, playOwnedSeason(first));
    final secondSettled = _settle(second, playOwnedSeason(second));
    expect(firstSettled.finance.signature, secondSettled.finance.signature);
    expect(firstSettled.managerHistorySeasonIndices,
        secondSettled.managerHistorySeasonIndices);
    List<Object> fixtures(PlayerPresidentOwnedFutureSeasonSettled settled) => [
          for (final fixture in settled.fixtures.fixtures)
            [
              fixture.globalKey,
              fixture.fixture.result!.matchSeed,
              fixture.fixture.result!.homeGoals,
              fixture.fixture.result!.awayGoals
            ],
          for (final entry in settled.fixtures.tables.entries)
            [entry.key.level, entry.value.map((row) => row.toJson()).toList()],
        ];
    expect(jsonEncode(fixtures(firstSettled)),
        jsonEncode(fixtures(secondSettled)));
  });

  test('genuine historical presidency loss terminates without future authority',
      () {
    final app = _start(clubId: 't1_16', electionInterval: 1);
    final completed = _historicalClose(app);
    final ended = _continue(app, completed) as PlayerPresidentOwnedCareerEnded;
    expect(ended.completedSeasonIndex, 0);
    expect(ended.control.lost, isTrue);
    expect(ended.control.active, isFalse);
    expect(app.currentStep, same(ended));
    expect(
        () => app.continueToNextSeason(expected: completed), throwsStateError);
    final foreign = _start();
    final foreignReady = _ready(foreign, _historicalClose(foreign));
    expect(
        () => app.activateNextSeason(expected: foreignReady), throwsStateError);
    expect(app.currentStep, same(ended));
  });

  test('genuine future presidency loss keeps terminal state after stale events',
      () {
    final app = _start(clubId: 't3_16', electionInterval: 1);
    final historicalReady = _ready(app, _historicalClose(app));
    final pending = app.activateNextSeason(expected: historicalReady);
    final w30 = playOwnedSeason(app);
    final settled = _settle(app, w30);
    final ended = _continue(app, settled) as PlayerPresidentOwnedCareerEnded;
    expect(ended.completedSeasonIndex, 1);
    expect(ended.control.lost, isTrue);
    expect(ended.control.active, isFalse);
    expect(() => app.activateNextSeason(expected: historicalReady),
        throwsStateError);
    expect(() => app.continueToNextSeason(expected: settled), throwsStateError);
    expect(() => app.completeFutureSeason(expected: w30), throwsStateError);
    expect(
        () => app.submitPromise(
              expected: pending,
              choice: pending.request
                  .contextAs<PlayerPromiseDecisionContext>()
                  .allowedTypes
                  .first,
            ),
        throwsStateError);
    expect(app.currentStep, same(ended));
  });

  test(
      'forced manager retirement exposes replacement directly at real boundary',
      () {
    final app = _start(electionInterval: 100);
    var ready = _ready(app, _historicalClose(app));
    for (var season = 1; season <= 15; season++) {
      app.activateNextSeason(expected: ready);
      final settled = _settle(app, playOwnedSeason(app));
      var step =
          _answerTransfer(app, app.continueToNextSeason(expected: settled));
      if (season == 1) {
        final review = step as PlayerPresidentOwnedSeasonManagerReviewPending;
        final replacement = app.submitManagerReview(
          expected: review,
          choice: PlayerManagerReviewChoice.replace,
        ) as PlayerPresidentOwnedSeasonManagerReplacementPending;
        final candidates = replacement.context.candidates.toList()
          ..sort((a, b) => (a.manager.retirementAge - a.manager.startAge)
              .compareTo(b.manager.retirementAge - b.manager.startAge));
        final selected = candidates.first.manager;
        expect(selected.id, 'manager_090');
        expect(selected.startAge, 52);
        expect(selected.retirementAge, 67);
        step = app.submitManagerReplacement(
            expected: replacement, selected: selected);
      } else if (season == 15) {
        // The production manager authority suppresses retain/review for a
        // retiring incumbent; the application must expose that exact branch.
        expect(
            step, isA<PlayerPresidentOwnedSeasonManagerReplacementPending>());
        final replacement =
            step as PlayerPresidentOwnedSeasonManagerReplacementPending;
        expect(replacement.context.reason, ManagerChangeReason.retirement);
        expect(replacement.context.outgoingManager.id, 'manager_090');
        step = app.submitManagerReplacement(
          expected: replacement,
          selected: replacement.context.candidates.first.manager,
        );
      } else {
        final review = step as PlayerPresidentOwnedSeasonManagerReviewPending;
        expect(review.context.canRetain, isTrue);
        expect(review.context.currentManager.id, 'manager_090');
        step = app.submitManagerReview(
            expected: review, choice: PlayerManagerReviewChoice.retain);
      }
      ready = step as PlayerPresidentOwnedSeasonContinuationReady;
      expect(ready.nextSeasonIndex, season + 1);
      expect(ready.managerHistorySeasonIndices,
          [for (var i = 1; i <= season; i++) i]);
    }
    expect(ready.nextSeasonIndex, 16);
    expect(app.currentStep, same(ready));
  });
}
