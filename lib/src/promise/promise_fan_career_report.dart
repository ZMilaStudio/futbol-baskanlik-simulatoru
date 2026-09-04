import '../fan/fan_career_report.dart';
import '../fan/fan_trust_reason.dart';
import 'promise_career_report.dart';

class PromiseFanCareerReport {
  const PromiseFanCareerReport({
    required this.promiseReport,
    required this.baselineFanReport,
    required this.fanReport,
  });

  final PromiseCareerReport promiseReport;
  final FanCareerReport baselineFanReport;
  final FanCareerReport fanReport;

  int get seasonCount => promiseReport.seasonCount;

  Iterable<FanTrustReason> get promiseReasons sync* {
    for (final snapshot in fanReport.snapshots) {
      for (final reason in snapshot.reasons) {
        if (reason.code.startsWith('promise_')) yield reason;
      }
    }
  }

  int get promiseReasonCount => promiseReasons.length;

  int get promiseIdentityReasons => promiseReasons
      .where((reason) => reason.dimension == FanTrustDimension.identity)
      .length;

  int get promiseFinancialReasons => promiseReasons
      .where((reason) => reason.dimension == FanTrustDimension.financial)
      .length;

  int get positivePromiseReasons =>
      promiseReasons.where((reason) => reason.delta > 0).length;

  int get negativePromiseReasons =>
      promiseReasons.where((reason) => reason.delta < 0).length;

  double get averageFinalIdentityTrust {
    if (fanReport.finalStates.isEmpty) return 0;
    return fanReport.finalStates.fold<int>(
          0,
          (sum, state) => sum + state.identityTrust,
        ) /
        fanReport.finalStates.length;
  }

  int get minimumFinalIdentityTrust {
    if (fanReport.finalStates.isEmpty) return 0;
    return fanReport.finalStates
        .map((state) => state.identityTrust)
        .reduce((a, b) => a < b ? a : b);
  }

  int get maximumFinalIdentityTrust {
    if (fanReport.finalStates.isEmpty) return 0;
    return fanReport.finalStates
        .map((state) => state.identityTrust)
        .reduce((a, b) => a > b ? a : b);
  }

  double get averageFinalOverallTrustDelta {
    if (fanReport.finalStates.isEmpty) return 0;
    final baseline = {
      for (final state in baselineFanReport.finalStates) state.clubId: state,
    };
    var total = 0;
    for (final state in fanReport.finalStates) {
      total += state.overallTrust - baseline[state.clubId]!.overallTrust;
    }
    return total / fanReport.finalStates.length;
  }

  double get averageFinalIdentityTrustDelta {
    if (fanReport.finalStates.isEmpty) return 0;
    final baseline = {
      for (final state in baselineFanReport.finalStates) state.clubId: state,
    };
    var total = 0;
    for (final state in fanReport.finalStates) {
      total += state.identityTrust - baseline[state.clubId]!.identityTrust;
    }
    return total / fanReport.finalStates.length;
  }

  String get signature =>
      '${promiseReport.signature}|baselineFan=${baselineFanReport.signature}|'
      'promiseFan=${fanReport.signature}';
}
