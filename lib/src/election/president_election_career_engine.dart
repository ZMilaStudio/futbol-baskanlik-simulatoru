import '../core/simulation_config.dart';
import '../fan/fan_career_engine.dart';
import '../league/club.dart';
import '../promise/promise_fan_impact_engine.dart';
import '../promise/promise_media_career_engine.dart';
import '../promise/promise_season_snapshot.dart';
import '../world/world_league.dart';
import 'president_approval_state.dart';
import 'president_election_career_report.dart';
import 'president_election_engine.dart';
import 'president_election_snapshot.dart';

class PresidentElectionCareerEngine {
  const PresidentElectionCareerEngine({
    this.reputationEngine = const PromiseMediaCareerEngine(),
    this.fanEngine = const FanCareerEngine(),
    this.fanImpactEngine = const PromiseFanImpactEngine(),
    this.electionEngine = const PresidentElectionEngine(),
  });

  final PromiseMediaCareerEngine reputationEngine;
  final FanCareerEngine fanEngine;
  final PromiseFanImpactEngine fanImpactEngine;
  final PresidentElectionEngine electionEngine;

  PresidentElectionCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
  }) {
    if (electionInterval <= 0) {
      throw ArgumentError.value(
        electionInterval,
        'electionInterval',
        'must be greater than zero',
      );
    }

    final reputationReport = reputationEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
    );
    final promiseByKey = {
      for (final snapshot in reputationReport.promiseReport.snapshots)
        '${snapshot.promise.seasonIndex}|${snapshot.promise.clubId}': snapshot,
    };
    final fanReport = fanEngine.simulateFromAdvancedReport(
      advancedReport: reputationReport.advancedTransferReport,
      extraReasonProvider: (context) {
        final key = '${context.seasonIndex}|${context.clubId}';
        final promiseSnapshot = promiseByKey[key];
        if (promiseSnapshot == null) {
          throw StateError('Missing election promise resolution for $key.');
        }
        return fanImpactEngine.evaluate(promiseSnapshot.resolution);
      },
    );

    final fanByKey = {
      for (final snapshot in fanReport.snapshots)
        '${snapshot.context.seasonIndex}|${snapshot.context.clubId}': snapshot,
    };
    final mediaByKey = {
      for (final snapshot in reputationReport.snapshots)
        '${snapshot.seasonIndex}|${snapshot.clubId}': snapshot,
    };
    final promisesByClub = <String, List<PromiseSeasonSnapshot>>{};
    for (final snapshot in reputationReport.promiseReport.snapshots) {
      promisesByClub.putIfAbsent(snapshot.promise.clubId, () => []).add(snapshot);
    }

    final worldSeasons = reputationReport.advancedTransferReport.worldReport.seasons;
    final clubIds = reputationReport
        .advancedTransferReport.worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();
    final states = {
      for (final clubId in clubIds) clubId: PresidentApprovalState.initial(clubId),
    };
    final elections = <PresidentElectionSnapshot>[];

    for (var offset = electionInterval - 1;
        offset < worldSeasons.length;
        offset += electionInterval) {
      final seasonIndex = worldSeasons[offset].seasonIndex;
      final termStartSeasonIndex =
          worldSeasons[offset - electionInterval + 1].seasonIndex;
      final termNumber = (offset + 1) ~/ electionInterval;

      for (final clubId in clubIds) {
        final key = '$seasonIndex|$clubId';
        final fanSnapshot = fanByKey[key];
        final mediaSnapshot = mediaByKey[key];
        if (fanSnapshot == null || mediaSnapshot == null) {
          throw StateError('Missing election reputation context for $key.');
        }
        final termPromises = (promisesByClub[clubId] ?? const <PromiseSeasonSnapshot>[])
            .where((snapshot) =>
                snapshot.promise.seasonIndex >= termStartSeasonIndex &&
                snapshot.promise.seasonIndex <= seasonIndex)
            .toList();
        if (termPromises.length != electionInterval) {
          throw StateError(
            'Expected $electionInterval term promises for $clubId '
            'at season $seasonIndex, found ${termPromises.length}.',
          );
        }
        final promiseScore = (termPromises.fold<int>(
                  0,
                  (sum, snapshot) => sum + snapshot.resolution.score,
                ) /
                termPromises.length)
            .round();
        final election = electionEngine.evaluate(
          clubId: clubId,
          seasonIndex: seasonIndex,
          termNumber: termNumber,
          fanOverallTrust: fanSnapshot.state.overallTrust,
          fanIdentityTrust: fanSnapshot.state.identityTrust,
          mediaCredibility: mediaSnapshot.credibilityAfterPromise,
          promiseScore: promiseScore,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        elections.add(election);
        states[clubId] = states[clubId]!.record(
          nextApproval: election.approval,
          outcome: election.outcome,
        );
      }
    }

    final finalStates = states.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return PresidentElectionCareerReport(
      reputationReport: reputationReport,
      fanReport: fanReport,
      electionInterval: electionInterval,
      elections: elections,
      finalStates: finalStates,
    );
  }
}
