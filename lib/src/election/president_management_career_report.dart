import 'president_management_profile.dart';
import 'president_reputation_career_report.dart';

class PresidentManagementTurnoverComparison {
  const PresidentManagementTurnoverComparison({
    required this.clubId,
    required this.electionSeasonIndex,
    required this.outgoing,
    required this.incoming,
  });

  final String clubId;
  final int electionSeasonIndex;
  final PresidentManagementProfile outgoing;
  final PresidentManagementProfile incoming;

  double get averageTraitDistance => outgoing.distanceTo(incoming);

  int get materiallyChangedTraits {
    var count = 0;
    for (var i = 0; i < outgoing.traits.length; i++) {
      if ((outgoing.traits[i] - incoming.traits[i]).abs() >= 15) count++;
    }
    return count;
  }

  bool get archetypeChanged => outgoing.archetype != incoming.archetype;
  bool get meaningfulChange => averageTraitDistance >= 12;

  String get signature =>
      '$clubId:s$electionSeasonIndex:${outgoing.presidentId}>'
      '${incoming.presidentId}:distance=${averageTraitDistance.toStringAsFixed(2)}:'
      'traits=$materiallyChangedTraits:archetypeChanged=$archetypeChanged';
}

class PresidentManagementCareerReport {
  PresidentManagementCareerReport({
    required this.sourceReport,
    required Iterable<PresidentManagementProfile> profiles,
    required Iterable<PresidentManagementTurnoverComparison> turnoverComparisons,
  })  : profiles = List.unmodifiable(profiles),
        turnoverComparisons = List.unmodifiable(turnoverComparisons);

  final PresidentReputationCareerReport sourceReport;
  final List<PresidentManagementProfile> profiles;
  final List<PresidentManagementTurnoverComparison> turnoverComparisons;

  int get totalProfiles => profiles.length;

  Map<PresidentManagementArchetype, int> get archetypeDistribution {
    final result = <PresidentManagementArchetype, int>{};
    for (final profile in profiles) {
      result.update(profile.archetype, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(result);
  }

  int get archetypesUsed => archetypeDistribution.length;
  int get archetypeChangedTurnovers =>
      turnoverComparisons.where((item) => item.archetypeChanged).length;
  int get meaningfulTurnovers =>
      turnoverComparisons.where((item) => item.meaningfulChange).length;

  double get averageTurnoverDistance => turnoverComparisons.isEmpty
      ? 0
      : turnoverComparisons.fold<double>(
            0,
            (sum, item) => sum + item.averageTraitDistance,
          ) /
          turnoverComparisons.length;

  double get averageFinancialDiscipline => _average((item) => item.financialDiscipline);
  double get averageRiskAppetite => _average((item) => item.riskAppetite);
  double get averageTransferAmbition => _average((item) => item.transferAmbition);
  double get averageYouthOrientation => _average((item) => item.youthOrientation);
  double get averageManagerPatience => _average((item) => item.managerPatience);

  int get minimumFinancialDiscipline => _minimum((item) => item.financialDiscipline);
  int get maximumFinancialDiscipline => _maximum((item) => item.financialDiscipline);
  int get minimumRiskAppetite => _minimum((item) => item.riskAppetite);
  int get maximumRiskAppetite => _maximum((item) => item.riskAppetite);
  int get minimumTransferAmbition => _minimum((item) => item.transferAmbition);
  int get maximumTransferAmbition => _maximum((item) => item.transferAmbition);
  int get minimumYouthOrientation => _minimum((item) => item.youthOrientation);
  int get maximumYouthOrientation => _maximum((item) => item.youthOrientation);
  int get minimumManagerPatience => _minimum((item) => item.managerPatience);
  int get maximumManagerPatience => _maximum((item) => item.managerPatience);

  double _average(int Function(PresidentManagementProfile) value) => profiles.isEmpty
      ? 0
      : profiles.fold<int>(0, (sum, item) => sum + value(item)) / profiles.length;

  int _minimum(int Function(PresidentManagementProfile) value) => profiles.isEmpty
      ? 0
      : profiles.map(value).reduce((a, b) => a < b ? a : b);

  int _maximum(int Function(PresidentManagementProfile) value) => profiles.isEmpty
      ? 0
      : profiles.map(value).reduce((a, b) => a > b ? a : b);

  String get signature {
    final sortedProfiles = List<PresidentManagementProfile>.of(profiles)
      ..sort((a, b) => a.presidentId.compareTo(b.presidentId));
    final sortedTurnovers =
        List<PresidentManagementTurnoverComparison>.of(turnoverComparisons)
          ..sort((a, b) {
            final club = a.clubId.compareTo(b.clubId);
            return club != 0
                ? club
                : a.electionSeasonIndex.compareTo(b.electionSeasonIndex);
          });
    return '${sourceReport.signature}|managementProfiles='
        '${sortedProfiles.map((item) => item.signature).join('|')}|managementTurnovers='
        '${sortedTurnovers.map((item) => item.signature).join('|')}';
  }
}
