import '../core/simulation_config.dart';
import '../league/club.dart';
import '../world/world_league.dart';
import 'president_election.dart';
import 'president_election_career_engine.dart';
import 'president_tenure.dart';
import 'president_tenure_career_report.dart';

class PresidentTenureCareerEngine {
  const PresidentTenureCareerEngine({
    this.electionEngine = const PresidentElectionCareerEngine(),
    this.profileGenerator = const PresidentProfileGenerator(),
  });

  final PresidentElectionCareerEngine electionEngine;
  final PresidentProfileGenerator profileGenerator;

  PresidentTenureCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
  }) {
    final electionReport = electionEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
    );
    final worldReport = electionReport.reputationReport.advancedTransferReport.worldReport;
    final firstSeasonIndex =
        worldReport.seasons.isEmpty ? config.seasonIndex : worldReport.seasons.first.seasonIndex;
    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();

    final initialStates = <PresidentTenureState>[];
    for (final clubId in clubIds) {
      initialStates.add(
        PresidentTenureState.initial(
          clubId: clubId,
          president: profileGenerator.generateInitial(
            clubId: clubId,
            careerSeed: config.careerSeed,
            simulationVersion: config.simulationVersion,
          ),
          startedSeasonIndex: firstSeasonIndex,
        ),
      );
    }
    final states = {
      for (final state in initialStates) state.clubId: state,
    };
    final turnovers = <PresidentTurnoverEvent>[];
    final orderedElections = List.of(electionReport.elections)
      ..sort((a, b) {
        final seasonCompare = a.seasonIndex.compareTo(b.seasonIndex);
        return seasonCompare != 0 ? seasonCompare : a.clubId.compareTo(b.clubId);
      });

    for (final election in orderedElections) {
      final current = states[election.clubId];
      if (current == null) {
        throw StateError('Missing president tenure state for ${election.clubId}.');
      }
      if (election.outcome == PresidentElectionOutcome.reelected) {
        states[election.clubId] = current.recordReelection();
        continue;
      }

      final incoming = profileGenerator.generateChallenger(
        clubId: election.clubId,
        seasonIndex: election.seasonIndex,
        electionTermNumber: election.termNumber,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      final effectiveSeasonIndex = election.seasonIndex + 1;
      turnovers.add(
        PresidentTurnoverEvent(
          clubId: election.clubId,
          electionSeasonIndex: election.seasonIndex,
          effectiveSeasonIndex: effectiveSeasonIndex,
          electionTermNumber: election.termNumber,
          outgoing: current.president,
          incoming: incoming,
          outgoingStartedSeasonIndex: current.startedSeasonIndex,
          outgoingTenureSeasons:
              effectiveSeasonIndex - current.startedSeasonIndex,
          outgoingReelections: current.reelectionsWon,
          electionMargin: election.margin,
          challengerStrength: election.challengerStrength,
        ),
      );
      states[election.clubId] = current.handover(
        incoming: incoming,
        effectiveSeasonIndex: effectiveSeasonIndex,
      );
    }

    final finalStates = states.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return PresidentTenureCareerReport(
      electionReport: electionReport,
      initialStates: initialStates,
      turnovers: turnovers,
      finalStates: finalStates,
    );
  }
}
