import '../core/simulation_config.dart';
import '../election/president_reputation_career_engine.dart';
import '../league/club.dart';
import '../manager/manager_career_report.dart';
import '../promise/promise_media_career_engine.dart';
import '../transfer/advanced_transfer_career_report.dart';
import '../world/world_league.dart';
import 'advanced_history_compaction.dart';
import 'advanced_runtime_career_engine.dart';
import 'president_domain_memory_checkpoint.dart';
import 'president_domain_resume_engine.dart';
import 'president_runtime_checkpoint.dart';

class PresidentDomainCareerEngine {
  const PresidentDomainCareerEngine({
    this.runtimeEngine = const AdvancedRuntimeCareerEngine(),
    this.compactor = const AdvancedRuntimeHistoryCompactor(),
    this.sourceEngine = const PromiseMediaCareerEngine(),
    this.reputationEngine = const PresidentReputationCareerEngine(),
    this.resumeEngine = const PresidentDomainResumeEngine(),
  });

  final AdvancedRuntimeCareerEngine runtimeEngine;
  final AdvancedRuntimeHistoryCompactor compactor;
  final PromiseMediaCareerEngine sourceEngine;
  final PresidentReputationCareerEngine reputationEngine;
  final PresidentDomainResumeEngine resumeEngine;

  PresidentDomainResumeResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }

    final full = runtimeEngine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
    );
    final compact = compactor.compactFull(full.checkpoint);
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
      seasons: full.checkpoint.manager.seasons,
      finalAssignments: full.checkpoint.manager.assignments,
    );
    final sourceReport = sourceEngine.simulateFromAdvancedReport(
      advancedReport: advancedReport,
      managerReport: managerReport,
      config: config,
    );
    final reputation = reputationEngine.simulateFromSourceReport(
      sourceReport: sourceReport,
      config: config,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    final presidentRuntime = PresidentRuntimeCheckpoint.capture(
      runtime: compact,
      report: reputation,
    );
    final domain = PresidentDomainMemoryCheckpoint.capture(
      presidentRuntime: presidentRuntime,
      report: reputation,
    );
    return _normalizeRecentFan(
      PresidentDomainResumeResult(
        report: reputation,
        checkpoint: domain,
      ),
    );
  }

  PresidentDomainResumeResult resume({
    required PresidentDomainMemoryCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    final result = resumeEngine.resume(
      checkpoint: checkpoint,
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return _normalizeRecentFan(result);
  }

  PresidentDomainResumeResult _normalizeRecentFan(
    PresidentDomainResumeResult result,
  ) {
    final stateByKey = <String, String>{};
    for (final season in result.report.seasons) {
      for (final item in season.clubs) {
        stateByKey['${item.seasonIndex}|${item.clubId}'] =
            item.fanAfter.signature;
      }
    }
    final normalized = result.checkpoint.recentFan
        .map(
          (item) => RecentFanMemory(
            clubId: item.clubId,
            seasonIndex: item.seasonIndex,
            expectationSignature: item.expectationSignature,
            stateSignature:
                stateByKey['${item.seasonIndex}|${item.clubId}'] ??
                    item.stateSignature,
            reasonSignatures: item.reasonSignatures,
          ),
        )
        .toList();
    final checkpoint = PresidentDomainMemoryCheckpoint(
      presidentRuntime: result.checkpoint.presidentRuntime,
      summary: result.checkpoint.summary,
      rawHistorySeasons: result.checkpoint.rawHistorySeasons,
      recentFan: normalized,
      recentMedia: result.checkpoint.recentMedia,
      currentTermPromises: result.checkpoint.currentTermPromises,
    );
    return PresidentDomainResumeResult(
      report: result.report,
      checkpoint: checkpoint,
    );
  }
}
