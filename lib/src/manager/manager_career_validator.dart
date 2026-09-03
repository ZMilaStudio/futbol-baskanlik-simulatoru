import '../world/world_career_validator.dart';
import 'manager_career_report.dart';

class ManagerCareerValidator {
  const ManagerCareerValidator({
    this.worldValidator = const WorldCareerValidator(),
  });

  final WorldCareerValidator worldValidator;

  List<String> validate(ManagerCareerReport report) {
    final issues = <String>[];
    issues.addAll(
      worldValidator
          .validate(report.worldReport)
          .map((issue) => 'World: $issue'),
    );

    if (report.managers.length < 48) {
      issues.add('Manager pool must contain at least 48 managers.');
    }
    final managerIds = report.managers.map((manager) => manager.id).toSet();
    if (managerIds.length != report.managers.length) {
      issues.add('Manager IDs must be unique.');
    }
    final managerById = {
      for (final manager in report.managers) manager.id: manager,
    };

    if (report.seasons.length != report.worldReport.seasons.length) {
      issues.add('Manager season count must match world season count.');
      return issues;
    }

    for (var index = 0; index < report.seasons.length; index++) {
      final season = report.seasons[index];
      final worldSeason = report.worldReport.seasons[index];
      if (season.seasonIndex != worldSeason.seasonIndex) {
        issues.add('Manager season $index has mismatched season index.');
      }
      if (season.clubs.length != 48) {
        issues.add('Season ${season.seasonIndex} must contain 48 manager clubs.');
      }
      final clubIds = season.clubs.map((club) => club.clubId).toSet();
      final seasonManagerIds = season.clubs.map((club) => club.managerId).toSet();
      if (clubIds.length != season.clubs.length) {
        issues.add('Season ${season.seasonIndex} has duplicate clubs.');
      }
      if (seasonManagerIds.length != season.clubs.length) {
        issues.add('Season ${season.seasonIndex} assigns a manager twice.');
      }

      final actualPositions = <String, int>{};
      for (final league in worldSeason.leagueResults) {
        for (var rowIndex = 0; rowIndex < league.report.table.length; rowIndex++) {
          actualPositions[league.report.table[rowIndex].clubId] = rowIndex + 1;
        }
      }

      for (final club in season.clubs) {
        final manager = managerById[club.managerId];
        if (manager == null) {
          issues.add('Unknown manager ${club.managerId}.');
          continue;
        }
        if (club.fitScore < 0 || club.fitScore > 100) {
          issues.add('${club.clubId} has invalid manager fit.');
        }
        if (club.strengthImpact < -2.500001 || club.strengthImpact > 2.500001) {
          issues.add('${club.clubId} has invalid manager strength impact.');
        }
        if (club.relationshipBefore < 0 || club.relationshipBefore > 100 ||
            club.relationshipAfter < 0 || club.relationshipAfter > 100) {
          issues.add('${club.clubId} has invalid board relationship.');
        }
        if (club.expectedPosition < 1 || club.expectedPosition > 16 ||
            club.actualPosition < 1 || club.actualPosition > 16) {
          issues.add('${club.clubId} has invalid league position.');
        }
        if (actualPositions[club.clubId] != club.actualPosition) {
          issues.add('${club.clubId} manager finish does not match league table.');
        }
        if (club.managerAge >= manager.retirementAge) {
          issues.add('${club.managerId} managed beyond retirement age.');
        }
      }

      final changesByClub = <String, dynamic>{};
      for (final change in season.changesAfterSeason) {
        if (changesByClub.containsKey(change.clubId)) {
          issues.add('Season ${season.seasonIndex} changes one club twice.');
        }
        changesByClub[change.clubId] = change;
        if (change.fromManagerId == change.toManagerId) {
          issues.add('${change.clubId} manager change kept the same manager.');
        }
        if (!managerIds.contains(change.fromManagerId) ||
            !managerIds.contains(change.toManagerId)) {
          issues.add('${change.clubId} manager change references unknown manager.');
        }
      }

      if (index < report.seasons.length - 1) {
        final currentByClub = {
          for (final club in season.clubs) club.clubId: club,
        };
        final nextByClub = {
          for (final club in report.seasons[index + 1].clubs) club.clubId: club,
        };
        for (final entry in currentByClub.entries) {
          final next = nextByClub[entry.key];
          if (next == null) {
            issues.add('${entry.key} missing from next manager season.');
            continue;
          }
          final change = changesByClub[entry.key];
          if (change == null) {
            if (entry.value.changedAfterSeason) {
              issues.add('${entry.key} flags a change without a change record.');
            }
            if (next.managerId != entry.value.managerId) {
              issues.add('${entry.key} changed manager without a change record.');
            }
          } else {
            if (!entry.value.changedAfterSeason) {
              issues.add('${entry.key} change record is missing the season flag.');
            }
            if (change.fromManagerId != entry.value.managerId ||
                change.toManagerId != next.managerId) {
              issues.add('${entry.key} manager change continuity is broken.');
            }
          }
        }
      } else if (season.changesAfterSeason.isNotEmpty ||
          season.clubs.any((club) => club.changedAfterSeason)) {
        issues.add('Final season must not appoint unused next-season managers.');
      }
    }

    if (report.finalAssignments.length != 48) {
      issues.add('Final manager assignments must contain 48 clubs.');
    }
    final finalClubIds = report.finalAssignments
        .map((assignment) => assignment.clubId)
        .toSet();
    final finalManagerIds = report.finalAssignments
        .map((assignment) => assignment.managerId)
        .toSet();
    if (finalClubIds.length != report.finalAssignments.length) {
      issues.add('Final manager assignments contain duplicate clubs.');
    }
    if (finalManagerIds.length != report.finalAssignments.length) {
      issues.add('Final manager assignments contain duplicate managers.');
    }
    for (final assignment in report.finalAssignments) {
      if (!managerIds.contains(assignment.managerId)) {
        issues.add('Final assignment references unknown manager.');
      }
      if (assignment.boardRelationship < 0 ||
          assignment.boardRelationship > 100) {
        issues.add('${assignment.clubId} has invalid final relationship.');
      }
    }

    if (report.seasons.isNotEmpty) {
      final lastManagers = {
        for (final club in report.seasons.last.clubs) club.clubId: club.managerId,
      };
      for (final assignment in report.finalAssignments) {
        if (lastManagers[assignment.clubId] != assignment.managerId) {
          issues.add('${assignment.clubId} final manager does not match final season.');
        }
      }
    }

    return issues;
  }
}
