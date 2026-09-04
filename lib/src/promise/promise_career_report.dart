import '../transfer/advanced_transfer_career_report.dart';
import 'president_promise.dart';
import 'promise_resolution.dart';
import 'promise_season_snapshot.dart';

class PromiseCareerReport {
  PromiseCareerReport({
    required this.advancedTransferReport,
    required Iterable<PromiseSeasonSnapshot> snapshots,
  }) : snapshots = List.unmodifiable(snapshots);

  final AdvancedTransferCareerReport advancedTransferReport;
  final List<PromiseSeasonSnapshot> snapshots;

  int get seasonCount => advancedTransferReport.worldReport.seasonCount;
  int get totalPromises => snapshots.length;

  int countStatus(PromiseStatus status) =>
      snapshots.where((item) => item.resolution.status == status).length;

  int get fulfilledPromises => countStatus(PromiseStatus.fulfilled);
  int get partialPromises => countStatus(PromiseStatus.partial);
  int get brokenPromises => countStatus(PromiseStatus.broken);

  double get averageScore {
    if (snapshots.isEmpty) return 0;
    return snapshots.fold<int>(
          0,
          (sum, item) => sum + item.resolution.score,
        ) /
        snapshots.length;
  }

  Map<PresidentPromiseType, int> get typeDistribution {
    final counts = <PresidentPromiseType, int>{};
    for (final snapshot in snapshots) {
      counts.update(
        snapshot.promise.type,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  Map<PromiseStatus, int> get statusDistribution => {
        for (final status in PromiseStatus.values) status: countStatus(status),
      };

  int get financialPromises => snapshots.where((item) {
        final type = item.promise.type;
        return type == PresidentPromiseType.reduceDebt ||
            type == PresidentPromiseType.stabilizeFinances;
      }).length;

  int get sportingPromises => totalPromises - financialPromises;

  String get signature {
    final buffer = StringBuffer(advancedTransferReport.signature);
    for (final snapshot in snapshots) {
      buffer.write('|promise=${snapshot.signature}');
    }
    return buffer.toString();
  }
}
