import '../contract/contract_event.dart';
import '../manager/manager_career_season.dart';
import '../transfer/loan_agreement.dart';
import 'advanced_runtime_checkpoint.dart';

class AdvancedHistorySummary {
  AdvancedHistorySummary({
    required this.completedSeasons,
    required this.contractEventCount,
    required Map<ContractEventType, int> contractEventsByType,
    required this.loanCount,
    required this.loanFeeMinorUnits,
    required this.managerSeasonCount,
    required this.managerChangeCount,
    required Map<ManagerChangeReason, int> managerChangesByReason,
  })  : contractEventsByType = Map.unmodifiable({
          for (final type in ContractEventType.values)
            type: contractEventsByType[type] ?? 0,
        }),
        managerChangesByReason = Map.unmodifiable({
          for (final reason in ManagerChangeReason.values)
            reason: managerChangesByReason[reason] ?? 0,
        });

  factory AdvancedHistorySummary.fromCheckpoint(
    AdvancedRuntimeCheckpoint checkpoint,
  ) =>
      AdvancedHistorySummary.fromHistory(
        completedSeasons: checkpoint.completedSeasons,
        contractEvents: checkpoint.transfer.contractEvents,
        loanHistory: checkpoint.transfer.loanHistory,
        managerSeasons: checkpoint.manager.seasons,
      );

  factory AdvancedHistorySummary.fromHistory({
    required int completedSeasons,
    required Iterable<ContractEvent> contractEvents,
    required Iterable<LoanAgreement> loanHistory,
    required Iterable<ManagerCareerSeason> managerSeasons,
  }) {
    final contractCounts = <ContractEventType, int>{};
    var contractCount = 0;
    for (final event in contractEvents) {
      contractCount++;
      contractCounts[event.type] = (contractCounts[event.type] ?? 0) + 1;
    }

    var loans = 0;
    var loanFees = 0;
    for (final loan in loanHistory) {
      loans++;
      loanFees += loan.loanFee.minorUnits;
    }

    final managerCounts = <ManagerChangeReason, int>{};
    var managerSeasonCount = 0;
    var managerChanges = 0;
    for (final season in managerSeasons) {
      managerSeasonCount++;
      for (final change in season.changesAfterSeason) {
        managerChanges++;
        managerCounts[change.reason] = (managerCounts[change.reason] ?? 0) + 1;
      }
    }

    return AdvancedHistorySummary(
      completedSeasons: completedSeasons,
      contractEventCount: contractCount,
      contractEventsByType: contractCounts,
      loanCount: loans,
      loanFeeMinorUnits: loanFees,
      managerSeasonCount: managerSeasonCount,
      managerChangeCount: managerChanges,
      managerChangesByReason: managerCounts,
    );
  }

  final int completedSeasons;
  final int contractEventCount;
  final Map<ContractEventType, int> contractEventsByType;
  final int loanCount;
  final int loanFeeMinorUnits;
  final int managerSeasonCount;
  final int managerChangeCount;
  final Map<ManagerChangeReason, int> managerChangesByReason;

  AdvancedHistorySummary append({
    required int completedSeasons,
    required Iterable<ContractEvent> contractEvents,
    required Iterable<LoanAgreement> loanHistory,
    required Iterable<ManagerCareerSeason> managerSeasons,
  }) {
    final delta = AdvancedHistorySummary.fromHistory(
      completedSeasons: completedSeasons,
      contractEvents: contractEvents,
      loanHistory: loanHistory,
      managerSeasons: managerSeasons,
    );
    return AdvancedHistorySummary(
      completedSeasons: completedSeasons,
      contractEventCount: contractEventCount + delta.contractEventCount,
      contractEventsByType: {
        for (final type in ContractEventType.values)
          type: (contractEventsByType[type] ?? 0) +
              (delta.contractEventsByType[type] ?? 0),
      },
      loanCount: loanCount + delta.loanCount,
      loanFeeMinorUnits: loanFeeMinorUnits + delta.loanFeeMinorUnits,
      managerSeasonCount: managerSeasonCount + delta.managerSeasonCount,
      managerChangeCount: managerChangeCount + delta.managerChangeCount,
      managerChangesByReason: {
        for (final reason in ManagerChangeReason.values)
          reason: (managerChangesByReason[reason] ?? 0) +
              (delta.managerChangesByReason[reason] ?? 0),
      },
    );
  }

  void validate(AdvancedRuntimeCheckpoint runtime) {
    if (completedSeasons != runtime.completedSeasons ||
        completedSeasons < 0 ||
        contractEventCount < runtime.transfer.contractEvents.length ||
        loanCount < runtime.transfer.loanHistory.length ||
        loanFeeMinorUnits < 0 ||
        managerSeasonCount != completedSeasons ||
        managerSeasonCount < runtime.manager.seasons.length ||
        managerChangeCount < 0) {
      throw ArgumentError('Invalid advanced history summary totals.');
    }
    if (contractEventsByType.values.any((value) => value < 0) ||
        contractEventsByType.values.fold<int>(0, (a, b) => a + b) !=
            contractEventCount) {
      throw ArgumentError('Invalid contract history summary.');
    }
    if (managerChangesByReason.values.any((value) => value < 0) ||
        managerChangesByReason.values.fold<int>(0, (a, b) => a + b) !=
            managerChangeCount) {
      throw ArgumentError('Invalid manager history summary.');
    }
  }

  String get signature {
    final contracts = ContractEventType.values
        .map((type) => '${type.name}:${contractEventsByType[type] ?? 0}')
        .join(',');
    final managers = ManagerChangeReason.values
        .map((reason) => '${reason.name}:${managerChangesByReason[reason] ?? 0}')
        .join(',');
    return '$completedSeasons|$contractEventCount|$contracts|$loanCount|'
        '$loanFeeMinorUnits|$managerSeasonCount|$managerChangeCount|$managers';
  }
}

class CompactAdvancedRuntimeCheckpoint {
  CompactAdvancedRuntimeCheckpoint({
    required this.runtime,
    required this.history,
    required this.recentHistoryStartSeasonIndex,
  }) {
    validate();
  }

  final AdvancedRuntimeCheckpoint runtime;
  final AdvancedHistorySummary history;
  final int recentHistoryStartSeasonIndex;

  int get completedSeasons => runtime.completedSeasons;
  int get nextSeasonIndex => runtime.nextSeasonIndex;

  void validate() {
    runtime.validate();
    history.validate(runtime);
    final initialSeasonIndex = runtime.world.config.seasonIndex;
    if (recentHistoryStartSeasonIndex < initialSeasonIndex ||
        recentHistoryStartSeasonIndex > runtime.nextSeasonIndex) {
      throw ArgumentError('Invalid recent history window start.');
    }
    for (final event in runtime.transfer.contractEvents) {
      if (event.seasonIndex < recentHistoryStartSeasonIndex) {
        throw ArgumentError('Contract detail escaped the recent history window.');
      }
    }
    final activeLoanSignatures =
        runtime.transfer.activeLoans.map((loan) => loan.signature).toSet();
    for (final loan in runtime.transfer.loanHistory) {
      if (loan.startSeasonIndex < recentHistoryStartSeasonIndex &&
          !activeLoanSignatures.contains(loan.signature)) {
        throw ArgumentError('Old inactive loan escaped the history window.');
      }
    }
    for (final season in runtime.manager.seasons) {
      if (season.seasonIndex < recentHistoryStartSeasonIndex) {
        throw ArgumentError('Manager detail escaped the recent history window.');
      }
    }
  }
}

class CompactAdvancedRuntimeSimulationResult {
  const CompactAdvancedRuntimeSimulationResult({
    required this.report,
    required this.checkpoint,
  });

  final dynamic report;
  final CompactAdvancedRuntimeCheckpoint checkpoint;
}

class AdvancedRuntimeHistoryCompactor {
  const AdvancedRuntimeHistoryCompactor({this.recentSeasonCount = 2})
      : assert(recentSeasonCount >= 0);

  final int recentSeasonCount;

  CompactAdvancedRuntimeCheckpoint compactFull(
    AdvancedRuntimeCheckpoint source,
  ) =>
      _compact(
        source,
        AdvancedHistorySummary.fromCheckpoint(source),
      );

  CompactAdvancedRuntimeCheckpoint compactAfterResume({
    required AdvancedRuntimeCheckpoint source,
    required AdvancedHistorySummary previousHistory,
    required int resumeStartSeasonIndex,
  }) {
    if (resumeStartSeasonIndex > source.nextSeasonIndex) {
      throw ArgumentError('Resume start cannot be after the checkpoint.');
    }
    final history = previousHistory.append(
      completedSeasons: source.completedSeasons,
      contractEvents: source.transfer.contractEvents
          .where((event) => event.seasonIndex >= resumeStartSeasonIndex),
      loanHistory: source.transfer.loanHistory
          .where((loan) => loan.startSeasonIndex >= resumeStartSeasonIndex),
      managerSeasons: source.manager.seasons
          .where((season) => season.seasonIndex >= resumeStartSeasonIndex),
    );
    return _compact(source, history);
  }

  CompactAdvancedRuntimeCheckpoint _compact(
    AdvancedRuntimeCheckpoint source,
    AdvancedHistorySummary history,
  ) {
    final initialSeasonIndex = source.world.config.seasonIndex;
    final start = (source.nextSeasonIndex - recentSeasonCount)
        .clamp(initialSeasonIndex, source.nextSeasonIndex);
    final activeLoanSignatures =
        source.transfer.activeLoans.map((loan) => loan.signature).toSet();

    final runtime = AdvancedRuntimeCheckpoint(
      world: source.world,
      transfer: AdvancedTransferRuntimeState(
        activeContracts: source.transfer.activeContracts,
        contractEvents: source.transfer.contractEvents
            .where((event) => event.seasonIndex >= start),
        activeLoans: source.transfer.activeLoans,
        loanHistory: source.transfer.loanHistory.where(
          (loan) =>
              loan.startSeasonIndex >= start ||
              activeLoanSignatures.contains(loan.signature),
        ),
        installmentObligations: source.transfer.installmentObligations,
      ),
      manager: ManagerRuntimeState(
        managers: source.manager.managers,
        assignments: source.manager.assignments,
        seasons: source.manager.seasons
            .where((season) => season.seasonIndex >= start),
      ),
    );

    return CompactAdvancedRuntimeCheckpoint(
      runtime: runtime,
      history: history,
      recentHistoryStartSeasonIndex: start,
    );
  }
}
