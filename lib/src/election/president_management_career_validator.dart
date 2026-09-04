import 'president_management_career_report.dart';
import 'president_reputation_career_validator.dart';

class PresidentManagementCareerValidator {
  const PresidentManagementCareerValidator();

  List<String> validate(PresidentManagementCareerReport report) {
    final issues = <String>[
      ...const PresidentReputationCareerValidator().validate(report.sourceReport),
    ];

    if (report.totalProfiles != report.sourceReport.uniquePresidents) {
      issues.add(
        'Management profile count mismatch: '
        '${report.totalProfiles}/${report.sourceReport.uniquePresidents}.',
      );
    }

    final ids = <String>{};
    for (final profile in report.profiles) {
      if (!ids.add(profile.presidentId)) {
        issues.add('Duplicate management profile ${profile.presidentId}.');
      }
      for (final trait in profile.traits) {
        if (trait < 20 || trait > 90) {
          issues.add('Management trait out of bounds for ${profile.presidentId}.');
          break;
        }
      }
    }

    final expectedIds = <String>{
      for (final state in report.sourceReport.initialTenureStates) state.president.id,
      for (final turnover in report.sourceReport.turnovers) turnover.incoming.id,
    };
    if (!ids.containsAll(expectedIds) || !expectedIds.containsAll(ids)) {
      issues.add('Management profile president set mismatch.');
    }

    if (report.turnoverComparisons.length != report.sourceReport.totalTurnovers) {
      issues.add('Management turnover comparison count mismatch.');
    }
    for (var i = 0;
        i < report.turnoverComparisons.length && i < report.sourceReport.turnovers.length;
        i++) {
      final comparison = report.turnoverComparisons[i];
      final turnover = report.sourceReport.turnovers[i];
      if (comparison.clubId != turnover.clubId ||
          comparison.electionSeasonIndex != turnover.electionSeasonIndex ||
          comparison.outgoing.presidentId != turnover.outgoing.id ||
          comparison.incoming.presidentId != turnover.incoming.id) {
        issues.add('Management turnover mapping mismatch at index $i.');
      }
      if (comparison.averageTraitDistance < 0 ||
          comparison.averageTraitDistance > 70 ||
          comparison.materiallyChangedTraits < 0 ||
          comparison.materiallyChangedTraits > 5) {
        issues.add('Invalid management turnover distance at index $i.');
      }
    }

    if (report.totalProfiles >= 20 && report.archetypesUsed < 4) {
      issues.add('President management archetype variety is too low.');
    }
    if (report.turnoverComparisons.length >= 20 && report.meaningfulTurnovers == 0) {
      issues.add('President turnovers never change management philosophy meaningfully.');
    }

    return issues;
  }
}
