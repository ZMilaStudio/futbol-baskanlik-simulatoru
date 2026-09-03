import '../core/money.dart';
import '../finance/club_finance_state.dart';
import 'transfer_career_report.dart';

class TransferCareerValidator {
  const TransferCareerValidator();

  List<String> validate(TransferCareerReport report) {
    final issues = <String>[];
    if (report.seasons.isEmpty) {
      issues.add('Career has no seasons.');
      return issues;
    }

    for (var i = 0; i < report.seasons.length; i++) {
      final season = report.seasons[i];
      final closingByClub = {
        for (final finance in season.finances)
          finance.clubId: ClubFinanceState(
            clubId: finance.clubId,
            cash: finance.closingCash,
            debt: finance.closingDebt,
          ),
      };
      final afterByClub = {
        for (final state in season.financeStatesAfterWindow) state.clubId: state,
      };
      final movedIds = <String>{};
      final expectedCash = {
        for (final entry in closingByClub.entries) entry.key: entry.value.cash,
      };

      for (final deal in season.transfersAfterSeason) {
        if (!movedIds.add(deal.playerId)) {
          issues.add('Season ${season.seasonIndex}: player ${deal.playerId} moved twice.');
        }
        if (deal.fromClubId == deal.toClubId) {
          issues.add('Season ${season.seasonIndex}: self transfer ${deal.playerId}.');
        }
        if (deal.fee <= Money.zero) {
          issues.add('Season ${season.seasonIndex}: non-positive fee ${deal.playerId}.');
        }
        if (closingByClub[deal.fromClubId] == null ||
            closingByClub[deal.toClubId] == null) {
          issues.add('Season ${season.seasonIndex}: transfer references unknown club.');
          continue;
        }
        expectedCash[deal.fromClubId] = expectedCash[deal.fromClubId]! + deal.fee;
        expectedCash[deal.toClubId] = expectedCash[deal.toClubId]! - deal.fee;
      }

      for (final entry in closingByClub.entries) {
        final post = afterByClub[entry.key];
        if (post == null) {
          issues.add('Season ${season.seasonIndex}: missing post-window finance ${entry.key}.');
          continue;
        }
        if (post.cash != expectedCash[entry.key]) {
          issues.add('Season ${season.seasonIndex}: transfer cash mismatch ${entry.key}.');
        }
        if (post.debt != entry.value.debt) {
          issues.add('Season ${season.seasonIndex}: transfer changed debt ${entry.key}.');
        }
        if (post.cash < Money.zero) {
          issues.add('Season ${season.seasonIndex}: negative post-window cash ${entry.key}.');
        }
      }

      if (i + 1 < report.seasons.length) {
        final next = report.seasons[i + 1];
        final nextOpening = {
          for (final finance in next.finances) finance.clubId: finance,
        };
        for (final state in season.financeStatesAfterWindow) {
          final opening = nextOpening[state.clubId];
          if (opening == null) {
            issues.add('Season ${next.seasonIndex}: missing finance ${state.clubId}.');
            continue;
          }
          if (opening.openingCash != state.cash || opening.openingDebt != state.debt) {
            issues.add('Season ${next.seasonIndex}: opening finance continuity failed ${state.clubId}.');
          }
        }
      }
    }

    final finalWindow = report.seasons.last.financeStatesAfterWindow;
    final finalByClub = {
      for (final state in report.finalFinanceStates) state.clubId: state,
    };
    for (final state in finalWindow) {
      final finalState = finalByClub[state.clubId];
      if (finalState == null ||
          finalState.cash != state.cash ||
          finalState.debt != state.debt) {
        issues.add('Final finance state mismatch ${state.clubId}.');
      }
    }

    return issues;
  }
}
