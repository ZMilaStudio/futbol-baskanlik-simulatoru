import '../core/simulation_config.dart';
import '../fan/fan_career_engine.dart';
import '../fan/fan_state.dart';
import '../league/club.dart';
import '../media/media_credibility_engine.dart';
import '../media/media_season_snapshot.dart';
import '../media/media_state.dart';
import '../promise/promise_fan_impact_engine.dart';
import '../promise/promise_media_career_engine.dart';
import '../promise/promise_media_career_report.dart';
import '../promise/promise_media_impact_engine.dart';
import '../world/world_league.dart';
import 'president_election.dart';
import 'president_election_engine.dart';
import 'president_election_snapshot.dart';
import 'president_reputation_career_report.dart';
import 'president_reputation_handover.dart';
import 'president_tenure.dart';

class PresidentReputationCareerEngine {
  const PresidentReputationCareerEngine({
    this.sourceEngine = const PromiseMediaCareerEngine(),
    this.fanEngine = const FanCareerEngine(),
    this.fanImpactEngine = const PromiseFanImpactEngine(),
    this.mediaCredibilityEngine = const MediaCredibilityEngine(),
    this.promiseMediaImpactEngine = const PromiseMediaImpactEngine(),
    this.electionEngine = const PresidentElectionEngine(),
    this.profileGenerator = const PresidentProfileGenerator(),
    this.handoverPolicy = const PresidentReputationHandoverPolicy(),
  });

  final PromiseMediaCareerEngine sourceEngine;
  final FanCareerEngine fanEngine;
  final PromiseFanImpactEngine fanImpactEngine;
  final MediaCredibilityEngine mediaCredibilityEngine;
  final PromiseMediaImpactEngine promiseMediaImpactEngine;
  final PresidentElectionEngine electionEngine;
  final PresidentProfileGenerator profileGenerator;
  final PresidentReputationHandoverPolicy handoverPolicy;

  PresidentReputationCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    final sourceReport = sourceEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
    );
    return simulateFromSourceReport(
      sourceReport: sourceReport,
      config: config,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
  }

  PresidentReputationCareerReport simulateFromSourceReport({
    required PromiseMediaCareerReport sourceReport,
    required SimulationConfig config,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    final worldReport = sourceReport.advancedTransferReport.worldReport;
    final worldSeasons = worldReport.seasons;
    final firstSeasonIndex =
        worldSeasons.isEmpty ? config.seasonIndex : worldSeasons.first.seasonIndex;
    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();
    final tenure = <PresidentTenureState>[
      for (final clubId in clubIds)
        PresidentTenureState.initial(
          clubId: clubId,
          president: profileGenerator.generateInitial(
            clubId: clubId,
            careerSeed: config.careerSeed,
            simulationVersion: config.simulationVersion,
          ),
          startedSeasonIndex: firstSeasonIndex,
        ),
    ];
    return _run(
      sourceReport: sourceReport,
      config: config,
      electionInterval: electionInterval,
      completedElectionTerms: 0,
      seasonsIntoCurrentTerm: 0,
      initialTenureStates: tenure,
      initialFanStates: [for (final clubId in clubIds) FanState.initial(clubId)],
      initialMediaStates: [
        for (final clubId in clubIds)
          MediaState(clubId: clubId, credibility: 65),
      ],
      priorTermPromiseScores: const {},
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
  }

  PresidentReputationCareerReport resumeFromSourceReport({
    required PromiseMediaCareerReport sourceReport,
    required SimulationConfig config,
    required int electionInterval,
    required int completedElectionTerms,
    required int seasonsIntoCurrentTerm,
    required Iterable<PresidentTenureState> initialTenureStates,
    required Iterable<FanState> initialFanStates,
    required Iterable<MediaState> initialMediaStates,
    required Map<String, List<int>> priorTermPromiseScores,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (completedElectionTerms < 0) {
      throw ArgumentError.value(completedElectionTerms, 'completedElectionTerms');
    }
    if (seasonsIntoCurrentTerm < 0 ||
        seasonsIntoCurrentTerm >= electionInterval) {
      throw ArgumentError.value(
        seasonsIntoCurrentTerm,
        'seasonsIntoCurrentTerm',
      );
    }
    return _run(
      sourceReport: sourceReport,
      config: config,
      electionInterval: electionInterval,
      completedElectionTerms: completedElectionTerms,
      seasonsIntoCurrentTerm: seasonsIntoCurrentTerm,
      initialTenureStates: initialTenureStates,
      initialFanStates: initialFanStates,
      initialMediaStates: initialMediaStates,
      priorTermPromiseScores: priorTermPromiseScores,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
  }

  PresidentReputationCareerReport _run({
    required PromiseMediaCareerReport sourceReport,
    required SimulationConfig config,
    required int electionInterval,
    required int completedElectionTerms,
    required int seasonsIntoCurrentTerm,
    required Iterable<PresidentTenureState> initialTenureStates,
    required Iterable<FanState> initialFanStates,
    required Iterable<MediaState> initialMediaStates,
    required Map<String, List<int>> priorTermPromiseScores,
    required bool hasFutureSeasonAfterReport,
  }) {
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }

    final promiseByKey = {
      for (final snapshot in sourceReport.promiseReport.snapshots)
        '${snapshot.promise.seasonIndex}|${snapshot.promise.clubId}': snapshot,
    };
    final fanTemplateReport = fanEngine.simulateFromAdvancedReport(
      advancedReport: sourceReport.advancedTransferReport,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      extraReasonProvider: (context) {
        final item = promiseByKey['${context.seasonIndex}|${context.clubId}'];
        if (item == null) {
          throw StateError('Missing president reputation promise fan source.');
        }
        return fanImpactEngine.evaluate(item.resolution);
      },
    );
    final fanTemplateByKey = {
      for (final snapshot in fanTemplateReport.snapshots)
        '${snapshot.context.seasonIndex}|${snapshot.context.clubId}': snapshot,
    };
    final mediaTemplateByKey = <String, MediaSeasonSnapshot>{};
    for (final season in sourceReport.baselineMediaReport.seasons) {
      for (final snapshot in season.clubs) {
        mediaTemplateByKey['${season.seasonIndex}|${snapshot.clubId}'] = snapshot;
      }
    }

    final worldReport = sourceReport.advancedTransferReport.worldReport;
    final worldSeasons = worldReport.seasons;
    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();

    final initialTenure = List<PresidentTenureState>.of(initialTenureStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final initialFan = List<FanState>.of(initialFanStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final initialMedia = List<MediaState>.of(initialMediaStates)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    if (initialTenure.length != clubIds.length ||
        initialFan.length != clubIds.length ||
        initialMedia.length != clubIds.length ||
        initialTenure
            .map((item) => item.clubId)
            .toSet()
            .difference(clubIds.toSet())
            .isNotEmpty ||
        initialFan
            .map((item) => item.clubId)
            .toSet()
            .difference(clubIds.toSet())
            .isNotEmpty ||
        initialMedia
            .map((item) => item.clubId)
            .toSet()
            .difference(clubIds.toSet())
            .isNotEmpty) {
      throw ArgumentError('President resume state must cover every club exactly once.');
    }

    final tenureStates = {for (final state in initialTenure) state.clubId: state};
    final fanStates = {for (final state in initialFan) state.clubId: state};
    final mediaStates = {for (final state in initialMedia) state.clubId: state};
    final termScores = <String, List<int>>{
      for (final clubId in clubIds)
        clubId: List<int>.of(priorTermPromiseScores[clubId] ?? const <int>[]),
    };
    for (final clubId in clubIds) {
      if (termScores[clubId]!.length != seasonsIntoCurrentTerm) {
        throw ArgumentError(
          'Prior promise score count must match election cursor for $clubId.',
        );
      }
    }

    final seasons = <PresidentReputationCareerSeason>[];
    final elections = <PresidentElectionSnapshot>[];
    final turnovers = <PresidentTurnoverEvent>[];
    final handovers = <PresidentReputationHandoverEvent>[];

    for (var offset = 0; offset < worldSeasons.length; offset++) {
      final seasonIndex = worldSeasons[offset].seasonIndex;
      final snapshots = <PresidentReputationSeasonSnapshot>[];

      for (final clubId in clubIds) {
        final key = '$seasonIndex|$clubId';
        final fanTemplate = fanTemplateByKey[key];
        final mediaTemplate = mediaTemplateByKey[key];
        final promiseSnapshot = promiseByKey[key];
        final tenure = tenureStates[clubId];
        final currentFan = fanStates[clubId];
        final currentMedia = mediaStates[clubId];
        if (fanTemplate == null ||
            mediaTemplate == null ||
            promiseSnapshot == null ||
            tenure == null ||
            currentFan == null ||
            currentMedia == null) {
          throw StateError('Missing president reputation source state for $key.');
        }

        termScores[clubId]!.add(promiseSnapshot.resolution.score);
        final nextFan = currentFan.apply(fanTemplate.reasons);
        final statementChange = mediaTemplate.statement == null
            ? null
            : mediaCredibilityEngine.evaluate(
                state: currentMedia,
                statement: mediaTemplate.statement!,
                managerChanged: mediaTemplate.managerChanged,
              );
        final afterStatement = statementChange?.after ?? currentMedia.credibility;
        final promiseChange = promiseMediaImpactEngine.evaluate(
          state: MediaState(clubId: clubId, credibility: afterStatement),
          resolution: promiseSnapshot.resolution,
        );
        final nextMedia = MediaState(
          clubId: clubId,
          credibility: promiseChange.after,
        );

        fanStates[clubId] = nextFan;
        mediaStates[clubId] = nextMedia;
        snapshots.add(
          PresidentReputationSeasonSnapshot(
            clubId: clubId,
            seasonIndex: seasonIndex,
            presidentId: tenure.president.id,
            fanBefore: currentFan,
            fanAfter: nextFan,
            mediaBefore: currentMedia.credibility,
            mediaAfterStatement: afterStatement,
            mediaAfterPromise: nextMedia.credibility,
            statementChange: statementChange,
            promiseChange: promiseChange,
          ),
        );
      }

      seasons.add(
        PresidentReputationCareerSeason(
          seasonIndex: seasonIndex,
          clubs: snapshots,
        ),
      );

      final globalTermProgress = seasonsIntoCurrentTerm + offset + 1;
      if (globalTermProgress % electionInterval != 0) continue;
      final termNumber =
          completedElectionTerms + (globalTermProgress ~/ electionInterval);

      for (final clubId in clubIds) {
        final fan = fanStates[clubId]!;
        final media = mediaStates[clubId]!;
        final currentTenure = tenureStates[clubId]!;
        final scores = termScores[clubId]!;
        if (scores.length != electionInterval) {
          throw StateError('Invalid president promise term coverage for $clubId.');
        }
        final promiseScore =
            (scores.fold<int>(0, (sum, score) => sum + score) / scores.length)
                .round();
        final election = electionEngine.evaluate(
          clubId: clubId,
          seasonIndex: seasonIndex,
          termNumber: termNumber,
          fanOverallTrust: fan.overallTrust,
          fanIdentityTrust: fan.identityTrust,
          mediaCredibility: media.credibility,
          promiseScore: promiseScore,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        elections.add(election);
        scores.clear();

        if (election.outcome == PresidentElectionOutcome.reelected) {
          tenureStates[clubId] = currentTenure.recordReelection();
          continue;
        }

        final incoming = profileGenerator.generateChallenger(
          clubId: clubId,
          seasonIndex: seasonIndex,
          electionTermNumber: termNumber,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        final effectiveSeasonIndex = seasonIndex + 1;
        turnovers.add(
          PresidentTurnoverEvent(
            clubId: clubId,
            electionSeasonIndex: seasonIndex,
            effectiveSeasonIndex: effectiveSeasonIndex,
            electionTermNumber: termNumber,
            outgoing: currentTenure.president,
            incoming: incoming,
            outgoingStartedSeasonIndex: currentTenure.startedSeasonIndex,
            outgoingTenureSeasons:
                effectiveSeasonIndex - currentTenure.startedSeasonIndex,
            outgoingReelections: currentTenure.reelectionsWon,
            electionMargin: election.margin,
            challengerStrength: election.challengerStrength,
          ),
        );

        final resetFan = handoverPolicy.resetFan(fan);
        final resetMedia = handoverPolicy.resetMedia(media);
        handovers.add(
          PresidentReputationHandoverEvent(
            clubId: clubId,
            electionSeasonIndex: seasonIndex,
            effectiveSeasonIndex: effectiveSeasonIndex,
            outgoingPresidentId: currentTenure.president.id,
            incomingPresidentId: incoming.id,
            fanBefore: fan,
            fanAfter: resetFan,
            mediaBefore: media,
            mediaAfter: resetMedia,
          ),
        );
        fanStates[clubId] = resetFan;
        mediaStates[clubId] = resetMedia;
        tenureStates[clubId] = currentTenure.handover(
          incoming: incoming,
          effectiveSeasonIndex: effectiveSeasonIndex,
        );
      }
    }

    final finalTenureStates = tenureStates.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final finalFanStates = fanStates.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final finalMediaStates = mediaStates.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));

    return PresidentReputationCareerReport(
      sourceReport: sourceReport,
      fanTemplateReport: fanTemplateReport,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      electionInterval: electionInterval,
      initialTenureStates: initialTenure,
      seasons: seasons,
      elections: elections,
      turnovers: turnovers,
      handovers: handovers,
      finalTenureStates: finalTenureStates,
      finalFanStates: finalFanStates,
      finalMediaStates: finalMediaStates,
    );
  }
}
