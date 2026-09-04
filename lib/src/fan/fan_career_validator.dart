import '../transfer/advanced_transfer_career_validator.dart';
import 'fan_career_report.dart';
import 'fan_expectation.dart';

class FanCareerValidator {
  const FanCareerValidator({
    this.advancedValidator = const AdvancedTransferCareerValidator(),
  });

  final AdvancedTransferCareerValidator advancedValidator;

  List<String> validate(FanCareerReport report) {
    final issues = <String>[
      ...advancedValidator.validate(report.advancedTransferReport),
    ];
    final worldReport = report.advancedTransferReport.worldReport;
    if (worldReport.seasons.isEmpty) return issues;

    final expectedSnapshots =
        worldReport.initialClubCount * worldReport.seasonCount;
    if (report.snapshots.length != expectedSnapshots) {
      issues.add(
        'Fan snapshot count mismatch: ${report.snapshots.length}/$expectedSnapshots.',
      );
    }

    final keys = <String>{};
    final countsByClub = <String, int>{};
    for (final snapshot in report.snapshots) {
      final key = '${snapshot.context.seasonIndex}|${snapshot.context.clubId}';
      if (!keys.add(key)) {
        issues.add('Duplicate fan snapshot $key.');
      }
      countsByClub.update(
        snapshot.context.clubId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (snapshot.state.clubId != snapshot.context.clubId) {
        issues.add('Fan state club mismatch $key.');
      }
      final scores = [
        snapshot.state.sportingTrust,
        snapshot.state.financialTrust,
        snapshot.state.transferTrust,
        snapshot.state.identityTrust,
        snapshot.state.overallTrust,
      ];
      if (scores.any((score) => score < 0 || score > 100)) {
        issues.add('Fan trust out of range $key.');
      }
      if (!snapshot.context.hasTransferWindow &&
          snapshot.expectation.type != FanExpectationType.none) {
        issues.add('Final/no-window fan expectation mismatch $key.');
      }
      if (snapshot.context.hasTransferWindow &&
          snapshot.expectation.type == FanExpectationType.none) {
        issues.add('Missing transfer-window fan expectation $key.');
      }
      for (final reason in snapshot.reasons) {
        if (reason.delta == 0 || reason.delta < -8 || reason.delta > 8) {
          issues.add('Invalid fan trust delta $key:${reason.signature}.');
        }
      }
    }

    for (final clubId in worldReport.initialLeagues
        .expand((league) => league.clubIds)) {
      if (countsByClub[clubId] != worldReport.seasonCount) {
        issues.add('Fan season coverage mismatch for $clubId.');
      }
    }

    if (report.finalStates.length != worldReport.initialClubCount) {
      issues.add('Final fan-state count mismatch.');
    }
    for (final state in report.finalStates) {
      final last = report.snapshots.lastWhere(
        (snapshot) => snapshot.context.clubId == state.clubId,
      );
      if (last.state.signature != state.signature) {
        issues.add('Final fan-state mismatch for ${state.clubId}.');
      }
    }

    return issues;
  }
}
