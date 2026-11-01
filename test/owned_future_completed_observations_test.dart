import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart';

void main() {
  test('future settled table selects actual completed league in W30 order', () {
    final app = firstFutureCareer();
    final opening = app.currentSeasonOpening;
    final w30 = playOwnedSeason(app);
    final settled = settleOwnedSeason(app, w30);
    final table = settled.leagueTable;
    final source = w30.fixtures.tableFor(opening.dashboard.leagueTier);
    expect(table.seasonIndex, 1);
    expect(table.controlledClubId, opening.controlledClubId);
    expect(table.leagueTier, opening.dashboard.leagueTier);
    expect(table.rows, hasLength(16));
    expect(table.championClubId, source.first.clubId);
    for (var i = 0; i < source.length; i++) {
      final actual = table.rows[i], expected = source[i];
      expect(actual.position, i + 1);
      expect(actual.clubId, expected.clubId);
      expect(actual.played, expected.played);
      expect(actual.wins, expected.wins);
      expect(actual.draws, expected.draws);
      expect(actual.losses, expected.losses);
      expect(actual.goalsFor, expected.goalsFor);
      expect(actual.goalsAgainst, expected.goalsAgainst);
      expect(actual.goalDifference, expected.goalDifference);
      expect(actual.points, expected.points);
    }
    expect(app.currentStep, same(settled));
  });

  test(
      'future match observation uses actual controlled fixtures and score sides',
      () {
    final app = firstFutureCareer();
    final opening = app.currentSeasonOpening;
    final w30 = playOwnedSeason(app);
    final settled = settleOwnedSeason(app, w30);
    final matches = settled.matchResults;
    final source = w30.fixtures.fixtures
        .where((entry) =>
            entry.tier == opening.dashboard.leagueTier &&
            (entry.fixture.homeClubId == opening.controlledClubId ||
                entry.fixture.awayClubId == opening.controlledClubId))
        .toList();
    expect(matches.seasonIndex, 1);
    expect(matches.leagueTier, opening.dashboard.leagueTier);
    expect(matches.controlledClubId, opening.controlledClubId);
    expect(matches.matches, hasLength(30));
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

  test('promoted or relegated opening does not reuse initial league membership',
      () {
    final probe = startOwnedCareer();
    final historical = probe.closeSeason(expected: playOwnedSeason(probe));
    final bottomClub = historical.leagueResults
        .singleWhere(
            (league) => league.tier == probe.preparedSeasonDashboard.leagueTier)
        .report
        .table
        .last
        .clubId;
    final app = firstFutureCareer(clubId: bottomClub);
    final actualOpening = app.currentSeasonOpening;
    expect(actualOpening.dashboard.leagueTier,
        isNot(app.preparedSeasonDashboard.leagueTier));
    final settled = settleOwnedSeason(app, playOwnedSeason(app));
    expect(settled.leagueTable.leagueTier, actualOpening.dashboard.leagueTier);
    expect(settled.matchResults.leagueTier, actualOpening.dashboard.leagueTier);
    expect(settled.leagueTable.rows.map((row) => row.clubId).toSet(),
        actualOpening.dashboard.league.clubIds.toSet());
  });

  test(
      'old completed views remain immutable and stable after genuine next opening',
      () {
    final app = firstFutureCareer();
    final first = settleOwnedSeason(app, playOwnedSeason(app));
    final table = first.leagueTable, matches = first.matchResults;
    final tableSignature = table.signature, matchSignature = matches.signature;
    expect(() => table.rows.clear(), throwsUnsupportedError);
    expect(() => matches.matches.clear(), throwsUnsupportedError);
    enterNextOwnedSeason(app, first);
    expect(app.currentSeasonOpening.seasonIndex, 2);
    final second = settleOwnedSeason(app, playOwnedSeason(app));
    expect(second.leagueTable.seasonIndex, 2);
    expect(second.matchResults.seasonIndex, 2);
    expect(first.leagueTable, same(table));
    expect(first.matchResults, same(matches));
    expect(table.signature, tableSignature);
    expect(matches.signature, matchSignature);
    expect(second.leagueTable, isNot(same(table)));
  });

  test('ticket answer changes no already committed match or table observation',
      () {
    final firstApp = firstFutureCareer(), secondApp = firstFutureCareer();
    final balanced = settleOwnedSeason(firstApp, playOwnedSeason(firstApp));
    final premium = settleOwnedSeason(secondApp, playOwnedSeason(secondApp),
        ticketTier: MatchdayTicketPriceTier.premium);
    expect(balanced.leagueTable.signature, premium.leagueTable.signature);
    expect(balanced.matchResults.signature, premium.matchResults.signature);
  });

  test('repeated readback cannot settle or advance another season', () {
    final app = firstFutureCareer();
    final w30 = playOwnedSeason(app);
    final settled = settleOwnedSeason(app, w30);
    final finance = settled.finance.signature;
    for (var i = 0; i < 3; i++) {
      expect(settled.leagueTable.rows.length, 16);
      expect(settled.matchResults.matches.length, 30);
      expect(app.currentStep, same(settled));
      expect(settled.finance.signature, finance);
    }
    expect(() => app.completeFutureSeason(expected: w30), throwsStateError);
    expect(app.currentStep, same(settled));
  });
}
