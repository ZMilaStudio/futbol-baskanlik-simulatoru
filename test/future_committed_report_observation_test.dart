import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';

import 'p2_ar_d_future_weekly_runtime_test.dart' show completedFutureApp;

void _expectReadOnly(StandingRow row) {
  final before = row.toJson();
  final mutations = <void Function()>[
    () => row.played = -1,
    () => row.wins = -2,
    () => row.draws = -3,
    () => row.losses = -4,
    () => row.goalsFor = -5,
    () => row.goalsAgainst = -6,
    () => row.points = -7,
    () => row.record(scored: 9, conceded: 0),
  ];
  for (final mutate in mutations) {
    expect(mutate, throwsUnsupportedError);
    expect(row.toJson(), before);
  }
}

void main() {
  for (final source in ['committed result', 'settlement capability']) {
    test('$source exposes read-only rows with exact W30 values and identities',
        () {
      final application = completedFutureApp();
      final w30 = application.futureWeeklyState!;
      final committed = application.commitFutureSeason(expectedW30: w30);
      final reports = source == 'committed result'
          ? committed.reports
          : committed.capability.reports;

      expect(reports, hasLength(3));
      for (final league in reports) {
        final weeklyRows = w30.fixtureSnapshot.tableFor(league.tier);
        final capabilityReport = committed.capability.reports
            .singleWhere((candidate) => candidate.tier == league.tier)
            .report;
        final committedReport = committed.reports
            .singleWhere((candidate) => candidate.tier == league.tier)
            .report;
        expect(league.report, same(capabilityReport));
        expect(league.report, same(committedReport));
        expect(league.report.table, hasLength(16));
        for (var index = 0; index < league.report.table.length; index++) {
          final row = league.report.table[index];
          expect(row.toJson(), weeklyRows[index].toJson());
          expect(row, same(capabilityReport.table[index]));
          expect(row, same(committedReport.table[index]));
          _expectReadOnly(row);
        }
      }

      // Every attempted observation mutation leaves the original capability
      // valid. Its unchanged identity/signature checks still admit settlement.
      final authority =
          application.handoffFutureEconomy(expectedCommitted: committed);
      expect(authority.prepareSettlement(committed.capability),
          RuntimeEconomyState.awaitingTicketDecision);
      final pending = authority.pending!;
      authority.submitTicket(
        pending,
        const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
        expectedRevision: authority.revision,
      );
      final settled =
          authority.executeSettlement(expectedCommitted: committed.capability);
      expect(authority.state, RuntimeEconomyState.settled);
      expect(settled.committedSource, same(committed.capability));
      expect(settled.receipt.results, hasLength(48));
      settled.receipt.verify(
        expectedOwner: authority.owner,
        expectedRevision: authority.revision,
        expectedProvenance: authority.provenance,
        expectedSeason: w30.targetSeasonIndex,
        expectedResults: settled.receipt.results,
        expectedEffectiveClubSource: authority.managerAuthority,
      );
    });
  }

  test('observation mutation after ticket Pending cannot poison settlement',
      () {
    final application = completedFutureApp();
    final committed = application.commitFutureSeason(
        expectedW30: application.futureWeeklyState!);
    final authority =
        application.handoffFutureEconomy(expectedCommitted: committed);
    authority.prepareSettlement(committed.capability);
    final pending = authority.pending!;
    final row = committed.capability.reports.first.report.table.first;

    _expectReadOnly(row);
    expect(authority.state, RuntimeEconomyState.awaitingTicketDecision);
    expect(authority.pending, same(pending));
    authority.submitTicket(
      pending,
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium),
      expectedRevision: authority.revision,
    );
    final settled =
        authority.executeSettlement(expectedCommitted: committed.capability);
    expect(authority.state, RuntimeEconomyState.settled);
    expect(authority.result, same(settled));
    expect(committed.capability.reports.first.report.table.first, same(row));
    expect(
        () => authority.executeSettlement(
            expectedCommitted: committed.capability),
        throwsStateError);
  });

  test('publication collections are immutable; calculation rows remain mutable',
      () {
    final application = completedFutureApp();
    final committed = application.commitFutureSeason(
        expectedW30: application.futureWeeklyState!);
    expect(() => committed.reports.clear(), throwsUnsupportedError);
    expect(() => committed.capability.reports.clear(), throwsUnsupportedError);
    final report = committed.reports.first.report;
    expect(() => report.table.clear(), throwsUnsupportedError);
    expect(() => report.table[0] = StandingRow(clubId: 'replacement'),
        throwsUnsupportedError);
    expect(() => report.fixtures.clear(), throwsUnsupportedError);

    final stagingRow = StandingRow(clubId: 'staging');
    stagingRow.record(scored: 2, conceded: 1);
    expect(stagingRow.played, 1);
    expect(stagingRow.points, 3);
    stagingRow.points = 4;
    expect(stagingRow.points, 4);
  });
}
