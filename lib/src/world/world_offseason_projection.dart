import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../player/team_strength_calculator.dart';
import '../transfer/transfer_deal.dart';
import '../transfer/transfer_market_engine.dart';
import '../transfer/transfer_market_result.dart';
import '../transfer/president_transfer_strategy_world_bridge.dart';
import 'world_league.dart';
import 'world_roster_hooks.dart';
import 'world_transfer_hooks.dart';

class WorldOffseasonProjectionResult {
  WorldOffseasonProjectionResult({
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
    required Iterable<Player> retired,
    required Iterable<Player> youthIntake,
    required Iterable<TransferDeal> transfers,
    required Iterable<TransferCashMovement> cashMovements,
    required Iterable<WorldLeague> nextLeagues,
  })  : players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates),
        retired = List.unmodifiable(retired),
        youthIntake = List.unmodifiable(youthIntake),
        transfers = List.unmodifiable(transfers),
        cashMovements = List.unmodifiable(cashMovements),
        nextLeagues = List.unmodifiable(nextLeagues);
  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final List<Player> retired;
  final List<Player> youthIntake;
  final List<TransferDeal> transfers;
  final List<TransferCashMovement> cashMovements;
  final List<WorldLeague> nextLeagues;
}

/// Shared legacy ordering. Terminal calls intentionally do no lifecycle work.
class WorldOffseasonProjection {
  const WorldOffseasonProjection({
    this.lifecycleEngine = const PlayerLifecycleEngine(),
    this.strengthCalculator = const TeamStrengthCalculator(),
    this.transferMarketEngine = const TransferMarketEngine(),
  });
  final PlayerLifecycleEngine lifecycleEngine;
  final TeamStrengthCalculator strengthCalculator;
  final TransferMarketEngine transferMarketEngine;

  /// Calculation seam, not an application/source authority constructor.
  /// The caller must already own detached hooks before starting this attempt.
  WorldOffseasonAttempt beginAttempt({
    required int seasonIndex,
    required SimulationConfig config,
    required List<Player> players,
    required List<Club> baseClubs,
    required List<Club> squadClubs,
    required List<ClubFinanceState> closingFinanceStates,
    required List<WorldLeague> nextLeagues,
    required WorldRosterHooks rosterHooks,
    required WorldTransferHooks transferHooks,
    required bool enableTransferInstallments,
  }) =>
      WorldOffseasonAttempt._(
        projection: this,
        seasonIndex: seasonIndex,
        config: config,
        players: players,
        baseClubs: baseClubs,
        squadClubs: squadClubs,
        closingFinanceStates: closingFinanceStates,
        nextLeagues: nextLeagues,
        rosterHooks: rosterHooks,
        transferHooks: transferHooks,
        enableTransferInstallments: enableTransferInstallments,
      );

  WorldOffseasonProjectionResult project({
    required bool hasNextSeason,
    required int seasonIndex,
    required SimulationConfig config,
    required List<Player> players,
    required List<Club> baseClubs,
    required List<Club> squadClubs,
    required List<ClubFinanceState> closingFinanceStates,
    required List<WorldLeague> nextLeagues,
    required WorldRosterHooks rosterHooks,
    required WorldTransferHooks transferHooks,
    required bool enableTransferInstallments,
  }) {
    if (!hasNextSeason)
      return WorldOffseasonProjectionResult(
        players: List.unmodifiable(players),
        financeStates: List.unmodifiable(closingFinanceStates),
        retired: const [],
        youthIntake: const [],
        transfers: const [],
        cashMovements: const [],
        nextLeagues: nextLeagues,
      );
    final attempt = beginAttempt(
      seasonIndex: seasonIndex,
      config: config,
      players: players,
      baseClubs: baseClubs,
      squadClubs: squadClubs,
      closingFinanceStates: closingFinanceStates,
      nextLeagues: nextLeagues,
      rosterHooks: rosterHooks,
      transferHooks: transferHooks,
      enableTransferInstallments: enableTransferInstallments,
    );
    attempt.prepareLifecycle();
    attempt.prepareRoster();
    attempt.prepareStrength();
    attempt.prepareContractYears();
    attempt.executeMarket();
    attempt.completeContractCallback();
    return attempt.completeFollowup();
  }
}

enum WorldOffseasonAttemptPhase {
  opening,
  lifecycle,
  roster,
  strength,
  contracts,
  market,
  callback,
  completed,
  failed,
}

/// Cached, single-pass calculation state. This is deliberately NOT a source
/// capability: possession of raw world values cannot mint runtime authority.
final class WorldOffseasonAttempt {
  WorldOffseasonAttempt._({
    required this.projection,
    required this.seasonIndex,
    required this.config,
    required this.players,
    required this.baseClubs,
    required this.squadClubs,
    required this.closingFinanceStates,
    required this.nextLeagues,
    required WorldRosterHooks rosterHooks,
    required WorldTransferHooks transferHooks,
    required this.enableTransferInstallments,
  })  : _rosterHooks = rosterHooks,
        _transferHooks = transferHooks;

  final WorldOffseasonProjection projection;
  final int seasonIndex;
  final SimulationConfig config;
  final List<Player> players;
  final List<Club> baseClubs;
  final List<Club> squadClubs;
  final List<ClubFinanceState> closingFinanceStates;
  final List<WorldLeague> nextLeagues;
  final WorldRosterHooks _rosterHooks;
  final WorldTransferHooks _transferHooks;
  final bool enableTransferInstallments;
  WorldOffseasonAttemptPhase _phase = WorldOffseasonAttemptPhase.opening;
  WorldOffseasonAttemptPhase get phase => _phase;
  PlayerLifecycleResult? _lifecycle;
  List<Player>? _preparedPlayers;
  List<Club>? _clubs;
  Map<String, int>? _contractYears;
  TransferMarketResult? _market;
  PresidentTransferStrategyWindowContext? _strategyContext;
  WorldOffseasonProjectionResult? _result;
  List<Player> get preparedPlayers =>
      _preparedPlayers ?? (throw StateError('Roster is not prepared.'));
  List<Club> get transferClubs =>
      _clubs ?? (throw StateError('Strength is not prepared.'));
  Map<String, int>? get contractYears {
    if (_phase.index < WorldOffseasonAttemptPhase.contracts.index ||
        _phase == WorldOffseasonAttemptPhase.failed) {
      throw StateError('Contracts are not prepared.');
    }
    return _contractYears;
  }

  T _run<T>(WorldOffseasonAttemptPhase expected,
      WorldOffseasonAttemptPhase next, T Function() operation) {
    if (_phase != expected)
      throw StateError('Unexpected offseason phase $_phase.');
    try {
      final value = operation();
      _phase = next;
      return value;
    } catch (_) {
      _phase = WorldOffseasonAttemptPhase.failed;
      rethrow;
    }
  }

  PlayerLifecycleResult prepareLifecycle() => _run(
        WorldOffseasonAttemptPhase.opening,
        WorldOffseasonAttemptPhase.lifecycle,
        () => _lifecycle = projection.lifecycleEngine.advance(
          currentPlayers: players,
          currentClubs: squadClubs,
          referenceClubs: baseClubs,
          careerSeed: config.careerSeed,
          nextSeasonIndex: seasonIndex + 1,
          simulationVersion: config.simulationVersion,
        ),
      );

  List<Player> prepareRoster() => _run(
        WorldOffseasonAttemptPhase.lifecycle,
        WorldOffseasonAttemptPhase.roster,
        () => _preparedPlayers = _rosterHooks.prepareNextSeasonPlayers(
          seasonIndex: seasonIndex,
          nextSeasonIndex: seasonIndex + 1,
          activePlayers: _lifecycle!.activePlayers,
          retiredPlayers: _lifecycle!.retiredPlayers,
          youthIntake: _lifecycle!.youthIntake,
          clubs: squadClubs,
          leaguesForNextSeason: nextLeagues,
          financeStates: closingFinanceStates,
        ),
      );

  List<Club> prepareStrength() => _run(
        WorldOffseasonAttemptPhase.roster,
        WorldOffseasonAttemptPhase.strength,
        () => _clubs = projection.strengthCalculator.deriveClubs(
          baseClubs: baseClubs,
          players: preparedPlayers,
        ),
      );

  Map<String, int>? prepareContractYears() => _run(
        WorldOffseasonAttemptPhase.strength,
        WorldOffseasonAttemptPhase.contracts,
        () {
          final years = _rosterHooks.contractYearsRemainingForTransfer(
            nextSeasonIndex: seasonIndex + 1,
            players: preparedPlayers,
          );
          return _contractYears = years;
        },
      );

  PresidentTransferStrategyWindowContext prepareStrategyContext() {
    if (_phase != WorldOffseasonAttemptPhase.contracts ||
        _strategyContext != null) {
      throw StateError('Transfer context requires the exact prepared prefix.');
    }
    final engine = projection.transferMarketEngine;
    if (engine is! PresidentTransferStrategyWorldMarketEngine) {
      throw StateError('Transfer strategy decision contract is unavailable.');
    }
    try {
      return _strategyContext = engine.prepareContext(
        clubs: transferClubs,
        players: preparedPlayers,
        financeStates: closingFinanceStates,
        careerSeed: config.careerSeed,
        seasonIndex: seasonIndex,
        simulationVersion: config.simulationVersion,
      );
    } catch (_) {
      _phase = WorldOffseasonAttemptPhase.failed;
      rethrow;
    }
  }

  TransferMarketResult executePreparedStrategy({
    required PresidentTransferStrategyWindowContext expectedContext,
    required Map<String, PresidentManagementProfile> acceptedProfiles,
  }) {
    // Reject an invalid command before entering the once-only execution phase.
    if (_strategyContext == null ||
        !identical(_strategyContext, expectedContext)) {
      throw StateError('Foreign or unprepared transfer window context.');
    }
    return _run(
      WorldOffseasonAttemptPhase.contracts,
      WorldOffseasonAttemptPhase.market,
      () => _market = (projection.transferMarketEngine
              as PresidentTransferStrategyWorldMarketEngine)
          .executeContext(
        context: expectedContext,
        profiles: acceptedProfiles,
        contractYearsRemainingByPlayer: _contractYears,
        enableInstallments: enableTransferInstallments,
      ),
    );
  }

  TransferMarketResult executeMarket() {
    if (_strategyContext != null) {
      throw StateError(
          'A prepared player window requires its accepted profiles.');
    }
    return _run(
      WorldOffseasonAttemptPhase.contracts,
      WorldOffseasonAttemptPhase.market,
      () => _market = projection.transferMarketEngine.simulateWindow(
        clubs: transferClubs,
        players: preparedPlayers,
        financeStates: closingFinanceStates,
        careerSeed: config.careerSeed,
        seasonIndex: seasonIndex,
        simulationVersion: config.simulationVersion,
        contractYearsRemainingByPlayer: _contractYears,
        enableInstallments: enableTransferInstallments,
      ),
    );
  }

  void completeContractCallback() => _run(
        WorldOffseasonAttemptPhase.market,
        WorldOffseasonAttemptPhase.callback,
        () => _rosterHooks.onTransferWindowCompleted(
          seasonIndex: seasonIndex,
          nextSeasonIndex: seasonIndex + 1,
          playersBeforeWindow: preparedPlayers,
          playersAfterWindow: _market!.players,
          transfers: _market!.deals,
          clubs: transferClubs,
          leaguesForNextSeason: nextLeagues,
          financeStates: _market!.financeStates,
        ),
      );

  WorldOffseasonProjectionResult completeFollowup() => _run(
        WorldOffseasonAttemptPhase.callback,
        WorldOffseasonAttemptPhase.completed,
        () {
          final post = _transferHooks.afterPermanentTransfers(
            seasonIndex: seasonIndex,
            nextSeasonIndex: seasonIndex + 1,
            players: _market!.players,
            financeStates: _market!.financeStates,
            permanentTransfers: _market!.deals,
            clubs: transferClubs,
            leaguesForNextSeason: nextLeagues,
          );
          return _result = WorldOffseasonProjectionResult(
            players: post.players,
            financeStates: post.financeStates,
            retired: _lifecycle!.retiredPlayers,
            youthIntake: _lifecycle!.youthIntake,
            transfers: _market!.deals,
            cashMovements: post.cashMovements,
            nextLeagues: nextLeagues,
          );
        },
      );

  WorldOffseasonProjectionResult get result =>
      _result ?? (throw StateError('Offseason has not completed.'));
}
