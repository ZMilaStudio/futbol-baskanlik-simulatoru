import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_season_fixtures_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/world/world_opening_state_initializer.dart';
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
      final context =
          request.contextAs<PlayerTransferStrategyDecisionContext>();
      return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
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
  throw StateError('M95 fixture did not complete.');
}

WorldLeague _leagueFor(Iterable<WorldLeague> leagues, String clubId) =>
    leagues.singleWhere((league) => league.clubIds.contains(clubId));

String _fixtureTuple(Fixture fixture) =>
    '${fixture.id}|${fixture.round}|${fixture.homeClubId}|${fixture.awayClubId}';

String _projectedTuple(
  PlayerPresidentPreparedSeasonFixture fixture,
  String controlledClubId,
) =>
    fixture.isHome
        ? '${fixture.fixtureId}|${fixture.round}|${controlledClubId}|${fixture.opponentClubId}'
        : '${fixture.fixtureId}|${fixture.round}|${fixture.opponentClubId}|${controlledClubId}';

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;

  PlayerPresidentInteractiveDecisionApplicationSession fresh([String? clubId]) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: clubId ?? controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      );

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    checkpoint = _drive(fresh()).result.checkpoint;
  });

  test('fresh projection exposes the canonical 16-team controlled schedule', () {
    final snapshot = fresh().preparedSeasonFixtures;
    final league = _leagueFor(world.leagues, controlledClubId);

    expect(snapshot.controlledClubId, controlledClubId);
    expect(snapshot.seasonIndex, config.seasonIndex);
    expect(snapshot.leagueTier, league.tier);
    expect(snapshot.fixtures, hasLength(30));
    expect(snapshot.fixtures.where((fixture) => fixture.isHome), hasLength(15));
    expect(snapshot.fixtures.where((fixture) => !fixture.isHome), hasLength(15));
    expect(
      snapshot.fixtures.map((fixture) => fixture.round).toList(),
      List<int>.generate(30, (index) => index + 1),
    );
    expect(
      snapshot.fixtures.map((fixture) => fixture.round).toSet(),
      hasLength(30),
    );
    expect(
      snapshot.fixtures.where(
        (fixture) => fixture.opponentClubId == controlledClubId,
      ),
      isEmpty,
    );
    expect(fresh().preparedSeasonFixtures.signature, snapshot.signature);
  });

  test('snapshot defensive copy, immutability and presentation ordering hold', () {
    final source = <PlayerPresidentPreparedSeasonFixture>[
      const PlayerPresidentPreparedSeasonFixture(
        fixtureId: 'b',
        round: 2,
        opponentClubId: 'club_b',
        isHome: false,
      ),
      const PlayerPresidentPreparedSeasonFixture(
        fixtureId: 'a',
        round: 1,
        opponentClubId: 'club_a',
        isHome: true,
      ),
    ];
    final snapshot = PlayerPresidentPreparedSeasonFixturesSnapshot(
      controlledClubId: 'club',
      seasonIndex: 3,
      leagueTier: LeagueTier.first,
      fixtures: source,
    );
    source.clear();

    expect(snapshot.fixtures.map((fixture) => fixture.round), [1, 2]);
    expect(snapshot.fixtures, hasLength(2));
    expect(
      () => snapshot.fixtures.add(
        const PlayerPresidentPreparedSeasonFixture(
          fixtureId: 'c',
          round: 3,
          opponentClubId: 'club_c',
          isHome: true,
        ),
      ),
      throwsUnsupportedError,
    );
    expect(snapshot.signature, snapshot.signature);
  });

  test('snapshot structural validation rejects duplicate fixture rounds', () {
    expect(
      () => PlayerPresidentPreparedSeasonFixturesSnapshot(
        controlledClubId: 'club',
        seasonIndex: 0,
        leagueTier: LeagueTier.first,
        fixtures: const [
          PlayerPresidentPreparedSeasonFixture(
            fixtureId: 'a',
            round: 1,
            opponentClubId: 'x',
            isHome: true,
          ),
          PlayerPresidentPreparedSeasonFixture(
            fixtureId: 'b',
            round: 1,
            opponentClubId: 'y',
            isHome: false,
          ),
        ],
      ),
      throwsStateError,
    );
  });

  test('new-game M95 tuples exactly match the real SeasonEngine schedule', () {
    final session = fresh();
    final snapshot = session.preparedSeasonFixtures;
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    final league = _leagueFor(opening.leagues, controlledClubId);
    final byId = {for (final club in opening.baseClubs) club.id: club};
    final orderedLeagueClubs = league.clubIds
        .map((clubId) => byId[clubId]!)
        .toList(growable: false);

    final report = const SeasonEngine().simulate(
      clubs: orderedLeagueClubs,
      config: config,
    );
    final real = report.fixtures
        .where(
          (fixture) =>
              fixture.homeClubId == controlledClubId ||
              fixture.awayClubId == controlledClubId,
        )
        .map(_fixtureTuple)
        .toList(growable: false);
    final projected = snapshot.fixtures
        .map((fixture) => _projectedTuple(fixture, controlledClubId))
        .toList(growable: false);

    expect(projected, real);
  });

  test('fixture generation is order-sensitive and M95 preserves league order', () {
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    final league = _leagueFor(opening.leagues, controlledClubId);
    final byId = {for (final club in opening.baseClubs) club.id: club};
    final canonical = league.clubIds
        .map((clubId) => byId[clubId]!)
        .toList(growable: false);
    final reordered = <Club>[
      ...canonical.skip(1),
      canonical.first,
    ];

    List<String> controlledTuples(List<Club> clubs) =>
        const FixtureGenerator()
            .generateDoubleRoundRobin(
              clubs: clubs,
              seasonIndex: config.seasonIndex,
            )
            .where(
              (fixture) =>
                  fixture.homeClubId == controlledClubId ||
                  fixture.awayClubId == controlledClubId,
            )
            .map(_fixtureTuple)
            .toList(growable: false);

    final canonicalTuples = controlledTuples(canonical);
    final reorderedTuples = controlledTuples(reordered);
    expect(reorderedTuples, isNot(equals(canonicalTuples)));

    final projectionTuples = fresh()
        .preparedSeasonFixtures
        .fixtures
        .map((fixture) => _projectedTuple(fixture, controlledClubId))
        .toList(growable: false);
    expect(projectionTuples, canonicalTuples);
  });

  test('M80 restore and transcript growth preserve opening fixture signature', () {
    final session = fresh();
    final openingSignature = session.preparedSeasonFixtures.signature;
    final restored = PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: session.encodeNewGameBootstrapSnapshot(),
    );
    expect(restored.preparedSeasonFixtures.signature, openingSignature);

    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
    expect(session.answeredDecisionCount, 1);

    final restoredAfterTranscript =
        PlayerPresidentInteractiveDecisionApplicationSession
            .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: session.encodeNewGameBootstrapSnapshot(),
    );
    expect(
      restoredAfterTranscript.preparedSeasonFixtures.signature,
      openingSignature,
    );
  });

  test('checkpoint projection uses nextSeasonLeagues and canonical generator', () {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final snapshot = session.preparedSeasonFixtures;
    final worldCheckpoint =
        checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime.world;
    final league =
        _leagueFor(worldCheckpoint.nextSeasonLeagues, controlledClubId);
    final byId = {for (final club in worldCheckpoint.baseClubs) club.id: club};
    final orderedLeagueClubs = league.clubIds
        .map((clubId) => byId[clubId]!)
        .toList(growable: false);
    final report = const SeasonEngine().simulate(
      clubs: orderedLeagueClubs,
      config: config.copyWith(seasonIndex: checkpoint.nextSeasonIndex),
    );

    final real = report.fixtures
        .where(
          (fixture) =>
              fixture.homeClubId == controlledClubId ||
              fixture.awayClubId == controlledClubId,
        )
        .map(_fixtureTuple)
        .toList(growable: false);
    final projected = snapshot.fixtures
        .map((fixture) => _projectedTuple(fixture, controlledClubId))
        .toList(growable: false);

    expect(worldCheckpoint.nextSeasonIndex, checkpoint.nextSeasonIndex);
    expect(snapshot.seasonIndex, checkpoint.nextSeasonIndex);
    expect(snapshot.leagueTier, league.tier);
    expect(snapshot.fixtures, hasLength(2 * (league.clubIds.length - 1)));
    expect(
      snapshot.fixtures.where((fixture) => fixture.isHome),
      hasLength(league.clubIds.length - 1),
    );
    expect(
      snapshot.fixtures.where((fixture) => !fixture.isHome),
      hasLength(league.clubIds.length - 1),
    );
    expect(projected, real);
  });

  test('M65 codec roundtrip re-derives identical fixture observation', () {
    final decoded = checkpointCodec.decode(checkpointCodec.encode(checkpoint));
    final a = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final b = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: decoded,
      resumeConfig: resumeConfig,
    );
    expect(b.preparedSeasonFixtures.signature, a.preparedSeasonFixtures.signature);
  });

  test('promotion/relegation proof uses the same real player-president checkpoint',
      () {
    const runtimeEngine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    final candidates = List<Club>.of(world.clubs)
      ..sort((a, b) => a.id.compareTo(b.id));

    PlayerPresidentTicketPricingRuntimeCheckpoint? movedCheckpoint;
    WorldLeague? oldLeague;
    WorldLeague? nextLeague;
    String? movedClubId;

    for (final club in candidates) {
      final candidateOldLeague = _leagueFor(world.leagues, club.id);
      final candidateCheckpoint = runtimeEngine
          .simulateWithCheckpoint(
            clubs: world.clubs,
            leagues: world.leagues,
            config: config,
            controlledClubId: club.id,
            seasonCount: 1,
            electionInterval: 4,
            hasFutureSeasonAfterReport: true,
          )
          .checkpoint;
      final candidateWorld = candidateCheckpoint
          .runtime.runtime.domain.presidentRuntime.runtime.runtime.world;
      final candidateNextLeague =
          _leagueFor(candidateWorld.nextSeasonLeagues, club.id);
      if (candidateOldLeague.tier != candidateNextLeague.tier) {
        movedCheckpoint = candidateCheckpoint;
        oldLeague = candidateOldLeague;
        nextLeague = candidateNextLeague;
        movedClubId = club.id;
        break;
      }
    }

    expect(
      movedCheckpoint,
      isNotNull,
      reason: 'Deterministic real runtime must expose a moved controlled club.',
    );
    expect(oldLeague!.tier, isNot(nextLeague!.tier));

    final resumed = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: movedCheckpoint!,
      resumeConfig: resumeConfig,
    );
    final snapshot = resumed.preparedSeasonFixtures;
    final expectedOpponents =
        nextLeague!.clubIds.where((id) => id != movedClubId).toSet();
    final oldOpponents =
        oldLeague!.clubIds.where((id) => id != movedClubId).toSet();
    final actualOpponents =
        snapshot.fixtures.map((fixture) => fixture.opponentClubId).toSet();

    expect(expectedOpponents, isNot(equals(oldOpponents)));
    expect(snapshot.leagueTier, nextLeague!.tier);
    expect(actualOpponents, expectedOpponents);
    expect(snapshot.fixtures, hasLength(2 * (nextLeague!.clubIds.length - 1)));
    expect(
      snapshot.fixtures.where((fixture) => fixture.isHome),
      hasLength(nextLeague!.clubIds.length - 1),
    );
    expect(
      snapshot.fixtures.where((fixture) => !fixture.isHome),
      hasLength(nextLeague!.clubIds.length - 1),
    );
  });

  test('M75 restore preserves derived fixtures without serializing projection',
      () {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final before = session.preparedSeasonFixtures;
    final step = session.advance();
    if (step is PlayerPresidentInteractiveDecisionPending) {
      session.submit(
        request: step.request,
        choice: _choiceFor(step.request),
      );
    }

    final encoded = session.encodePersistenceBundle();
    expect(encoded, isNot(contains('preparedSeasonFixtures')));

    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: encoded,
    );
    expect(restored.preparedSeasonFixtures.signature, before.signature);
    expect(restored.preparedSeasonFixtures.seasonIndex, before.seasonIndex);
    expect(restored.preparedSeasonFixtures.leagueTier, before.leagueTier);
  });

  test('Pending and submitWithResolution keep the same snapshot object', () {
    final session = fresh();
    final before = session.preparedSeasonFixtures;
    final pending =
        session.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(session.preparedSeasonFixtures, same(before));

    final result = session.submitWithResolution(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
    expect(result.resolution.requestKey, pending.request.key);
    expect(session.preparedSeasonFixtures, same(before));
  });

  test('next-season handoff creates a fresh prepared fixture snapshot', () {
    final session = fresh();
    final first = session.preparedSeasonFixtures;
    _drive(session);

    final next = session.continuePlayerCareerToNextSeason();
    expect(next.preparedSeasonFixtures, isNot(same(first)));
    expect(next.preparedSeasonFixtures.seasonIndex, first.seasonIndex + 1);
  });
}
