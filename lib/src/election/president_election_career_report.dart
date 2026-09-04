import '../fan/fan_career_report.dart';
import '../promise/promise_media_career_report.dart';
import 'president_approval_state.dart';
import 'president_election.dart';
import 'president_election_snapshot.dart';

class PresidentElectionCareerReport {
  PresidentElectionCareerReport({
    required this.reputationReport,
    required this.fanReport,
    required this.electionInterval,
    required Iterable<PresidentElectionSnapshot> elections,
    required Iterable<PresidentApprovalState> finalStates,
  })  : elections = List.unmodifiable(elections),
        finalStates = List.unmodifiable(finalStates);

  final PromiseMediaCareerReport reputationReport;
  final FanCareerReport fanReport;
  final int electionInterval;
  final List<PresidentElectionSnapshot> elections;
  final List<PresidentApprovalState> finalStates;

  int get seasonCount => reputationReport.seasonCount;
  int get totalElections => elections.length;
  int get reelections => elections
      .where((election) => election.outcome == PresidentElectionOutcome.reelected)
      .length;
  int get losses => totalElections - reelections;

  double get reelectionRate =>
      totalElections == 0 ? 0 : reelections / totalElections;

  double get averageApproval => totalElections == 0
      ? 0
      : elections.fold<int>(0, (sum, item) => sum + item.approval) /
          totalElections;

  double get averageChallengerStrength => totalElections == 0
      ? 0
      : elections.fold<int>(0, (sum, item) => sum + item.challengerStrength) /
          totalElections;

  int get minimumApproval => totalElections == 0
      ? 0
      : elections.map((item) => item.approval).reduce((a, b) => a < b ? a : b);

  int get maximumApproval => totalElections == 0
      ? 0
      : elections.map((item) => item.approval).reduce((a, b) => a > b ? a : b);

  int get competitiveElections =>
      elections.where((item) => item.margin.abs() <= 5).length;

  int get landslideReelections => elections
      .where((item) =>
          item.outcome == PresidentElectionOutcome.reelected && item.margin >= 10)
      .length;

  int get landslideLosses => elections
      .where((item) =>
          item.outcome == PresidentElectionOutcome.lost && item.margin <= -10)
      .length;

  int get boundaryApprovals =>
      elections.where((item) => item.approval <= 5 || item.approval >= 95).length;

  String get signature {
    final buffer = StringBuffer()
      ..write(reputationReport.signature)
      ..write('|electionFan=${fanReport.signature}')
      ..write('|electionInterval=$electionInterval');
    for (final election in elections) {
      buffer.write('|election=${election.signature}');
    }
    final states = List<PresidentApprovalState>.of(finalStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final state in states) {
      buffer.write('|electionFinal=${state.signature}');
    }
    return buffer.toString();
  }
}
