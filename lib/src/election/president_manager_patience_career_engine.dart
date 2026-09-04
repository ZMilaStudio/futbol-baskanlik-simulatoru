import '../core/simulation_config.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_career_report.dart';
import '../manager/manager_patience_policy.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../world/world_league.dart';
import 'president_management_career_engine.dart';
import 'president_manager_patience_career_report.dart';
import 'president_manager_patience_timeline.dart';

class PresidentManagerPatienceCareerEngine {
  const PresidentManagerPatienceCareerEngine({
    this.sourceEngine = const PresidentManagementCareerEngine(),
    this.advancedEngine = const AdvancedTransferWorldCareerEngine(),
    this.dismissalPolicy = const ManagerDismissalPolicy(),
  });

  final PresidentManagementCareerEngine sourceEngine;
  final AdvancedTransferWorldCareerEngine advancedEngine;
  final ManagerDismissalPolicy dismissalPolicy;

  PresidentManagerPatienceCareerReport simulate({
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
    final timeline = PresidentManagerPatienceTimeline.fromReport(sourceReport);

    final managerController = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      patienceProvider: timeline.patienceFor,
      dismissalPolicy: dismissalPolicy,
    );
    final influencedAdvancedReport = advancedEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: managerController,
    );
    final influencedManagerReport = ManagerCareerReport(
      worldReport: influencedAdvancedReport.worldReport,
      managers: managerController.managers,
      seasons: managerController.seasons,
      finalAssignments: managerController.finalAssignments,
    );

    final baselineManagerReport =
        sourceReport.sourceReport.sourceReport.managerReport;
    final baselineByKey = {
      for (final season in baselineManagerReport.seasons)
        for (final club in season.clubs)
          '${season.seasonIndex}|${club.clubId}': club,
    };
    final reasonByKey = {
      for (final season in influencedManagerReport.seasons)
        for (final change in season.changesAfterSeason)
          '${season.seasonIndex}|${change.clubId}': change.reason,
    };

    final decisions = <PresidentManagerPatienceDecisionSnapshot>[];
    for (final season in influencedManagerReport.seasons) {
      for (final club in season.clubs) {
        final key = '${season.seasonIndex}|${club.clubId}';
        final baseline = baselineByKey[key];
        if (baseline == null) {
          throw StateError('Missing M18 baseline manager season for $key.');
        }
        final president = timeline.resolve(club.clubId, season.seasonIndex);
        decisions.add(
          PresidentManagerPatienceDecisionSnapshot(
            clubId: club.clubId,
            seasonIndex: season.seasonIndex,
            presidentId: president.presidentId,
            archetype: president.archetype,
            managerPatience: president.managerPatience,
            thresholds: dismissalPolicy.thresholds(president.managerPatience),
            managerId: club.managerId,
            baselineManagerId: baseline.managerId,
            expectedPosition: club.expectedPosition,
            actualPosition: club.actualPosition,
            relationshipAfter: club.relationshipAfter,
            changedAfterSeason: club.changedAfterSeason,
            baselineChangedAfterSeason: baseline.changedAfterSeason,
            changeReason: reasonByKey[key],
          ),
        );
      }
    }

    return PresidentManagerPatienceCareerReport(
      sourceReport: sourceReport,
      influencedAdvancedReport: influencedAdvancedReport,
      influencedManagerReport: influencedManagerReport,
      decisions: decisions,
    );
  }
}
