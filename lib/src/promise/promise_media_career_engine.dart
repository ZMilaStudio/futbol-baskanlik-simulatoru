import '../core/simulation_config.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_career_report.dart';
import '../media/media_career_engine.dart';
import '../media/media_credibility_engine.dart';
import '../media/media_state.dart';
import '../transfer/advanced_transfer_career_report.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../world/world_league.dart';
import 'promise_career_engine.dart';
import 'promise_media_career_report.dart';
import 'promise_media_impact_engine.dart';
import 'promise_media_season_snapshot.dart';

class PromiseMediaCareerEngine {
  const PromiseMediaCareerEngine({
    this.advancedEngine = const AdvancedTransferWorldCareerEngine(),
    this.mediaEngine = const MediaCareerEngine(),
    this.mediaCredibilityEngine = const MediaCredibilityEngine(),
    this.promiseEngine = const PromiseCareerEngine(),
    this.promiseImpactEngine = const PromiseMediaImpactEngine(),
  });

  final AdvancedTransferWorldCareerEngine advancedEngine;
  final MediaCareerEngine mediaEngine;
  final MediaCredibilityEngine mediaCredibilityEngine;
  final PromiseCareerEngine promiseEngine;
  final PromiseMediaImpactEngine promiseImpactEngine;

  PromiseMediaCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    final managerController = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
    );
    final advancedReport = advancedEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: managerController,
    );
    final managerReport = ManagerCareerReport(
      worldReport: advancedReport.worldReport,
      managers: managerController.managers,
      seasons: managerController.seasons,
      finalAssignments: managerController.finalAssignments,
    );
    return simulateFromAdvancedReport(
      advancedReport: advancedReport,
      managerReport: managerReport,
      config: config,
    );
  }

  PromiseMediaCareerReport simulateFromAdvancedReport({
    required AdvancedTransferCareerReport advancedReport,
    required ManagerCareerReport managerReport,
    required SimulationConfig config,
  }) {
    if (managerReport.worldReport.signature != advancedReport.worldReport.signature) {
      throw ArgumentError('Manager report must belong to the supplied advanced world.');
    }

    final baselineMediaReport = mediaEngine.fromManagerReport(
      managerReport: managerReport,
      config: config,
    );
    final promiseReport = promiseEngine.simulateFromAdvancedReport(
      advancedReport: advancedReport,
      config: config,
    );

    final clubIds = managerReport.seasons.isEmpty
        ? <String>[]
        : managerReport.seasons.first.clubs.map((club) => club.clubId).toList();
    final states = {
      for (final clubId in clubIds)
        clubId: MediaState(clubId: clubId, credibility: 65),
    };
    final promisesByKey = {
      for (final snapshot in promiseReport.snapshots)
        '${snapshot.promise.seasonIndex}|${snapshot.promise.clubId}':
            snapshot.resolution,
    };
    final seasons = <PromiseMediaCareerSeason>[];

    for (final mediaSeason in baselineMediaReport.seasons) {
      final snapshots = <PromiseMediaSeasonSnapshot>[];
      for (final baseline in mediaSeason.clubs) {
        final current = states[baseline.clubId];
        if (current == null) {
          throw StateError('Missing combined media state for ${baseline.clubId}.');
        }

        final statementChange = baseline.statement == null
            ? null
            : mediaCredibilityEngine.evaluate(
                state: current,
                statement: baseline.statement!,
                managerChanged: baseline.managerChanged,
              );
        final afterStatement = statementChange?.after ?? current.credibility;
        final resolution = promisesByKey[
          '${mediaSeason.seasonIndex}|${baseline.clubId}'
        ];
        if (resolution == null) {
          throw StateError(
            'Missing promise resolution for ${baseline.clubId} '
            'season ${mediaSeason.seasonIndex}.',
          );
        }
        final promiseChange = promiseImpactEngine.evaluate(
          state: MediaState(
            clubId: baseline.clubId,
            credibility: afterStatement,
          ),
          resolution: resolution,
        );
        states[baseline.clubId] = current.copyWith(
          credibility: promiseChange.after,
        );
        snapshots.add(PromiseMediaSeasonSnapshot(
          clubId: baseline.clubId,
          seasonIndex: mediaSeason.seasonIndex,
          credibilityBefore: current.credibility,
          credibilityAfterStatement: afterStatement,
          credibilityAfterPromise: promiseChange.after,
          statementChange: statementChange,
          promiseChange: promiseChange,
        ));
      }
      seasons.add(PromiseMediaCareerSeason(
        seasonIndex: mediaSeason.seasonIndex,
        clubs: snapshots,
      ));
    }

    final finalStates = states.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return PromiseMediaCareerReport(
      advancedTransferReport: advancedReport,
      managerReport: managerReport,
      baselineMediaReport: baselineMediaReport,
      promiseReport: promiseReport,
      seasons: seasons,
      finalStates: finalStates,
    );
  }
}
