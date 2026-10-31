import '../core/simulation_config.dart';
import '../finance/club_finance_season.dart';
import '../league/club.dart';
import '../promise/president_promise.dart';
import '../promise/promise_season_snapshot.dart';
import '../season/weekly_world_fixture_result_core.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_application_session.dart';
import 'player_president_accepted_promise_closing_projection.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_preseason_weekly_handoff.dart';
import 'player_president_prepared_season_dashboard_snapshot.dart';
import 'player_president_prepared_season_fixtures_snapshot.dart';
import 'player_president_prepared_squad_snapshot.dart';

/// Consumer observations, never M65 checkpoints or runtime capabilities.
sealed class PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonStep._();
}

final class PlayerPresidentOwnedSeasonPromisePending
    extends PlayerPresidentOwnedSeasonStep {
  const PlayerPresidentOwnedSeasonPromisePending._(this.request) : super._();

  /// The original M73 request; the consumer does not receive its boundary.
  final PlayerPresidentInteractiveDecisionRequest request;
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

/// A historical squad-only closing observation. Manager authority remains
/// unavailable by design. This is deliberately not legacy M73 Completed.
final class PlayerPresidentOwnedSeasonClosed
    extends PlayerPresidentOwnedSeasonStep {
  PlayerPresidentOwnedSeasonClosed._(this._source) : super._();

  final PlayerPresidentAcceptedPromiseClosingCandidate _source;
  int get seasonIndex => _source.seasonIndex;
  String get controlledClubId => _source.controlledClubId;
  ClubFinanceSeason get finance => _source.financeFor(controlledClubId);
  PromiseSeasonSnapshot get promise => _source.promiseFor(controlledClubId);

  /// B1 supplies fresh defensive views of mutable legacy standing rows.
  List<LeagueSeasonSnapshot> get leagueResults => _source.leagueResults;
}

/// Opt-in, runtime-only application entry for the genuinely owned first season.
///
/// Owns the original application for its entire lifetime. It cannot adopt a
/// caller's legacy Completed, checkpoint, restored runtime, or closing candidate.
/// Commands consume the exact currently published observation, so a stale UI
/// event cannot answer another career or advance an extra round.
///
/// Persistence is intentionally unavailable: the underlying owned preseason
/// already rejects M75 and M80. This API must not replace the mobile save/load
/// route without an explicit product decision. This first-season consumer API
/// ends at B2; it does not yet expose B3-B continuation. No historical manager
/// authority is synthesized.
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

  PlayerPresidentOwnedSeasonStep get currentStep => _step;

  PlayerPresidentPreparedSeasonDashboardSnapshot get preparedSeasonDashboard =>
      _application.preparedSeasonDashboard;
  PlayerPresidentPreparedSquadSnapshot get preparedSquad =>
      _application.preparedSquad;
  PlayerPresidentPreparedSeasonFixturesSnapshot get preparedSeasonFixtures =>
      _application.preparedSeasonFixtures;

  PlayerPresidentOwnedSeasonPromiseResolved submitPromise({
    required PlayerPresidentOwnedSeasonPromisePending expected,
    required PresidentPromiseType choice,
  }) {
    _requireCurrent(expected);
    final accepted = _boundary.submit(
      pending: _boundary.pending!,
      request: expected.request,
      choice: choice,
    );
    final resolved =
        PlayerPresidentOwnedSeasonPromiseResolved._(accepted.consequence);
    _step = resolved;
    return resolved;
  }

  /// Opens W0 only after the consumer acknowledges the real promise result.
  PlayerPresidentOwnedSeasonRunning continueAfterPromise({
    required PlayerPresidentOwnedSeasonPromiseResolved expected,
  }) {
    _requireCurrent(expected);
    final weekly = _application.openPreseasonWeeklyHandoff();
    return _publishWeekly(weekly);
  }

  PlayerPresidentOwnedSeasonRunning advanceRound({
    required PlayerPresidentOwnedSeasonRunning expected,
  }) {
    _requireCurrent(expected);
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

  PlayerPresidentOwnedSeasonRunning _publishWeekly(
    PlayerPresidentPreseasonWeeklyState weekly,
  ) {
    final running = PlayerPresidentOwnedSeasonRunning._(weekly.fixtureSnapshot);
    _weekly = weekly;
    _step = running;
    return running;
  }

  void _requireCurrent(PlayerPresidentOwnedSeasonStep expected) {
    if (!identical(expected, _step)) {
      throw StateError('Foreign or stale owned-season application step.');
    }
  }
}
