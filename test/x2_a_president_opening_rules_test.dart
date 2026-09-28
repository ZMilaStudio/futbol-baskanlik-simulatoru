import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';
import 'package:test/test.dart';

const _config = SimulationConfig(careerSeed: 20260903);
const _sourceSha = '647ba661e5397115fc14532920a1922cf4bfff14';

class _CountingPresidentGenerator extends PresidentProfileGenerator {
  int initialCalls = 0;
  int challengerCalls = 0;

  @override
  PresidentProfile generateInitial({
    required String clubId,
    required int careerSeed,
    required int simulationVersion,
  }) {
    initialCalls++;
    return super.generateInitial(
      clubId: clubId,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
  }

  @override
  PresidentProfile generateChallenger({
    required String clubId,
    required int seasonIndex,
    required int electionTermNumber,
    required int careerSeed,
    required int simulationVersion,
  }) {
    challengerCalls++;
    return super.generateChallenger(
      clubId: clubId,
      seasonIndex: seasonIndex,
      electionTermNumber: electionTermNumber,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
  }
}

class _CountingManagementGenerator extends PresidentManagementProfileGenerator {
  int calls = 0;

  @override
  PresidentManagementProfile generate({
    required PresidentProfile president,
    required int careerSeed,
    required int simulationVersion,
  }) {
    calls++;
    return super.generate(
      president: president,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
  }
}

class _CustomPresidentGenerator extends PresidentProfileGenerator {
  const _CustomPresidentGenerator();

  @override
  PresidentProfile generateInitial({
    required String clubId,
    required int careerSeed,
    required int simulationVersion,
  }) => PresidentProfile(id: 'custom_$clubId', name: 'Custom $clubId');
}

class _BrokenManagementGenerator extends PresidentManagementProfileGenerator {
  const _BrokenManagementGenerator();

  @override
  PresidentManagementProfile generate({
    required PresidentProfile president,
    required int careerSeed,
    required int simulationVersion,
  }) => const PresidentManagementProfile(
        presidentId: 'mismatched-president',
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: 60,
        riskAppetite: 60,
        transferAmbition: 60,
        youthOrientation: 60,
        managerPatience: 60,
      );
}

class _BlankPresidentGenerator extends PresidentProfileGenerator {
  const _BlankPresidentGenerator();

  @override
  PresidentProfile generateInitial({
    required String clubId,
    required int careerSeed,
    required int simulationVersion,
  }) => const PresidentProfile(id: '', name: '');
}

Map<String, Object?> _frozenRow(PresidentOpeningClubState item) => {
      'clubId': item.clubId,
      'presidentId': item.president.id,
      'presidentName': item.president.name,
      'presidentSignature': item.president.signature,
      'managementPresidentId': item.managementProfile.presidentId,
      'managementArchetype': item.managementProfile.archetype.name,
      'managementTraits': item.managementProfile.traits,
      'managementSignature': item.managementProfile.signature,
      'tenureNumber': item.tenure.tenureNumber,
      'startedSeasonIndex': item.tenure.startedSeasonIndex,
      'reelectionsWon': item.tenure.reelectionsWon,
      'tenureSignature': item.tenure.signature,
      'fanValues': <int>[
        item.fan.sportingTrust,
        item.fan.financialTrust,
        item.fan.transferTrust,
        item.fan.identityTrust,
        item.fan.overallTrust,
      ],
      'fanSignature': item.fan.signature,
      'mediaCredibility': item.media.credibility,
      'mediaSignature': item.media.signature,
    };

void main() {
  final world = const FictionalWorldFactory().build();
  const opening = PresidentOpeningStateInitializer();

  test('X2-A real shared source exactly matches independently frozen 48-club JSON', () {
    final actual = opening.prepareWorld(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      controlledClubId: 't1_01',
    );
    expect(actual.clubs, hasLength(48));
    expect(actual.byClubId, hasLength(48));
    expect(actual.controlledPresidentId, 'president_t1_01_initial');
    final evidence = <String, Object?>{
      'sourceMainSha': _sourceSha,
      'careerSeed': _config.careerSeed,
      'simulationVersion': _config.simulationVersion,
      'seasonIndex': _config.seasonIndex,
      'electionInterval': actual.electionInterval,
      'completedElectionTerms': actual.completedElectionTerms,
      'seasonsIntoCurrentTerm': actual.seasonsIntoCurrentTerm,
      'firstElectionSeasonIndex': actual.firstElectionSeasonIndex,
      'controlledClubId': actual.controlledClubId,
      'controlledPresidentId': actual.controlledPresidentId,
      'orderedClubIds': actual.orderedClubIds,
      'rows': actual.clubs.map(_frozenRow).toList(),
    };
    final frozen = jsonDecode(
      File('test/fixtures/x2_a0_president_opening_baseline.json')
          .readAsStringSync(),
    );
    expect(evidence, equals(frozen),
        reason: 'The X2-A opening MUST retain original production values.');
    print('X2A_FROZEN_48_CLUB_PARITY=PASS');
  });

  test('X2-A immutable replay, exact identity links and independent per-club RNG', () {
    final first = opening.prepareWorld(
      clubs: world.clubs, leagues: world.leagues, config: _config,
      controlledClubId: 't1_01',
    );
    final repeated = opening.prepareWorld(
      clubs: world.clubs.reversed.toList(),
      leagues: world.leagues.reversed.toList(),
      config: _config,
      controlledClubId: 't1_01',
    );
    expect(repeated.orderedClubIds, first.orderedClubIds);
    expect(repeated.clubs.map((x) => x.signature).toList(),
        first.clubs.map((x) => x.signature).toList());
    final shuffledClub = world.leagues.first.clubIds.reversed.toList();
    final reordered = opening.prepareWorld(
      clubs: world.clubs.reversed.toList(),
      leagues: [
        world.leagues.first.copyWith(clubIds: shuffledClub),
        ...world.leagues.skip(1),
      ],
      config: _config,
      controlledClubId: 't1_01',
    );
    expect(reordered.orderedClubIds.first, shuffledClub.first);
    expect(reordered.orderedClubIds, isNot(first.orderedClubIds));
    for (final id in first.orderedClubIds) {
      final state = first.byClubId[id]!;
      expect(reordered.byClubId[id]!.signature, state.signature);
      expect(state.tenure.clubId, id);
      expect(identical(state.tenure.president, state.president), isTrue);
      expect(state.managementProfile.presidentId, state.president.id);
      expect(state.fan.clubId, id);
      expect(state.media.clubId, id);
      expect(_frozenRow(state), _frozenRow(opening.prepareClub(clubId: id, config: _config)));
    }
    expect(first.byClubId['t1_01'], same(first.controlledClub));
    expect(first.controlledPresidentId, first.controlledClub!.tenure.president.id);
    expect(() => first.clubs.clear(), throwsUnsupportedError);
    expect(() => first.byClubId.clear(), throwsUnsupportedError);
    expect(() => first.orderedClubIds.clear(), throwsUnsupportedError);
    expect(() => world.leagues.first.clubIds.add('other'), throwsUnsupportedError);
    final other = opening.prepareClub(
      clubId: 't1_01', config: const SimulationConfig(careerSeed: 20260904),
    );
    expect(other.signature, isNot(first.byClubId['t1_01']!.signature));
  });

  test('X2-A small fixtures, missing/duplicate IDs and invalid openings fail closed', () {
    const club = Club(id: 'small', name: 'Small', strength: 60);
    final league = WorldLeague(tier: LeagueTier.second, clubIds: ['small']);
    final small = opening.prepareWorld(
      clubs: [club], leagues: [league], config: _config,
      controlledClubId: 'small',
    );
    expect(small.clubs, hasLength(1));
    expect(small.controlledPresidentId, 'president_small_initial');
    expect(small.orderedClubIds, ['small']);
    expect(() => opening.prepareWorld(
      clubs: [club, club], leagues: [league], config: _config,
    ), throwsStateError);
    expect(() => opening.prepareWorld(
      clubs: [club, const Club(id: 'orphan', name: 'Orphan', strength: 50)],
      leagues: [league], config: _config,
    ), throwsStateError);
    expect(() => opening.prepareWorld(
      clubs: [club],
      leagues: [WorldLeague(tier: LeagueTier.second, clubIds: ['ghost'])],
      config: _config,
    ), throwsStateError);
    expect(() => opening.prepareWorld(
      clubs: [club],
      leagues: [WorldLeague(tier: LeagueTier.second, clubIds: ['small', 'small'])],
      config: _config,
    ), throwsStateError);
    expect(() => opening.prepareWorld(
      clubs: [club], leagues: [league], config: _config,
      controlledClubId: 'ghost',
    ), throwsArgumentError);
    expect(() => opening.prepareWorld(
      clubs: [club], leagues: [league], config: _config, electionInterval: 0,
    ), throwsArgumentError);
    expect(() => opening.prepareClub(clubId: '', config: _config), throwsArgumentError);
    expect(() => opening.prepareClub(
      clubId: 'small', config: const SimulationConfig(careerSeed: 1, seasonIndex: -1),
    ), throwsArgumentError);
    expect(() => opening.prepareClub(
      clubId: 'small', config: const SimulationConfig(careerSeed: 1, simulationVersion: 0),
    ), throwsArgumentError);
    expect(() => const PresidentOpeningStateInitializer(
      managementGenerator: _BrokenManagementGenerator(),
    ).prepareClub(clubId: 'small', config: _config), throwsStateError);
    expect(() => const PresidentOpeningStateInitializer(
      presidentGenerator: _BlankPresidentGenerator(),
    ).prepareClub(clubId: 'small', config: _config), throwsStateError);
  });

  test('X2-A injected generators remain authoritative, including custom identity', () {
    final president = _CountingPresidentGenerator();
    final management = _CountingManagementGenerator();
    final initializer = PresidentOpeningStateInitializer(
      presidentGenerator: president,
      managementGenerator: management,
    );
    final state = initializer.prepareWorld(
      clubs: world.clubs, leagues: world.leagues, config: _config,
      controlledClubId: 't1_01',
    );
    expect(president.initialCalls, 48);
    expect(management.calls, 48);
    expect(state.byClubId['t1_01']!.signature,
        opening.prepareClub(clubId: 't1_01', config: _config).signature);

    const custom = PresidentOpeningStateInitializer(
      presidentGenerator: _CustomPresidentGenerator(),
    );
    final injected = custom.prepareClub(clubId: 't1_01', config: _config);
    expect(injected.president.id, 'custom_t1_01');
    expect(injected.tenure.president.id, injected.president.id);
    expect(injected.managementProfile.presidentId, injected.president.id);

    final customTenure = PresidentTenureCareerEngine(
      profileGenerator: president,
    ).simulate(clubs: world.clubs, leagues: world.leagues, config: _config, seasonCount: 1);
    final before = president.initialCalls;
    expect(before, 96);
    expect(customTenure.initialStates.first.president.id, 'president_t1_01_initial');
    final customReputation = PresidentReputationCareerEngine(
      profileGenerator: president,
    ).simulate(clubs: world.clubs, leagues: world.leagues, config: _config, seasonCount: 1);
    expect(customReputation.initialTenureStates, hasLength(48));
    expect(president.initialCalls, before + 48);
    final sponsor = SponsorRuntimeCareerEngine(
      presidentGenerator: president,
      managementProfileGenerator: management,
    ).simulateWithCheckpoint(clubs: world.clubs, leagues: world.leagues, config: _config, seasonCount: 1);
    expect(sponsor.boundaries.single.contracts, hasLength(48));
    expect(president.initialCalls, before + 96);
    expect(management.calls, 96);
    print('X2A_CUSTOM_GENERATOR_DI_PARITY=PASS');
  });

  test('X2-A legacy sponsor, M65, M79, tenure and reputation opening parity', () {
    final expected = opening.prepareWorld(
      clubs: world.clubs, leagues: world.leagues, config: _config,
      controlledClubId: 't1_01',
    );
    final tenure = const PresidentTenureCareerEngine().simulate(
      clubs: world.clubs, leagues: world.leagues, config: _config, seasonCount: 1,
    );
    final reputation = const PresidentReputationCareerEngine().simulate(
      clubs: world.clubs, leagues: world.leagues, config: _config, seasonCount: 1,
    );
    expect(tenure.initialStates.map((x) => x.signature).toList(),
        expected.clubs.map((x) => x.tenure.signature).toList());
    expect(reputation.initialTenureStates.map((x) => x.signature).toList(),
        expected.clubs.map((x) => x.tenure.signature).toList());

    final sponsor = const SponsorRuntimeCareerEngine().simulateWithCheckpoint(
      clubs: world.clubs, leagues: world.leagues, config: _config, seasonCount: 1,
    );
    for (final contract in sponsor.boundaries.single.contracts) {
      expect(contract.acceptedByPresidentId,
          expected.byClubId[contract.offer.clubId]!.president.id);
    }
    final m65 = const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs, leagues: world.leagues, config: _config,
      controlledClubId: 't1_01', seasonCount: 1,
    );
    expect(m65.checkpoint.tenureControl.playerPresidentId,
        expected.controlledPresidentId);
    final m79 = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs, leagues: world.leagues, config: _config,
      controlledClubId: 't1_01', seasonCount: 1,
    );
    expect(m79.checkpointOrNull, isNull);
    expect(m79.preparedSeasonDashboard.presidentTenure.signature,
        expected.controlledClub!.tenure.signature);
    expect(m79.preparedSeasonDashboard.fanOverallTrust,
        expected.controlledClub!.fan.overallTrust);
    expect(m79.preparedSeasonDashboard.playerControl.playerPresidentId,
        expected.controlledPresidentId);
    print('X2A_LEGACY_OPENING_DELEGATION=PASS');
  });
}
