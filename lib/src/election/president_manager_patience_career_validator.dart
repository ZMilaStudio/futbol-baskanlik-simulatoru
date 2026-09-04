import '../manager/manager_career_validator.dart';
import '../manager/manager_patience_policy.dart';
import 'president_management_career_validator.dart';
import 'president_manager_patience_career_report.dart';

class PresidentManagerPatienceCareerValidator {
  const PresidentManagerPatienceCareerValidator({
    this.dismissalPolicy = const ManagerDismissalPolicy(),
  });

  final ManagerDismissalPolicy dismissalPolicy;

  List<String> validate(PresidentManagerPatienceCareerReport report) {
    final issues = <String>[
      ...const PresidentManagementCareerValidator()
          .validate(report.sourceReport)
          .map((item) => 'M17 source: $item'),
      ...const ManagerCareerValidator()
          .validate(report.influencedManagerReport)
          .map((item) => 'M18 manager: $item'),
    ];

    final expectedDecisionCount = report.influencedManagerReport.seasons.fold<int>(
      0,
      (sum, season) => sum + season.clubs.length,
    );
    if (report.decisions.length != expectedDecisionCount) {
      issues.add(
        'M18 decision count mismatch: '
        '${report.decisions.length}/$expectedDecisionCount.',
      );
    }

    final keys = <String>{};
    for (final item in report.decisions) {
      final key = '${item.seasonIndex}|${item.clubId}';
      if (!keys.add(key)) {
        issues.add('Duplicate M18 decision snapshot $key.');
      }
      if (item.managerPatience < 20 || item.managerPatience > 90) {
        issues.add('M18 manager patience out of bounds for $key.');
      }
      final expectedThresholds = dismissalPolicy.thresholds(item.managerPatience);
      if (expectedThresholds.signature != item.thresholds.signature) {
        issues.add('M18 threshold mismatch for $key.');
      }
      if (item.changedAfterSeason != (item.changeReason != null)) {
        issues.add('M18 change reason mismatch for $key.');
      }
      if (item.expectedPosition < 1 ||
          item.expectedPosition > 16 ||
          item.actualPosition < 1 ||
          item.actualPosition > 16) {
        issues.add('M18 league position out of bounds for $key.');
      }
      if (item.relationshipAfter < 0 || item.relationshipAfter > 100) {
        issues.add('M18 relationship out of bounds for $key.');
      }
    }

    if (report.influencedManagerReport.seasonCount !=
        report.baselineManagerReport.seasonCount) {
      issues.add('M18 baseline/influenced season count mismatch.');
    }
    if (report.lowPatienceClubSeasons == 0) {
      issues.add('M18 has no low-patience club seasons.');
    }
    if (report.highPatienceClubSeasons == 0) {
      issues.add('M18 has no high-patience club seasons.');
    }
    if (report.decisions.length >= 100 && report.decisionDifferences == 0) {
      issues.add('M18 patience never changes a manager decision.');
    }
    if (report.decisions.length >= 100 && report.managerIdentityDifferences == 0) {
      issues.add('M18 patience never changes manager identity history.');
    }
    if (report.decisions.length >= 100 && !report.worldChanged) {
      issues.add('M18 manager patience never changes the simulated world.');
    }
    if (report.influencedManagerChanges < 1 ||
        report.influencedManagerChanges > 300) {
      issues.add('M18 manager change count is implausible.');
    }

    return issues;
  }
}
