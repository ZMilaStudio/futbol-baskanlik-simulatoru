import 'package:futbol_baskanlik_m0/facility_sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
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
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';
import 'package:futbol_baskanlik_m0/president_facility_investment_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';
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
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M91 interactive session did not converge.');
    }
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
}

PlayerPresidentInteractiveSessionCompleted _withoutPromise(
  PlayerPresidentInteractiveSessionCompleted completed,
) {
  final boundary = completed.result.boundaries.single;
  final ticketBoundary = boundary.source;
  final facilityBoundary = ticketBoundary.source;
  final combinedBoundary = facilityBoundary.source;
  final sponsorBoundary = combinedBoundary.sponsor;
  final reputation = sponsorBoundary.report;
  final promiseMedia = reputation.sourceReport;

  final emptyPromiseReport = PromiseCareerReport(
    advancedTransferReport: promiseMedia.promiseReport.advancedTransferReport,
    snapshots: const <PromiseSeasonSnapshot>[],
  );
  final nextPromiseMedia = PromiseMediaCareerReport(
    advancedTransferReport: promiseMedia.advancedTransferReport,
    managerReport: promiseMedia.managerReport,
    baselineMediaReport: promiseMedia.baselineMediaReport,
    promiseReport: emptyPromiseReport,
    seasons: promiseMedia.seasons,
    finalStates: promiseMedia.finalStates,
  );
  final nextReputation = PresidentReputationCareerReport(
    sourceReport: nextPromiseMedia,
    fanTemplateReport: reputation.fanTemplateReport,
    careerSeed: reputation.careerSeed,
    simulationVersion: reputation.simulationVersion,
    electionInterval: reputation.electionInterval,
    initialTenureStates: reputation.initialTenureStates,
    seasons: reputation.seasons,
    elections: reputation.elections,
    turnovers: reputation.turnovers,
    handovers: reputation.handovers,
    finalTenureStates: reputation.finalTenureStates,
    finalFanStates: reputation.finalFanStates,
    finalMediaStates: reputation.finalMediaStates,
  );
  final nextSponsorBoundary = SponsorRuntimeSeasonBoundary(
    seasonIndex: sponsorBoundary.seasonIndex,
    report: nextReputation,
    contracts: sponsorBoundary.contracts,
    revenueByClub: sponsorBoundary.revenueByClub,
    checkpoint: sponsorBoundary.checkpoint,
  );
  final nextCombinedBoundary = FacilitySponsorCrisisRuntimeSeasonBoundary(
    sponsor: nextSponsorBoundary,
    crisis: combinedBoundary.crisis,
    checkpoint: combinedBoundary.checkpoint,
  );
  final nextFacilityBoundary = PresidentFacilityInvestmentRuntimeSeasonBoundary(
    source: nextCombinedBoundary,
    checkpoint: facilityBoundary.checkpoint,
    investment: facilityBoundary.investment,
  );
  final nextTicketBoundary = PlayerPresidentTicketPricingRuntimeSeasonBoundary(
    source: nextFacilityBoundary,
    pricingDecisions: ticketBoundary.pricingDecisions,
    checkpoint: ticketBoundary.checkpoint,
  );
  final nextBoundary = PlayerPresidentUnifiedManagerRuntimeSeasonBoundary(
    source: nextTicketBoundary,
    checkpoint: boundary.checkpoint,
    managerDecision: boundary.managerDecision,
  );
  return PlayerPresidentInteractiveSessionCompleted(
    result: PlayerPresidentUnifiedManagerRuntimeCareerResult(
      checkpoint: completed.result.checkpoint,
      boundaries: [nextBoundary],
    ),
    decisionCount: completed.decisionCount,
  );
}

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );

  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentInteractiveDecisionApplicationSession newGameSession;
  late PlayerPresidentInteractiveSessionCompleted newGameCompleted;
  late PlayerPresidentInteractiveDecisionApplicationSession checkpointSession;
  late PlayerPresidentInteractiveSessionCompleted checkpointCompleted;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;

    newGameSession = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
      crisisActivationThreshold: 0,
      candidateLimit: 5,
    );
    newGameCompleted = _drive(newGameSession);

    final openingCheckpoint =
        const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      aiCrisisEngine: CrisisDecisionEngine(activationThreshold: 0),
      candidateLimit: 5,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
    checkpointSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: openingCheckpoint,
      resumeConfig: resumeConfig,
    );
    checkpointCompleted = _drive(checkpointSession);
  });

  test('public projection exposes exact new-game completed-season authority', () {
    final projection =
        PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);
    final boundary = newGameCompleted.result.boundaries.single;
    final worldSeason = boundary
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
    final league = worldSeason.leaguesBeforeSeason
        .singleWhere((item) => item.clubIds.contains(controlledClubId));
    final leagueResult = worldSeason.leagueResults
        .singleWhere((item) => item.tier == league.tier);
    final rowIndex = leagueResult.report.table
        .indexWhere((item) => item.clubId == controlledClubId);
    final row = leagueResult.report.table[rowIndex];
    final movement = worldSeason.movementsAfterSeason
        .where((item) => item.clubId == controlledClubId)
        .toList(growable: false);

    expect(projection.seasonIndex, boundary.seasonIndex);
    expect(projection.controlledClubId, controlledClubId);
    expect(projection.leagueTier, league.tier);
    expect(projection.leagueName, league.tier.displayName);
    expect(projection.finalPosition, rowIndex + 1);
    expect(identical(projection.standing, row), isTrue);
    expect(projection.standing.played, row.played);
    expect(projection.standing.wins, row.wins);
    expect(projection.standing.draws, row.draws);
    expect(projection.standing.losses, row.losses);
    expect(projection.standing.goalsFor, row.goalsFor);
    expect(projection.standing.goalsAgainst, row.goalsAgainst);
    expect(projection.standing.goalDifference, row.goalDifference);
    expect(projection.standing.points, row.points);
    expect(projection.championClubId, leagueResult.report.championClubId);
    expect(
      projection.movement?.signature,
      movement.isEmpty ? isNull : movement.single.signature,
    );
  });

  test('finance projection is the exact completed-season M65 seam', () {
    final projection =
        PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);
    final boundary = newGameCompleted.result.boundaries.single;
    final authoritative = boundary.source.financeFor(controlledClubId);
    final nextWorld = boundary
        .checkpoint
        .runtime
        .runtime
        .domain
        .presidentRuntime
        .runtime
        .runtime
        .world;
    final nextFinanceState = nextWorld.nextSeasonFinanceStates
        .singleWhere((item) => item.clubId == controlledClubId);

    expect(identical(projection.finance, authoritative), isTrue);
    expect(projection.finance.signature, authoritative.signature);
    expect(projection.finance.clubId, controlledClubId);
    expect(projection.finance.closingCash, authoritative.closingCash);
    expect(projection.finance.closingDebt, authoritative.closingDebt);
    expect(projection.finance.totalRevenue, authoritative.totalRevenue);
    expect(projection.finance.operatingResult, authoritative.operatingResult);
    expect(projection.finance.sponsorRevenue, authoritative.sponsorRevenue);
    expect(projection.finance.matchdayRevenue, authoritative.matchdayRevenue);
    expect(projection.finance.health, authoritative.health);
    expect(nextFinanceState.clubId, projection.finance.clubId);
    expect(projection.finance, isA<ClubFinanceSeason>());
  });

  test('manager projection keeps completed-season manager after replacement', () {
    final projection =
        PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);
    final boundary = newGameCompleted.result.boundaries.single;
    final decision = boundary.managerDecision;

    expect(decision, isNotNull);
    expect(decision!.reviewChoice, PlayerManagerReviewChoice.replace);
    expect(projection.manager.id, decision.reviewContext.currentManager.id);
    expect(
      projection.managerSeason.managerId,
      decision.reviewContext.currentManager.id,
    );
    expect(
      projection.managerSeason.expectedPosition,
      decision.reviewContext.season.expectedPosition,
    );
    expect(
      projection.managerSeason.actualPosition,
      decision.reviewContext.season.actualPosition,
    );

    final managerState = boundary
        .checkpoint
        .runtime
        .runtime
        .domain
        .presidentRuntime
        .runtime
        .runtime
        .manager;
    final postSeasonAssignment = managerState.assignments
        .singleWhere((item) => item.clubId == controlledClubId);
    expect(decision.selectedManager, isNotNull);
    expect(postSeasonAssignment.managerId, decision.selectedManager!.id);
    expect(projection.manager.id, isNot(postSeasonAssignment.managerId));
  });

  test('promise projection preserves canonical resolution and supports null', () {
    final projection =
        PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);
    final promise = projection.promise;

    expect(promise, isNotNull);
    expect(promise!.context.clubId, controlledClubId);
    expect(promise.context.seasonIndex, projection.seasonIndex);
    expect(promise.promise.type, promise.resolution.promise.type);
    expect(
      promise.resolution.status,
      isIn(PromiseStatus.values),
    );
    expect(
      promise.resolution.reason,
      isIn(PromiseResolutionReason.values),
    );
    expect(promise.resolution.score, inInclusiveRange(0, 100));

    final withoutPromise = PlayerPresidentCompletedSeasonReport.fromCompleted(
      _withoutPromise(newGameCompleted),
    );
    expect(withoutPromise.promise, isNull);
  });

  test('checkpoint-origin Completed has exact one-season projection parity', () {
    final projection =
        PlayerPresidentCompletedSeasonReport.fromCompleted(checkpointCompleted);
    final boundary = checkpointCompleted.result.boundaries.single;
    final worldSeason = boundary
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
    final league = worldSeason.leaguesBeforeSeason
        .singleWhere((item) => item.clubIds.contains(controlledClubId));
    final leagueResult = worldSeason.leagueResults
        .singleWhere((item) => item.tier == league.tier);
    final rowIndex = leagueResult.report.table
        .indexWhere((item) => item.clubId == controlledClubId);

    expect(projection.seasonIndex, boundary.seasonIndex);
    expect(projection.controlledClubId, controlledClubId);
    expect(projection.leagueTier, league.tier);
    expect(projection.finalPosition, rowIndex + 1);
    expect(
      identical(projection.standing, leagueResult.report.table[rowIndex]),
      isTrue,
    );
    expect(
      identical(projection.finance, boundary.source.financeFor(controlledClubId)),
      isTrue,
    );
  });

  test('repeated projection is deterministic and read-only', () {
    final first =
        PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);
    final second =
        PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);

    expect(second.seasonIndex, first.seasonIndex);
    expect(second.controlledClubId, first.controlledClubId);
    expect(second.leagueTier, first.leagueTier);
    expect(second.finalPosition, first.finalPosition);
    expect(identical(second.standing, first.standing), isTrue);
    expect(second.championClubId, first.championClubId);
    expect(identical(second.movement, first.movement), isTrue);
    expect(identical(second.finance, first.finance), isTrue);
    expect(identical(second.manager, first.manager), isTrue);
    expect(identical(second.managerSeason, first.managerSeason), isTrue);
    expect(identical(second.promise, first.promise), isTrue);
  });

  test('new-game bootstrap bytes transcript and Completed checkpoint are immutable',
      () {
    final bytesBefore = newGameSession.encodeNewGameBootstrapSnapshot();
    final transcriptBefore =
        newGameSession.newGameBootstrapSnapshot.transcript.signature;
    final answeredBefore = newGameSession.answeredDecisionCount;
    final checkpointBefore = newGameCompleted.result.checkpoint.signature;

    PlayerPresidentCompletedSeasonReport.fromCompleted(newGameCompleted);

    expect(newGameSession.encodeNewGameBootstrapSnapshot(), bytesBefore);
    expect(
      newGameSession.newGameBootstrapSnapshot.transcript.signature,
      transcriptBefore,
    );
    expect(newGameSession.answeredDecisionCount, answeredBefore);
    expect(newGameCompleted.result.checkpoint.signature, checkpointBefore);
  });

  test('checkpoint bundle bytes transcript and checkpoints are immutable', () {
    final bytesBefore = checkpointSession.encodePersistenceBundle();
    final transcriptBefore =
        checkpointSession.persistenceBundle.transcript.signature;
    final openingCheckpointBefore = checkpointSession.checkpoint.signature;
    final completedCheckpointBefore =
        checkpointCompleted.result.checkpoint.signature;
    final answeredBefore = checkpointSession.answeredDecisionCount;

    PlayerPresidentCompletedSeasonReport.fromCompleted(checkpointCompleted);

    expect(checkpointSession.encodePersistenceBundle(), bytesBefore);
    expect(
      checkpointSession.persistenceBundle.transcript.signature,
      transcriptBefore,
    );
    expect(checkpointSession.checkpoint.signature, openingCheckpointBefore);
    expect(
      checkpointCompleted.result.checkpoint.signature,
      completedCheckpointBefore,
    );
    expect(checkpointSession.answeredDecisionCount, answeredBefore);
  });

  test('multi-season Completed root fails closed', () {
    final boundary = newGameCompleted.result.boundaries.single;
    final malformed = PlayerPresidentInteractiveSessionCompleted(
      result: PlayerPresidentUnifiedManagerRuntimeCareerResult(
        checkpoint: newGameCompleted.result.checkpoint,
        boundaries: [boundary, boundary],
      ),
      decisionCount: newGameCompleted.decisionCount,
    );

    expect(
      () => PlayerPresidentCompletedSeasonReport.fromCompleted(malformed),
      throwsStateError,
    );
  });
}
