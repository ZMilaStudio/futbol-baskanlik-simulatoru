import '../core/simulation_config.dart';
import '../finance/club_finance_season.dart';
import '../finance/season_finance_authority_receipt.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../manager/manager_fit_model.dart';
import '../manager/manager_impact_model.dart';
import '../manager/manager_pool_generator.dart';
import '../transfer/advanced_transfer_controller.dart';
import '../transfer/loan_market_engine.dart';
import '../world/world_career_engine.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import '../world/world_offseason_projection.dart';
import '../transfer/loan_agreement.dart';
import '../transfer/president_transfer_strategy_world_bridge.dart';
import 'advanced_runtime_checkpoint.dart';

enum PreparedRuntimeOrigin { initial, resumed }

/// Production closing owner captured before movement or any completion hook.
/// The original transfer controller and detached manager continuation remain
/// private; a raw report/controller bundle cannot construct this object.
final class OwnedAdvancedAnnualClosing {
  OwnedAdvancedAnnualClosing._(this.world, this._transfer, this.managerOpening);
  final OwnedWorldAnnualClosing world;
  final AdvancedTransferController _transfer;
  final ManagerSeasonAuthority managerOpening;
  Object? _transition;
  ManagerContinuationAuthority? _managerContinuation;
  List<LoanAgreement> get loanHistory => _transfer.loanHistory;
  int get contractCount => _transfer.activeContracts.length;
  void claim(
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance,
      required Object transition}) {
    if (_transition != null)
      throw StateError('Advanced closing already claimed.');
    world.claim(
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance);
    _transition = transition;
  }

  void _check(Object transition) {
    world.validate();
    if (!identical(_transition, transition)) {
      throw StateError('Foreign advanced closing transition.');
    }
  }

  void validateTransition(Object transition) => _check(transition);

  ManagerContinuationAuthority completeManager(
      {required Object transition,
      required bool hasNextSeason,
      required List<WorldLeague> nextLeagues}) {
    _check(transition);
    if (_managerContinuation != null)
      throw StateError('Manager completion already consumed.');
    return _managerContinuation = managerOpening.completeOwnedAnnualClosing(
      closing: world,
      hasNextSeason: hasNextSeason,
      nextLeagues: nextLeagues,
    );
  }

  WorldOffseasonAttempt beginOffseason(
      {required Object transition,
      required List<WorldLeague> nextLeagues,
      PresidentTransferStrategyProfileProvider? profileProvider}) {
    _check(transition);
    if (_managerContinuation == null)
      throw StateError('Manager completion must precede lifecycle.');
    return world.beginOffseason(nextLeagues, profileProvider: profileProvider);
  }
}

/// Controllers never escape this lease. Moving preserves the actual instances,
/// rather than restoring another controller from their observable values.
final class PreparedAdvancedRuntimeSeason {
  PreparedAdvancedRuntimeSeason._(
      this._engine,
      this._manager,
      this._transfer,
      this._world,
      this.origin,
      this.managerAuthority,
      this.managerLineage,
      this.transferLineage)
      : _openingContractCount = _transfer.activeContracts.length;
  final AdvancedRuntimeCareerEngine _engine;
  final ManagerCareerController _manager;
  final AdvancedTransferController _transfer;
  final PreparedWorldExecution _world;
  final PreparedRuntimeOrigin origin;
  final ManagerSeasonAuthority? managerAuthority;
  final Object managerLineage, transferLineage;
  Object get owner => _world.owner;
  Object get revision => _world.revision;
  Object get provenance => _world.provenance;
  Object get executionIdentity => _world.executionIdentity;
  PreparedWorldOpening get opening => _world.opening;
  // Evidence of the real lazy boundary, not a complete transfer capability.
  int get openingContractCount => _openingContractCount;
  final int _openingContractCount;
  PreparedExecutionState _state = PreparedExecutionState.prepared;
  PreparedExecutionState get state => _state;

  void _check(Object expectedOwner, Object expectedRevision,
      Object expectedProvenance) {
    if (_state != PreparedExecutionState.prepared ||
        !identical(owner, expectedOwner) ||
        !identical(revision, expectedRevision) ||
        !identical(provenance, expectedProvenance)) {
      throw StateError('Foreign, stale or consumed advanced lease.');
    }
  }

  PreparedAdvancedRuntimeSeason move(
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    _check(expectedOwner, expectedRevision, expectedProvenance);
    final moved = _world.move(
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance);
    final successor = PreparedAdvancedRuntimeSeason._(
        _engine,
        _manager,
        _transfer,
        moved,
        origin,
        managerAuthority,
        managerLineage,
        transferLineage);
    _state = PreparedExecutionState.moved;
    return successor;
  }

  AdvancedEconomyRecipient moveToEconomy(
      {required FullM65RuntimeEconomyContinuationAuthority authority,
      required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    _check(expectedOwner, expectedRevision, expectedProvenance);
    final result = AdvancedEconomyRecipient._(
        _transfer,
        _world.moveToEconomy(
            authority: authority,
            expectedOwner: expectedOwner,
            expectedRevision: expectedRevision,
            expectedProvenance: expectedProvenance));
    _state = PreparedExecutionState.moved;
    return result;
  }
}

final class AdvancedEconomyRecipient {
  AdvancedEconomyRecipient._(this._transfer, this._world);
  final AdvancedTransferController _transfer;
  final WorldEconomyRecipient _world;
  int get contractCount => _transfer.activeContracts.length;
  OwnedAdvancedAnnualClosing releaseSettledAnnualClosing({
    required FullM65RuntimeEconomyContinuationAuthority authority,
    required CommittedSeasonSettlementCapability committed,
    required SeasonFinanceAuthorityReceipt receipt,
  }) {
    final world = _world.releaseSettledAnnualClosing(
        committed: committed, receipt: receipt);
    if (!identical(authority.managerAuthority.effectiveClubs,
        world.opening.effectiveClubs)) {
      throw StateError('Foreign settled manager opening.');
    }
    return OwnedAdvancedAnnualClosing._(
        world, _transfer, authority.managerAuthority);
  }

  List<ClubFinanceSeason> executeCommittedFinance(
          {required Object expectedExecution,
          required CommittedSeasonSettlementCapability committed}) =>
      _world.executeCommittedFinance(
          expectedExecution: expectedExecution, committed: committed);
}

class AdvancedRuntimeCareerEngine {
  OwnedAdvancedAnnualClosing captureAnnualClosing(
      PreparedAdvancedRuntimeSeason prepared,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    prepared._check(expectedOwner, expectedRevision, expectedProvenance);
    final manager = prepared.managerAuthority;
    if (!identical(prepared._engine, this) || manager == null) {
      throw StateError('Closing capture requires original manager authority.');
    }
    prepared._state = PreparedExecutionState.executing;
    try {
      final world = worldEngine.captureAnnualClosing(prepared._world,
          expectedOwner: expectedOwner,
          expectedRevision: expectedRevision,
          expectedProvenance: expectedProvenance);
      final boundary =
          OwnedAdvancedAnnualClosing._(world, prepared._transfer, manager);
      prepared._state = PreparedExecutionState.moved;
      return boundary;
    } catch (_) {
      prepared._state = PreparedExecutionState.failed;
      rethrow;
    }
  }

  const AdvancedRuntimeCareerEngine({
    this.worldEngine = const WorldCareerEngine(),
    this.managerPoolGenerator = const ManagerPoolGenerator(),
    this.managerFitModel = const ManagerFitModel(),
    this.managerImpactModel = const ManagerImpactModel(),
    this.loanMarketEngine = const LoanMarketEngine(),
  });

  final WorldCareerEngine worldEngine;
  final ManagerPoolGenerator managerPoolGenerator;
  final ManagerFitModel managerFitModel;
  final ManagerImpactModel managerImpactModel;
  final LoanMarketEngine loanMarketEngine;

  AdvancedRuntimeSimulationResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
  }) {
    final prepared = prepareInitial(
        clubs: clubs,
        leagues: leagues,
        config: config,
        seasonCount: seasonCount);
    return executePrepared(prepared,
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance);
  }

  PreparedAdvancedRuntimeSeason prepareInitial(
      {required List<Club> clubs,
      required List<WorldLeague> leagues,
      required SimulationConfig config,
      int seasonCount = 1,
      Object? owner,
      Object? revision,
      Object? provenance,
      bool captureManagerAuthority = false}) {
    final transferController = AdvancedTransferController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      loanMarketEngine: loanMarketEngine,
    );
    final managerController = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      poolGenerator: managerPoolGenerator,
      fitModel: managerFitModel,
      impactModel: managerImpactModel,
    );

    final world = worldEngine.prepareInitial(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: managerController,
      rosterHooks: transferController,
      financeHooks: transferController,
      transferHooks: transferController,
      enableTransferInstallments: true,
      owner: owner ?? Object(),
      revision: revision ?? Object(),
      provenance: provenance ?? Object(),
    );
    return _prepared(managerController, transferController, world,
        PreparedRuntimeOrigin.initial, captureManagerAuthority);
  }

  AdvancedRuntimeSimulationResult resume({
    required AdvancedRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) {
    final prepared =
        prepareResume(checkpoint: checkpoint, seasonCount: seasonCount);
    return executePrepared(prepared,
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance);
  }

  PreparedAdvancedRuntimeSeason prepareResume(
      {required AdvancedRuntimeCheckpoint checkpoint,
      int seasonCount = 1,
      Object? owner,
      Object? revision,
      Object? provenance,
      bool captureManagerAuthority = false}) {
    checkpoint.validate();
    final config = checkpoint.world.config;
    final transferController = AdvancedTransferController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      activeContracts: checkpoint.transfer.activeContracts,
      contractEvents: checkpoint.transfer.contractEvents,
      activeLoans: checkpoint.transfer.activeLoans,
      loanHistory: checkpoint.transfer.loanHistory,
      installmentObligations: checkpoint.transfer.installmentObligations,
      loanMarketEngine: loanMarketEngine,
    );
    final managerController = ManagerCareerController.restore(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
      managers: checkpoint.manager.managers,
      assignments: checkpoint.manager.assignments,
      seasons: checkpoint.manager.seasons,
      poolGenerator: managerPoolGenerator,
      fitModel: managerFitModel,
      impactModel: managerImpactModel,
    );

    final world = worldEngine.prepareResume(
      checkpoint: checkpoint.world,
      seasonCount: seasonCount,
      hooks: managerController,
      rosterHooks: transferController,
      financeHooks: transferController,
      transferHooks: transferController,
      enableTransferInstallments: true,
      owner: owner ?? Object(),
      revision: revision ?? Object(),
      provenance: provenance ?? Object(),
    );
    return _prepared(managerController, transferController, world,
        PreparedRuntimeOrigin.resumed, captureManagerAuthority);
  }

  PreparedAdvancedRuntimeSeason _prepared(
      ManagerCareerController manager,
      AdvancedTransferController transfer,
      PreparedWorldExecution world,
      PreparedRuntimeOrigin origin,
      bool captureManagerAuthority) {
    final authority = captureManagerAuthority
        ? manager.captureSeasonAuthority(
            owner: world.owner,
            sourceRevision: world.revision,
            seasonIndex: world.opening.seasonIndex,
            effectiveClubs: world.opening.effectiveClubs)
        : null;
    final result = PreparedAdvancedRuntimeSeason._(
        this, manager, transfer, world, origin, authority, Object(), Object());
    return result;
  }

  AdvancedRuntimeSimulationResult executePrepared(
      PreparedAdvancedRuntimeSeason prepared,
      {required Object expectedOwner,
      required Object expectedRevision,
      required Object expectedProvenance}) {
    prepared._check(expectedOwner, expectedRevision, expectedProvenance);
    if (!identical(prepared._engine, this)) {
      throw StateError('Prepared runtime belongs to another producer.');
    }
    prepared._state = PreparedExecutionState.executing;
    try {
      final world = worldEngine.executePrepared(prepared._world,
          expectedOwner: expectedOwner,
          expectedRevision: expectedRevision,
          expectedProvenance: expectedProvenance);
      final result = AdvancedRuntimeSimulationResult(
          report: world.report,
          checkpoint: _checkpoint(
              world: world.checkpoint,
              transferController: prepared._transfer,
              managerController: prepared._manager));
      prepared._state = PreparedExecutionState.completed;
      return result;
    } catch (_) {
      prepared._state = PreparedExecutionState.failed;
      rethrow;
    }
  }

  AdvancedRuntimeCheckpoint _checkpoint({
    required WorldCheckpoint world,
    required AdvancedTransferController transferController,
    required ManagerCareerController managerController,
  }) =>
      AdvancedRuntimeCheckpoint(
        world: world,
        transfer: AdvancedTransferRuntimeState(
          activeContracts: transferController.activeContracts,
          contractEvents: transferController.contractEvents,
          activeLoans: transferController.activeLoans,
          loanHistory: transferController.loanHistory,
          installmentObligations: transferController.installmentObligations,
        ),
        manager: ManagerRuntimeState(
          managers: managerController.managers,
          assignments: managerController.finalAssignments,
          seasons: managerController.seasons,
        ),
      );
}
