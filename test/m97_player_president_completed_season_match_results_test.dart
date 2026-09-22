import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_match_results_snapshot.dart';
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
  throw StateError('M97 interactive season did not complete.');
}

SeasonReport _copyReport(
  SeasonReport source, {
  List<Fixture>? fixtures,
}) =>
    SeasonReport(
      seasonIndex: source.seasonIndex,
      seed: source.seed,
      championClubId: source.championClubId,
      table: source.table,
      fixtures: fixtures ?? List<Fixture>.of(source.fixtures),
      homeWins: source.homeWins,
      draws: source.draws,
      awayWins: source.awayWins,
      totalGoals: source.totalGoals,
    );

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

  test('real Completed exposes exact authoritative controlled-club results', () {
    final snapshot = m91.matchResults;
    expect(snapshot, isNotNull);
    final results = snapshot!;
    final sourceControlled = seasonReport.fixtures
        .where(
          (fixture) =>
              fixture.homeClubId == controlledClubId ||
              fixture.awayClubId == controlledClubId,
        )
        .toList(growable: false);

    expect(seasonReport.fixtures, hasLength(240));
    expect(results.matches, hasLength(30));
    expect(sourceControlled, hasLength(30));
    expect(results.seasonIndex, m91.seasonIndex);
    expect(results.controlledClubId, controlledClubId);
    expect(results.leagueTier, m91.leagueTier);
    expect(results.matches.where((match) => match.isHome), hasLength(15));
    expect(results.matches.where((match) => !match.isHome), hasLength(15));
    expect(
      results.matches.map((match) => match.fixtureId).toList(growable: false),
      sourceControlled.map((fixture) => fixture.id).toList(growable: false),
    );

    for (var index = 0; index < sourceControlled.length; index++) {
      final source = sourceControlled[index];
      final projected = results.matches[index];
      final sourceResult = source.result;
      expect(sourceResult, isNotNull);
      final isHome = source.homeClubId == controlledClubId;
      expect(projected.fixtureId, source.id);
      expect(projected.round, source.round);
      expect(projected.isHome, isHome);
      expect(
        projected.opponentClubId,
        isHome ? source.awayClubId : source.homeClubId,
      );
      expect(
        projected.goalsFor,
        isHome ? sourceResult.homeGoals : sourceResult.awayGoals,
      );
      expect(
        projected.goalsAgainst,
        isHome ? sourceResult.awayGoals : sourceResult.homeGoals,
      );
    }

    expect(
      results.matches.map((match) => match.round).toList(growable: false),
      List<int>.generate(30, (index) => index + 1),
    );

    for (final opponent in completedLeague.clubIds
        .where((id) => id != controlledClubId)) {
      final pair = results.matches
          .where((match) => match.opponentClubId == opponent)
          .toList(growable: false);
      expect(pair, hasLength(2));
      expect(pair.where((match) => match.isHome), hasLength(1));
      expect(pair.where((match) => !match.isHome), hasLength(1));
    }
  });

  test('aggregate score parity is test-only and matches M91 plus M96', () {
    final results = m91.matchResults!;
    final tableRow = m91.leagueTable!.rows
        .singleWhere((row) => row.clubId == controlledClubId);
    var wins = 0;
    var draws = 0;
    var losses = 0;
    var goalsFor = 0;
    var goalsAgainst = 0;
    for (final match in results.matches) {
      goalsFor += match.goalsFor;
      goalsAgainst += match.goalsAgainst;
      if (match.goalsFor > match.goalsAgainst) {
        wins++;
      } else if (match.goalsFor == match.goalsAgainst) {
        draws++;
      } else {
        losses++;
      }
    }
    final points = wins * 3 + draws;

    expect(results.matches.length, m91.standing.played);
    expect(wins, m91.standing.wins);
    expect(draws, m91.standing.draws);
    expect(losses, m91.standing.losses);
    expect(goalsFor, m91.standing.goalsFor);
    expect(goalsAgainst, m91.standing.goalsAgainst);
    expect(points, m91.standing.points);

    expect(results.matches.length, tableRow.played);
    expect(wins, tableRow.wins);
    expect(draws, tableRow.draws);
    expect(losses, tableRow.losses);
    expect(goalsFor, tableRow.goalsFor);
    expect(goalsAgainst, tableRow.goalsAgainst);
    expect(points, tableRow.points);
  });

  test('snapshot preserves source order and isolates mutable source fixture list', () {
    final source = List<Fixture>.of(seasonReport.fixtures);
    final syntheticReport = _copyReport(seasonReport, fixtures: source);
    final snapshot =
        PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
      controlledClubId: controlledClubId,
      completedLeague: completedLeague,
      report: syntheticReport,
    );
    final beforeIds =
        snapshot.matches.map((match) => match.fixtureId).toList(growable: false);
    final signature = snapshot.signature;

    expect(
      () => snapshot.matches.add(snapshot.matches.first),
      throwsUnsupportedError,
    );

    final controlledIndexes = <int>[];
    for (var index = 0; index < source.length; index++) {
      final fixture = source[index];
      if (fixture.homeClubId == controlledClubId ||
          fixture.awayClubId == controlledClubId) {
        controlledIndexes.add(index);
      }
    }
    final firstIndex = controlledIndexes.first;
    final secondIndex = controlledIndexes[1];
    final temp = source[firstIndex];
    source[firstIndex] = source[secondIndex];
    source[secondIndex] = temp;

    expect(
      snapshot.matches.map((match) => match.fixtureId).toList(growable: false),
      beforeIds,
    );
    expect(snapshot.signature, signature);

    final reordered =
        PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
      controlledClubId: controlledClubId,
      completedLeague: completedLeague,
      report: syntheticReport,
    );
    expect(reordered.signature, isNot(signature));
  });

  test('builder rejects null result, duplicate ID, bad count and bad membership', () {
    final controlledSource = seasonReport.fixtures.firstWhere(
      (fixture) =>
          fixture.homeClubId == controlledClubId ||
          fixture.awayClubId == controlledClubId,
    );

    final nullResult = List<Fixture>.of(seasonReport.fixtures);
    final nullIndex =
        nullResult.indexWhere((fixture) => fixture.id == controlledSource.id);
    nullResult[nullIndex] = Fixture(
      id: controlledSource.id,
      seasonIndex: controlledSource.seasonIndex,
      round: controlledSource.round,
      homeClubId: controlledSource.homeClubId,
      awayClubId: controlledSource.awayClubId,
    );
    expect(
      () => PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
        controlledClubId: controlledClubId,
        completedLeague: completedLeague,
        report: _copyReport(seasonReport, fixtures: nullResult),
      ),
      throwsStateError,
    );

    final duplicate = List<Fixture>.of(seasonReport.fixtures);
    final replacement = duplicate[1];
    duplicate[1] = Fixture(
      id: duplicate.first.id,
      seasonIndex: replacement.seasonIndex,
      round: replacement.round,
      homeClubId: replacement.homeClubId,
      awayClubId: replacement.awayClubId,
      result: replacement.result,
    );
    expect(
      () => PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
        controlledClubId: controlledClubId,
        completedLeague: completedLeague,
        report: _copyReport(seasonReport, fixtures: duplicate),
      ),
      throwsStateError,
    );

    final badCount = List<Fixture>.of(seasonReport.fixtures)..removeLast();
    expect(
      () => PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
        controlledClubId: controlledClubId,
        completedLeague: completedLeague,
        report: _copyReport(seasonReport, fixtures: badCount),
      ),
      throwsStateError,
    );

    final outsider = List<Fixture>.of(seasonReport.fixtures);
    final memberIndex =
        outsider.indexWhere((fixture) => fixture.id == controlledSource.id);
    outsider[memberIndex] = Fixture(
      id: controlledSource.id,
      seasonIndex: controlledSource.seasonIndex,
      round: controlledSource.round,
      homeClubId: controlledClubId,
      awayClubId: 'outside_completed_league',
      result: controlledSource.result,
    );
    expect(
      () => PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
        controlledClubId: controlledClubId,
        completedLeague: completedLeague,
        report: _copyReport(seasonReport, fixtures: outsider),
      ),
      throwsStateError,
    );
  });

  test('real promotion transition keeps M97 on completed-season authority', () {
    const runtimeEngine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    final candidates = List<Club>.of(world.clubs)
      ..sort((a, b) => a.id.compareTo(b.id));

    PlayerPresidentCompletedSeasonMatchResultsSnapshot? movedSnapshot;
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
          PlayerPresidentCompletedSeasonMatchResultsSnapshot.fromSeasonReport(
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
      movedSnapshot.matches.every(
        (match) => beforeLeague!.clubIds.contains(match.opponentClubId),
      ),
      isTrue,
    );
  });

  test('M97-only fixture corruption keeps M91 and M96 but hides M97', () {
    final source = seasonReport.fixtures;
    final targetIndex = source.indexWhere(
      (fixture) =>
          fixture.homeClubId == controlledClubId ||
          fixture.awayClubId == controlledClubId,
    );
    final original = source[targetIndex];
    source[targetIndex] = Fixture(
      id: original.id,
      seasonIndex: original.seasonIndex,
      round: original.round,
      homeClubId: original.homeClubId,
      awayClubId: original.awayClubId,
    );
    addTearDown(() => source[targetIndex] = original);

    final projection =
        PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
    expect(projection.leagueTable, isNotNull);
    expect(projection.matchResults, isNull);
    expect(projection.controlledClubId, controlledClubId);
    expect(projection.finalPosition, m91.finalPosition);
  });
}
