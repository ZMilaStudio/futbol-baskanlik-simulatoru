import '../media/media_career_validator.dart';
import '../media/media_state.dart';
import '../transfer/advanced_transfer_career_validator.dart';
import 'promise_career_validator.dart';
import 'promise_media_career_report.dart';

class PromiseMediaCareerValidator {
  const PromiseMediaCareerValidator();

  List<String> validate(PromiseMediaCareerReport report) {
    final issues = <String>[
      ...const AdvancedTransferCareerValidator()
          .validate(report.advancedTransferReport),
      ...const MediaCareerValidator().validate(report.baselineMediaReport),
      ...const PromiseCareerValidator().validate(report.promiseReport),
    ];

    if (report.managerReport.worldReport.signature !=
        report.advancedTransferReport.worldReport.signature) {
      issues.add('Manager and advanced-transfer layers use different worlds.');
    }
    if (report.baselineMediaReport.managerReport.signature !=
        report.managerReport.signature) {
      issues.add('Baseline media does not use the shared manager report.');
    }
    if (report.promiseReport.advancedTransferReport.signature !=
        report.advancedTransferReport.signature) {
      issues.add('Promise layer does not use the shared advanced report.');
    }
    if (report.seasonCount != report.promiseReport.seasonCount ||
        report.seasonCount != report.baselineMediaReport.seasonCount) {
      issues.add('Combined media/promise season count mismatch.');
    }

    if (report.seasons.isEmpty) return issues;

    final promiseByKey = {
      for (final snapshot in report.promiseReport.snapshots)
        '${snapshot.promise.seasonIndex}|${snapshot.promise.clubId}':
            snapshot.promise,
    };
    var states = {
      for (final snapshot in report.seasons.first.clubs)
        snapshot.clubId: MediaState(clubId: snapshot.clubId, credibility: 65),
    };
    final seen = <String>{};

    for (final season in report.seasons) {
      for (final snapshot in season.clubs) {
        final key = '${season.seasonIndex}|${snapshot.clubId}';
        if (!seen.add(key)) issues.add('Duplicate combined snapshot $key.');
        if (snapshot.seasonIndex != season.seasonIndex) {
          issues.add('Combined season index mismatch $key.');
        }
        final previous = states[snapshot.clubId];
        if (previous == null) {
          issues.add('Missing combined prior state $key.');
          continue;
        }
        if (snapshot.credibilityBefore != previous.credibility) {
          issues.add('Combined opening credibility mismatch $key.');
        }
        final statementChange = snapshot.statementChange;
        if (statementChange == null) {
          if (snapshot.credibilityAfterStatement != snapshot.credibilityBefore) {
            issues.add('Statement-free credibility changed $key.');
          }
        } else {
          if (statementChange.before != snapshot.credibilityBefore ||
              statementChange.after != snapshot.credibilityAfterStatement ||
              statementChange.delta != statementChange.after - statementChange.before) {
            issues.add('Statement credibility equation failed $key.');
          }
        }

        final promise = promiseByKey[key];
        final change = snapshot.promiseChange;
        if (promise == null || change.promiseId != promise.id) {
          issues.add('Promise credibility link mismatch $key.');
        }
        if (change.before != snapshot.credibilityAfterStatement ||
            change.after != snapshot.credibilityAfterPromise ||
            change.delta != change.after - change.before) {
          issues.add('Promise credibility equation failed $key.');
        }
        if (change.after < 0 || change.after > 100 ||
            change.delta < -3 || change.delta > 2) {
          issues.add('Promise credibility change out of range $key.');
        }
        states[snapshot.clubId] = previous.copyWith(
          credibility: snapshot.credibilityAfterPromise,
        );
      }
    }

    if (seen.length != report.promiseReport.snapshots.length) {
      issues.add('Combined club-season coverage mismatch.');
    }

    final finalByClub = {
      for (final state in report.finalStates) state.clubId: state,
    };
    if (finalByClub.length != states.length) {
      issues.add('Combined final media-state count mismatch.');
    }
    for (final entry in states.entries) {
      if (finalByClub[entry.key]?.credibility != entry.value.credibility) {
        issues.add('Combined final credibility mismatch for ${entry.key}.');
      }
    }

    if (report.positivePromiseChanges == 0 ||
        report.neutralPromiseChanges == 0 ||
        report.negativePromiseChanges == 0) {
      issues.add('Promise-media outcomes lack positive/neutral/negative variety.');
    }

    return issues;
  }
}
