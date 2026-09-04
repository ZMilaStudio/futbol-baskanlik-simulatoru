import '../core/simulation_config.dart';
import '../league/club.dart';
import '../world/world_league.dart';
import 'president_management_career_report.dart';
import 'president_management_profile.dart';
import 'president_reputation_career_engine.dart';
import 'president_tenure.dart';

class PresidentManagementCareerEngine {
  const PresidentManagementCareerEngine({
    this.sourceEngine = const PresidentReputationCareerEngine(),
    this.profileGenerator = const PresidentManagementProfileGenerator(),
  });

  final PresidentReputationCareerEngine sourceEngine;
  final PresidentManagementProfileGenerator profileGenerator;

  PresidentManagementCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
  }) {
    final sourceReport = sourceEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
    );

    final presidents = <String, PresidentProfile>{};
    for (final state in sourceReport.initialTenureStates) {
      presidents[state.president.id] = state.president;
    }
    for (final turnover in sourceReport.turnovers) {
      presidents[turnover.outgoing.id] = turnover.outgoing;
      presidents[turnover.incoming.id] = turnover.incoming;
    }

    final profileByPresident = <String, PresidentManagementProfile>{};
    for (final president in presidents.values) {
      profileByPresident[president.id] = profileGenerator.generate(
        president: president,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
    }

    final profiles = profileByPresident.values.toList()
      ..sort((a, b) => a.presidentId.compareTo(b.presidentId));
    final comparisons = <PresidentManagementTurnoverComparison>[];
    for (final turnover in sourceReport.turnovers) {
      final outgoing = profileByPresident[turnover.outgoing.id];
      final incoming = profileByPresident[turnover.incoming.id];
      if (outgoing == null || incoming == null) {
        throw StateError('Missing M17 management profile for ${turnover.clubId}.');
      }
      comparisons.add(
        PresidentManagementTurnoverComparison(
          clubId: turnover.clubId,
          electionSeasonIndex: turnover.electionSeasonIndex,
          outgoing: outgoing,
          incoming: incoming,
        ),
      );
    }

    return PresidentManagementCareerReport(
      sourceReport: sourceReport,
      profiles: profiles,
      turnoverComparisons: comparisons,
    );
  }
}
