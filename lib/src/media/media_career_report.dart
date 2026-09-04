import '../manager/manager_career_report.dart';
import 'media_credibility_change.dart';
import 'media_season_snapshot.dart';
import 'media_state.dart';
import 'media_statement.dart';

class MediaCareerReport {
  MediaCareerReport({
    required this.managerReport,
    required Iterable<MediaCareerSeason> seasons,
    required Iterable<MediaState> finalStates,
  })  : seasons = List.unmodifiable(seasons),
        finalStates = List.unmodifiable(finalStates);

  final ManagerCareerReport managerReport;
  final List<MediaCareerSeason> seasons;
  final List<MediaState> finalStates;

  int get seasonCount => seasons.length;

  Iterable<MediaSeasonSnapshot> get _snapshots sync* {
    for (final season in seasons) {
      yield* season.clubs;
    }
  }

  int get totalStatements =>
      _snapshots.where((snapshot) => snapshot.statement != null).length;

  int get totalContradictions => _snapshots
      .where((snapshot) =>
          snapshot.change?.resolution == MediaResolution.contradiction)
      .length;

  int get totalConsistentStatements => _snapshots
      .where((snapshot) =>
          snapshot.change?.resolution == MediaResolution.consistent)
      .length;

  int get strongSupportContradictions => _snapshots
      .where((snapshot) =>
          snapshot.change?.reason == MediaCredibilityReason.supportBroken)
      .length;

  Map<MediaStance, int> get stanceDistribution {
    final counts = <MediaStance, int>{};
    for (final snapshot in _snapshots) {
      final stance = snapshot.statement?.stance;
      if (stance == null) continue;
      counts.update(stance, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  double get averageFinalCredibility {
    if (finalStates.isEmpty) return 0;
    return finalStates.fold<int>(0, (sum, state) => sum + state.credibility) /
        finalStates.length;
  }

  int get minimumFinalCredibility {
    if (finalStates.isEmpty) return 0;
    return finalStates
        .map((state) => state.credibility)
        .reduce((a, b) => a < b ? a : b);
  }

  int get maximumFinalCredibility {
    if (finalStates.isEmpty) return 0;
    return finalStates
        .map((state) => state.credibility)
        .reduce((a, b) => a > b ? a : b);
  }

  int get boundaryClubs => finalStates
      .where((state) => state.credibility <= 5 || state.credibility >= 95)
      .length;

  String get signature {
    final buffer = StringBuffer(managerReport.signature);
    for (final season in seasons) {
      buffer.write('|media=${season.signature}');
    }
    final sortedStates = List<MediaState>.of(finalStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final state in sortedStates) {
      buffer.write('|mediaFinal=${state.signature}');
    }
    return buffer.toString();
  }
}
