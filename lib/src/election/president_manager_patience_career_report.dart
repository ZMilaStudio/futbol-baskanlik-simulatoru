import '../manager/manager_career_report.dart';
import '../manager/manager_career_season.dart';
import '../manager/manager_patience_policy.dart';
import '../transfer/advanced_transfer_career_report.dart';
import 'president_management_career_report.dart';
import 'president_management_profile.dart';

class PresidentManagerPatienceDecisionSnapshot {
  const PresidentManagerPatienceDecisionSnapshot({
    required this.clubId,
    required this.seasonIndex,
    required this.presidentId,
    required this.archetype,
    required this.managerPatience,
    required this.thresholds,
    required this.managerId,
    required this.baselineManagerId,
    required this.expectedPosition,
    required this.actualPosition,
    required this.relationshipAfter,
    required this.changedAfterSeason,
    required this.baselineChangedAfterSeason,
    required this.changeReason,
  });

  final String clubId;
  final int seasonIndex;
  final String presidentId;
  final PresidentManagementArchetype archetype;
  final int managerPatience;
  final ManagerDismissalThresholds thresholds;
  final String managerId;
  final String baselineManagerId;
  final int expectedPosition;
  final int actualPosition;
  final double relationshipAfter;
  final bool changedAfterSeason;
  final bool baselineChangedAfterSeason;
  final ManagerChangeReason? changeReason;

  bool get decisionChanged => changedAfterSeason != baselineChangedAfterSeason;
  bool get managerIdentityChanged => managerId != baselineManagerId;
  bool get dismissal =>
      changeReason != null && changeReason != ManagerChangeReason.retirement;

  String get signature =>
      '$clubId:s$seasonIndex:$presidentId:${archetype.name}:'
      'patience=$managerPatience:${thresholds.signature}:'
      'manager=$baselineManagerId>$managerId:'
      'pos=$expectedPosition>$actualPosition:'
      'rel=${relationshipAfter.toStringAsFixed(2)}:'
      'change=$baselineChangedAfterSeason>$changedAfterSeason:'
      'reason=${changeReason?.name ?? 'none'}';
}

class PresidentManagerPatienceCareerReport {
  PresidentManagerPatienceCareerReport({
    required this.sourceReport,
    required this.influencedAdvancedReport,
    required this.influencedManagerReport,
    required Iterable<PresidentManagerPatienceDecisionSnapshot> decisions,
  }) : decisions = List.unmodifiable(decisions);

  final PresidentManagementCareerReport sourceReport;
  final AdvancedTransferCareerReport influencedAdvancedReport;
  final ManagerCareerReport influencedManagerReport;
  final List<PresidentManagerPatienceDecisionSnapshot> decisions;

  ManagerCareerReport get baselineManagerReport =>
      sourceReport.sourceReport.sourceReport.managerReport;
  AdvancedTransferCareerReport get baselineAdvancedReport =>
      sourceReport.sourceReport.sourceReport.advancedTransferReport;

  int get baselineManagerChanges => baselineManagerReport.totalManagerChanges;
  int get influencedManagerChanges => influencedManagerReport.totalManagerChanges;
  int get managerChangeDelta => influencedManagerChanges - baselineManagerChanges;
  int get decisionDifferences => decisions.where((item) => item.decisionChanged).length;
  int get managerIdentityDifferences =>
      decisions.where((item) => item.managerIdentityChanged).length;

  int get finalAssignmentDifferences {
    final baseline = {
      for (final item in baselineManagerReport.finalAssignments)
        item.clubId: item.managerId,
    };
    var count = 0;
    for (final item in influencedManagerReport.finalAssignments) {
      if (baseline[item.clubId] != item.managerId) count++;
    }
    return count;
  }

  int get lowPatienceClubSeasons =>
      decisions.where((item) => item.managerPatience <= 40).length;
  int get highPatienceClubSeasons =>
      decisions.where((item) => item.managerPatience >= 75).length;
  int get lowPatienceDismissals => decisions
      .where((item) => item.managerPatience <= 40 && item.dismissal)
      .length;
  int get highPatienceDismissals => decisions
      .where((item) => item.managerPatience >= 75 && item.dismissal)
      .length;

  double get lowPatienceDismissalRate => lowPatienceClubSeasons == 0
      ? 0
      : lowPatienceDismissals / lowPatienceClubSeasons;
  double get highPatienceDismissalRate => highPatienceClubSeasons == 0
      ? 0
      : highPatienceDismissals / highPatienceClubSeasons;

  double get averageDismissalPatience {
    final items = decisions.where((item) => item.dismissal).toList();
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (sum, item) => sum + item.managerPatience) /
        items.length;
  }

  double get averageRetainedPatience {
    final items = decisions.where((item) => !item.changedAfterSeason).toList();
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (sum, item) => sum + item.managerPatience) /
        items.length;
  }

  Map<ManagerChangeReason, int> get changeReasons {
    final result = <ManagerChangeReason, int>{};
    for (final item in decisions) {
      final reason = item.changeReason;
      if (reason == null) continue;
      result.update(reason, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(result);
  }

  bool get worldChanged =>
      influencedAdvancedReport.worldReport.signature !=
      baselineAdvancedReport.worldReport.signature;

  String get signature {
    final sorted = List<PresidentManagerPatienceDecisionSnapshot>.of(decisions)
      ..sort((a, b) {
        final season = a.seasonIndex.compareTo(b.seasonIndex);
        return season != 0 ? season : a.clubId.compareTo(b.clubId);
      });
    return '${sourceReport.signature}|m18Advanced=${influencedAdvancedReport.signature}|'
        'm18Manager=${influencedManagerReport.signature}|m18Decisions='
        '${sorted.map((item) => item.signature).join('|')}';
  }
}
