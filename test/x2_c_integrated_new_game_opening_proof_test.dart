import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
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
}
