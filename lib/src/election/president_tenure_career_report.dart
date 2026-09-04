import 'president_election_career_report.dart';
import 'president_tenure.dart';

class PresidentTenureCareerReport {
  PresidentTenureCareerReport({
    required this.electionReport,
    required Iterable<PresidentTenureState> initialStates,
    required Iterable<PresidentTurnoverEvent> turnovers,
    required Iterable<PresidentTenureState> finalStates,
  })  : initialStates = List.unmodifiable(initialStates),
        turnovers = List.unmodifiable(turnovers),
        finalStates = List.unmodifiable(finalStates);

  final PresidentElectionCareerReport electionReport;
  final List<PresidentTenureState> initialStates;
  final List<PresidentTurnoverEvent> turnovers;
  final List<PresidentTenureState> finalStates;

  int get seasonCount => electionReport.seasonCount;
  int get totalTurnovers => turnovers.length;
  int get recordedReelections =>
      turnovers.fold<int>(0, (sum, item) => sum + item.outgoingReelections) +
      finalStates.fold<int>(0, (sum, item) => sum + item.reelectionsWon);

  int get uniquePresidents {
    final ids = <String>{};
    for (final state in initialStates) {
      ids.add(state.president.id);
    }
    for (final turnover in turnovers) {
      ids.add(turnover.incoming.id);
    }
    return ids.length;
  }

  int get clubsWithTurnover => turnovers.map((item) => item.clubId).toSet().length;

  int get repeatedTurnoverClubs {
    final counts = <String, int>{};
    for (final turnover in turnovers) {
      counts.update(turnover.clubId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.values.where((count) => count > 1).length;
  }

  int get maximumTurnoversPerClub {
    if (turnovers.isEmpty) return 0;
    final counts = <String, int>{};
    for (final turnover in turnovers) {
      counts.update(turnover.clubId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.values.reduce((a, b) => a > b ? a : b);
  }

  double get averageOutgoingTenureSeasons => turnovers.isEmpty
      ? 0
      : turnovers.fold<int>(0, (sum, item) => sum + item.outgoingTenureSeasons) /
          turnovers.length;

  int get minimumOutgoingTenureSeasons => turnovers.isEmpty
      ? 0
      : turnovers
          .map((item) => item.outgoingTenureSeasons)
          .reduce((a, b) => a < b ? a : b);

  int get maximumOutgoingTenureSeasons => turnovers.isEmpty
      ? 0
      : turnovers
          .map((item) => item.outgoingTenureSeasons)
          .reduce((a, b) => a > b ? a : b);

  String get signature {
    final buffer = StringBuffer(electionReport.signature);
    final initial = List<PresidentTenureState>.of(initialStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final state in initial) {
      buffer.write('|presidentInitial=${state.signature}');
    }
    for (final turnover in turnovers) {
      buffer.write('|presidentTurnover=${turnover.signature}');
    }
    final finalList = List<PresidentTenureState>.of(finalStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    for (final state in finalList) {
      buffer.write('|presidentFinal=${state.signature}');
    }
    return buffer.toString();
  }
}
