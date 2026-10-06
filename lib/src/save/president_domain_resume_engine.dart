import '../election/president_management_profile.dart';
import '../core/simulation_config.dart';
import '../fan/fan_season_snapshot.dart';
import '../media/media_season_snapshot.dart';
import '../media/media_state.dart';
import '../manager/manager_career_season.dart';
import '../promise/promise_season_snapshot.dart';
import '../transfer/loan_agreement.dart';
import '../world/world_career_season.dart';
import '../election/president_reputation_career_engine.dart';
import '../election/president_reputation_career_report.dart';
import '../manager/manager_career_report.dart';
import '../promise/promise_media_career_engine.dart';
import '../transfer/advanced_transfer_career_report.dart';
import 'advanced_history_compaction.dart';
import 'advanced_runtime_career_engine.dart';
import 'president_domain_memory_checkpoint.dart';
import 'president_runtime_checkpoint.dart';

class PresidentDomainResumeResult {
  const PresidentDomainResumeResult({
    required this.report,
    required this.checkpoint,
  });

  final PresidentReputationCareerReport report;
  final PresidentDomainMemoryCheckpoint checkpoint;
}

class PresidentDomainResumeEngine {
  const PresidentDomainResumeEngine({
    this.runtimeEngine = const AdvancedRuntimeCareerEngine(),
    this.compactor = const AdvancedRuntimeHistoryCompactor(),
    this.sourceEngine = const PromiseMediaCareerEngine(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.profileGenerator = const PresidentManagementProfileGenerator(),
  });

  final AdvancedRuntimeCareerEngine runtimeEngine;
  final AdvancedRuntimeHistoryCompactor compactor;
  final PromiseMediaCareerEngine sourceEngine;
  final PresidentReputationCareerEngine reputationEngine;
  final PresidentManagementProfileGenerator profileGenerator;

  /// Shared single-season calculation. The transition owns and validates the
  /// inputs; this result is not a checkpoint or a runtime authority capability.
  PresidentDomainSeasonEffects projectRuntimeSeason({
    required WorldCareerSeason season,
    required SimulationConfig config,
    required Iterable<PresidentClubRuntimeState> priorClubs,
    required Iterable<PromiseSeasonSnapshot> acceptedPromises,
    required Iterable<LoanAgreement> loanHistory,
    required int electionInterval,
    required int completedElectionTerms,
    required int seasonsIntoCurrentTerm,
    required Map<String, List<int>> priorTermPromiseScores,
    required bool hasNextSeason,
    ManagerCareerSeason? managerSeason,
  }) {
    if (electionInterval <= 0 ||
        completedElectionTerms < 0 ||
        seasonsIntoCurrentTerm < 0 ||
        seasonsIntoCurrentTerm >= electionInterval ||
        (managerSeason != null &&
            managerSeason.seasonIndex != season.seasonIndex)) {
      throw StateError('Invalid owned domain season/cursor.');
    }
    final states = priorClubs.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final promises = acceptedPromises.toList();
    final byClub = {for (final p in promises) p.promise.clubId: p};
    final ids = season.clubs.map((c) => c.id).toSet();
    if (states.length != ids.length ||
        states.map((c) => c.clubId).toSet().length != ids.length ||
        promises.length != ids.length ||
        byClub.length != ids.length ||
        !states.every((s) => ids.contains(s.clubId)) ||
        !ids.every(byClub.containsKey)) {
      throw StateError(
          'Domain successor requires exact club/promise coverage.');
    }
    final next = <PresidentClubRuntimeState>[];
    final fanEvidence = <FanSeasonSnapshot>[];
    final mediaEvidence = <MediaSeasonSnapshot>[];
    final reputationEvidence = <PresidentReputationSeasonSnapshot>[];
    final elections = <PresidentElectionSuccessor>[];
    final scores = <String, List<int>>{};
    final termProgress = seasonsIntoCurrentTerm + 1;
    final completesTerm = termProgress == electionInterval;
    for (final state in states) {
      state.validate();
      final promise = byClub[state.clubId]!;
      final priorScores = priorTermPromiseScores[state.clubId] ?? const <int>[];
      if (priorScores.length != seasonsIntoCurrentTerm) {
        throw StateError('Domain promise cursor mismatch for ${state.clubId}.');
      }
      final fan = reputationEngine.fanEngine.projectSeason(
        priorState: state.fanReputation,
        season: season,
        loanHistory: loanHistory,
        hasNextSeason: hasNextSeason,
        extraReasonProvider: (_) =>
            reputationEngine.fanImpactEngine.evaluate(promise.resolution),
      );
      fanEvidence.add(fan);
      final media = managerSeason == null
          ? null
          : sourceEngine.mediaEngine.projectClubSeason(
              priorState: state.mediaReputation,
              clubSeason: managerSeason.clubs
                  .singleWhere((c) => c.clubId == state.clubId),
              seasonIndex: season.seasonIndex,
              managerChanged: managerSeason.changesAfterSeason
                  .any((c) => c.clubId == state.clubId),
              config: config,
            );
      if (media != null) mediaEvidence.add(media);
      final reputation = reputationEngine.projectClubSeason(
        seasonIndex: season.seasonIndex,
        tenure: state.tenure,
        priorFan: state.fanReputation,
        priorMedia: state.mediaReputation,
        fanReasons: fan.reasons,
        acceptedPromise: promise,
        managerMedia: media,
      );
      reputationEvidence.add(reputation);
      final termScores = [...priorScores, promise.resolution.score];
      var tenure = state.tenure;
      var nextFan = reputation.fanAfter;
      var nextMedia = MediaState(
          clubId: state.clubId, credibility: reputation.mediaAfterPromise);
      if (completesTerm) {
        final election = reputationEngine.projectElection(
          config: config,
          seasonIndex: season.seasonIndex,
          termNumber: completedElectionTerms + 1,
          electionInterval: electionInterval,
          tenure: tenure,
          fan: nextFan,
          media: nextMedia,
          acceptedPromiseScores: termScores,
        );
        elections.add(election);
        tenure = election.tenure;
        nextFan = election.fan;
        nextMedia = election.media;
        termScores.clear();
      }
      scores[state.clubId] = List.unmodifiable(termScores);
      next.add(PresidentClubRuntimeState(
        tenure: tenure,
        managementProfile: identical(tenure.president, state.tenure.president)
            ? state.managementProfile
            : profileGenerator.generate(
                president: tenure.president,
                careerSeed: config.careerSeed,
                simulationVersion: config.simulationVersion),
        fanReputation: nextFan,
        mediaReputation: nextMedia,
      ));
    }
    return PresidentDomainSeasonEffects._(
      next,
      fanEvidence,
      mediaEvidence,
      reputationEvidence,
      elections,
      scores,
      completedElectionTerms + (completesTerm ? 1 : 0),
      completesTerm ? 0 : termProgress,
    );
  }

  PresidentDomainResumeResult resume({
    required PresidentDomainMemoryCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    final previousCompact = checkpoint.presidentRuntime.runtime;
    final resumeStartSeasonIndex = previousCompact.nextSeasonIndex;
    final full = runtimeEngine.resume(
      checkpoint: previousCompact.runtime,
      seasonCount: seasonCount,
    );
    final compact = compactor.compactAfterResume(
      source: full.checkpoint,
      previousHistory: previousCompact.history,
      resumeStartSeasonIndex: resumeStartSeasonIndex,
    );

    final advancedReport = AdvancedTransferCareerReport(
      worldReport: full.report,
      activeContracts: full.checkpoint.transfer.activeContracts,
      contractEvents: full.checkpoint.transfer.contractEvents,
      loanHistory: full.checkpoint.transfer.loanHistory,
      activeLoans: full.checkpoint.transfer.activeLoans,
      installmentObligations: full.checkpoint.transfer.installmentObligations,
    );
    final managerReport = ManagerCareerReport(
      worldReport: full.report,
      managers: full.checkpoint.manager.managers,
      seasons: full.checkpoint.manager.seasons
          .where((item) => item.seasonIndex >= resumeStartSeasonIndex),
      finalAssignments: full.checkpoint.manager.assignments,
    );
    final config = full.checkpoint.world.config;
    final sourceReport = sourceEngine.simulateFromAdvancedReport(
      advancedReport: advancedReport,
      managerReport: managerReport,
      config: config,
    );

    final priorScores = <String, List<int>>{};
    for (final item in checkpoint.currentTermPromises) {
      priorScores.putIfAbsent(item.clubId, () => <int>[]).add(item.score);
    }
    final initialTenure =
        checkpoint.presidentRuntime.clubs.map((item) => item.tenure).toList();
    final initialFan = checkpoint.presidentRuntime.clubs
        .map((item) => item.fanReputation)
        .toList();
    final initialMedia = checkpoint.presidentRuntime.clubs
        .map((item) => item.mediaReputation)
        .toList();
    final reputation = reputationEngine.resumeFromSourceReport(
      sourceReport: sourceReport,
      config: config,
      electionInterval: checkpoint.presidentRuntime.electionInterval,
      completedElectionTerms:
          checkpoint.presidentRuntime.completedElectionTerms,
      seasonsIntoCurrentTerm:
          checkpoint.presidentRuntime.seasonsIntoCurrentTerm,
      initialTenureStates: initialTenure,
      initialFanStates: initialFan,
      initialMediaStates: initialMedia,
      priorTermPromiseScores: priorScores,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );

    final fanByClub = {
      for (final state in reputation.finalFanStates) state.clubId: state,
    };
    final mediaByClub = {
      for (final state in reputation.finalMediaStates) state.clubId: state,
    };
    final presidentClubs = <PresidentClubRuntimeState>[];
    for (final tenure in reputation.finalTenureStates) {
      final fan = fanByClub[tenure.clubId];
      final media = mediaByClub[tenure.clubId];
      if (fan == null || media == null) {
        throw StateError(
            'Missing resumed president state for ${tenure.clubId}.');
      }
      presidentClubs.add(
        PresidentClubRuntimeState(
          tenure: tenure,
          managementProfile: profileGenerator.generate(
            president: tenure.president,
            careerSeed: config.careerSeed,
            simulationVersion: config.simulationVersion,
          ),
          fanReputation: fan,
          mediaReputation: media,
        ),
      );
    }
    presidentClubs.sort((a, b) => a.clubId.compareTo(b.clubId));
    final interval = checkpoint.presidentRuntime.electionInterval;
    final presidentRuntime = PresidentRuntimeCheckpoint(
      runtime: compact,
      electionInterval: interval,
      completedElectionTerms: compact.completedSeasons ~/ interval,
      seasonsIntoCurrentTerm: compact.completedSeasons % interval,
      clubs: presidentClubs,
    );

    final nextSummary = PresidentDomainHistorySummary(
      fanSnapshots: checkpoint.summary.fanSnapshots +
          reputation.fanTemplateReport.snapshots.length,
      fanReasons: checkpoint.summary.fanReasons +
          reputation.fanTemplateReport.reasonCount,
      mediaStatements: checkpoint.summary.mediaStatements +
          sourceReport.baselineMediaReport.totalStatements,
      mediaContradictions: checkpoint.summary.mediaContradictions +
          sourceReport.baselineMediaReport.totalContradictions,
      promisesFulfilled: checkpoint.summary.promisesFulfilled +
          sourceReport.promiseReport.fulfilledPromises,
      promisesPartial: checkpoint.summary.promisesPartial +
          sourceReport.promiseReport.partialPromises,
      promisesBroken: checkpoint.summary.promisesBroken +
          sourceReport.promiseReport.brokenPromises,
    );

    final lastSeasonIndex = compact.nextSeasonIndex - 1;
    final recentStart = lastSeasonIndex - checkpoint.rawHistorySeasons + 1;
    final recentFan = <RecentFanMemory>[
      ...checkpoint.recentFan.where((item) => item.seasonIndex >= recentStart),
      ...reputation.fanTemplateReport.snapshots
          .where((item) => item.context.seasonIndex >= recentStart)
          .map(
            (item) => RecentFanMemory(
              clubId: item.context.clubId,
              seasonIndex: item.context.seasonIndex,
              expectationSignature: item.expectation.signature,
              stateSignature: item.state.signature,
              reasonSignatures: item.reasons.map((reason) => reason.signature),
            ),
          ),
    ]..sort((a, b) {
        final season = a.seasonIndex.compareTo(b.seasonIndex);
        return season != 0 ? season : a.clubId.compareTo(b.clubId);
      });

    final recentMedia = <RecentMediaMemory>[
      ...checkpoint.recentMedia
          .where((item) => item.seasonIndex >= recentStart),
    ];
    for (final season in sourceReport.baselineMediaReport.seasons) {
      if (season.seasonIndex < recentStart) continue;
      for (final item in season.clubs) {
        recentMedia.add(
          RecentMediaMemory(
            clubId: item.clubId,
            seasonIndex: item.seasonIndex,
            managerId: item.managerId,
            managerChanged: item.managerChanged,
            credibilityBefore: item.credibilityBefore,
            credibilityAfter: item.credibilityAfter,
            statementSignature: item.statement?.signature,
            changeSignature: item.change?.signature,
          ),
        );
      }
    }
    recentMedia.sort((a, b) {
      final season = a.seasonIndex.compareTo(b.seasonIndex);
      return season != 0 ? season : a.clubId.compareTo(b.clubId);
    });

    final finalTermOffset = presidentRuntime.seasonsIntoCurrentTerm;
    final termStartSeasonIndex =
        presidentRuntime.nextSeasonIndex - finalTermOffset;
    final currentTermPromises = <CurrentTermPromiseMemory>[
      if (finalTermOffset > 0)
        ...checkpoint.currentTermPromises.where(
          (item) => item.seasonIndex >= termStartSeasonIndex,
        ),
      if (finalTermOffset > 0)
        ...sourceReport.promiseReport.snapshots
            .where((item) => item.promise.seasonIndex >= termStartSeasonIndex)
            .map(
              (item) => CurrentTermPromiseMemory(
                clubId: item.promise.clubId,
                seasonIndex: item.promise.seasonIndex,
                promiseType: item.promise.type.name,
                status: item.resolution.status.name,
                score: item.resolution.score,
              ),
            ),
    ]..sort((a, b) {
        final season = a.seasonIndex.compareTo(b.seasonIndex);
        return season != 0 ? season : a.clubId.compareTo(b.clubId);
      });

    return PresidentDomainResumeResult(
      report: reputation,
      checkpoint: PresidentDomainMemoryCheckpoint(
        presidentRuntime: presidentRuntime,
        summary: nextSummary,
        rawHistorySeasons: checkpoint.rawHistorySeasons,
        recentFan: recentFan,
        recentMedia: recentMedia,
        currentTermPromises: currentTermPromises,
      ),
    );
  }
}

final class PresidentDomainSeasonEffects {
  PresidentDomainSeasonEffects._(
      Iterable<PresidentClubRuntimeState> clubs,
      Iterable<FanSeasonSnapshot> fan,
      Iterable<MediaSeasonSnapshot> media,
      Iterable<PresidentReputationSeasonSnapshot> reputation,
      Iterable<PresidentElectionSuccessor> elections,
      Map<String, List<int>> scores,
      this.completedElectionTerms,
      this.seasonsIntoCurrentTerm)
      : clubs = List.unmodifiable(clubs),
        fan = List.unmodifiable(fan),
        media = List.unmodifiable(media),
        reputation = List.unmodifiable(reputation),
        elections = List.unmodifiable(elections),
        termPromiseScores = Map.unmodifiable(scores);
  final List<PresidentClubRuntimeState> clubs;
  final List<FanSeasonSnapshot> fan;
  final List<MediaSeasonSnapshot> media;
  final List<PresidentReputationSeasonSnapshot> reputation;
  final List<PresidentElectionSuccessor> elections;
  final Map<String, List<int>> termPromiseScores;
  final int completedElectionTerms, seasonsIntoCurrentTerm;
}
