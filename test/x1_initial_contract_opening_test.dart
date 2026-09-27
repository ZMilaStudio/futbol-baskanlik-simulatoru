import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const version = 1;
  const season = 0;
  const generator = InitialContractOpeningGenerator();

  test('real WorldOpeningState supplies pure immutable X1 opening and lazy M7 parity', () {
    final world = const FictionalWorldFactory().build();
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
    );
    final inputIds = opening.players.map((p) => p.signature).toList();
    final leagueIds = opening.leagues.map((l) => l.clubIds.join('|')).toList();
    final legacy = PlayerContractController(
      careerSeed: seed,
      simulationVersion: version,
      initialSeasonIndex: season,
    );
    expect(legacy.activeContracts, isEmpty);
    expect(legacy.events, isEmpty);

    final initial = generator.generate(
      careerSeed: seed,
      simulationVersion: version,
      seasonIndex: season,
      players: opening.players,
      leagues: opening.leagues,
    );
    final repeat = generator.generate(
      careerSeed: seed,
      simulationVersion: version,
      seasonIndex: season,
      players: opening.players,
      leagues: opening.leagues,
    );
    expect(initial.activeContracts, hasLength(864));
    expect(initial.initialEvents, hasLength(864));
    expect(initial.sourceDigest, hasLength(64));
    expect(initial.sourceDigest, repeat.sourceDigest);
    expect(initial.activeContracts.map((c) => c.signature).toList(),
        repeat.activeContracts.map((c) => c.signature).toList());
    expect(initial.initialEvents.map((e) => e.signature).toList(),
        repeat.initialEvents.map((e) => e.signature).toList());
    expect(initial.matchesSource(
      careerSeed: seed,
      simulationVersion: version,
      seasonIndex: season,
      players: opening.players,
      leagues: opening.leagues,
    ), isTrue);
    expect(initial.matchesSource(
      careerSeed: seed + 1,
      simulationVersion: version,
      seasonIndex: season,
      players: opening.players,
      leagues: opening.leagues,
    ), isFalse);
    expect(initial.matchesSource(
      careerSeed: seed,
      simulationVersion: version,
      seasonIndex: season,
      players: opening.players.reversed.toList(),
      leagues: opening.leagues,
    ), isFalse);
    expect(() => initial.activeContracts.clear(), throwsUnsupportedError);
    expect(() => initial.initialEvents.clear(), throwsUnsupportedError);
    expect(opening.players.map((p) => p.signature).toList(), inputIds);
    expect(opening.leagues.map((l) => l.clubIds.join('|')).toList(), leagueIds);
    expect(legacy.activeContracts, isEmpty, reason: 'Pure generator must not initialize production.');

    final firstWages = legacy.annualWagesByClub(
      seasonIndex: season,
      players: opening.players,
      clubs: opening.baseClubs,
      leagues: opening.leagues,
      financeStates: opening.financeStates,
    )!;
    expect(legacy.activeContracts.map((c) => c.signature).toList(),
        initial.activeContracts.map((c) => c.signature).toList());
    expect(legacy.events.map((e) => e.signature).toList(),
        initial.initialEvents.map((e) => e.signature).toList());
    final independentlySummed = <String, Money>{
      for (final club in opening.baseClubs) club.id: Money.zero,
    };
    for (final contract in initial.activeContracts) {
      independentlySummed[contract.clubId] =
          independentlySummed[contract.clubId]! + contract.annualWage;
    }
    expect(firstWages, independentlySummed);
    final secondWages = legacy.annualWagesByClub(
      seasonIndex: season,
      players: opening.players,
      clubs: opening.baseClubs,
      leagues: opening.leagues,
      financeStates: opening.financeStates,
    )!;
    expect(secondWages, firstWages);
    expect(legacy.activeContracts, hasLength(864));
    expect(legacy.events, hasLength(864));
  });

  test('frozen pre-X1 production term/wage/event fixture and RNG draw order', () {
    final players = <Player>[
      const Player(
        id: 'fixed_young', name: 'Young', clubId: 'club_1',
        position: PlayerPosition.goalkeeper, age: 20,
        ability: 74, potential: 82, retirementAge: 38,
        isAcademyGraduate: false,
      ),
      const Player(
        id: 'fixed_old', name: 'Old', clubId: 'club_3',
        position: PlayerPosition.forward, age: 33,
        ability: 55, potential: 60, retirementAge: 38,
        isAcademyGraduate: false,
      ),
      const Player(
        id: 'fixed_mid', name: 'Mid', clubId: 'club_2',
        position: PlayerPosition.midfielder, age: 26,
        ability: 65, potential: 72, retirementAge: 38,
        isAcademyGraduate: false,
      ),
    ];
    final leagues = <WorldLeague>[
      WorldLeague(tier: LeagueTier.first, clubIds: ['club_1']),
      WorldLeague(tier: LeagueTier.second, clubIds: ['club_2']),
      WorldLeague(tier: LeagueTier.third, clubIds: ['club_3']),
    ];
    final initial = generator.generate(
      careerSeed: seed,
      simulationVersion: version,
      seasonIndex: season,
      players: players,
      leagues: leagues,
    );
    // Fixed baseline derived from the pre-extraction _ensureInitialized:
    // sorted ID order; initial-contract RNG; 3/3/2-year term;
    // WageModel -> tier factor -> random 9730/9533/10088 bps.
    expect(initial.activeContracts.map((c) => c.signature).toList(), [
      'fixed_mid|club_2|0|3|60610814',
      'fixed_old|club_3|0|2|25724400',
      'fixed_young|club_1|0|3|72683100',
    ]);
    expect(initial.initialEvents.map((e) => e.signature).toList(), [
      '0|fixed_mid|initial|-|club_2|60610814|3',
      '0|fixed_old|initial|-|club_3|25724400|2',
      '0|fixed_young|initial|-|club_1|72683100|3',
    ]);
    expect(players.map((p) => p.id).toList(),
        ['fixed_young', 'fixed_old', 'fixed_mid']);
    final controller = PlayerContractController(
      careerSeed: seed,
      simulationVersion: version,
      initialSeasonIndex: season,
    );
    expect(controller.activeContracts, isEmpty);
    final wages = controller.annualWagesByClub(
      seasonIndex: season,
      players: players,
      clubs: const [
        Club(id: 'club_1', name: 'One', strength: 72),
        Club(id: 'club_2', name: 'Two', strength: 64),
        Club(id: 'club_3', name: 'Three', strength: 58),
      ],
      leagues: leagues,
      financeStates: const [],
    )!;
    expect(wages['club_1'], const Money.fromMinorUnits(72683100));
    expect(wages['club_2'], const Money.fromMinorUnits(60610814));
    expect(wages['club_3'], const Money.fromMinorUnits(25724400));
    expect(controller.events.map((e) => e.signature).toList(),
        initial.initialEvents.map((e) => e.signature).toList());
    expect(controller.activeContracts.map((c) => c.signature).toList(),
        initial.activeContracts.map((c) => c.signature).toList());

    final restored = PlayerContractController.restore(
      careerSeed: seed,
      simulationVersion: version,
      initialSeasonIndex: season + 99,
      activeContracts: initial.activeContracts,
      events: initial.initialEvents,
    );
    expect(restored.annualWagesByClub(
      seasonIndex: season,
      players: players,
      clubs: const [
        Club(id: 'club_1', name: 'One', strength: 72),
        Club(id: 'club_2', name: 'Two', strength: 64),
        Club(id: 'club_3', name: 'Three', strength: 58),
      ],
      leagues: const [],
      financeStates: const [],
    ), wages);
    expect(restored.events, hasLength(3));
    expect(restored.activeContracts, hasLength(3));
  });

  test('wrong lazy season and missing tier/free agent fail closed', () {
    final world = const FictionalWorldFactory().build();
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
    );
    final controller = PlayerContractController(
      careerSeed: seed,
      simulationVersion: version,
      initialSeasonIndex: season,
    );
    expect(() => controller.annualWagesByClub(
      seasonIndex: 1,
      players: opening.players,
      clubs: opening.baseClubs,
      leagues: opening.leagues,
      financeStates: opening.financeStates,
    ), throwsStateError);
    expect(controller.activeContracts, isEmpty);
    expect(controller.events, isEmpty);

    final stray = opening.players.first.copyWith(clubId: 'unknown_club');
    final free = opening.players.first.copyWith(clubId: Player.freeAgentClubId);
    for (final bad in [stray, free]) {
      expect(() => generator.generate(
        careerSeed: seed,
        simulationVersion: version,
        seasonIndex: season,
        players: [bad],
        leagues: opening.leagues,
      ), throwsStateError);
      expect(() => controller.annualWagesByClub(
        seasonIndex: season,
        players: [bad],
        clubs: opening.baseClubs,
        leagues: opening.leagues,
        financeStates: opening.financeStates,
      ), throwsStateError);
      expect(controller.activeContracts, isEmpty);
      expect(controller.events, isEmpty);
    }
  });

  test('duplicate IDs retain legacy map-overwrite / two-event behavior', () {
    final world = const FictionalWorldFactory().build();
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
    );
    final a = opening.players.first;
    final b = a.copyWith(clubId: opening.baseClubs[1].id);
    final initial = generator.generate(
      careerSeed: seed, simulationVersion: version, seasonIndex: season,
      players: [a, b], leagues: opening.leagues,
    );
    final controller = PlayerContractController(
      careerSeed: seed, simulationVersion: version, initialSeasonIndex: season,
    );
    controller.annualWagesByClub(
      seasonIndex: season, players: [a, b], clubs: opening.baseClubs,
      leagues: opening.leagues, financeStates: opening.financeStates,
    );
    expect(initial.activeContracts, hasLength(1));
    expect(initial.initialEvents, hasLength(2));
    expect(controller.activeContracts.map((c) => c.signature).toList(),
        initial.activeContracts.map((c) => c.signature).toList());
    expect(controller.events.map((e) => e.signature).toList(),
        initial.initialEvents.map((e) => e.signature).toList());
  });

  test('advanced transfer opening uses the unchanged shared lazy contract path', () {
    final world = const FictionalWorldFactory().build();
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs, leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
    );
    final transfer = AdvancedTransferController(
      careerSeed: seed, simulationVersion: version, initialSeasonIndex: season,
    );
    expect(transfer.activeContracts, isEmpty);
    expect(transfer.contractEvents, isEmpty);
    expect(transfer.activeLoans, isEmpty);
    expect(transfer.installmentObligations, isEmpty);
    final initial = generator.generate(
      careerSeed: seed, simulationVersion: version, seasonIndex: season,
      players: opening.players, leagues: opening.leagues,
    );
    transfer.annualWagesByClub(
      seasonIndex: season, players: opening.players,
      clubs: opening.baseClubs, leagues: opening.leagues,
      financeStates: opening.financeStates,
    );
    expect(transfer.activeContracts.map((c) => c.signature).toList(),
        initial.activeContracts.map((c) => c.signature).toList());
    expect(transfer.contractEvents.map((e) => e.signature).toList(),
        initial.initialEvents.map((e) => e.signature).toList());
    expect(transfer.activeLoans, isEmpty);
    expect(transfer.installmentObligations, isEmpty);
  });
}
