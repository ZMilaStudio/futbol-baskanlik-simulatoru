import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/world/world_opening_state_initializer.dart';
import 'package:test/test.dart';

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const m65Codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentTicketPricingRuntimeCheckpoint completed;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    completed = m65Codec.decode(m65Codec.encode(
      const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine()
          .simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      ).checkpoint,
    ));
  });

  PlayerPresidentInteractiveDecisionApplicationSession newGame({
    List<Club>? clubs,
    List<WorldLeague>? leagues,
    SimulationConfig gameConfig = config,
    String? controlledClub,
  }) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: clubs ?? world.clubs,
        leagues: leagues ?? world.leagues,
        config: gameConfig,
        controlledClubId: controlledClub ?? controlledClubId,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      );

  SeasonOpeningProof startProof({
    PlayerPresidentInteractiveDecisionApplicationSession? application,
    List<Club>? clubs,
    List<WorldLeague>? leagues,
    int expectedSeason = 0,
    String? expectedClub,
    String expectedRules = SeasonOpeningProof.rulesetId,
  }) =>
      SeasonOpeningProof.fromNewGame(
        application: application ?? newGame(),
        sourceClubs: clubs ?? world.clubs,
        sourceLeagues: leagues ?? world.leagues,
        expectedSeasonIndex: expectedSeason,
        expectedControlledClubId: expectedClub ?? controlledClubId,
        expectedRulesetId: expectedRules,
      );

  SeasonOpeningProof checkpointProof({
    PlayerPresidentTicketPricingRuntimeCheckpoint? source,
    int? expectedSeason,
    String? expectedClub,
    String expectedRules = SeasonOpeningProof.rulesetId,
  }) {
    final cp = source ?? completed;
    return SeasonOpeningProof.fromCompletedM65(
      checkpoint: cp,
      expectedSeasonIndex: expectedSeason ?? cp.nextSeasonIndex,
      expectedControlledClubId: expectedClub ?? controlledClubId,
      expectedRulesetId: expectedRules,
    );
  }

  test('M79 actual unmodified new-game source yields deterministic P1 proof',
      () {
    final a = startProof();
    final b = startProof();
    expect(a.originKind, SeasonOpeningOriginKind.newGame);
    expect(a.seasonIndex, config.seasonIndex);
    expect(a.controlledClubId, controlledClubId);
    expect(a.config.careerSeed, config.careerSeed);
    expect(a.config.simulationVersion, config.simulationVersion);
    expect(a.sourceRevisionType, SeasonOpeningProof.sourceRevisionKind);
    expect(a.sourceRevision, a.originSourceDigest);
    expect(a.simulationRulesId, SeasonOpeningProof.rulesetId);
    expect(a.originSourceDigest, b.originSourceDigest);
    expect(a.openingCareerStateDigest, b.openingCareerStateDigest);
    expect(a.fixturePlanFingerprint, b.fixturePlanFingerprint);
    expect(a.playersDigest, b.playersDigest);
    expect(a.financeDigest, b.financeDigest);
    expect(a.orderedWorldDigest, b.orderedWorldDigest);
    expect(a.originSourceDigest.length, 64);
    a.verifyNewGame(
      application: newGame(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    expect(a.fixtureSnapshot.completedMatchCount, 0);
  });

  test('real M65 v1 completed checkpoint opens the actual next season', () {
    final proof = checkpointProof();
    expect(completed.completedSeasons, 1);
    expect(proof.originKind, SeasonOpeningOriginKind.completedM65);
    expect(proof.seasonIndex, completed.nextSeasonIndex);
    expect(proof.seasonIndex, 1);
    expect(proof.controlledClubId, completed.controlledClubId);
    expect(proof.originSourceDigest, checkpointProof().originSourceDigest);
    expect(proof.openingCareerStateDigest,
        checkpointProof().openingCareerStateDigest);
    proof.verifyCompletedM65(checkpoint: completed);
    expect(proof.fixtureSnapshot.seasonIndex, completed.nextSeasonIndex);
    expect(proof.fixtureSnapshot.completedMatchCount, 0);
    expect(proof.originSourceDigest, isNot(startProof().originSourceDigest));
    expect(
      () => proof.verifyNewGame(
        application: newGame(),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(
      () => startProof().verifyCompletedM65(checkpoint: completed),
      throwsStateError,
    );
  });

  test('wrong season, controlled club and ruleset fail before a proof exists',
      () {
    expect(() => startProof(expectedSeason: 1), throwsStateError);
    expect(() => startProof(expectedClub: 't1_02'), throwsStateError);
    expect(
      () => startProof(expectedRules: 'unverified-rules'),
      throwsStateError,
    );
    expect(
      () => checkpointProof(expectedSeason: completed.nextSeasonIndex + 1),
      throwsStateError,
    );
    expect(
      () => checkpointProof(expectedClub: 't1_02'),
      throwsStateError,
    );
    expect(
      () => checkpointProof(expectedRules: 'unverified-rules'),
      throwsStateError,
    );
  });

  test('M80 independently supplied world rejects changed club and league',
      () {
    final reference = startProof();
    final changedClubs = [
      for (final club in world.clubs)
        club.id == controlledClubId
            ? club.copyWith(strength: club.strength + 0.5)
            : club,
    ];
    expect(
      () => reference.verifyNewGame(
        application: newGame(),
        sourceClubs: changedClubs,
        sourceLeagues: world.leagues,
      ),
      throwsA(anything),
    );
    final changedLeagues = [
      for (final league in world.leagues)
        league.tier == LeagueTier.first
            ? league.copyWith(clubIds: [
                league.clubIds[1],
                league.clubIds[0],
                ...league.clubIds.skip(2),
              ])
            : league,
    ];
    expect(
      () => reference.verifyNewGame(
        application: newGame(),
        sourceClubs: world.clubs,
        sourceLeagues: changedLeagues,
      ),
      throwsA(anything),
    );
    // Order is authoritative to FixtureGenerator, even if sorted membership
    // signatures happen to match.
    final reordered = startProof(
      application: newGame(leagues: changedLeagues),
      leagues: changedLeagues,
    );
    expect(reordered.orderedWorldDigest, isNot(reference.orderedWorldDigest));
    expect(reordered.fixturePlanFingerprint,
        isNot(reference.fixturePlanFingerprint));
    expect(reordered.originSourceDigest, isNot(reference.originSourceDigest));
  });

  test('actual different M79 config changes independent source identity',
      () {
    const changedConfig = SimulationConfig(
      careerSeed: 20260904,
      homeAdvantageRating: 3.0,
    );
    final changed = startProof(
      application: newGame(gameConfig: changedConfig),
    );
    expect(changed.originSourceDigest, isNot(startProof().originSourceDigest));
    expect(changed.playersDigest, isNot(startProof().playersDigest));
    expect(changed.financeDigest, isNot(startProof().financeDigest));
    expect(changed.openingCareerStateDigest,
        isNot(startProof().openingCareerStateDigest));
    expect(
      () => startProof().verifyNewGame(
        application: newGame(gameConfig: changedConfig),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
  });

  test('independent player and finance projection drift are detected', () {
    final proof = startProof();
    final actual = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    proof.assertOpeningProjectionMatches(actual);
    final players = List<Player>.of(actual.players);
    players[0] = players[0].copyWith(ability: players[0].ability + 0.25);
    expect(
      () => proof.assertOpeningProjectionMatches(WorldOpeningState(
        baseClubs: actual.baseClubs,
        leagues: actual.leagues,
        players: players,
        financeStates: actual.financeStates,
      )),
      throwsStateError,
    );
    final finance = List<ClubFinanceState>.of(actual.financeStates);
    finance[0] = ClubFinanceState(
      clubId: finance[0].clubId,
      cash: Money.fromMinorUnits(finance[0].cash.minorUnits + 1),
      debt: finance[0].debt,
    );
    expect(
      () => proof.assertOpeningProjectionMatches(WorldOpeningState(
        baseClubs: actual.baseClubs,
        leagues: actual.leagues,
        players: actual.players,
        financeStates: finance,
      )),
      throwsStateError,
    );
    final altered = List<Club>.of(actual.baseClubs);
    altered[0] = altered[0].copyWith(strength: altered[0].strength + 0.25);
    expect(
      () => proof.assertOpeningProjectionMatches(WorldOpeningState(
        baseClubs: altered,
        leagues: actual.leagues,
        players: actual.players,
        financeStates: actual.financeStates,
      )),
      throwsStateError,
    );
    // Projection comparison is a secondary consistency check; true authority
    // verification above always requires independently supplied M79/M65.
  });

  test('different real completed-M65 source and tenure state fail closed', () {
    final p = checkpointProof();
    final changedSource = const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: [
        for (final c in world.clubs)
          c.id == controlledClubId
              ? c.copyWith(strength: c.strength + 0.5)
              : c,
      ],
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
    expect(
      () => p.verifyCompletedM65(checkpoint: changedSource),
      throwsStateError,
    );
    expect(
      checkpointProof(source: changedSource).originSourceDigest,
      isNot(p.originSourceDigest),
    );
    final alternateTenure = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: completed.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: controlledClubId,
        playerPresidentId: 'm3c-p1-other-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    expect(
      () => p.verifyCompletedM65(checkpoint: alternateTenure),
      throwsStateError,
    );
  });

  test('M1 canonical plan is 720 unplayed, ordered and seed-compatible', () {
    final opening = startProof();
    final fixtures = opening.fixtureSnapshot.fixtures;
    expect(opening.fixtureSnapshot.totalRounds, 30);
    expect(opening.fixtureSnapshot.nextRound, 1);
    expect(opening.fixtureSnapshot.completedRounds, 0);
    expect(opening.fixtureSnapshot.completedMatchCount, 0);
    expect(fixtures.length, 720);
    expect(fixtures.every((f) => !f.isPlayed), isTrue);
    expect(fixtures.map((f) => f.globalKey).toSet().length, 720);
    for (var round = 1; round <= 30; round++) {
      expect(fixtures.where((f) => f.round == round).length, 24);
      for (final tier in LeagueTier.values) {
        expect(
          fixtures.where((f) => f.round == round && f.tier == tier).length,
          8,
        );
      }
    }
    for (final league in world.leagues) {
      final leagueClubs = [
        for (final id in league.clubIds)
          world.clubs.singleWhere((c) => c.id == id),
      ];
      final legacy = const FixtureGenerator().generateDoubleRoundRobin(
        clubs: leagueClubs,
        seasonIndex: config.seasonIndex,
      );
      final projected = fixtures
          .where((entry) => entry.tier == league.tier)
          .map((entry) => entry.fixture)
          .toList();
      expect(projected.length, legacy.length);
      for (var i = 0; i < legacy.length; i++) {
        expect(projected[i].id, legacy[i].id);
        expect(projected[i].round, legacy[i].round);
        expect(projected[i].homeClubId, legacy[i].homeClubId);
        expect(projected[i].awayClubId, legacy[i].awayClubId);
      }
      final first = projected.first;
      final byId = {for (final c in leagueClubs) c.id: c};
      final sourceResult = const MatchEngine().simulate(
        fixture: first,
        home: byId[first.homeClubId]!,
        away: byId[first.awayClubId]!,
        config: config,
      );
      final legacyResult = const MatchEngine().simulate(
        fixture: legacy.first,
        home: byId[legacy.first.homeClubId]!,
        away: byId[legacy.first.awayClubId]!,
        config: config,
      );
      expect(sourceResult.matchSeed, legacyResult.matchSeed);
    }
    expect(() => fixtures.clear(), throwsUnsupportedError);
    expect(opening.fixturePlanFingerprint, startProof().fixturePlanFingerprint);
  });

  test('an answered M79 transcript is not a pristine P1 new-game source', () {
    final app = newGame();
    final first = app.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(first.request.key, isNotEmpty);
    expect(app.answeredDecisionCount, 0);
    expect(app.newGameBootstrapSnapshot.transcript.decisionCount, 0);

    // A pending request alone is not an accepted answer: P1 is still valid.
    final pendingProof = startProof(
      application: app,
      expectedRules: SeasonOpeningProof.rulesetId,
    );
    expect(pendingProof.originKind, SeasonOpeningOriginKind.newGame);

    // Submit a real, valid M73/M79 answer and confirm M74/M80 captured it.
    expect(first.request.kind, PlayerPresidentInteractiveDecisionKind.sponsor);
    final context = first.request.contextAs<PlayerSponsorDecisionContext>();
    app.submit(
      request: first.request,
      choice: PlayerSponsorOfferChoice(offerId: context.aiChoice.id),
    );
    expect(app.answeredDecisionCount, 1);
    final transcript = app.newGameBootstrapSnapshot.transcript;
    expect(transcript.decisionCount, 1);
    expect(transcript.entries, isNotEmpty);
    expect(transcript.entries.single.requestKey, first.request.key);

    // The ruleset is correct; rejection must be caused by the accepted answer.
    expect(
      () => startProof(
        application: app,
        expectedRules: SeasonOpeningProof.rulesetId,
      ),
      throwsStateError,
    );
  });
}
