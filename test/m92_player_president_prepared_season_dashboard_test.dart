import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_season_dashboard_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

Object _choiceFor(
  PlayerPresidentInteractiveDecisionRequest request, {
  int? sponsorTerm,
}) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice.hold;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final context = request.contextAs<PlayerSponsorDecisionContext>();
      final offer = sponsorTerm == null
          ? context.aiChoice
          : context.offers.firstWhere(
              (item) => item.termSeasons == sponsorTerm,
            );
      return PlayerSponsorOfferChoice(offerId: offer.id);
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
      final context =
          request.contextAs<PlayerTransferStrategyDecisionContext>();
      return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return request
          .contextAs<PlayerPresidentTicketPricingDecisionContext>()
          .aiChoice;
  }
}

PlayerPresidentInteractiveSessionStep _answer(
  PlayerPresidentInteractiveDecisionApplicationSession session,
  int count, {
  int? sponsorTerm,
}) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  for (var index = 0; index < count; index++) {
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    step = session.submit(
      request: pending.request,
      choice: _choiceFor(pending.request, sponsorTerm: sponsorTerm),
    );
  }
  return step;
}

PlayerPresidentInteractiveSessionCompleted _drive(
  PlayerPresidentInteractiveDecisionApplicationSession session, {
  int? sponsorTerm,
}) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  var guard = 0;
  while (step is PlayerPresidentInteractiveDecisionPending) {
    guard++;
    if (guard > 100) {
      throw StateError('M92 prepared dashboard session did not converge.');
    }
    step = session.submit(
      request: step.request,
      choice: _choiceFor(step.request, sponsorTerm: sponsorTerm),
    );
  }
  return step as PlayerPresidentInteractiveSessionCompleted;
}

T _singleWhere<T>(
  Iterable<T> values,
  bool Function(T item) predicate,
) {
  final matches = values.where(predicate).toList(growable: false);
  expect(matches, hasLength(1));
  return matches.single;
}

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const forcedThreshold = 0;
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: forcedThreshold,
    candidateLimit: 5,
  );

  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentInteractiveSessionCompleted completedLongSponsor;
  late PlayerPresidentInteractiveSessionCompleted completedOneYearSponsor;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    completedLongSponsor = _drive(
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: forcedThreshold,
        candidateLimit: 5,
      ),
      sponsorTerm: 3,
    );
    completedOneYearSponsor = _drive(
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: forcedThreshold,
        candidateLimit: 5,
      ),
      sponsorTerm: 1,
    );
  });

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: forcedThreshold,
        candidateLimit: 5,
      );

  test('M92 public prepared snapshot uses canonical fresh opening state', () {
    final session = fresh();
    final snapshot = session.preparedSeasonDashboard;

    expect(
      snapshot,
      isA<PlayerPresidentPreparedSeasonDashboardSnapshot>(),
    );
    expect(snapshot.controlledClubId, controlledClubId);
    expect(snapshot.seasonIndex, config.seasonIndex);

    final league = _singleWhere(
      world.leagues,
      (item) => item.clubIds.contains(controlledClubId),
    );
    expect(snapshot.leagueTier, league.tier);
    expect(snapshot.leagueId, league.id);

    final runtimeReport = const WorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final canonicalFinance = _singleWhere(
      runtimeReport.initialFinanceStates,
      (item) => item.clubId == controlledClubId,
    );
    expect(snapshot.finance.signature, canonicalFinance.signature);
    expect(snapshot.cash, canonicalFinance.cash);
    expect(snapshot.debt, canonicalFinance.debt);

    expect(
      snapshot.fanOverallTrust,
      FanState.initial(controlledClubId).overallTrust,
    );

    final president = const PresidentProfileGenerator().generateInitial(
      clubId: controlledClubId,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    expect(snapshot.presidentTenure.president.id, president.id);
    expect(snapshot.presidentTenure.startedSeasonIndex, config.seasonIndex);
    expect(snapshot.playerControl.playerPresidentId, president.id);
    expect(snapshot.playerControlActive, isTrue);

    expect(snapshot.academyLevel, 0);
    expect(snapshot.stadiumLevel, 0);
    expect(snapshot.trainingGroundLevel, 0);
    expect(snapshot.activeSponsor, isNull);
  });

  test('M92 opening manager matches real ManagerCareerController initialization',
      () {
    final snapshot = fresh().preparedSeasonDashboard;
    final players = const PlayerPoolGenerator().generate(
      clubs: world.clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final squadClubs = const TeamStrengthCalculator().deriveClubs(
      baseClubs: world.clubs,
      players: players,
    );
    final finance = <ClubFinanceState>[];
    final clubById = {for (final club in world.clubs) club.id: club};
    for (final league in world.leagues) {
      finance.addAll(
        const BasicEconomyEngine().initialStates(
          clubs: league.clubIds
              .map((clubId) => clubById[clubId]!)
              .toList(growable: false),
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
          economicScaleBps: league.tier.economicScaleBps,
        ),
      );
    }

    final controller = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
    );
    controller.adjustClubsForSeason(
      seasonIndex: config.seasonIndex,
      squadClubs: squadClubs,
      players: players,
      leagues: world.leagues,
      financeStates: finance,
    );
    final assignment = _singleWhere(
      controller.finalAssignments,
      (item) => item.clubId == controlledClubId,
    );
    final manager = _singleWhere(
      controller.managers,
      (item) => item.id == assignment.managerId,
    );

    expect(snapshot.manager.id, manager.id);
    expect(snapshot.manager.signature, manager.signature);
    expect(snapshot.managerAssignment.signature, assignment.signature);
    expect(snapshot.boardRelationship, assignment.boardRelationship);
  });

  test('M92 prepared snapshot is stable while transcript grows', () {
    final session = fresh();
    final before = session.preparedSeasonDashboard;
    final bootstrapBefore = session.encodeNewGameBootstrapSnapshot();
    final answerCountBefore = session.answeredDecisionCount;

    expect(identical(before, session.preparedSeasonDashboard), isTrue);
    expect(session.encodeNewGameBootstrapSnapshot(), bootstrapBefore);
    expect(session.answeredDecisionCount, answerCountBefore);

    final next = _answer(session, 3);
    expect(next, isA<PlayerPresidentInteractiveDecisionPending>());
    expect(session.answeredDecisionCount, 3);
    expect(identical(before, session.preparedSeasonDashboard), isTrue);
    expect(session.preparedSeasonDashboard.signature, before.signature);

    final bootstrapAfterAnswers = session.encodeNewGameBootstrapSnapshot();
    final snapshotAgain = session.preparedSeasonDashboard;
    expect(identical(snapshotAgain, before), isTrue);
    expect(session.encodeNewGameBootstrapSnapshot(), bootstrapAfterAnswers);
    expect(session.answeredDecisionCount, 3);
  });

  test('M92 M80 restore keeps the same prepared opening snapshot', () {
    final session = fresh();
    final openingSignature = session.preparedSeasonDashboard.signature;
    _answer(session, 3);
    final encoded = session.encodeNewGameBootstrapSnapshot();

    final restored = PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: encoded,
    );

    expect(restored.answeredDecisionCount, 3);
    expect(restored.preparedSeasonDashboard.signature, openingSignature);
    expect(restored.encodeNewGameBootstrapSnapshot(), encoded);
  });

  test('M92 checkpoint projection selects exact prepared M65 authority', () {
    final checkpoint = completedLongSponsor.result.checkpoint;
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final snapshot = session.preparedSeasonDashboard;

    final facilityRuntime = checkpoint.runtime;
    final sponsorPresident = facilityRuntime.runtime;
    final presidentRuntime = sponsorPresident.domain.presidentRuntime;
    final advanced = presidentRuntime.runtime.runtime;
    final worldCheckpoint = advanced.world;

    expect(snapshot.controlledClubId, checkpoint.controlledClubId);
    expect(snapshot.seasonIndex, checkpoint.nextSeasonIndex);

    final league = _singleWhere(
      worldCheckpoint.nextSeasonLeagues,
      (item) => item.clubIds.contains(checkpoint.controlledClubId),
    );
    final finance = _singleWhere(
      worldCheckpoint.nextSeasonFinanceStates,
      (item) => item.clubId == checkpoint.controlledClubId,
    );
    final presidentState = _singleWhere(
      presidentRuntime.clubs,
      (item) => item.clubId == checkpoint.controlledClubId,
    );
    final assignment = _singleWhere(
      advanced.manager.assignments,
      (item) => item.clubId == checkpoint.controlledClubId,
    );
    final manager = _singleWhere(
      advanced.manager.managers,
      (item) => item.id == assignment.managerId,
    );
    final sponsor = _singleWhere(
      sponsorPresident.sponsor.activeContracts,
      (item) => item.offer.clubId == checkpoint.controlledClubId,
    );

    expect(snapshot.league.signature, league.signature);
    expect(snapshot.finance.signature, finance.signature);
    expect(snapshot.fanOverallTrust, presidentState.fanReputation.overallTrust);
    expect(snapshot.presidentTenure.signature, presidentState.tenure.signature);
    expect(snapshot.playerControl.signature, checkpoint.tenureControl.signature);
    expect(snapshot.manager.signature, manager.signature);
    expect(snapshot.managerAssignment.signature, assignment.signature);
    expect(
      snapshot.academyLevel,
      facilityRuntime.facilities.academyFor(checkpoint.controlledClubId).level,
    );
    expect(
      snapshot.stadiumLevel,
      facilityRuntime.facilities.stadiumFor(checkpoint.controlledClubId).level,
    );
    expect(
      snapshot.trainingGroundLevel,
      facilityRuntime.facilities
          .trainingGroundFor(checkpoint.controlledClubId)
          .level,
    );
    expect(snapshot.activeSponsor!.signature, sponsor.signature);
  });

  test('M92 checkpoint supports no sponsor and source rejects duplicates', () {
    final noSponsorCheckpoint = completedOneYearSponsor.result.checkpoint;
    final noSponsorSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: noSponsorCheckpoint,
      resumeConfig: resumeConfig,
    );
    expect(noSponsorSession.preparedSeasonDashboard.activeSponsor, isNull);

    final sponsorCheckpoint =
        completedLongSponsor.result.checkpoint.runtime.runtime.sponsor;
    final controlledContract = _singleWhere(
      sponsorCheckpoint.activeContracts,
      (item) =>
          item.offer.clubId ==
          completedLongSponsor.result.checkpoint.controlledClubId,
    );
    expect(
      () => SponsorRuntimeCheckpoint(
        nextSeasonIndex: sponsorCheckpoint.nextSeasonIndex,
        activeContracts: [controlledContract, controlledContract],
        totalRevenuePaid: sponsorCheckpoint.totalRevenuePaid,
      ),
      throwsStateError,
    );
  });

  test('M92 checkpoint save reload and M75 restore preserve snapshot', () {
    final checkpoint = completedLongSponsor.result.checkpoint;
    final originalBytes = checkpointCodec.encode(checkpoint);
    final cloned = checkpointCodec.decode(originalBytes);

    final originalSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final clonedSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: cloned,
      resumeConfig: resumeConfig,
    );

    expect(
      clonedSession.preparedSeasonDashboard.signature,
      originalSession.preparedSeasonDashboard.signature,
    );
    expect(checkpointCodec.encode(checkpoint), originalBytes);

    final partial = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    _answer(partial, 2);
    final preparedSignature = partial.preparedSeasonDashboard.signature;
    final bundleBytes = partial.encodePersistenceBundle();

    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: bundleBytes,
    );
    expect(restored.answeredDecisionCount, 2);
    expect(restored.preparedSeasonDashboard.signature, preparedSignature);
    expect(restored.encodePersistenceBundle(), bundleBytes);
  });

  test('M92 next-season handoff creates a new prepared snapshot', () {
    final opening = fresh().preparedSeasonDashboard;
    final openingSignature = opening.signature;
    final checkpoint = completedLongSponsor.result.checkpoint;

    final nextSession =
        PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final next = nextSession.preparedSeasonDashboard;

    expect(next.seasonIndex, opening.seasonIndex + 1);
    expect(identical(next, opening), isFalse);
    expect(opening.signature, openingSignature);
  });

  test('M92 invalid authority fails closed without fabricated defaults', () {
    final badLeagues = List<WorldLeague>.of(world.leagues);
    final second = badLeagues[1];
    badLeagues[1] = WorldLeague(
      tier: second.tier,
      clubIds: [
        controlledClubId,
        ...second.clubIds.skip(1),
      ],
    );

    expect(
      () => PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: badLeagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
      ),
      throwsStateError,
    );

    final valid = fresh().preparedSeasonDashboard;
    final anotherManager = const ManagerPoolGenerator()
        .generate(
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        )
        .firstWhere((item) => item.id != valid.managerAssignment.managerId);
    expect(
      () => PlayerPresidentPreparedSeasonDashboardSnapshot(
        controlledClubId: valid.controlledClubId,
        seasonIndex: valid.seasonIndex,
        league: valid.league,
        finance: valid.finance,
        fanOverallTrust: valid.fanOverallTrust,
        presidentTenure: valid.presidentTenure,
        playerControl: valid.playerControl,
        manager: anotherManager,
        managerAssignment: valid.managerAssignment,
        academyFacility: valid.academyFacility,
        stadiumFacility: valid.stadiumFacility,
        trainingGroundFacility: valid.trainingGroundFacility,
        activeSponsor: valid.activeSponsor,
      ),
      throwsStateError,
    );
  });
}
