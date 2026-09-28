import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/src/world/world_opening_state_initializer.dart';
import 'package:test/test.dart';

const _config = SimulationConfig(careerSeed: 20260903);

void main() {
  final world = const FictionalWorldFactory().build();
  const controlledClubId = 't1_01';

  PlayerPresidentInteractiveDecisionApplicationSession application({
    List<Club>? clubs,
    List<WorldLeague>? leagues,
    SimulationConfig config = _config,
    String controlled = controlledClubId,
    int electionInterval = 4,
  }) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: clubs ?? world.clubs,
        leagues: leagues ?? world.leagues,
        config: config,
        controlledClubId: controlled,
        electionInterval: electionInterval,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      );

  IntegratedNewGameOpeningProof proof({
    PlayerPresidentInteractiveDecisionApplicationSession? source,
    List<Club>? clubs,
    List<WorldLeague>? leagues,
    int expectedSeason = 0,
    String expectedClub = controlledClubId,
    int rawHistorySeasons = 2,
  }) =>
      IntegratedNewGameOpeningProof.fromNewGame(
        application: source ?? application(),
        sourceClubs: clubs ?? world.clubs,
        sourceLeagues: leagues ?? world.leagues,
        expectedSeasonIndex: expectedSeason,
        expectedControlledClubId: expectedClub,
        rawHistorySeasons: rawHistorySeasons,
      );

  test(
    'X2-C joins P1, X1, X2-A and X2-B from one real pristine M79 source',
    () {
      final integrated = proof();
      expect(integrated.seasonIndex, 0);
      expect(integrated.controlledClubId, controlledClubId);
      expect(integrated.seasonOpening.fixtureSnapshot.fixtures, hasLength(720));
      expect(integrated.seasonOpening.fixtureSnapshot.completedMatchCount, 0);
      expect(integrated.initialContracts.activeContracts, hasLength(864));
      expect(integrated.initialContracts.initialEvents, hasLength(864));
      expect(integrated.presidentOpening.clubs, hasLength(48));
      expect(
        integrated.presidentDomainMemory.opening,
        same(integrated.presidentOpening),
      );
      expect(
        integrated.presidentDomainMemory.controlledPresidentId,
        'president_t1_01_initial',
      );
      expect(integrated.presidentDomainMemory.rawHistorySeasons, 2);
      expect(integrated.presidentDomainMemory.summary.totalPromises, 0);
      expect(integrated.presidentDomainMemory.recentFan, isEmpty);
      expect(integrated.presidentDomainMemory.recentMedia, isEmpty);
      expect(
        integrated.presidentDomainMemory.resolvedCurrentTermPromises,
        isEmpty,
      );

      final frozen = jsonDecode(
        File(
          'test/fixtures/x2_a0_president_opening_baseline.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(
        integrated.presidentOpening.orderedClubIds,
        frozen['orderedClubIds'],
      );
      expect(
        () => integrated.presidentOpening.clubs.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => integrated.initialContracts.activeContracts.clear(),
        throwsUnsupportedError,
      );
      print('X2C_INTEGRATED_NEW_GAME_OPENING=PASS');
    },
  );

  test(
    'X2-C independently verifies the same real M79 source deterministically',
    () {
      final first = proof();
      final second = proof();
      expect(
        first.seasonOpening.originSourceDigest,
        second.seasonOpening.originSourceDigest,
      );
      expect(
        first.initialContracts.sourceDigest,
        second.initialContracts.sourceDigest,
      );
      expect(
        first.presidentDomainMemory.signature,
        second.presidentDomainMemory.signature,
      );
      first.verifyNewGame(
        application: application(),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      );
      print('X2C_INDEPENDENT_SOURCE_VERIFICATION=PASS');
    },
  );

  test('X2-C rejects mismatched source/config/world/opening observations', () {
    final reference = proof();
    const changedConfig = SimulationConfig(careerSeed: 20260904);
    expect(
      () => reference.verifyNewGame(
        application: application(config: changedConfig),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(() => proof(expectedSeason: 1), throwsStateError);
    expect(() => proof(expectedClub: 't1_02'), throwsStateError);
    expect(() => proof(rawHistorySeasons: 0), throwsArgumentError);

    final reordered = [
      for (final league in world.leagues)
        league.tier == LeagueTier.first
            ? league.copyWith(
                clubIds: [
                  league.clubIds[1],
                  league.clubIds[0],
                  ...league.clubIds.skip(2),
                ],
              )
            : league,
    ];
    expect(
      () => reference.verifyNewGame(
        application: application(leagues: reordered),
        sourceClubs: world.clubs,
        sourceLeagues: reordered,
      ),
      throwsStateError,
    );
    print('X2C_CROSS_DOMAIN_NEGATIVE_GATES=PASS');
  });

  test(
    'X2-C rejects answered M79 and cannot use completed state as pristine',
    () {
      final app = application();
      final pending =
          app.advance() as PlayerPresidentInteractiveDecisionPending;
      final context = pending.request.contextAs<PlayerSponsorDecisionContext>();
      app.submit(
        request: pending.request,
        choice: PlayerSponsorOfferChoice(offerId: context.aiChoice.id),
      );
      expect(() => proof(source: app), throwsStateError);
      print('X2C_PRISTINE_BOUNDARY=PASS');
    },
  );

  test('X2-C ordered X1 source, contract and event output parity with real lazy controller', () {
    final integrated = proof();
    final independentWorld = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
    );
    final independentlyGenerated = const InitialContractOpeningGenerator().generate(
      careerSeed: _config.careerSeed,
      simulationVersion: _config.simulationVersion,
      seasonIndex: _config.seasonIndex,
      players: independentWorld.players,
      leagues: independentWorld.leagues,
    );
    final actual = integrated.initialContracts;
    expect(actual.sourceDigest, independentlyGenerated.sourceDigest);
    expect(actual.careerSeed, independentlyGenerated.careerSeed);
    expect(actual.simulationVersion, independentlyGenerated.simulationVersion);
    expect(actual.seasonIndex, independentlyGenerated.seasonIndex);
    expect(actual.sourcePlayerCount, independentlyGenerated.sourcePlayerCount);
    expect(actual.sourceLeagueCount, independentlyGenerated.sourceLeagueCount);
    expect(actual.sourcePlayerCount, independentWorld.players.length);
    expect(actual.sourceLeagueCount, independentWorld.leagues.length);
    expect(
      actual.activeContracts.map((contract) => contract.signature).toList(),
      independentlyGenerated.activeContracts.map((contract) => contract.signature).toList(),
    );
    expect(
      actual.initialEvents.map((event) => event.signature).toList(),
      independentlyGenerated.initialEvents.map((event) => event.signature).toList(),
    );

    final playerIds = independentWorld.players.map((player) => player.id).toSet();
    final contractIds = actual.activeContracts.map((contract) => contract.playerId).toSet();
    final eventIds = actual.initialEvents.map((event) => event.playerId).toSet();
    expect(contractIds.length, playerIds.length);
    expect(eventIds.length, playerIds.length);
    expect(contractIds, playerIds);
    expect(eventIds, playerIds);

    final lazy = PlayerContractController(
      careerSeed: _config.careerSeed,
      simulationVersion: _config.simulationVersion,
      initialSeasonIndex: _config.seasonIndex,
    );
    expect(lazy.activeContracts, isEmpty);
    expect(lazy.events, isEmpty);
    lazy.annualWagesByClub(
      seasonIndex: _config.seasonIndex,
      players: independentWorld.players,
      clubs: independentWorld.baseClubs,
      leagues: independentWorld.leagues,
      financeStates: independentWorld.financeStates,
    );
    expect(
      lazy.activeContracts.map((contract) => contract.signature).toList(),
      actual.activeContracts.map((contract) => contract.signature).toList(),
    );
    expect(
      lazy.events.map((event) => event.signature).toList(),
      actual.initialEvents.map((event) => event.signature).toList(),
    );
    integrated.verifyNewGame(
      application: application(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    print('X2C_X1_ORDERED_CONTRACT_EVENT_LEGACY_PARITY=PASS');
  });

  test('X2-C full P1 independent M79/M80 source and fixture-plan verification', () {
    final integrated = proof();
    final app = application();
    final independentP1 = SeasonOpeningProof.fromNewGame(
      application: app,
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
      expectedSeasonIndex: 0,
      expectedControlledClubId: controlledClubId,
    );
    integrated.seasonOpening.verifyNewGame(
      application: app,
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    integrated.verifyNewGame(
      application: app,
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    expect(integrated.seasonOpening.fixturePlanFingerprint,
        independentP1.fixturePlanFingerprint);
    expect(integrated.seasonOpening.fixtureSnapshot.fixtures.length, 720);
    expect(integrated.seasonOpening.fixtureSnapshot.completedMatchCount, 0);
    expect(
      () => integrated.verifyNewGame(
        application: app,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
        expectedRulesetId: 'invalid-ruleset',
      ),
      throwsStateError,
    );
    print('X2C_FULL_P1_CANONICAL_FIXTURE_SOURCE_VERIFICATION=PASS');
  });

  test('X2-C rejects independently changed version, election and world inputs', () {
    final reference = proof();
    final differentVersion = application(
      config: const SimulationConfig(careerSeed: 20260903, simulationVersion: 2),
    );
    expect(
      () => reference.verifyNewGame(
        application: differentVersion,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(
      () => reference.verifyNewGame(
        application: application(electionInterval: 5),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );

    final changedClubs = List<Club>.of(world.clubs);
    changedClubs[0] = changedClubs[0].copyWith(
      strength: changedClubs[0].strength + 0.25,
    );
    // The supplied world must independently match the actual application's
    // M80 fingerprint, even before P1's full canonical-identity comparison.
    expect(
      () => reference.verifyNewGame(
        application: application(),
        sourceClubs: changedClubs,
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(
      () => reference.verifyNewGame(
        application: application(clubs: changedClubs),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(
      () => reference.verifyNewGame(
        application: application(clubs: changedClubs),
        sourceClubs: changedClubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );

    final reversedLeagues = world.leagues.reversed.toList();
    expect(
      () => reference.verifyNewGame(
        application: application(),
        sourceClubs: world.clubs,
        sourceLeagues: reversedLeagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(
      () => reference.verifyNewGame(
        application: application(leagues: reversedLeagues),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    print('X2C_CHANGED_VERSION_ELECTION_WORLD_FAIL_CLOSED=PASS');
  });

  test('X2-C detects independently observed player and finance projection drift', () {
    final integrated = proof();
    final independent = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
    );
    integrated.seasonOpening.assertOpeningProjectionMatches(independent);
    final players = List<Player>.of(independent.players);
    players[0] = players[0].copyWith(ability: players[0].ability + 0.25);
    expect(
      () => integrated.seasonOpening.assertOpeningProjectionMatches(
        WorldOpeningState(
          baseClubs: independent.baseClubs,
          leagues: independent.leagues,
          players: players,
          financeStates: independent.financeStates,
        ),
      ),
      throwsStateError,
    );
    final finance = List<ClubFinanceState>.of(independent.financeStates);
    finance[0] = ClubFinanceState(
      clubId: finance[0].clubId,
      cash: Money.fromMinorUnits(finance[0].cash.minorUnits + 1),
      debt: finance[0].debt,
    );
    expect(
      () => integrated.seasonOpening.assertOpeningProjectionMatches(
        WorldOpeningState(
          baseClubs: independent.baseClubs,
          leagues: independent.leagues,
          players: independent.players,
          financeStates: finance,
        ),
      ),
      throwsStateError,
    );
    // The public X2-C verifier accepts M79 plus clubs/leagues, not an
    // arbitrary injected player/finance DTO. P1 has this diagnostic gate.
    print('X2C_INDEPENDENT_PLAYER_FINANCE_PROJECTION_DRIFT=PASS');
  });

  test('X2-C rejects missing/duplicate clubs, wrong control/season and raw window', () {
    final reference = proof();
    final missing = List<Club>.of(world.clubs)..removeLast();
    final duplicate = List<Club>.of(world.clubs);
    duplicate[duplicate.length - 1] = duplicate.first;
    expect(() => proof(clubs: missing), throwsA(isA<SaveLoadException>()));
    expect(() => proof(clubs: duplicate), throwsA(isA<SaveLoadException>()));
    expect(
      () => reference.verifyNewGame(
        application: application(),
        sourceClubs: missing,
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(
      () => reference.verifyNewGame(
        application: application(),
        sourceClubs: duplicate,
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(
      () => reference.verifyNewGame(
        application: application(controlled: 't1_02'),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(() => proof(expectedClub: 't1_02'), throwsStateError);
    expect(() => proof(expectedSeason: 1), throwsStateError);
    expect(() => proof(rawHistorySeasons: -1), throwsArgumentError);
    print('X2C_MISSING_DUPLICATE_CONTROL_SEASON_WINDOW_FAIL_CLOSED=PASS');
  });
}
