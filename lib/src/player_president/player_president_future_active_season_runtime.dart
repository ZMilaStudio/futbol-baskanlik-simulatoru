part of 'player_president_interactive_decision_application_session.dart';

/// Private-minted application proof used by the M73/M56 future acceptance
/// kernel. The request key is evidence, never authority by itself.
final class ApplicationFuturePromiseAcceptanceClaim {
  ApplicationFuturePromiseAcceptanceClaim._(this.application, this.opening);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentActiveFutureSeasonOpening opening;

  void validate({
    required PlayerPresidentInteractiveDecisionPending pending,
    required PlayerPresidentInteractiveDecisionRequest request,
  }) {
    if (!identical(application._activeFutureSeasonOpening, opening) ||
        !identical(opening.application, application) ||
        !identical(opening.promisePending, pending) ||
        !identical(pending.request, request) ||
        !identical(request.context, opening.controlledPromiseContext) ||
        request.kind != PlayerPresidentInteractiveDecisionKind.promise ||
        request.sequence != 1 ||
        request.phase != 'preseasonPromise' ||
        request.clubId != opening.controlledClubId ||
        request.contextSignature !=
            opening.controlledPromiseContext.signature ||
        request.keyNamespace == null ||
        !request.keyNamespace!.startsWith(
          'future-preseason-promise/v1:s${opening.targetSeasonIndex}:',
        )) {
      throw StateError('Foreign or stale future promise Pending.');
    }
  }
}

final class PlayerPresidentFuturePromiseApplied {
  PlayerPresidentFuturePromiseApplied._(
    this.application,
    this.opening,
    this.acceptance,
  );
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentActiveFutureSeasonOpening opening;
  final PlayerPresidentFuturePromiseAcceptance acceptance;
  PlayerPresidentInteractiveDecisionRequest get request => acceptance.request;
  PresidentPromiseType get acceptedChoice => acceptance.choice;
  PlayerPresidentPromiseConsequence get consequence => acceptance.consequence;
  List<PresidentPromise> get activePromises => acceptance.activePromises;
  WeeklyWorldFixtureSnapshot get w0 => opening.w0;
  PreparedTicketRuntimeSeason get prepared => opening.prepared;
  ManagerSeasonAuthority get managerAuthority => opening.managerAuthority;
  int get targetSeasonIndex => opening.targetSeasonIndex;
  PostoffseasonRuntimeOrigin get origin => opening.origin;
}

final class PlayerPresidentFutureWeeklyState {
  PlayerPresidentFutureWeeklyState._({
    required this.application,
    required this.applied,
    required this.fixtureSnapshot,
    this.predecessor,
    this.committedRound,
  });
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentFuturePromiseApplied applied;
  final WeeklyWorldFixtureSnapshot fixtureSnapshot;
  final PlayerPresidentFutureWeeklyState? predecessor;
  final int? committedRound;
  PlayerPresidentActiveFutureSeasonOpening get opening => applied.opening;
  PreparedTicketRuntimeSeason get prepared => applied.prepared;
  ManagerSeasonAuthority get managerAuthority => applied.managerAuthority;
  List<PresidentPromise> get activePromises => applied.activePromises;
  int get targetSeasonIndex => applied.targetSeasonIndex;
  PostoffseasonRuntimeOrigin get origin => applied.origin;
  int get nextRound => fixtureSnapshot.nextRound;
  int get completedMatchCount => fixtureSnapshot.completedMatchCount;
  bool get isComplete => fixtureSnapshot.isComplete;
}

final class PlayerPresidentFutureCommittedSeasonResult {
  PlayerPresidentFutureCommittedSeasonResult._({
    required this.application,
    required this.weeklyState,
    required List<LeagueSeasonSnapshot> reports,
  }) : reports = List.unmodifiable(reports);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentFutureWeeklyState weeklyState;
  final List<LeagueSeasonSnapshot> reports;
  late final CommittedSeasonSettlementCapability capability;
  PlayerPresidentFuturePromiseApplied get applied => weeklyState.applied;
  PlayerPresidentActiveFutureSeasonOpening get opening => applied.opening;
  PreparedTicketRuntimeSeason get prepared => applied.prepared;
  ManagerSeasonAuthority get managerAuthority => applied.managerAuthority;
  int get targetSeasonIndex => applied.targetSeasonIndex;
  PostoffseasonRuntimeOrigin get origin => applied.origin;
  WeeklyWorldFixtureSnapshot get w30 => weeklyState.fixtureSnapshot;
}

/// Exact application claim for a detached single-round calculation.
final class ApplicationFutureWeeklyClaim {
  ApplicationFutureWeeklyClaim._(
    this.application,
    this.current,
    this.expectedRound,
  );
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentFutureWeeklyState current;
  final int expectedRound;
  PlayerPresidentActiveFutureSeasonOpening get opening => current.opening;

  void validatePrepared(PreparedTicketRuntimeSeason source) {
    if (!identical(application._futureWeeklyState, current) ||
        !identical(application._futurePromiseApplied, current.applied) ||
        !identical(application._activeFutureSeasonOpening, opening) ||
        !identical(source, current.prepared) ||
        expectedRound != current.fixtureSnapshot.nextRound ||
        current.fixtureSnapshot.isComplete) {
      throw StateError('Foreign, stale or completed future weekly claim.');
    }
  }
}

final class ApplicationFutureCommittedClaim {
  ApplicationFutureCommittedClaim._(this.application, this.candidate);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentFutureCommittedSeasonResult candidate;
  void validatePrepared(PreparedTicketRuntimeSeason source) {
    if (!identical(application._futureWeeklyState, candidate.weeklyState) ||
        application._futureCommittedSeason != null ||
        !identical(source, candidate.prepared) ||
        !identical(application._activeFutureSeasonOpening, candidate.opening) ||
        !candidate.w30.isComplete ||
        candidate.w30.completedMatchCount != 720) {
      throw StateError('Foreign or stale future committed claim.');
    }
  }
}

final class ApplicationFutureEconomyClaim {
  ApplicationFutureEconomyClaim._(this.application, this.committed);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentFutureCommittedSeasonResult committed;
  void validatePrepared(PreparedTicketRuntimeSeason source) {
    if (!identical(application._futureCommittedSeason, committed) ||
        !identical(source, committed.prepared) ||
        !identical(committed.capability.completedSource, committed) ||
        application._futureEconomyAuthority != null) {
      throw StateError('Foreign, stale or repeated future economy claim.');
    }
  }
}

extension FutureActiveSeasonApplicationRuntime
    on PlayerPresidentInteractiveDecisionApplicationSession {
  PlayerPresidentFuturePromiseApplied? get futurePromiseApplied =>
      _futurePromiseApplied;
  PlayerPresidentFutureWeeklyState? get futureWeeklyState => _futureWeeklyState;
  PlayerPresidentFutureCommittedSeasonResult? get futureCommittedSeason =>
      _futureCommittedSeason;
  FullM65RuntimeEconomyContinuationAuthority? get futureEconomyAuthority =>
      _futureEconomyAuthority;

  PlayerPresidentFuturePromiseApplied acceptFuturePromise({
    required PlayerPresidentActiveFutureSeasonOpening expectedOpening,
    required PlayerPresidentInteractiveDecisionPending expectedPending,
    required PresidentPromiseType choice,
    PlayerPresidentInteractiveDecisionRequest? expectedRequest,
  }) {
    final previous = _futurePromiseApplied;
    if (previous != null) {
      if (!identical(previous.opening, expectedOpening) ||
          !identical(expectedPending, expectedOpening.promisePending) ||
          previous.acceptedChoice != choice) {
        throw StateError('Conflicting future promise answer.');
      }
      return previous;
    }
    if (!identical(_activeFutureSeasonOpening, expectedOpening)) {
      throw StateError('Future promise requires the active opening.');
    }
    final request = expectedRequest ?? expectedPending.request;
    final claim =
        ApplicationFuturePromiseAcceptanceClaim._(this, expectedOpening);
    final accepted = PlayerPresidentFuturePromiseAcceptance.accept(
      claim: claim,
      pending: expectedPending,
      request: request,
      choice: choice,
    );
    final applied = PlayerPresidentFuturePromiseApplied._(
      this,
      expectedOpening,
      accepted,
    );
    final weekly = PlayerPresidentFutureWeeklyState._(
      application: this,
      applied: applied,
      fixtureSnapshot: expectedOpening.w0,
    );
    _futurePromiseApplied = applied;
    _futureWeeklyState = weekly;
    return applied;
  }

  PlayerPresidentFutureWeeklyState advanceFutureWeek({
    required PlayerPresidentFutureWeeklyState expectedState,
    required int expectedRound,
  }) {
    final current = _futureWeeklyState;
    if (current != null &&
        identical(current.predecessor, expectedState) &&
        current.committedRound == expectedRound) {
      return current;
    }
    if (!identical(current, expectedState)) {
      throw StateError('Stale future weekly predecessor.');
    }
    final claim =
        ApplicationFutureWeeklyClaim._(this, expectedState, expectedRound);
    final snapshot = expectedState.prepared.advanceFutureRound(
      claim: claim,
      snapshot: expectedState.fixtureSnapshot,
      expectedRound: expectedRound,
    );
    _validateFutureRound(
        expectedState.fixtureSnapshot, snapshot, expectedRound);
    final successor = PlayerPresidentFutureWeeklyState._(
      application: this,
      applied: expectedState.applied,
      fixtureSnapshot: snapshot,
      predecessor: expectedState,
      committedRound: expectedRound,
    );
    _futureWeeklyState = successor;
    return successor;
  }

  PlayerPresidentFutureCommittedSeasonResult commitFutureSeason({
    required PlayerPresidentFutureWeeklyState expectedW30,
  }) {
    final previous = _futureCommittedSeason;
    if (previous != null) {
      if (!identical(previous.weeklyState, expectedW30)) {
        throw StateError('Conflicting future committed result.');
      }
      return previous;
    }
    if (!identical(_futureWeeklyState, expectedW30) ||
        !expectedW30.isComplete ||
        expectedW30.nextRound != 31 ||
        expectedW30.completedMatchCount != 720) {
      throw StateError('Future commit requires the exact application W30.');
    }
    final reports = _futureReports(expectedW30);
    final candidate = PlayerPresidentFutureCommittedSeasonResult._(
      application: this,
      weeklyState: expectedW30,
      reports: reports,
    );
    final claim = ApplicationFutureCommittedClaim._(this, candidate);
    candidate.capability = expectedW30.prepared.mintFutureCommittedCapability(
      claim: claim,
      completedSource: candidate,
      reports: reports,
      promiseContexts: expectedW30.opening.promiseContexts,
      activePromises: expectedW30.activePromises,
    );
    _futureCommittedSeason = candidate;
    return candidate;
  }

  FullM65RuntimeEconomyContinuationAuthority handoffFutureEconomy({
    required PlayerPresidentFutureCommittedSeasonResult expectedCommitted,
  }) {
    final previous = _futureEconomyAuthority;
    if (previous != null) {
      if (!identical(_futureCommittedSeason, expectedCommitted)) {
        throw StateError('Conflicting future economy handoff.');
      }
      return previous;
    }
    if (!identical(_futureCommittedSeason, expectedCommitted)) {
      throw StateError('Future economy requires the exact committed result.');
    }
    final claim = ApplicationFutureEconomyClaim._(this, expectedCommitted);
    final authority = expectedCommitted.prepared.claimFutureEconomy(
      claim: claim,
      capability: expectedCommitted.capability,
    );
    _futureEconomyAuthority = authority;
    return authority;
  }
}

void _validateFutureRound(
  WeeklyWorldFixtureSnapshot before,
  WeeklyWorldFixtureSnapshot after,
  int round,
) {
  if (after.seasonIndex != before.seasonIndex ||
      after.nextRound != round + 1 ||
      after.completedMatchCount != before.completedMatchCount + 24 ||
      after.fixtures.length != before.fixtures.length) {
    throw StateError('Future round successor invariants failed.');
  }
  for (var i = 0; i < before.fixtures.length; i++) {
    final oldEntry = before.fixtures[i];
    final nextEntry = after.fixtures[i];
    if (oldEntry.round == round) {
      if (oldEntry.isPlayed || !nextEntry.isPlayed) {
        throw StateError('Future round did not commit exactly once.');
      }
    } else if (!identical(oldEntry, nextEntry)) {
      throw StateError('Future round altered an unrelated fixture identity.');
    }
  }
}

List<LeagueSeasonSnapshot> _futureReports(
  PlayerPresidentFutureWeeklyState state,
) {
  final reports = <LeagueSeasonSnapshot>[];
  for (final league in state.opening.opening.leagues) {
    final entries = state.fixtureSnapshot.fixtures
        .where((entry) => entry.tier == league.tier)
        .toList(growable: false);
    final fixtures =
        entries.map((entry) => entry.fixture).toList(growable: false);
    final rows = {
      for (final clubId in league.clubIds) clubId: StandingRow(clubId: clubId),
    };
    var homeWins = 0, draws = 0, awayWins = 0, totalGoals = 0;
    for (final fixture in fixtures) {
      final result = fixture.result;
      if (result == null) throw StateError('W30 contains an unplayed fixture.');
      rows[fixture.homeClubId]!.record(
        scored: result.homeGoals,
        conceded: result.awayGoals,
      );
      rows[fixture.awayClubId]!.record(
        scored: result.awayGoals,
        conceded: result.homeGoals,
      );
      totalGoals += result.homeGoals + result.awayGoals;
      if (result.homeGoals > result.awayGoals) {
        homeWins++;
      } else if (result.homeGoals == result.awayGoals) {
        draws++;
      } else {
        awayWins++;
      }
    }
    final table = rows.values.toList()
      ..sort((a, b) {
        var value = b.points.compareTo(a.points);
        if (value != 0) return value;
        value = b.goalDifference.compareTo(a.goalDifference);
        if (value != 0) return value;
        value = b.goalsFor.compareTo(a.goalsFor);
        if (value != 0) return value;
        value = b.wins.compareTo(a.wins);
        return value != 0 ? value : a.clubId.compareTo(b.clubId);
      });
    final weeklyTable = state.fixtureSnapshot.tableFor(league.tier);
    if (table.length != weeklyTable.length) {
      throw StateError('Future report table coverage mismatch.');
    }
    for (var i = 0; i < table.length; i++) {
      final a = table[i], b = weeklyTable[i];
      if (a.clubId != b.clubId ||
          a.played != b.played ||
          a.wins != b.wins ||
          a.draws != b.draws ||
          a.losses != b.losses ||
          a.goalsFor != b.goalsFor ||
          a.goalsAgainst != b.goalsAgainst ||
          a.points != b.points) {
        throw StateError('Future report does not match W30 table.');
      }
    }
    final report = SeasonReport(
      seasonIndex: state.targetSeasonIndex,
      seed: state.opening.opening.config.careerSeed,
      championClubId: table.first.clubId,
      table: List.unmodifiable(table),
      fixtures: List.unmodifiable(fixtures),
      homeWins: homeWins,
      draws: draws,
      awayWins: awayWins,
      totalGoals: totalGoals,
    );
    final issues = const SeasonValidator().validate(report);
    if (issues.isNotEmpty) {
      throw StateError('Invalid future committed report: ${issues.join('; ')}');
    }
    reports.add(LeagueSeasonSnapshot(tier: league.tier, report: report));
  }
  return List.unmodifiable(reports);
}
