import 'president_election.dart';
import 'president_election_career_validator.dart';
import 'president_tenure.dart';
import 'president_tenure_career_report.dart';

class PresidentTenureCareerValidator {
  const PresidentTenureCareerValidator();

  List<String> validate(PresidentTenureCareerReport report) {
    final issues = <String>[
      ...const PresidentElectionCareerValidator().validate(report.electionReport),
    ];
    final worldReport =
        report.electionReport.reputationReport.advancedTransferReport.worldReport;
    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();
    final firstSeasonIndex = worldReport.seasons.isEmpty
        ? 0
        : worldReport.seasons.first.seasonIndex;

    if (report.initialStates.length != clubIds.length) {
      issues.add('Initial president-state count mismatch.');
    }
    if (report.finalStates.length != clubIds.length) {
      issues.add('Final president-state count mismatch.');
    }
    if (report.totalTurnovers != report.electionReport.losses) {
      issues.add(
        'President turnover/loss mismatch: '
        '${report.totalTurnovers}/${report.electionReport.losses}.',
      );
    }
    if (report.recordedReelections != report.electionReport.reelections) {
      issues.add(
        'President reelection history mismatch: '
        '${report.recordedReelections}/${report.electionReport.reelections}.',
      );
    }

    final initialByClub = <String, PresidentTenureState>{};
    final presidentIds = <String>{};
    for (final state in report.initialStates) {
      if (initialByClub.containsKey(state.clubId)) {
        issues.add('Duplicate initial president state for ${state.clubId}.');
      }
      initialByClub[state.clubId] = state;
      if (!presidentIds.add(state.president.id)) {
        issues.add('Duplicate initial president id ${state.president.id}.');
      }
      if (state.tenureNumber != 1 ||
          state.startedSeasonIndex != firstSeasonIndex ||
          state.reelectionsWon != 0) {
        issues.add('Invalid initial president tenure for ${state.clubId}.');
      }
    }

    final turnoverByKey = <String, PresidentTurnoverEvent>{};
    for (final turnover in report.turnovers) {
      final key = '${turnover.electionSeasonIndex}|${turnover.clubId}';
      if (turnoverByKey.containsKey(key)) {
        issues.add('Duplicate president turnover $key.');
      }
      turnoverByKey[key] = turnover;
      if (!presidentIds.add(turnover.incoming.id)) {
        issues.add('Reused incoming president id ${turnover.incoming.id}.');
      }
    }

    var states = <String, PresidentTenureState>{
      for (final entry in initialByClub.entries) entry.key: entry.value,
    };
    final orderedElections = List.of(report.electionReport.elections)
      ..sort((a, b) {
        final seasonCompare = a.seasonIndex.compareTo(b.seasonIndex);
        return seasonCompare != 0 ? seasonCompare : a.clubId.compareTo(b.clubId);
      });

    for (final election in orderedElections) {
      final key = '${election.seasonIndex}|${election.clubId}';
      final current = states[election.clubId];
      if (current == null) {
        issues.add('Missing replay president state $key.');
        continue;
      }
      final turnover = turnoverByKey[key];
      if (election.outcome == PresidentElectionOutcome.reelected) {
        if (turnover != null) {
          issues.add('Reelection incorrectly created turnover $key.');
        }
        states[election.clubId] = current.recordReelection();
        continue;
      }

      if (turnover == null) {
        issues.add('Election loss missing president turnover $key.');
        continue;
      }
      final expectedEffectiveSeason = election.seasonIndex + 1;
      final expectedTenureSeasons =
          expectedEffectiveSeason - current.startedSeasonIndex;
      if (turnover.electionTermNumber != election.termNumber ||
          turnover.effectiveSeasonIndex != expectedEffectiveSeason ||
          turnover.outgoing.id != current.president.id ||
          turnover.outgoingStartedSeasonIndex != current.startedSeasonIndex ||
          turnover.outgoingTenureSeasons != expectedTenureSeasons ||
          turnover.outgoingReelections != current.reelectionsWon ||
          turnover.electionMargin != election.margin ||
          turnover.challengerStrength != election.challengerStrength ||
          turnover.incoming.id == turnover.outgoing.id) {
        issues.add('President turnover history mismatch $key.');
      }
      if (turnover.outgoingTenureSeasons <= 0) {
        issues.add('Non-positive president tenure length $key.');
      }
      states[election.clubId] = current.handover(
        incoming: turnover.incoming,
        effectiveSeasonIndex: turnover.effectiveSeasonIndex,
      );
    }

    if (turnoverByKey.length != report.turnovers.length) {
      issues.add('President turnover key coverage mismatch.');
    }
    if (report.uniquePresidents != report.initialStates.length + report.turnovers.length) {
      issues.add('President identity count mismatch.');
    }

    final finalByClub = {
      for (final state in report.finalStates) state.clubId: state,
    };
    for (final clubId in clubIds) {
      final replay = states[clubId];
      final finalState = finalByClub[clubId];
      if (replay == null || finalState == null || replay.signature != finalState.signature) {
        issues.add('Final president tenure mismatch for $clubId.');
      }
      final clubTurnovers =
          report.turnovers.where((item) => item.clubId == clubId).length;
      if (finalState != null && finalState.tenureNumber != clubTurnovers + 1) {
        issues.add('Final president tenure number mismatch for $clubId.');
      }
    }

    return issues;
  }
}
