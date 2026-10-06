import '../core/simulation_config.dart';
import '../league/club.dart';
import '../manager/manager_career_report.dart';
import '../manager/manager_career_season.dart';
import '../manager/manager_world_career_engine.dart';
import '../world/world_league.dart';
import 'media_career_report.dart';
import 'media_credibility_engine.dart';
import 'media_season_snapshot.dart';
import 'media_state.dart';
import 'media_statement_engine.dart';

class MediaCareerEngine {
  const MediaCareerEngine({
    this.managerEngine = const ManagerWorldCareerEngine(),
    this.statementEngine = const MediaStatementEngine(),
    this.credibilityEngine = const MediaCredibilityEngine(),
  });

  final ManagerWorldCareerEngine managerEngine;
  final MediaStatementEngine statementEngine;
  final MediaCredibilityEngine credibilityEngine;

  MediaSeasonSnapshot projectClubSeason({
    required MediaState priorState,
    required ManagerClubSeason clubSeason,
    required int seasonIndex,
    required bool managerChanged,
    required SimulationConfig config,
  }) {
    if (priorState.clubId != clubSeason.clubId) {
      throw StateError('Manager/media club lineage mismatch.');
    }
    final statement = statementEngine.generate(
      clubSeason: clubSeason,
      seasonIndex: seasonIndex,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final change = statement == null
        ? null
        : credibilityEngine.evaluate(
            state: priorState,
            statement: statement,
            managerChanged: managerChanged,
          );
    return MediaSeasonSnapshot(
      clubId: clubSeason.clubId,
      managerId: clubSeason.managerId,
      seasonIndex: seasonIndex,
      managerChanged: managerChanged,
      credibilityBefore: priorState.credibility,
      credibilityAfter: change?.after ?? priorState.credibility,
      statement: statement,
      change: change,
    );
  }

  MediaCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    final managerReport = managerEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
    );
    return fromManagerReport(
      managerReport: managerReport,
      config: config,
    );
  }

  MediaCareerReport fromManagerReport({
    required ManagerCareerReport managerReport,
    required SimulationConfig config,
  }) {
    final clubIds = managerReport.seasons.isEmpty
        ? <String>[]
        : managerReport.seasons.first.clubs.map((club) => club.clubId).toList();
    var states = {
      for (final clubId in clubIds)
        clubId: MediaState(clubId: clubId, credibility: 65),
    };
    final seasons = <MediaCareerSeason>[];

    for (final managerSeason in managerReport.seasons) {
      final changesByClub = {
        for (final change in managerSeason.changesAfterSeason)
          change.clubId: change,
      };
      final snapshots = <MediaSeasonSnapshot>[];

      for (final clubSeason in managerSeason.clubs) {
        final current = states[clubSeason.clubId];
        if (current == null) {
          throw StateError('Missing media state for ${clubSeason.clubId}.');
        }
        final snapshot = projectClubSeason(
          priorState: current,
          clubSeason: clubSeason,
          seasonIndex: managerSeason.seasonIndex,
          managerChanged: changesByClub.containsKey(clubSeason.clubId),
          config: config,
        );
        if (snapshot.change != null) {
          states[clubSeason.clubId] = current.copyWith(
            credibility: snapshot.credibilityAfter,
          );
        }
        snapshots.add(snapshot);
      }

      seasons.add(
        MediaCareerSeason(
          seasonIndex: managerSeason.seasonIndex,
          clubs: snapshots,
        ),
      );
    }

    final finalStates = states.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return MediaCareerReport(
      managerReport: managerReport,
      seasons: seasons,
      finalStates: finalStates,
    );
  }
}
