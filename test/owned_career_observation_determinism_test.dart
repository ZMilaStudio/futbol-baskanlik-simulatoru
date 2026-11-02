import 'dart:convert';

import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart' show startOwnedCareer;

List<Object?> _careerTrace(PlayerPresidentOwnedSeasonApplication app,
    {required bool denseReads}) {
  final trace = <Object?>[];
  final retained = <(String, String Function(), String)>[];
  final completedFutureSeasons = <int>[];

  void retain(String label, String Function() read) {
    final value = read();
    retained.add((label, read, value));
    trace.add([label, value]);
  }

  void checkRetained() {
    final step = app.currentStep;
    for (final (label, read, original) in retained) {
      expect(read(), original, reason: 'Retained observation changed: $label');
    }
    expect(app.currentStep, same(step));
  }

  void readBurst() {
    if (denseReads) {
      for (var read = 0; read < 3; read++) {
        checkRetained();
      }
    }
  }

  for (var season = 0; season <= 3; season++) {
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(pending.seasonIndex, season);
    expect(pending.hasManagerSeasonAuthority, season > 0);
    expect(pending.managerHistorySeasonIndices,
        [for (var index = 1; index < season; index++) index]);
    // Future request keys contain application-local runtime identities. The
    // compared request context and domain observations intentionally do not.
    trace.add([
      'pending',
      season,
      pending.request.kind.name,
      pending.request.sequence,
      pending.request.contextSignature
    ]);
    final opening = app.currentSeasonOpening;
    expect(opening.seasonIndex, season);
    retain('opening-$season', () => opening.signature);
    readBurst();

    final choice = pending.request
        .contextAs<PlayerPromiseDecisionContext>()
        .allowedTypes
        .first;
    final resolved = app.submitPromise(expected: pending, choice: choice);
    retain('accepted-promise-$season',
        () => resolved.consequence.promise.signature);
    readBurst();
    var running = app.continueAfterPromise(expected: resolved);
    expect(running.seasonIndex, season);
    expect(running.nextRound, 1);
    expect(running.completedMatchCount, 0);
    trace.add(['W0', season, running.nextRound, running.completedMatchCount]);
    readBurst();
    if (season == 3) break;

    for (var round = 1; round <= 30; round++) {
      running = app.advanceRound(expected: running);
      readBurst();
    }
    expect(running.isComplete, isTrue);
    expect(running.completedMatchCount, 720);
    trace.add(['W30', season, running.nextRound, running.completedMatchCount]);

    PlayerPresidentOwnedSeasonCompletion completed;
    if (season == 0) {
      final closed = app.closeSeason(expected: running);
      retain('historical-finance', () => closed.finance.signature);
      retain('historical-promise', () => closed.promise.signature);
      retain(
          'historical-tables',
          () => jsonEncode([
                for (final league in closed.leagueResults)
                  [league.tier.level, league.report.toJson()],
              ]));
      retain('historical-table', () => closed.leagueTable.signature);
      retain('historical-matches', () => closed.matchResults.signature);
      completed = closed;
    } else {
      final ticket = app.completeFutureSeason(expected: running)
          as PlayerPresidentOwnedSeasonTicketPending;
      readBurst();
      final settled = app.submitTicket(
        expected: ticket,
        choice:
            const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
      );
      expect(settled.seasonIndex, season);
      expect(settled.fixtures.completedMatchCount, 720);
      retain('finance-$season', () => settled.finance.signature);
      retain('table-$season', () => settled.leagueTable.signature);
      retain('matches-$season', () => settled.matchResults.signature);
      completed = settled;
    }
    readBurst();

    var next = app.continueToNextSeason(expected: completed);
    readBurst();
    final transfer = next as PlayerPresidentOwnedSeasonTransferPending;
    next = app.submitTransfer(
      expected: transfer,
      choice: const PlayerTransferStrategyChoice(
        financialDiscipline: 50,
        transferAmbition: 50,
        riskAppetite: 50,
        youthOrientation: 50,
      ),
    );
    readBurst();
    if (season > 0) {
      expect(next, isA<PlayerPresidentOwnedSeasonManagerReviewPending>());
    }
    if (next is PlayerPresidentOwnedSeasonManagerReviewPending) {
      final review = season == 2 || !next.context.canRetain
          ? PlayerManagerReviewChoice.replace
          : PlayerManagerReviewChoice.retain;
      trace.add(['manager-review', season, review.name]);
      next = app.submitManagerReview(expected: next, choice: review);
      readBurst();
    }
    if (next is PlayerPresidentOwnedSeasonManagerReplacementPending) {
      final selected = next.context.candidates.first.manager;
      trace.add(['manager-replacement', season, selected.id]);
      next = app.submitManagerReplacement(expected: next, selected: selected);
      readBurst();
    }
    final ready = next as PlayerPresidentOwnedSeasonContinuationReady;
    expect(ready.completedSeasonIndex, season);
    expect(ready.nextSeasonIndex, season + 1);
    expect(ready.control.active, isTrue);
    retain('closing-promise-$season', () => ready.completedPromise.signature);
    retain('closing-control-$season', () => ready.control.signature);
    retain('manager-history-$season',
        () => jsonEncode(ready.managerHistorySeasonIndices));
    if (season == 0) {
      expect(ready.completedManager, isNull);
      trace.add(['closing-manager-0', null]);
    } else {
      final manager = ready.completedManager!;
      expect(manager.clubId, opening.controlledClubId);
      expect(manager.managerId, opening.dashboard.manager.id);
      retain('closing-manager-$season', () => manager.signature);
      completedFutureSeasons.add(season);
    }
    readBurst();
    app.activateNextSeason(expected: ready);
    readBurst();
  }

  expect(completedFutureSeasons, [1, 2]);
  final thirdW0 = app.currentStep as PlayerPresidentOwnedSeasonRunning;
  expect(thirdW0.seasonIndex, 3);
  expect(thirdW0.completedMatchCount, 0);
  expect(thirdW0.nextRound, 1);
  checkRetained();
  return trace;
}

void main() {
  test('public multi-season observations stay deterministic under dense reads',
      () {
    final dense = startOwnedCareer();
    final sparse = startOwnedCareer();
    expect(dense, isNot(same(sparse)));

    final denseTrace = _careerTrace(dense, denseReads: true);
    final sparseTrace = _careerTrace(sparse, denseReads: false);

    expect(sparseTrace, denseTrace);
  });
}
