import '../transfer/advanced_transfer_career_report.dart';
import 'fan_expectation.dart';
import 'fan_season_snapshot.dart';
import 'fan_state.dart';

class FanCareerReport {
  FanCareerReport({
    required this.advancedTransferReport,
    required Iterable<FanSeasonSnapshot> snapshots,
    required Iterable<FanState> finalStates,
  })  : snapshots = List.unmodifiable(snapshots),
        finalStates = List.unmodifiable(finalStates);

  final AdvancedTransferCareerReport advancedTransferReport;
  final List<FanSeasonSnapshot> snapshots;
  final List<FanState> finalStates;

  double get averageFinalTrust {
    if (finalStates.isEmpty) return 0;
    return finalStates.fold<int>(
          0,
          (sum, state) => sum + state.overallTrust,
        ) /
        finalStates.length;
  }

  int get minFinalTrust => finalStates.isEmpty
      ? 0
      : finalStates
          .map((state) => state.overallTrust)
          .reduce((a, b) => a < b ? a : b);

  int get maxFinalTrust => finalStates.isEmpty
      ? 0
      : finalStates
          .map((state) => state.overallTrust)
          .reduce((a, b) => a > b ? a : b);

  int get boundaryFinalStates => finalStates
      .where((state) => state.overallTrust <= 5 || state.overallTrust >= 95)
      .length;

  int get reasonCount => snapshots.fold(
        0,
        (sum, snapshot) => sum + snapshot.reasons.length,
      );

  int get smartLoanExpectations => snapshots
      .where((snapshot) =>
          snapshot.expectation.type == FanExpectationType.smartLoanReinforcement)
      .length;

  int get financialDisciplineExpectations => snapshots
      .where((snapshot) =>
          snapshot.expectation.type == FanExpectationType.financialDiscipline)
      .length;

  Map<FanExpectationType, int> get expectationCounts {
    final counts = <FanExpectationType, int>{};
    for (final snapshot in snapshots) {
      counts.update(
        snapshot.expectation.type,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  String get signature {
    final buffer = StringBuffer(advancedTransferReport.signature);
    for (final snapshot in snapshots) {
      buffer.write('|fan=${snapshot.signature}');
    }
    return buffer.toString();
  }
}
