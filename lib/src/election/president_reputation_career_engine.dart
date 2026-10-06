import '../core/simulation_config.dart';
import '../fan/fan_career_engine.dart';
import '../fan/fan_state.dart';
import '../fan/fan_trust_reason.dart';
import '../league/club.dart';
import '../media/media_credibility_engine.dart';
import '../media/media_season_snapshot.dart';
import '../media/media_state.dart';
import '../promise/promise_fan_impact_engine.dart';
import '../promise/promise_media_career_engine.dart';
import '../promise/promise_media_career_report.dart';
import '../promise/promise_media_impact_engine.dart';
import '../promise/promise_season_snapshot.dart';
import '../world/world_league.dart';
import 'president_election.dart';
import 'president_election_engine.dart';
import 'president_election_snapshot.dart';
import 'president_opening_state_initializer.dart';
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

  PresidentElectionSuccessor projectElection({
    required SimulationConfig config,
    required int seasonIndex,
    required int termNumber,
    required int electionInterval,
    required PresidentTenureState tenure,
    required FanState fan,
    required MediaState media,
    required List<int> acceptedPromiseScores,
  }) {
    final clubId = tenure.clubId;
    if (electionInterval <= 0 ||
        acceptedPromiseScores.length != electionInterval ||
        fan.clubId != clubId ||
        media.clubId != clubId) {
      throw StateError('Invalid president promise term coverage for $clubId.');
    }
    final promiseScore = (acceptedPromiseScores.fold<int>(0, (a, b) => a + b) /
            acceptedPromiseScores.length)
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
    if (election.outcome == PresidentElectionOutcome.reelected) {
      return PresidentElectionSuccessor._(
        election,
        tenure.recordReelection(),
        fan,
        media,
        null,
        null,
      );
    }
    final incoming = profileGenerator.generateChallenger(
      clubId: clubId,
      seasonIndex: seasonIndex,
      electionTermNumber: termNumber,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final effectiveSeasonIndex = seasonIndex + 1;
    final turnover = PresidentTurnoverEvent(
      clubId: clubId,
      electionSeasonIndex: seasonIndex,
      effectiveSeasonIndex: effectiveSeasonIndex,
      electionTermNumber: termNumber,
      outgoing: tenure.president,
      incoming: incoming,
      outgoingStartedSeasonIndex: tenure.startedSeasonIndex,
      outgoingTenureSeasons: effectiveSeasonIndex - tenure.startedSeasonIndex,
      outgoingReelections: tenure.reelectionsWon,
      electionMargin: election.margin,
      challengerStrength: election.challengerStrength,
    );
    final resetFan = handoverPolicy.resetFan(fan);
    final resetMedia = handoverPolicy.resetMedia(media);
    final handover = PresidentReputationHandoverEvent(
      clubId: clubId,
      electionSeasonIndex: seasonIndex,
      effectiveSeasonIndex: effectiveSeasonIndex,
      outgoingPresidentId: tenure.president.id,
      incomingPresidentId: incoming.id,
      fanBefore: fan,
      fanAfter: resetFan,
      mediaBefore: media,
      mediaAfter: resetMedia,
    );
    return PresidentElectionSuccessor._(
      election,
      tenure.handover(
          incoming: incoming, effectiveSeasonIndex: effectiveSeasonIndex),
      resetFan,
      resetMedia,
      turnover,
      handover,
    );
  }

  /// One actual accepted-promise/domain update. A missing real manager media
  /// source means no statement, not a generated/reconstructed manager season.
  PresidentReputationSeasonSnapshot projectClubSeason({
    required int seasonIndex,
    required PresidentTenureState tenure,
    required FanState priorFan,
    required MediaState priorMedia,
    required Iterable<FanTrustReason> fanReasons,
    required PromiseSeasonSnapshot acceptedPromise,
    MediaSeasonSnapshot? managerMedia,
  }) {
    final clubId = tenure.clubId;
    if (priorFan.clubId != clubId ||
        priorMedia.clubId != clubId ||
        acceptedPromise.promise.clubId != clubId ||
        acceptedPromise.promise.seasonIndex != seasonIndex ||
        !identical(
            acceptedPromise.resolution.promise, acceptedPromise.promise) ||
        (managerMedia != null &&
            (managerMedia.clubId != clubId ||
                managerMedia.seasonIndex != seasonIndex))) {
      throw StateError('President successor input lineage mismatch.');
    }
    final nextFan = priorFan.apply(fanReasons);
    final statement = managerMedia?.statement;
    final statementChange = statement == null
        ? null
        : mediaCredibilityEngine.evaluate(
            state: priorMedia,
            statement: statement,
            managerChanged: managerMedia!.managerChanged,
          );
    final afterStatement = statementChange?.after ?? priorMedia.credibility;
    final promiseChange = promiseMediaImpactEngine.evaluate(
      state: MediaState(clubId: clubId, credibility: afterStatement),
      resolution: acceptedPromise.resolution,
    );
    return PresidentReputationSeasonSnapshot(
      clubId: clubId,
      seasonIndex: seasonIndex,
      presidentId: tenure.president.id,
      fanBefore: priorFan,
      fanAfter: nextFan,
      mediaBefore: priorMedia.credibility,
      mediaAfterStatement: afterStatement,
      mediaAfterPromise: promiseChange.after,
      statementChange: statementChange,
      promiseChange: promiseChange,
    );
  }

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
    final firstSeasonIndex = worldSeasons.isEmpty
        ? config.seasonIndex
        : worldSeasons.first.seasonIndex;
    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();
    final initial = [
      for (final clubId in clubIds)
        PresidentOpeningStateInitializer(
          presidentGenerator: profileGenerator,
        ).prepareClub(
          clubId: clubId,
          config: config,
          startedSeasonIndex: firstSeasonIndex,
        ),
    ];
    return _run(
      sourceReport: sourceReport,
      config: config,
      electionInterval: electionInterval,
      completedElectionTerms: 0,
      seasonsIntoCurrentTerm: 0,
      initialTenureStates: [for (final item in initial) item.tenure],
      initialFanStates: [for (final item in initial) item.fan],
      initialMediaStates: [for (final item in initial) item.media],
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
      throw ArgumentError.value(
          completedElectionTerms, 'completedElectionTerms');
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
        mediaTemplateByKey['${season.seasonIndex}|${snapshot.clubId}'] =
            snapshot;
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
      throw ArgumentError(
          'President resume state must cover every club exactly once.');
    }

    final tenureStates = {
      for (final state in initialTenure) state.clubId: state
    };
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
          throw StateError(
              'Missing president reputation source state for $key.');
        }

        termScores[clubId]!.add(promiseSnapshot.resolution.score);
        final snapshot = projectClubSeason(
          seasonIndex: seasonIndex,
          tenure: tenure,
          priorFan: currentFan,
          priorMedia: currentMedia,
          fanReasons: fanTemplate.reasons,
          acceptedPromise: promiseSnapshot,
          managerMedia: mediaTemplate,
        );
        fanStates[clubId] = snapshot.fanAfter;
        mediaStates[clubId] = MediaState(
          clubId: clubId,
          credibility: snapshot.mediaAfterPromise,
        );
        snapshots.add(snapshot);
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
        final successor = projectElection(
          config: config,
          seasonIndex: seasonIndex,
          termNumber: termNumber,
          electionInterval: electionInterval,
          tenure: currentTenure,
          fan: fan,
          media: media,
          acceptedPromiseScores: scores,
        );
        elections.add(successor.election);
        scores.clear();
        if (successor.turnover != null) turnovers.add(successor.turnover!);
        if (successor.handover != null) handovers.add(successor.handover!);
        fanStates[clubId] = successor.fan;
        mediaStates[clubId] = successor.media;
        tenureStates[clubId] = successor.tenure;
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

/// Immutable calculation evidence. It neither owns nor publishes runtime state.
final class PresidentElectionSuccessor {
  PresidentElectionSuccessor._(this.election, this.tenure, this.fan, this.media,
      this.turnover, this.handover);
  final PresidentElectionSnapshot election;
  final PresidentTenureState tenure;
  final FanState fan;
  final MediaState media;
  final PresidentTurnoverEvent? turnover;
  final PresidentReputationHandoverEvent? handover;
}
