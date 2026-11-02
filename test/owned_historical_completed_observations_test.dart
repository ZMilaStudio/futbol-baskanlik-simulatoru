import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart';

void main() {
  test('historical table copies every W30 scalar in authoritative order', () {
    for (final clubId in ['t1_01', 't2_01', 't3_01']) {
      final app = startOwnedCareer(clubId: clubId);
      final opening = app.currentSeasonOpening;
      final w30 = playOwnedSeason(app);
      final closed = app.closeSeason(expected: w30);
      final table = closed.leagueTable;
      final source = w30.fixtures.tableFor(opening.dashboard.leagueTier);

      expect(table.seasonIndex, 0);
      expect(table.controlledClubId, clubId);
      expect(table.leagueTier, opening.dashboard.leagueTier);
      expect(table.rows, hasLength(16));
      expect(table.championClubId, source.first.clubId);
      for (var i = 0; i < source.length; i++) {
        final row = table.rows[i], expected = source[i];
        expect(row.position, i + 1);
        expect(row.clubId, expected.clubId);
        expect(row.played, expected.played);
        expect(row.wins, expected.wins);
        expect(row.draws, expected.draws);
        expect(row.losses, expected.losses);
        expect(row.goalsFor, expected.goalsFor);
        expect(row.goalsAgainst, expected.goalsAgainst);
        expect(row.goalDifference, expected.goalDifference);
        expect(row.points, expected.points);
      }
      expect(app.currentStep, same(closed));
    }
  });

  test(
      'historical matches preserve W30 fixture order and controlled perspective',
      () {
    final app = startOwnedCareer(clubId: 't2_01');
    final opening = app.currentSeasonOpening;
    final w30 = playOwnedSeason(app);
    final closed = app.closeSeason(expected: w30);
    final matches = closed.matchResults;
    final source = w30.fixtures.fixtures
        .where((entry) =>
            entry.tier == opening.dashboard.leagueTier &&
            (entry.fixture.homeClubId == opening.controlledClubId ||
                entry.fixture.awayClubId == opening.controlledClubId))
        .toList();

    expect(matches.seasonIndex, 0);
    expect(matches.controlledClubId, opening.controlledClubId);
    expect(matches.leagueTier, opening.dashboard.leagueTier);
    expect(matches.matches, hasLength(30));
    expect(matches.matches.where((row) => row.isHome), hasLength(15));
    for (var i = 0; i < source.length; i++) {
      final fixture = source[i].fixture, row = matches.matches[i];
      final home = fixture.homeClubId == opening.controlledClubId;
      expect(row.fixtureId, fixture.id);
      expect(row.round, fixture.round);
      expect(row.isHome, home);
      expect(
          row.opponentClubId, home ? fixture.awayClubId : fixture.homeClubId);
      expect(row.goalsFor,
          home ? fixture.result!.homeGoals : fixture.result!.awayGoals);
      expect(row.goalsAgainst,
          home ? fixture.result!.awayGoals : fixture.result!.homeGoals);
    }
  });

  test('typed historical views isolate legacy mutations and remain read only',
      () {
    final app = startOwnedCareer();
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final table = closed.leagueTable, matches = closed.matchResults;
    final tableSignature = table.signature, matchSignature = matches.signature;
    final finance = closed.finance, promise = closed.promise;
    final financeSignature = finance.signature,
        promiseSignature = promise.signature;
    final legacy = closed.leagueResults
        .singleWhere((league) => league.tier == table.leagueTier)
        .report;
    legacy.table.first.points += 100;
    legacy.table.first.goalsFor += 50;

    expect(() => table.rows.clear(), throwsUnsupportedError);
    expect(() => matches.matches.clear(), throwsUnsupportedError);
    for (var read = 0; read < 3; read++) {
      expect(closed.leagueTable, same(table));
      expect(closed.matchResults, same(matches));
      expect(table.signature, tableSignature);
      expect(matches.signature, matchSignature);
      expect(closed.finance, same(finance));
      expect(closed.promise, same(promise));
      expect(closed.finance.signature, financeSignature);
      expect(closed.promise.signature, promiseSignature);
      expect(app.currentStep, same(closed));
    }
    expect(
        closed.leagueResults
            .singleWhere((league) => league.tier == table.leagueTier)
            .report
            .table
            .first
            .points,
        table.rows.first.points);
  });

  test('historical promoted and relegated views retain their as-played league',
      () {
    final probe = startOwnedCareer();
    final probeClosed = probe.closeSeason(expected: playOwnedSeason(probe));
    final top = probeClosed.leagueResults
        .singleWhere((league) => league.tier.level == 1)
        .report;
    final middle = probeClosed.leagueResults
        .singleWhere((league) => league.tier.level == 2)
        .report;
    for (final (clubId, promoted) in [
      (top.table.last.clubId, false),
      (middle.table.first.clubId, true),
    ]) {
      final app = startOwnedCareer(clubId: clubId);
      final opening = app.currentSeasonOpening;
      final closed = app.closeSeason(expected: playOwnedSeason(app));
      final table = closed.leagueTable, matches = closed.matchResults;
      final tableSignature = table.signature,
          matchSignature = matches.signature;
      expect(closed.promise.outcome.promoted, promoted);
      expect(closed.promise.outcome.relegated, !promoted);
      expect(table.leagueTier, opening.dashboard.leagueTier);
      expect(matches.leagueTier, opening.dashboard.leagueTier);
      expect(table.rows.map((row) => row.clubId).toSet(),
          opening.dashboard.league.clubIds.toSet());

      enterNextOwnedSeason(app, closed);
      expect(app.currentSeasonOpening.dashboard.leagueTier,
          isNot(opening.dashboard.leagueTier));
      expect(closed.leagueTable.signature, tableSignature);
      expect(closed.matchResults.signature, matchSignature);
    }
  });

  test('historical views survive genuine future play and settlement', () {
    final app = startOwnedCareer();
    final closed = app.closeSeason(expected: playOwnedSeason(app));
    final table = closed.leagueTable, matches = closed.matchResults;
    final tableSignature = table.signature, matchSignature = matches.signature;
    final finance = closed.finance.signature,
        promise = closed.promise.signature;
    enterNextOwnedSeason(app, closed);
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(pending.hasManagerSeasonAuthority, isTrue);
    expect(pending.managerHistorySeasonIndices, isEmpty);
    final settled = settleOwnedSeason(app, playOwnedSeason(app));

    expect(settled.seasonIndex, 1);
    expect(settled.leagueTable, isNot(same(table)));
    expect(settled.matchResults, isNot(same(matches)));
    expect(closed.leagueTable, same(table));
    expect(closed.matchResults, same(matches));
    expect(table.signature, tableSignature);
    expect(matches.signature, matchSignature);
    expect(closed.finance.signature, finance);
    expect(closed.promise.signature, promise);
    expect(app.currentStep, same(settled));
  });

  test(
      'foreign stale and repeated close cannot replace historical observations',
      () {
    final app = startOwnedCareer(), other = startOwnedCareer();
    final w30 = playOwnedSeason(app), foreignW30 = playOwnedSeason(other);
    expect(() => app.closeSeason(expected: foreignW30), throwsStateError);
    expect(app.currentStep, same(w30));
    final closed = app.closeSeason(expected: w30);
    final table = closed.leagueTable, matches = closed.matchResults;
    final tableSignature = table.signature, matchSignature = matches.signature;
    expect(() => app.closeSeason(expected: w30), throwsStateError);
    expect(app.currentStep, same(closed));
    enterNextOwnedSeason(app, closed);
    final futureW30 = playOwnedSeason(app);
    expect(() => app.closeSeason(expected: w30), throwsStateError);
    expect(() => app.closeSeason(expected: futureW30), throwsStateError);
    expect(app.currentStep, same(futureW30));
    expect(closed.leagueTable, same(table));
    expect(closed.matchResults, same(matches));
    expect(table.signature, tableSignature);
    expect(matches.signature, matchSignature);
  });
}
