part of 'player_president_interactive_decision_application_session.dart';

/// Read-only, non-persisted opening observation. No controller, capability or
/// mutable runtime recipient escapes through the existing component snapshots.
final class PlayerPresidentPreparedSeasonOpeningSnapshot {
  PlayerPresidentPreparedSeasonOpeningSnapshot._(
    this.dashboard,
    this.squad,
    this.fixtures,
  ) {
    if (squad.controlledClubId != controlledClubId ||
        fixtures.controlledClubId != controlledClubId ||
        squad.seasonIndex != seasonIndex ||
        fixtures.seasonIndex != seasonIndex ||
        fixtures.leagueTier != dashboard.leagueTier) {
      throw StateError('Prepared opening observations have different sources.');
    }
  }

  final PlayerPresidentPreparedSeasonDashboardSnapshot dashboard;
  final PlayerPresidentPreparedSquadSnapshot squad;
  final PlayerPresidentPreparedSeasonFixturesSnapshot fixtures;
  String get controlledClubId => dashboard.controlledClubId;
  int get seasonIndex => dashboard.seasonIndex;
  String get signature =>
      '${dashboard.signature}||${squad.signature}||${fixtures.signature}';
}

/// Selects from the exact admitted graph, never regenerates a president,
/// manager, roster, finance state, investment or schedule.
PlayerPresidentPreparedSeasonOpeningSnapshot _preparedFutureSeasonOpening({
  required TrustedFuturePreparedRuntimeAdmission admission,
  required PreparedTicketRuntimeSeason prepared,
  required WeeklyWorldFixtureSnapshot w0,
}) {
  final world = prepared.opening;
  final id = admission.controlledClubId;
  final seasonIndex = admission.targetSeasonIndex;
  if (!identical(prepared, admission.prepared) ||
      world.seasonIndex != seasonIndex ||
      w0.seasonIndex != seasonIndex ||
      w0.nextRound != 1 ||
      w0.completedMatchCount != 0) {
    throw StateError('Prepared future observation requires the exact W0.');
  }
  final league = _singlePreparedWhere(world.leagues,
      (league) => league.clubIds.contains(id), 'future opening league');
  final president = _singlePreparedWhere(
      admission.sourceGraph.crisisEvidence.presidentClubs,
      (club) => club.clubId == id,
      'future opening president');
  final managerSource = prepared.managerAuthority!;
  final assignment = _singlePreparedWhere(
      managerSource.assignments.values,
      (assignment) => assignment.clubId == id,
      'future opening manager assignment');
  final dashboard = PlayerPresidentPreparedSeasonDashboardSnapshot(
    controlledClubId: id,
    seasonIndex: seasonIndex,
    league: league,
    finance: _singlePreparedWhere(world.financeStates,
        (state) => state.clubId == id, 'future opening finance'),
    fanOverallTrust: president.fanReputation.overallTrust,
    presidentTenure: president.tenure,
    playerControl: admission.control,
    manager: _singlePreparedWhere(
        managerSource.managers,
        (manager) => manager.id == assignment.managerId,
        'future opening manager'),
    managerAssignment: assignment,
    academyFacility: _singlePreparedWhere(prepared.facilities.academyFacilities,
        (state) => state.clubId == id, 'future opening academy'),
    stadiumFacility: _singlePreparedWhere(prepared.facilities.stadiumFacilities,
        (state) => state.clubId == id, 'future opening stadium'),
    trainingGroundFacility: _singlePreparedWhere(
        prepared.facilities.trainingGroundFacilities,
        (state) => state.clubId == id,
        'future opening training ground'),
    activeSponsor: _activePreparedSponsor(
      prepared.openingSponsor.activeContracts,
      controlledClubId: id,
      seasonIndex: seasonIndex,
    ),
  );
  final rows = <PlayerPresidentPreparedSeasonFixture>[];
  for (final entry in w0.fixtures) {
    final fixture = entry.fixture;
    if (entry.tier != league.tier ||
        fixture.homeClubId != id && fixture.awayClubId != id) continue;
    final home = fixture.homeClubId == id;
    rows.add(PlayerPresidentPreparedSeasonFixture(
      fixtureId: fixture.id,
      round: fixture.round,
      opponentClubId: home ? fixture.awayClubId : fixture.homeClubId,
      isHome: home,
    ));
  }
  if (rows.length != w0.totalRounds) {
    throw StateError('Prepared future fixtures do not cover the opening.');
  }
  return PlayerPresidentPreparedSeasonOpeningSnapshot._(
    dashboard,
    _preparedSquadFromPlayers(
      clubs: world.effectiveClubs,
      players: world.players,
      controlledClubId: id,
      seasonIndex: seasonIndex,
    ),
    PlayerPresidentPreparedSeasonFixturesSnapshot(
      controlledClubId: id,
      seasonIndex: seasonIndex,
      leagueTier: league.tier,
      fixtures: rows,
    ),
  );
}
