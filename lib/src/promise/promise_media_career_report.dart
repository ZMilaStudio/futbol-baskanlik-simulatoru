import '../manager/manager_career_report.dart';
import '../media/media_career_report.dart';
import '../media/media_state.dart';
import '../transfer/advanced_transfer_career_report.dart';
import 'promise_career_report.dart';
import 'promise_media_season_snapshot.dart';

class PromiseMediaCareerReport {
  PromiseMediaCareerReport({
    required this.advancedTransferReport,
    required this.managerReport,
    required this.baselineMediaReport,
    required this.promiseReport,
    required Iterable<PromiseMediaCareerSeason> seasons,
    required Iterable<MediaState> finalStates,
  })  : seasons = List.unmodifiable(seasons),
        finalStates = List.unmodifiable(finalStates);

  final AdvancedTransferCareerReport advancedTransferReport;
  final ManagerCareerReport managerReport;
  final MediaCareerReport baselineMediaReport;
  final PromiseCareerReport promiseReport;
  final List<PromiseMediaCareerSeason> seasons;
  final List<MediaState> finalStates;

  int get seasonCount => seasons.length;

  Iterable<PromiseMediaSeasonSnapshot> get snapshots sync* {
    for (final season in seasons) {
      yield* season.clubs;
    }
  }

  int get promiseChanges => snapshots.length;
  int get positivePromiseChanges =>
      snapshots.where((snapshot) => snapshot.promiseChange.delta > 0).length;
  int get neutralPromiseChanges =>
      snapshots.where((snapshot) => snapshot.promiseChange.delta == 0).length;
  int get negativePromiseChanges =>
      snapshots.where((snapshot) => snapshot.promiseChange.delta < 0).length;

  double get averageFinalCredibility {
    if (finalStates.isEmpty) return 0;
    return finalStates.fold<int>(0, (sum, state) => sum + state.credibility) /
        finalStates.length;
  }

  double get averageCredibilityDelta =>
      averageFinalCredibility - baselineMediaReport.averageFinalCredibility;

  int get minimumFinalCredibility => finalStates.isEmpty
      ? 0
      : finalStates
          .map((state) => state.credibility)
          .reduce((a, b) => a < b ? a : b);

  int get maximumFinalCredibility => finalStates.isEmpty
      ? 0
      : finalStates
          .map((state) => state.credibility)
          .reduce((a, b) => a > b ? a : b);

  int get boundaryClubs => finalStates
      .where((state) => state.credibility <= 5 || state.credibility >= 95)
      .length;

  String get signature {
    final buffer = StringBuffer()
      ..write(advancedTransferReport.signature)
      ..write('|manager=${managerReport.signature}')
      ..write('|baselineMedia=${baselineMediaReport.signature}')
      ..write('|promise=${promiseReport.signature}');
    for (final season in seasons) {
      buffer.write('|promiseMedia=${season.signature}');
    }
    final states = List<MediaState>.of(finalStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final state in states) {
      buffer.write('|promiseMediaFinal=${state.signature}');
    }
    return buffer.toString();
  }
}
