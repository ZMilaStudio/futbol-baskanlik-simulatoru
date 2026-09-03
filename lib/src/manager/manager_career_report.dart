import '../world/world_career_report.dart';
import 'manager.dart';
import 'manager_assignment.dart';
import 'manager_career_season.dart';

class ManagerCareerReport {
  ManagerCareerReport({
    required this.worldReport,
    required Iterable<Manager> managers,
    required Iterable<ManagerCareerSeason> seasons,
    required Iterable<ManagerAssignment> finalAssignments,
  })  : managers = List.unmodifiable(managers),
        seasons = List.unmodifiable(seasons),
        finalAssignments = List.unmodifiable(finalAssignments);

  final WorldCareerReport worldReport;
  final List<Manager> managers;
  final List<ManagerCareerSeason> seasons;
  final List<ManagerAssignment> finalAssignments;

  int get seasonCount => seasons.length;
  int get totalManagerChanges => seasons.fold(
        0,
        (sum, season) => sum + season.changesAfterSeason.length,
      );
  int get totalRetirements => seasons.fold(
        0,
        (sum, season) =>
            sum +
            season.changesAfterSeason
                .where((change) => change.reason == ManagerChangeReason.retirement)
                .length,
      );
  int get totalDismissals => totalManagerChanges - totalRetirements;

  int get uniqueManagersUsed {
    final ids = <String>{};
    for (final season in seasons) {
      ids.addAll(season.clubs.map((club) => club.managerId));
    }
    return ids.length;
  }

  double get averageStrengthImpact {
    var total = 0.0;
    var count = 0;
    for (final season in seasons) {
      for (final club in season.clubs) {
        total += club.strengthImpact;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  double get averageFinalRelationship {
    if (finalAssignments.isEmpty) return 0;
    return finalAssignments.fold<double>(
          0,
          (sum, assignment) => sum + assignment.boardRelationship,
        ) /
        finalAssignments.length;
  }

  String get signature {
    final buffer = StringBuffer(worldReport.signature);
    for (final season in seasons) {
      buffer.write('|manager=${season.signature}');
    }
    final assignments = List<ManagerAssignment>.of(finalAssignments)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final assignment in assignments) {
      buffer.write('|finalManager=${assignment.signature}');
    }
    return buffer.toString();
  }
}
