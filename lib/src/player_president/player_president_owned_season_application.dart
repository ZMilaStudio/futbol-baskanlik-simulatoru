import '../core/simulation_config.dart';
import '../finance/club_finance_season.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../league/club.dart';
import '../manager/manager.dart';
import '../manager/player_president_manager_control.dart';
import '../promise/president_promise.dart';
import '../promise/player_president_promise_control.dart';
import '../promise/promise_season_snapshot.dart';
import '../season/weekly_world_fixture_result_core.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import 'player_president_interactive_decision_application_session.dart';
import 'player_president_accepted_promise_closing_projection.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_preseason_weekly_handoff.dart';
import 'player_president_prepared_season_dashboard_snapshot.dart';
import 'player_president_prepared_season_fixtures_snapshot.dart';
import 'player_president_prepared_squad_snapshot.dart';
import 'player_president_postseason_runtime_transition.dart';
import 'player_president_completed_season_league_table_snapshot.dart';
import 'player_president_completed_season_match_results_snapshot.dart';

/// Consumer observations, never M65 checkpoints or runtime capabilities.
sealed class PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonStep._();
}

final class PlayerPresidentOwnedSeasonPromisePending
    extends PlayerPresidentOwnedSeasonStep {
  PlayerPresidentOwnedSeasonPromisePending._(
    this.request, {
    this.hasManagerSeasonAuthority = false,
    Iterable<int> managerHistorySeasonIndices = const [],
  })  : managerHistorySeasonIndices =
            List.unmodifiable(managerHistorySeasonIndices),
        super._();

  /// The original M73 request; the consumer does not receive its boundary.
  final PlayerPresidentInteractiveDecisionRequest request;
  int get seasonIndex =>
      request.contextAs<PlayerPromiseDecisionContext>().seasonIndex;
  final bool hasManagerSeasonAuthority;
  final List<int> managerHistorySeasonIndices;
}

final class PlayerPresidentOwnedSeasonPromiseResolved
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonPromiseResolved._(this.consequence)
      : super._();

  /// The real M56 onApplied consequence, without a reconstructed effect.
  final PlayerPresidentPromiseConsequence consequence;
}

final class PlayerPresidentOwnedSeasonRunning
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonRunning._(this.fixtures) : super._();

  final WeeklyWorldFixtureSnapshot fixtures;
  int get seasonIndex => fixtures.seasonIndex;
  int get nextRound => fixtures.nextRound;
  int get completedMatchCount => fixtures.completedMatchCount;
  bool get isComplete => fixtures.isComplete;
}

/// An owned season boundary that can enter the real postseason lifecycle.
/// Historical B2 and future full-M65 settlement remain distinct types.
sealed class PlayerPresidentOwnedSeasonCompletion
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonCompletion._() : super._();
}

/// Historical squad-only B2; manager authority is unavailable by design.
/// This is deliberately not legacy M73 Completed or full-M65 settlement.
final class PlayerPresidentOwnedSeasonClosed
    extends PlayerPresidentOwnedSeasonCompletion {
  PlayerPresidentOwnedSeasonClosed._(this._source) : super._();

  final PlayerPresidentAcceptedPromiseClosingCandidate _source;
  int get seasonIndex => _source.seasonIndex;
  String get controlledClubId => _source.controlledClubId;
  ClubFinanceSeason get finance => _source.financeFor(controlledClubId);
  PromiseSeasonSnapshot get promise => _source.promiseFor(controlledClubId);

  /// B1 supplies fresh defensive views of mutable legacy standing rows.
  List<LeagueSeasonSnapshot> get leagueResults => _source.leagueResults;
}

/// Genuine future W30 finance settlement. Promise annual resolution is later,
/// in the production postseason domain stage; this is not a historical B2.
final class PlayerPresidentOwnedFutureSeasonSettled
    extends PlayerPresidentOwnedSeasonCompletion {
  PlayerPresidentOwnedFutureSeasonSettled._(this._committed, this._settlement)
      : managerHistorySeasonIndices = List.unmodifiable(_committed
            .managerAuthority.seasons
            .map((season) => season.seasonIndex)),
        super._() {
    final league = _committed.opening.opening.leagues.singleWhere(
      (league) => league.clubIds.contains(controlledClubId),
    );
    final report = _committed.reports
        .singleWhere((item) => item.tier == league.tier)
        .report;
    if (report.seasonIndex != seasonIndex) {
      throw StateError('Future completed observation has a foreign season.');
    }
    leagueTable =
        PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
      controlledClubId: controlledClubId,
      completedLeague: league,
      report: report,
    );
    matchResults =
        PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
      controlledClubId: controlledClubId,
      completedLeague: league,
      report: report,
    );
  }

  final PlayerPresidentFutureCommittedSeasonResult _committed;
  final FullM65CommittedSeasonSettlementResult _settlement;
  final List<int> managerHistorySeasonIndices;
  int get seasonIndex => _committed.targetSeasonIndex;
  String get controlledClubId => _committed.opening.controlledClubId;
  ClubFinanceSeason get finance => _settlement.receipt.results
      .singleWhere((row) => row.clubId == controlledClubId);
  WeeklyWorldFixtureSnapshot get fixtures => _committed.w30;

  /// Existing M96/M97 immutable projections of the actual completed league.
  late final PlayerPresidentCompletedSeasonLeagueTableSnapshot leagueTable;
  late final PlayerPresidentCompletedSeasonMatchResultsSnapshot matchResults;
}

final class PlayerPresidentOwnedSeasonTransferPending
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonTransferPending._(this.context) : super._();
  final PlayerTransferStrategyDecisionContext context;
}

final class PlayerPresidentOwnedSeasonManagerReviewPending
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonManagerReviewPending._(this.context)
      : super._();
  final PlayerManagerReviewContext context;
}

final class PlayerPresidentOwnedSeasonManagerReplacementPending
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonManagerReplacementPending._(this.context)
      : super._();
  final PlayerManagerReplacementContext context;
}

final class PlayerPresidentOwnedSeasonTicketPending
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonTicketPending._(this.context) : super._();
  final PlayerPresidentTicketPricingDecisionContext context;
}

/// Publication observation only. The lossless recipient stays private.
final class PlayerPresidentOwnedSeasonContinuationReady
    extends PlayerPresidentOwnedSeasonStep {
  PlayerPresidentOwnedSeasonContinuationReady._(
      LosslessPostOffseasonRuntimeGraph graph)
      : nextSeasonIndex = graph.targetSeasonIndex,
        completedSeasonIndex = graph.targetSeasonIndex - 1,
        control = graph.control,
        managerHistorySeasonIndices = List.unmodifiable(graph
            .managerEvidence.completedSeasons
            .map((season) => season.seasonIndex)),
        super._();
  final int nextSeasonIndex;
  final int completedSeasonIndex;
  final PlayerPresidentTenureControlState control;
  final List<int> managerHistorySeasonIndices;
}

final class PlayerPresidentOwnedCareerEnded
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedCareerEnded._(
      this.completedSeasonIndex, this.control)
      : super._();
  final int completedSeasonIndex;
  final PlayerPresidentTenureControlState control;
}

enum PlayerPresidentOwnedSeasonFailureStage {
  settlement,
  postseason,
  activation
}

/// An attempted single-pass lifecycle failed. There is no replay/retry command.
final class PlayerPresidentOwnedSeasonFailed
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonFailed._(this.stage) : super._();
  final PlayerPresidentOwnedSeasonFailureStage stage;
}

/// Opt-in, runtime-only application entry for one genuinely owned career.
///
/// Owns the original application for its entire lifetime. It cannot adopt a
/// caller's legacy Completed, checkpoint, restored runtime, or closing candidate.
/// Commands consume the exact currently published observation, so a stale UI
/// event cannot answer another career or advance an extra round.
///
/// Persistence is intentionally unavailable: the underlying owned preseason
/// already rejects M75 and M80. This API must not replace the mobile save/load
/// route without an explicit product decision. B3-B continuation retains the
/// same application and original runtime graph. No historical manager authority
/// is synthesized, and no raw capability or ownership recipient is exposed.
final class PlayerPresidentOwnedSeasonApplication {
  PlayerPresidentOwnedSeasonApplication._(this._application, this._boundary)
      : _step = PlayerPresidentOwnedSeasonPromisePending._(
          _boundary.pending!.request,
        );

  factory PlayerPresidentOwnedSeasonApplication.start({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int electionInterval = 4,
  }) {
    final application =
        PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: true,
    );
    final boundary = application.startPreseasonPromise(
      sourceClubs: clubs,
      sourceLeagues: leagues,
    );
    return PlayerPresidentOwnedSeasonApplication._(application, boundary);
  }

  final PlayerPresidentInteractiveDecisionApplicationSession _application;
  final PlayerPresidentPreseasonPromiseBoundary _boundary;
  PlayerPresidentOwnedSeasonStep _step;
  PlayerPresidentPreseasonWeeklyState? _weekly;
  PlayerPresidentActiveFutureSeasonOpening? _futureOpening;
  PlayerPresidentFutureWeeklyState? _futureWeekly;
  PlayerPresidentFutureCommittedSeasonResult? _committed;
  FullM65RuntimeEconomyContinuationAuthority? _economy;
  RuntimeEconomyTicketPending? _ticketPending;
  SinglePassPostseasonRuntimeTransition? _transition;
  PostseasonTransferPending? _transferPending;
  PostseasonManagerPending? _managerPending;
  LosslessPostOffseasonRuntimeGraph? _continuation;

  PlayerPresidentOwnedSeasonStep get currentStep => _step;

  /// The most recently opened season, captured before its promise acceptance.
  /// Existing prepared getters below intentionally keep their initial meaning.
  PlayerPresidentPreparedSeasonOpeningSnapshot get currentSeasonOpening =>
      _application.preparedSeasonOpening;

  /// Initial historical opening observations, never current future-season state.
  PlayerPresidentPreparedSeasonDashboardSnapshot get preparedSeasonDashboard =>
      _application.preparedSeasonDashboard;

  /// Initial historical squad, not a projection of the active future roster.
  PlayerPresidentPreparedSquadSnapshot get preparedSquad =>
      _application.preparedSquad;

  /// Initial historical fixture plan; current fixtures belong to Running.
  PlayerPresidentPreparedSeasonFixturesSnapshot get preparedSeasonFixtures =>
      _application.preparedSeasonFixtures;

  PlayerPresidentOwnedSeasonPromiseResolved submitPromise({
    required PlayerPresidentOwnedSeasonPromisePending expected,
    required PresidentPromiseType choice,
  }) {
    _requireCurrent(expected);
    final opening = _futureOpening;
    final consequence = opening == null
        ? _boundary
            .submit(
              pending: _boundary.pending!,
              request: expected.request,
              choice: choice,
            )
            .consequence
        : _application
            .acceptFuturePromise(
              expectedOpening: opening,
              expectedPending: opening.promisePending,
              expectedRequest: expected.request,
              choice: choice,
            )
            .consequence;
    final resolved = PlayerPresidentOwnedSeasonPromiseResolved._(consequence);
    _step = resolved;
    return resolved;
  }

  /// Opens W0 only after the consumer acknowledges the real promise result.
  PlayerPresidentOwnedSeasonRunning continueAfterPromise({
    required PlayerPresidentOwnedSeasonPromiseResolved expected,
  }) {
    _requireCurrent(expected);
    if (_futureOpening != null) {
      final weekly = _application.futureWeeklyState!;
      _futureWeekly = weekly;
      return _publishFixtures(weekly.fixtureSnapshot);
    }
    final weekly = _application.openPreseasonWeeklyHandoff();
    return _publishWeekly(weekly);
  }

  PlayerPresidentOwnedSeasonRunning advanceRound({
    required PlayerPresidentOwnedSeasonRunning expected,
  }) {
    _requireCurrent(expected);
    if (_futureOpening != null) {
      final previous = _futureWeekly!;
      final weekly = _application.advanceFutureWeek(
        expectedState: previous,
        expectedRound: previous.nextRound,
      );
      _futureWeekly = weekly;
      return _publishFixtures(weekly.fixtureSnapshot);
    }
    final previous = _weekly!;
    final weekly = _application.advancePreseasonWeek(
      expectedState: previous,
      expectedRound: previous.nextRound,
    );
    return _publishWeekly(weekly);
  }

  /// Delegates W30 -> B1 -> B2 once. No annual replay, manager history,
  /// checkpoint, finance formula or postseason orchestration is invented here.
  PlayerPresidentOwnedSeasonClosed closeSeason({
    required PlayerPresidentOwnedSeasonRunning expected,
  }) {
    _requireCurrent(expected);
    if (_futureOpening != null) {
      throw StateError('Future W30 requires genuine economy settlement.');
    }
    final result = _application.projectCommittedSeason(
      expectedState: _weekly!,
    );
    final closing = _application.closeAcceptedPromises(
      expectedResultCandidate: result,
    );
    final closed = PlayerPresidentOwnedSeasonClosed._(closing);
    _step = closed;
    return closed;
  }

  /// Admits the exact owned future W30 to its original full-M65 economy.
  PlayerPresidentOwnedSeasonStep completeFutureSeason({
    required PlayerPresidentOwnedSeasonRunning expected,
  }) {
    _requireCurrent(expected);
    if (_futureOpening == null || !expected.isComplete) {
      throw StateError('Settlement requires a completed owned future season.');
    }
    try {
      final committed =
          _application.commitFutureSeason(expectedW30: _futureWeekly!);
      _committed = committed;
      final economy =
          _application.handoffFutureEconomy(expectedCommitted: committed);
      _economy = economy;
      final state = economy.prepareSettlement(committed.capability);
      if (state == RuntimeEconomyState.awaitingTicketDecision) {
        final pending = economy.pending!;
        _ticketPending = pending;
        return _step =
            PlayerPresidentOwnedSeasonTicketPending._(pending.context);
      }
      if (state != RuntimeEconomyState.ready) {
        throw StateError('Owned economy decision contract is unavailable.');
      }
      return _settleFuture();
    } catch (_) {
      _step = const PlayerPresidentOwnedSeasonFailed._(
          PlayerPresidentOwnedSeasonFailureStage.settlement);
      rethrow;
    }
  }

  PlayerPresidentOwnedFutureSeasonSettled submitTicket({
    required PlayerPresidentOwnedSeasonTicketPending expected,
    required MatchdayTicketPricingChoice choice,
  }) {
    _requireCurrent(expected);
    // The existing authority validates the exact Pending and choice before it
    // consumes the answer. A rejected answer preserves this consumer step.
    _economy!.submitTicket(_ticketPending!, choice,
        expectedRevision: _economy!.revision);
    return _settleFuture();
  }

  PlayerPresidentOwnedFutureSeasonSettled _settleFuture() {
    try {
      final settlement = _economy!.executeSettlement(
        expectedCommitted: _committed!.capability,
      );
      final settled =
          PlayerPresidentOwnedFutureSeasonSettled._(_committed!, settlement);
      _step = settled;
      return settled;
    } catch (_) {
      _step = const PlayerPresidentOwnedSeasonFailed._(
          PlayerPresidentOwnedSeasonFailureStage.settlement);
      rethrow;
    }
  }

  PlayerPresidentOwnedSeasonStep continueToNextSeason({
    required PlayerPresidentOwnedSeasonCompletion expected,
  }) {
    _requireCurrent(expected);
    try {
      final transition = switch (expected) {
        PlayerPresidentOwnedSeasonClosed() => _application
            .startPostseasonTransition(expectedSource: expected._source),
        PlayerPresidentOwnedFutureSeasonSettled() =>
          _application.startFuturePostseasonTransition(
              expectedSettlement: expected._settlement, hasNextSeason: true),
      };
      _transition = transition;
      final pending = transition.prepareTransfer();
      _transferPending = pending;
      if (pending != null) {
        return _step =
            PlayerPresidentOwnedSeasonTransferPending._(pending.context);
      }
      return _finishPostseason();
    } catch (_) {
      _failPostseason();
      rethrow;
    }
  }

  PlayerPresidentOwnedSeasonStep submitTransfer({
    required PlayerPresidentOwnedSeasonTransferPending expected,
    required PlayerTransferStrategyChoice choice,
  }) {
    _requireCurrent(expected);
    try {
      _transition!
          .submitTransfer(expectedPending: _transferPending!, choice: choice);
    } catch (_) {
      _recordTerminalPostseasonFailure();
      rethrow;
    }
    return _finishPostseason();
  }

  PlayerPresidentOwnedSeasonStep _finishPostseason() {
    try {
      final transition = _transition!;
      transition.prepareDomain();
      transition.prepareOuterSuccessor();
      final manager = transition.managerPending;
      _managerPending = manager;
      if (transition.phase ==
          PostseasonRuntimeTransitionPhase.managerPreparationPending) {
        final replacement = manager!.replacement;
        return _step = replacement == null
            ? PlayerPresidentOwnedSeasonManagerReviewPending._(manager.review)
            : PlayerPresidentOwnedSeasonManagerReplacementPending._(
                replacement);
      }
      return _publishContinuation();
    } catch (_) {
      _failPostseason();
      rethrow;
    }
  }

  PlayerPresidentOwnedSeasonStep submitManagerReview({
    required PlayerPresidentOwnedSeasonManagerReviewPending expected,
    required PlayerManagerReviewChoice choice,
  }) {
    _requireCurrent(expected);
    PostseasonManagerPending? replacement;
    try {
      replacement = _transition!.submitManagerReview(
          expectedPending: _managerPending!, choice: choice);
    } catch (_) {
      _recordTerminalPostseasonFailure();
      rethrow;
    }
    if (replacement != null) {
      _managerPending = replacement;
      return _step = PlayerPresidentOwnedSeasonManagerReplacementPending._(
          replacement.replacement!);
    }
    return _publishContinuation();
  }

  PlayerPresidentOwnedSeasonStep submitManagerReplacement({
    required PlayerPresidentOwnedSeasonManagerReplacementPending expected,
    required Manager selected,
  }) {
    _requireCurrent(expected);
    try {
      _transition!.submitManagerReplacement(
          expectedPending: _managerPending!, selected: selected);
    } catch (_) {
      _recordTerminalPostseasonFailure();
      rethrow;
    }
    return _publishContinuation();
  }

  PlayerPresidentOwnedSeasonStep _publishContinuation() {
    try {
      final graph = _futureOpening == null
          ? _application.publishPostseasonContinuation(
              expectedTransition: _transition!)
          : _application.publishFuturePostseasonContinuation(
              expectedTransition: _transition!);
      _continuation = graph;
      if (graph.control.lost) {
        return _step = PlayerPresidentOwnedCareerEnded._(
            graph.targetSeasonIndex - 1, graph.control);
      }
      return _step = PlayerPresidentOwnedSeasonContinuationReady._(graph);
    } catch (_) {
      _failPostseason();
      rethrow;
    }
  }

  PlayerPresidentOwnedSeasonPromisePending activateNextSeason({
    required PlayerPresidentOwnedSeasonContinuationReady expected,
  }) {
    _requireCurrent(expected);
    try {
      final graph = _continuation!;
      if (_futureOpening != null) {
        _application.activateNextFutureSeason(expectedContinuation: graph);
      }
      final entry = _application.claimFutureRuntimeEntry(
        expectedSource: graph,
        expectedSourceRevision: graph.revision,
        expectedOrigin: graph.origin,
        expectedTargetSeason: graph.targetSeasonIndex,
      );
      final prepared = _application.prepareFutureRuntime(expectedEntry: entry);
      final opening = _application.openFutureSeason(
        expectedAdmission: _application.futureRuntimeAdmission!,
        expectedPrepared: prepared,
      );
      final pending = PlayerPresidentOwnedSeasonPromisePending._(
        opening.promisePending.request,
        hasManagerSeasonAuthority: true,
        managerHistorySeasonIndices: opening.managerAuthority.seasons
            .map((season) => season.seasonIndex),
      );
      _futureOpening = opening;
      _futureWeekly = null;
      _committed = null;
      _economy = null;
      _ticketPending = null;
      _transition = null;
      _transferPending = null;
      _managerPending = null;
      _continuation = null;
      _step = pending;
      return pending;
    } catch (_) {
      _step = const PlayerPresidentOwnedSeasonFailed._(
          PlayerPresidentOwnedSeasonFailureStage.activation);
      rethrow;
    }
  }

  void _recordTerminalPostseasonFailure() {
    if (_transition?.phase == PostseasonRuntimeTransitionPhase.failed) {
      _failPostseason();
    }
  }

  void _failPostseason() {
    _step = const PlayerPresidentOwnedSeasonFailed._(
        PlayerPresidentOwnedSeasonFailureStage.postseason);
  }

  PlayerPresidentOwnedSeasonRunning _publishWeekly(
    PlayerPresidentPreseasonWeeklyState weekly,
  ) {
    _weekly = weekly;
    return _publishFixtures(weekly.fixtureSnapshot);
  }

  PlayerPresidentOwnedSeasonRunning _publishFixtures(
      WeeklyWorldFixtureSnapshot snapshot) {
    final running = PlayerPresidentOwnedSeasonRunning._(snapshot);
    _step = running;
    return running;
  }

  void _requireCurrent(PlayerPresidentOwnedSeasonStep expected) {
    if (!identical(expected, _step)) {
      throw StateError('Foreign or stale owned-season application step.');
    }
  }
}
