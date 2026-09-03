import '../season/season_validator.dart';
import 'career_report.dart';

class CareerValidator {
  const CareerValidator({this.seasonValidator = const SeasonValidator()});

  final SeasonValidator seasonValidator;

  List<String> validate(CareerReport report) {
    final issues = <String>[];

    if (report.seasons.isEmpty) {
      issues.add('Career contains no seasons.');
      return issues;
    }

    if (report.endDate != report.startDate.addYears(report.seasonCount)) {
      issues.add('Career end date does not match season count.');
    }

    for (var i = 0; i < report.seasons.length; i++) {
      final season = report.seasons[i];
      final expectedStart = report.startDate.addYears(i);
      final expectedEnd = expectedStart.addYears(1);
      if (season.startDate != expectedStart || season.endDate != expectedEnd) {
        issues.add('Season $i has an invalid date window.');
      }
      final expectedSeasonIndex = report.initialSeasonIndex + i;
      if (season.report.seasonIndex != expectedSeasonIndex) {
        issues.add(
          'Season $i has report index ${season.report.seasonIndex}; '
          'expected $expectedSeasonIndex.',
        );
      }
      for (final issue in seasonValidator.validate(season.report)) {
        issues.add('Season $i: $issue');
      }
    }

    final clubIds = report.finalClubs.map((club) => club.id).toList();
    if (clubIds.toSet().length != clubIds.length) {
      issues.add('Final club IDs are not unique.');
    }

    return issues;
  }
}
