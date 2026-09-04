import '../fan/fan_career_report.dart';
import '../fan/fan_state.dart';
import '../media/media_credibility_change.dart';
import '../media/media_state.dart';
import '../promise/promise_media_career_report.dart';
import '../promise/promise_media_credibility_change.dart';
import 'president_election.dart';
import 'president_election_snapshot.dart';
import 'president_reputation_handover.dart';
import 'president_tenure.dart';

class PresidentReputationSeasonSnapshot {
  const PresidentReputationSeasonSnapshot({
    required this.clubId,
    required this.seasonIndex,
    required this.presidentId,
    required this.fanBefore,
    required this.fanAfter,
    required this.mediaBefore,
    required this.mediaAfterStatement,
    required this.mediaAfterPromise,
    required this.statementChange,
    required this.promiseChange,
  });

  final String clubId;
  final int seasonIndex;
  final String presidentId;
  final FanState fanBefore;
  final FanState fanAfter;
  final int mediaBefore;
  final int mediaAfterStatement;
  final int mediaAfterPromise;
  final MediaCredibilityChange? statementChange;
  final PromiseMediaCredibilityChange promiseChange;

  String get signature =>
      '$clubId:s$seasonIndex:$presidentId:'
      'fan=${fanBefore.signature}>${fanAfter.signature}:'
      'media=$mediaBefore>$mediaAfterStatement>$mediaAfterPromise:'
      'stmt=${statementChange?.signature ?? 'none'}:'
      'promise=${promiseChange.signature}';
}

class PresidentReputationCareerSeason {
  PresidentReputationCareerSeason({
    required this.seasonIndex,
    required Iterable<PresidentReputationSeasonSnapshot> clubs,
  }) : clubs = List.unmodifiable(clubs);

  final int seasonIndex;
  final List<PresidentReputationSeasonSnapshot> clubs;

  String get signature {
    final sorted = List<PresidentReputationSeasonSnapshot>.of(clubs)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return '$seasonIndex:${sorted.map((item) => item.signature).join('|')}';
  }
}

class PresidentReputationCareerReport {
  PresidentReputationCareerReport({
    required this.sourceReport,
    required this.fanTemplateReport,
    required this.careerSeed,
    required this.simulationVersion,
    required this.electionInterval,
    required Iterable<PresidentTenureState> initialTenureStates,
    required Iterable<PresidentReputationCareerSeason> seasons,
    required Iterable<PresidentElectionSnapshot> elections,
    required Iterable<PresidentTurnoverEvent> turnovers,
    required Iterable<PresidentReputationHandoverEvent> handovers,
    required Iterable<PresidentTenureState> finalTenureStates,
    required Iterable<FanState> finalFanStates,
    required Iterable<MediaState> finalMediaStates,
  })  : initialTenureStates = List.unmodifiable(initialTenureStates),
        seasons = List.unmodifiable(seasons),
        elections = List.unmodifiable(elections),
        turnovers = List.unmodifiable(turnovers),
        handovers = List.unmodifiable(handovers),
        finalTenureStates = List.unmodifiable(finalTenureStates),
        finalFanStates = List.unmodifiable(finalFanStates),
        finalMediaStates = List.unmodifiable(finalMediaStates);

  final PromiseMediaCareerReport sourceReport;
  final FanCareerReport fanTemplateReport;
  final int careerSeed;
  final int simulationVersion;
  final int electionInterval;
  final List<PresidentTenureState> initialTenureStates;
  final List<PresidentReputationCareerSeason> seasons;
  final List<PresidentElectionSnapshot> elections;
  final List<PresidentTurnoverEvent> turnovers;
  final List<PresidentReputationHandoverEvent> handovers;
  final List<PresidentTenureState> finalTenureStates;
  final List<FanState> finalFanStates;
  final List<MediaState> finalMediaStates;

  int get seasonCount => seasons.length;
  int get totalElections => elections.length;
  int get reelections => elections
      .where((item) => item.outcome == PresidentElectionOutcome.reelected)
      .length;
  int get losses => totalElections - reelections;
  int get totalTurnovers => turnovers.length;
  double get reelectionRate =>
      totalElections == 0 ? 0 : reelections / totalElections;

  int get uniquePresidents {
    final ids = <String>{
      for (final state in initialTenureStates) state.president.id,
      for (final turnover in turnovers) turnover.incoming.id,
    };
    return ids.length;
  }

  double get averageFinalMediaCredibility => finalMediaStates.isEmpty
      ? 0
      : finalMediaStates.fold<int>(0, (sum, item) => sum + item.credibility) /
          finalMediaStates.length;

  int get minimumFinalMediaCredibility => finalMediaStates.isEmpty
      ? 0
      : finalMediaStates
          .map((item) => item.credibility)
          .reduce((a, b) => a < b ? a : b);

  int get maximumFinalMediaCredibility => finalMediaStates.isEmpty
      ? 0
      : finalMediaStates
          .map((item) => item.credibility)
          .reduce((a, b) => a > b ? a : b);

  double get averageFinalIdentityTrust => finalFanStates.isEmpty
      ? 0
      : finalFanStates.fold<int>(0, (sum, item) => sum + item.identityTrust) /
          finalFanStates.length;

  int get minimumFinalIdentityTrust => finalFanStates.isEmpty
      ? 0
      : finalFanStates
          .map((item) => item.identityTrust)
          .reduce((a, b) => a < b ? a : b);

  int get maximumFinalIdentityTrust => finalFanStates.isEmpty
      ? 0
      : finalFanStates
          .map((item) => item.identityTrust)
          .reduce((a, b) => a > b ? a : b);

  double get averageHandoverMediaDelta => handovers.isEmpty
      ? 0
      : handovers.fold<int>(0, (sum, item) => sum + item.mediaDelta) /
          handovers.length;

  double get averageHandoverIdentityDelta => handovers.isEmpty
      ? 0
      : handovers.fold<int>(0, (sum, item) => sum + item.identityDelta) /
          handovers.length;

  String get signature {
    final buffer = StringBuffer(sourceReport.signature)
      ..write('|fanTemplate=${fanTemplateReport.signature}')
      ..write('|seed=$careerSeed:sim=$simulationVersion:interval=$electionInterval');
    for (final state in initialTenureStates) {
      buffer.write('|repInitial=${state.signature}');
    }
    for (final season in seasons) {
      buffer.write('|repSeason=${season.signature}');
    }
    for (final election in elections) {
      buffer.write('|repElection=${election.signature}');
    }
    for (final turnover in turnovers) {
      buffer.write('|repTurnover=${turnover.signature}');
    }
    for (final handover in handovers) {
      buffer.write('|repHandover=${handover.signature}');
    }
    for (final state in finalTenureStates) {
      buffer.write('|repFinalTenure=${state.signature}');
    }
    for (final state in finalFanStates) {
      buffer.write('|repFinalFan=${state.signature}');
    }
    for (final state in finalMediaStates) {
      buffer.write('|repFinalMedia=${state.signature}');
    }
    return buffer.toString();
  }
}
