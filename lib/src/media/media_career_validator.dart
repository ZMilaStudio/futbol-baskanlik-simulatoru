import '../manager/manager_career_validator.dart';
import 'media_career_report.dart';
import 'media_state.dart';

class MediaCareerValidator {
  const MediaCareerValidator({
    this.managerValidator = const ManagerCareerValidator(),
  });

  final ManagerCareerValidator managerValidator;

  List<String> validate(MediaCareerReport report) {
    final issues = <String>[];
    for (final issue in managerValidator.validate(report.managerReport)) {
      issues.add('Manager career: $issue');
    }

    if (report.seasonCount != report.managerReport.seasonCount) {
      issues.add('Media season count does not match manager career.');
    }
    if (report.seasons.isEmpty) {
      return issues;
    }

    var states = {
      for (final snapshot in report.seasons.first.clubs)
        snapshot.clubId: MediaState(clubId: snapshot.clubId, credibility: 65),
    };
    final statementIds = <String>{};

    for (var i = 0; i < report.seasons.length; i++) {
      final season = report.seasons[i];
      final managerSeason = report.managerReport.seasons[i];
      if (season.seasonIndex != managerSeason.seasonIndex) {
        issues.add('Media season $i has wrong season index.');
      }
      if (season.clubs.length != managerSeason.clubs.length) {
        issues.add('Media season $i has wrong club count.');
      }

      final managerByClub = {
        for (final club in managerSeason.clubs) club.clubId: club,
      };
      final changedClubs = {
        for (final change in managerSeason.changesAfterSeason) change.clubId,
      };
      final seenClubs = <String>{};

      for (final snapshot in season.clubs) {
        if (!seenClubs.add(snapshot.clubId)) {
          issues.add('Media season $i duplicates club ${snapshot.clubId}.');
        }
        final managerClub = managerByClub[snapshot.clubId];
        if (managerClub == null) {
          issues.add('Media season $i has unknown club ${snapshot.clubId}.');
          continue;
        }
        if (snapshot.managerId != managerClub.managerId) {
          issues.add('Media season $i manager mismatch for ${snapshot.clubId}.');
        }
        if (snapshot.managerChanged != changedClubs.contains(snapshot.clubId)) {
          issues.add('Media season $i manager-change mismatch for ${snapshot.clubId}.');
        }

        final previous = states[snapshot.clubId];
        if (previous == null) {
          issues.add('Media season $i missing prior state for ${snapshot.clubId}.');
          continue;
        }
        if (snapshot.credibilityBefore != previous.credibility) {
          issues.add('Media season $i opening credibility mismatch for ${snapshot.clubId}.');
        }
        if (snapshot.credibilityAfter < 0 || snapshot.credibilityAfter > 100) {
          issues.add('Media season $i credibility out of range for ${snapshot.clubId}.');
        }

        final statement = snapshot.statement;
        final change = snapshot.change;
        if (statement == null) {
          if (change != null) {
            issues.add('Media season $i has change without statement for ${snapshot.clubId}.');
          }
          if (snapshot.credibilityBefore != snapshot.credibilityAfter) {
            issues.add('Media season $i changed credibility without statement for ${snapshot.clubId}.');
          }
        } else {
          if (!statementIds.add(statement.id)) {
            issues.add('Duplicate media statement ID ${statement.id}.');
          }
          if (statement.clubId != snapshot.clubId ||
              statement.targetManagerId != snapshot.managerId ||
              statement.seasonIndex != season.seasonIndex) {
            issues.add('Media season $i statement context mismatch for ${snapshot.clubId}.');
          }
          if (change == null) {
            issues.add('Media season $i statement missing credibility result for ${snapshot.clubId}.');
          } else if (change.before != snapshot.credibilityBefore ||
              change.after != snapshot.credibilityAfter ||
              change.delta != change.after - change.before) {
            issues.add('Media season $i credibility equation fails for ${snapshot.clubId}.');
          }
        }

        states[snapshot.clubId] = previous.copyWith(
          credibility: snapshot.credibilityAfter,
        );
      }
    }

    final finalById = {
      for (final state in report.finalStates) state.clubId: state,
    };
    if (finalById.length != states.length) {
      issues.add('Final media state count mismatch.');
    }
    for (final entry in states.entries) {
      final finalState = finalById[entry.key];
      if (finalState == null || finalState.credibility != entry.value.credibility) {
        issues.add('Final media state mismatch for ${entry.key}.');
      }
    }

    return issues;
  }
}
