import '../core/money.dart';
import '../player/player_career_validator.dart';
import 'club_finance_state.dart';
import 'economy_career_report.dart';

class EconomyCareerValidator {
  const EconomyCareerValidator({
    this.playerValidator = const PlayerCareerValidator(),
  });

  final PlayerCareerValidator playerValidator;

  List<String> validate(EconomyCareerReport report) {
    final issues = <String>[];

    for (final issue in playerValidator.validate(report.playerCareer)) {
      issues.add('Player career: $issue');
    }

    if (report.seasonCount != report.playerCareer.seasonCount) {
      issues.add('Finance season count does not match player career.');
    }

    final expectedClubIds =
        report.playerCareer.finalClubs.map((club) => club.id).toSet();
    var previousStates = {
      for (final state in report.initialStates) state.clubId: state,
    };

    if (previousStates.keys.toSet().difference(expectedClubIds).isNotEmpty ||
        expectedClubIds.difference(previousStates.keys.toSet()).isNotEmpty) {
      issues.add('Initial finance club set does not match career clubs.');
    }

    for (var seasonOffset = 0;
        seasonOffset < report.seasons.length;
        seasonOffset++) {
      final season = report.seasons[seasonOffset];
      final expectedIndex =
          report.playerCareer.initialSeasonIndex + seasonOffset;
      if (season.seasonIndex != expectedIndex) {
        issues.add(
          'Finance season $seasonOffset has index ${season.seasonIndex}; '
          'expected $expectedIndex.',
        );
      }

      final ids = season.clubs.map((club) => club.clubId).toList();
      if (ids.toSet().length != ids.length) {
        issues.add('Finance season $seasonOffset contains duplicate clubs.');
      }
      if (ids.toSet().difference(expectedClubIds).isNotEmpty ||
          expectedClubIds.difference(ids.toSet()).isNotEmpty) {
        issues.add('Finance season $seasonOffset has the wrong club set.');
      }

      final nextStates = <String, ClubFinanceState>{};
      for (final club in season.clubs) {
        final previous = previousStates[club.clubId];
        if (previous == null) {
          issues.add(
            'Finance season $seasonOffset missing previous state for '
            '${club.clubId}.',
          );
          continue;
        }

        if (club.openingCash != previous.cash ||
            club.openingDebt != previous.debt) {
          issues.add(
            'Finance season $seasonOffset does not carry forward '
            '${club.clubId} opening balances.',
          );
        }

        final nonNegative = [
          club.openingCash,
          club.openingDebt,
          club.centralRevenue,
          club.sponsorRevenue,
          club.matchdayRevenue,
          club.prizeRevenue,
          club.wageExpense,
          club.operatingExpense,
          club.interestExpense,
          club.principalRepaid,
          club.emergencyBorrowing,
          club.closingCash,
          club.closingDebt,
        ];
        if (nonNegative.any((money) => money < Money.zero)) {
          issues.add(
            'Finance season $seasonOffset has a negative balance component '
            'for ${club.clubId}.',
          );
        }

        if (club.principalRepaid > club.openingDebt) {
          issues.add(
            'Finance season $seasonOffset repays more debt than opening '
            'principal for ${club.clubId}.',
          );
        }
        if (club.expectedClosingCash != club.closingCash) {
          issues.add(
            'Finance season $seasonOffset cash equation fails for '
            '${club.clubId}.',
          );
        }
        if (club.expectedClosingDebt != club.closingDebt) {
          issues.add(
            'Finance season $seasonOffset debt equation fails for '
            '${club.clubId}.',
          );
        }

        nextStates[club.clubId] = ClubFinanceState(
          clubId: club.clubId,
          cash: club.closingCash,
          debt: club.closingDebt,
        );
      }
      previousStates = nextStates;
    }

    final finalById = {
      for (final state in report.finalStates) state.clubId: state,
    };
    if (finalById.keys.toSet().difference(expectedClubIds).isNotEmpty ||
        expectedClubIds.difference(finalById.keys.toSet()).isNotEmpty) {
      issues.add('Final finance club set does not match career clubs.');
    }
    for (final clubId in expectedClubIds) {
      final expected = previousStates[clubId];
      final actual = finalById[clubId];
      if (expected == null || actual == null) {
        continue;
      }
      if (expected.cash != actual.cash || expected.debt != actual.debt) {
        issues.add('Final finance state mismatch for $clubId.');
      }
    }

    return issues;
  }
}
