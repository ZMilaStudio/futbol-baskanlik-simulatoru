import 'dart:collection';

import '../core/money.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../league/club.dart';
import '../sponsor/sponsor_system.dart';
import 'club_finance_season.dart';
import 'club_finance_state.dart';

part 'full_m65_season_finance_pipeline.dart';

/// Observed facility context, not a replay of attendance computation.
final class FinanceAttendanceEvidence {
  const FinanceAttendanceEvidence(
      {required this.club,
      required this.stadiumLevel,
      required this.fanTrust,
      required this.leaguePosition,
      required this.multiplierBps});
  final Club club;
  final int stadiumLevel;
  final int fanTrust;
  final int leaguePosition;
  final int multiplierBps;
}

/// Runtime-only evidence of one successful, three-league M65 settlement.
/// Construction is library-private; consumers cannot mint successful receipts.
final class SeasonFinanceAuthorityReceipt {
  SeasonFinanceAuthorityReceipt._(
      {required this.owner,
      required this.sourceRevision,
      required this.provenance,
      required this.seasonIndex,
      required this.effectiveClubSource,
      required Map<String, ClubFinanceConsumedInput> inputs,
      required List<ClubFinanceSeason> results})
      : inputs = Map.unmodifiable(inputs),
        results = List.unmodifiable(results);
  final Object owner;
  final Object sourceRevision;
  final Object provenance;
  final Object? effectiveClubSource;
  final int seasonIndex;
  final Map<String, ClubFinanceConsumedInput> inputs;
  final List<ClubFinanceSeason> results;
  bool get successful => true;

  /// Identity and arithmetic checks only. No engine, provider or controller calls.
  void verify(
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance,
      required int expectedSeason,
      required Iterable<ClubFinanceSeason> expectedResults,
      Object? expectedEffectiveClubSource}) {
    if (!identical(owner, expectedOwner) ||
        !identical(sourceRevision, expectedRevision) ||
        !identical(provenance, expectedProvenance) ||
        seasonIndex != expectedSeason ||
        !identical(effectiveClubSource, expectedEffectiveClubSource)) {
      throw StateError('Foreign settlement authority.');
    }
    final supplied = expectedResults.toList(growable: false);
    final byId = {for (final row in supplied) row.clubId: row};
    if (inputs.length != 48 ||
        results.length != 48 ||
        supplied.length != 48 ||
        byId.length != 48) throw StateError('Incomplete settlement coverage.');
    for (final row in results) {
      final input = inputs[row.clubId]!;
      if (!identical(byId[row.clubId], row) ||
          row.openingCash != input.opening.cash ||
          row.openingDebt != input.opening.debt ||
          row.wageExpense != input.wages ||
          row.sponsorRevenue != input.sponsorRevenue ||
          row.transferInstallmentIncome != input.installmentIncome ||
          row.transferInstallmentExpense != input.installmentExpense ||
          row.closingCash != row.expectedClosingCash ||
          row.closingDebt != row.expectedClosingDebt ||
          input.ticket.context.club.id != row.clubId ||
          !identical(input.club, input.ticket.context.club) ||
          !identical(input.club, input.attendance.club) ||
          input.ticket.context.seasonIndex != seasonIndex ||
          input.sponsorSource.seasonIndex != seasonIndex ||
          input.sponsorSource.revenueByClub[row.clubId] !=
              input.sponsorRevenue ||
          !identical(
              input.ticket.outcome.base, input.ticket.context.baseAttendance) ||
          input.finalMultiplierBps !=
              input.ticket.outcome.revenueMultiplierBps ||
          input.attendance.multiplierBps != input.incomingMultiplierBps) {
        throw StateError('Consumed input/result mismatch for ${row.clubId}.');
      }
    }
  }
}

final class ClubFinanceConsumedInput {
  const ClubFinanceConsumedInput(
      {required this.club,
      required this.opening,
      required this.wages,
      required this.installmentIncome,
      required this.installmentExpense,
      required this.sponsorRevenue,
      required this.sponsorSource,
      required this.attendance,
      required this.ticket,
      required this.incomingMultiplierBps,
      required this.finalMultiplierBps,
      required this.economicScaleBps,
      required this.costScaleBps});
  final Club club;
  final ClubFinanceState opening;
  final Money wages;
  final Money installmentIncome;
  final Money installmentExpense;
  final Money sponsorRevenue;
  final SponsorSeasonResolution sponsorSource;
  final FinanceAttendanceEvidence attendance;
  final PlayerPresidentTicketPricingDecision ticket;
  final int incomingMultiplierBps;
  final int finalMultiplierBps;
  final int economicScaleBps;
  final int costScaleBps;
}
