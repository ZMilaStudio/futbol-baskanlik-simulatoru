import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_league_table_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

Object _choiceFor(PlayerPresidentInteractiveDecisionRequest request) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice.hold;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final context = request.contextAs<PlayerSponsorDecisionContext>();
      return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
    case PlayerPresidentInteractiveDecisionKind.crisis:
      final context = request.contextAs<PlayerCrisisDecisionContext>();
      return PlayerCrisisActionChoice(action: context.aiDecision.action);
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return PlayerManagerReviewChoice.replace;
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      final context = request.contextAs<PlayerManagerReplacementContext>();
      return PlayerManagerReplacementChoice(
        managerId: context.candidates.first.manager.id,
      );
    case PlayerPresidentInteractiveDecisionKind.promise:
      return request.contextAs<PlayerPromiseDecisionContext>().aiPromise.type;
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      return request
          .contextAs<PlayerMediaStatementDecisionContext>()
          .aiStatement
          .stance;
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      return PlayerTransferStrategyChoice.fromProfile(
        request.contextAs<PlayerTransferStrategyDecisionContext>().aiProfile,
      );
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return request
          .contextAs<PlayerPresidentTicketPricingDecisionContext>()
          .aiChoice;
  }
}

PlayerPresidentInteractiveSessionCompleted _drive(
  PlayerPresidentInteractiveDecisionApplicationSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  for (var guard = 0; guard < 100; guard++) {
    if (step is PlayerPresidentInteractiveSessionCompleted) return step;
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    step = session.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
  }
  throw StateError('M96 interactive season did not complete.');
}

StandingRow _standing(
  String clubId, {
  int wins = 1,
  int draws = 0,
  int losses = 0,
  int goalsFor = 2,
  int goalsAgainst = 0,
  int points = 3,
}) {
  final row = StandingRow(clubId: clubId);
  row
    ..played = wins + draws + losses
    ..wins = wins
    ..draws = draws
    ..losses = losses
    ..goalsFor = goalsFor
    ..goalsAgainst = goalsAgainst
    ..points = points;
  return row;
}

SeasonReport _report(
  List<StandingRow> rows, {
  String? championClubId,
  int seasonIndex = 0,
}) =>
    SeasonReport(
      seasonIndex: seasonIndex,
      seed: 20260903,
      championClubId: championClubId ?? rows.first.clubId,
      table: rows,
      fixtures: const [],
      homeWins: 0,
      draws: 0,
      awayWins: 0,
      totalGoals: 0,
    );

WorldLeague _league(List<String> ids, [LeagueTier tier = LeagueTier.first]) =>
    WorldLeague(tier: tier, clubIds: ids);

void main() {
  const config = SimulationConfig(careerSeed: 20260903);

  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentInteractiveSessionCompleted completed;
  late WorldCareerSeason worldSeason;
  late WorldLeague completedLeague;
  late SeasonReport seasonReport;
  late PlayerPresidentCompletedSeasonReport m91;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    completed = _drive(
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      ),
    );
    final boundary = completed.result.boundaries.single;
    worldSeason = boundary
        .source
        .source
        .source
        .sponsor
        .report
        .sourceReport
        .advancedTransferReport
        .worldReport
        .seasons
        .single;
    completedLeague = worldSeason.leaguesBeforeSeason
        .singleWhere((league) => league.clubIds.contains(controlledClubId));
    seasonReport = worldSeason.leagueResults
        .singleWhere((result) => result.tier == completedLeague.tier)
        .report;
    m91 = PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
  });

  test('real Completed exposes exact immutable authoritative final table', () {
    final snapshot = m91.leagueTable;
    expect(snapshot, isNotNull);
    final table = snapshot!;

    expect(table.rows, hasLength(16));
    expect(
      table.rows.map((row) => row.position).toList(growable: false),
      List<int>.generate(table.rows.length, (index) => index + 1),
    );
    expect(
      table.rows.map((row) => row.clubId).toSet(),
      hasLength(table.rows.length),
    );
    expect(
      table.rows.where((row) => row.clubId == controlledClubId),
      hasLength(1),
    );
    expect(table.rows.first.position, 1);
    expect(table.rows.first.clubId, seasonReport.championClubId);
    expect(table.championClubId, m91.championClubId);
    expect(table.seasonIndex, m91.seasonIndex);
    expect(table.leagueTier, m91.leagueTier);

    expect(
      table.rows.map((row) => row.clubId).toList(growable: false),
      seasonReport.table.map((row) => row.clubId).toList(growable: false),
    );

    for (var index = 0; index < seasonReport.table.length; index++) {
      final source = seasonReport.table[index];
      final projected = table.rows[index];
      expect(projected.position, index + 1);
      expect(projected.clubId, source.clubId);
      expect(projected.played, source.played);
      expect(projected.wins, source.wins);
      expect(projected.draws, source.draws);
      expect(projected.losses, source.losses);
      expect(projected.goalsFor, source.goalsFor);
      expect(projected.goalsAgainst, source.goalsAgainst);
      expect(projected.goalDifference, source.goalDifference);
      expect(projected.points, source.points);
    }

    final controlled =
        table.rows.singleWhere((row) => row.clubId == controlledClubId);
    expect(controlled.position, m91.finalPosition);
    expect(controlled.played, m91.standing.played);
    expect(controlled.wins, m91.standing.wins);
    expect(controlled.draws, m91.standing.draws);
    expect(controlled.losses, m91.standing.losses);
    expect(controlled.goalsFor, m91.standing.goalsFor);
    expect(controlled.goalsAgainst, m91.standing.goalsAgainst);
    expect(controlled.goalDifference, m91.standing.goalDifference);
    expect(controlled.points, m91.standing.points);
    expect(table.rows.every((row) => row.played == 30), isTrue);
  });

  test('builder preserves source order and ordered signature deterministically', () {
    final a = _standing('club_a', wins: 2, goalsFor: 5, points: 6);
    final b = _standing('club_b', wins: 1, goalsFor: 2, points: 3);
    final c = _standing(
      'club_c',
      draws: 1,
      goalsFor: 1,
      goalsAgainst: 1,
      points: 1,
    );
    final source = [a, c, b];
    final report = _report(source, championClubId: 'club_a');
    final snapshot =
        PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
      controlledClubId: 'club_c',
      completedLeague: _league(['club_a', 'club_b', 'club_c']),
      report: report,
    );
    final repeated =
        PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
      controlledClubId: 'club_c',
      completedLeague: _league(['club_a', 'club_b', 'club_c']),
      report: report,
    );

    expect(
      snapshot.rows.map((row) => row.clubId),
      ['club_a', 'club_c', 'club_b'],
    );
    expect(repeated.signature, snapshot.signature);

    final reordered =
        PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
      controlledClubId: 'club_c',
      completedLeague: _league(['club_a', 'club_b', 'club_c']),
      report: _report([a, b, c], championClubId: 'club_a'),
    );
    expect(reordered.signature, isNot(snapshot.signature));
  });

  test('snapshot defensive copy isolates mutable StandingRow after projection', () {
    final champion = _standing('club_a');
    final controlled = _standing(
      'club_b',
      draws: 1,
      goalsFor: 1,
      goalsAgainst: 1,
      points: 1,
    );
    final snapshot =
        PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
      controlledClubId: 'club_b',
      completedLeague: _league(['club_a', 'club_b']),
      report: _report([champion, controlled]),
    );
    final signature = snapshot.signature;
    final copied = snapshot.rows[1];

    expect(() => snapshot.rows.add(copied), throwsUnsupportedError);

    controlled.record(scored: 5, conceded: 0);
    expect(copied.played, 2);
    expect(copied.points, 1);
    expect(copied.goalsFor, 1);
    expect(copied.goalsAgainst, 1);
    expect(snapshot.signature, signature);
  });

  test('builder fails closed for duplicate, missing and membership mismatches', () {
    expect(
      () => PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: 'club_a',
        completedLeague: _league(['club_a', 'club_b']),
        report: _report([_standing('club_a'), _standing('club_a')]),
      ),
      throwsStateError,
    );
    expect(
      () => PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: 'missing',
        completedLeague: _league(['club_a', 'club_b']),
        report: _report([_standing('club_a'), _standing('club_b')]),
      ),
      throwsStateError,
    );
    expect(
      () => PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: 'club_a',
        completedLeague: _league(['club_a', 'club_b']),
        report: _report([_standing('club_a'), _standing('club_c')]),
      ),
      throwsStateError,
    );
  });

  test('builder fails closed for champion and invalid stat integrity', () {
    expect(
      () => PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: 'club_a',
        completedLeague: _league(['club_a', 'club_b']),
        report: _report(
          [_standing('club_a'), _standing('club_b')],
          championClubId: 'club_b',
        ),
      ),
      throwsStateError,
    );

    final invalid = _standing('club_b');
    invalid.played = 4;
    expect(
      () => PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: 'club_b',
        completedLeague: _league(['club_a', 'club_b']),
        report: _report([_standing('club_a'), invalid]),
      ),
      throwsStateError,
    );

    final negative = _standing('club_b');
    negative.points = -1;
    expect(
      () => PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: 'club_b',
        completedLeague: _league(['club_a', 'club_b']),
        report: _report([_standing('club_a'), negative]),
      ),
      throwsStateError,
    );
  });

  test('real promotion transition keeps M96 on completed-season membership', () {
    const runtimeEngine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    final candidates = List<Club>.of(world.clubs)
      ..sort((a, b) => a.id.compareTo(b.id));

    PlayerPresidentCompletedSeasonLeagueTableSnapshot? movedSnapshot;
    WorldLeague? beforeLeague;
    WorldLeague? afterLeague;
    LeagueMovement? movement;

    for (final club in candidates) {
      final result = runtimeEngine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: club.id,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
      );
      final boundary = result.boundaries.single;
      final candidateSeason = boundary
          .source
          .source
          .source
          .sponsor
          .report
          .sourceReport
          .advancedTransferReport
          .worldReport
          .seasons
          .single;
      final movements = candidateSeason.movementsAfterSeason
          .where((item) => item.clubId == club.id)
          .toList(growable: false);
      if (movements.isEmpty) continue;

      final selectedMovement = movements.single;
      final selectedBefore = candidateSeason.leaguesBeforeSeason
          .singleWhere((league) => league.clubIds.contains(club.id));
      final selectedAfter = candidateSeason.leaguesAfterTransition
          .singleWhere((league) => league.clubIds.contains(club.id));
      final selectedReport = candidateSeason.leagueResults
          .singleWhere((item) => item.tier == selectedBefore.tier)
          .report;

      movedSnapshot =
          PlayerPresidentCompletedSeasonLeagueTableSnapshot.fromSeasonReport(
        controlledClubId: club.id,
        completedLeague: selectedBefore,
        report: selectedReport,
      );
      beforeLeague = selectedBefore;
      afterLeague = selectedAfter;
      movement = selectedMovement;
      break;
    }

    if (movedSnapshot == null ||
        beforeLeague == null ||
        afterLeague == null ||
        movement == null) {
      fail('Deterministic real runtime exposed no moved controlled club.');
    }

    expect(movement.from, isNot(movement.to));
    expect(movedSnapshot.leagueTier, movement.from);
    expect(beforeLeague.tier, movement.from);
    expect(afterLeague.tier, movement.to);
    expect(
      movedSnapshot.rows.map((row) => row.clubId).toSet(),
      beforeLeague.clubIds.toSet(),
    );
    expect(
      movedSnapshot.rows.map((row) => row.clubId).toSet(),
      isNot(equals(afterLeague.clubIds.toSet())),
    );
  });
}
