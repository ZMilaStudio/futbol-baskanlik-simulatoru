import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_world_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('M55 without a player provider preserves M54 exactly', () {
    final fixture = _fixture();
    final aiProvider = _StaticProfileProvider({
      'a_buyer': _profile('buyer_ai', youthOrientation: 20),
      'z_seller': _profile('seller_ai', youthOrientation: 60),
    });
    final baseline = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: aiProvider,
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 55001,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final controlled = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: PlayerPresidentTransferStrategyProfileProvider(
        aiProfileProvider: aiProvider,
        controlledClubId: 'a_buyer',
      ),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 55001,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    expect(controlled.signature, baseline.signature);
  });

  test('M55 overrides only the controlled club transfer traits', () {
    final world = const FictionalWorldFactory().build();
    final profiles = {
      for (final club in world.clubs)
        club.id: _profile('${club.id}_ai', youthOrientation: 60),
    };
    final controlledClubId = world.clubs.first.id;
    final provider = PlayerPresidentTransferStrategyProfileProvider(
      aiProfileProvider: _StaticProfileProvider(profiles),
      controlledClubId: controlledClubId,
      decisionProvider: const _FixedDecisionProvider(
        PlayerTransferStrategyChoice(
          financialDiscipline: 90,
          transferAmbition: 20,
          riskAppetite: 20,
          youthOrientation: 90,
        ),
      ),
    );
    final context = PresidentTransferStrategyWindowContext(
      clubs: world.clubs,
      players: const [],
      financeStates: const [],
      careerSeed: 55002,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final effective = provider.profilesForWindow(context);
    final original = profiles[controlledClubId]!;
    final changed = effective[controlledClubId]!;

    expect(changed.presidentId, original.presidentId);
    expect(changed.archetype, original.archetype);
    expect(changed.managerPatience, original.managerPatience);
    expect(changed.financialDiscipline, 90);
    expect(changed.transferAmbition, 20);
    expect(changed.riskAppetite, 20);
    expect(changed.youthOrientation, 90);
    for (final club in world.clubs.skip(1)) {
      expect(effective[club.id]!.signature, profiles[club.id]!.signature);
    }
  });

  test('M55 player youth strategy changes a real transfer candidate', () {
    final fixture = _fixture();
    final aiProvider = _StaticProfileProvider({
      'a_buyer': _profile('buyer_ai', youthOrientation: 20),
      'z_seller': _profile('seller_ai', youthOrientation: 60),
    });
    final ai = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: aiProvider,
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final player = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: PlayerPresidentTransferStrategyProfileProvider(
        aiProfileProvider: aiProvider,
        controlledClubId: 'a_buyer',
        decisionProvider: const _FixedDecisionProvider(
          PlayerTransferStrategyChoice(
            financialDiscipline: 60,
            transferAmbition: 60,
            riskAppetite: 60,
            youthOrientation: 90,
          ),
        ),
      ),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    expect(
      ai.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId,
      'ready_forward',
    );
    expect(
      player.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId,
      'young_forward',
    );
  });

  test('M55 explicit market policies bypass AI and player providers', () {
    final fixture = _fixture();
    const activity = TransferActivityPolicy(maxDealsPerWindow: 1);
    final explicit = {'a_buyer': activity};
    final controlled = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: PlayerPresidentTransferStrategyProfileProvider(
        aiProfileProvider: const _ThrowingProfileProvider(),
        controlledClubId: 'a_buyer',
        decisionProvider: const _ThrowingDecisionProvider(),
      ),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 55004,
      seasonIndex: 0,
      simulationVersion: 1,
      activityPoliciesByClub: explicit,
    );
    final baseline = const TransferMarketEngine().simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 55004,
      seasonIndex: 0,
      simulationVersion: 1,
      activityPoliciesByClub: explicit,
    );

    expect(controlled.signature, baseline.signature);
  });

  test('M55 player bridge is deterministic on the real 48-club world', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 55005);
    final controlledClubId = world.clubs.first.id;
    final baseline = const PresidentTransferStrategyWorldBridge().wrap(
      base: const WorldCareerEngine(),
      profileProvider: const _NeutralWorldProfileProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final first = const PlayerPresidentTransferStrategyWorldBridge().wrap(
      base: const WorldCareerEngine(),
      aiProfileProvider: const _NeutralWorldProfileProvider(),
      controlledClubId: controlledClubId,
      decisionProvider: const _AiParityDecisionProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final second = const PlayerPresidentTransferStrategyWorldBridge().wrap(
      base: const WorldCareerEngine(),
      aiProfileProvider: const _NeutralWorldProfileProvider(),
      controlledClubId: controlledClubId,
      decisionProvider: const _AiParityDecisionProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    const codec = WorldSaveCodec();

    expect(first.report.signature, baseline.report.signature);
    expect(codec.encode(first.checkpoint), codec.encode(baseline.checkpoint));
    expect(second.report.signature, first.report.signature);
    expect(codec.encode(second.checkpoint), codec.encode(first.checkpoint));
  });
}

class _StaticProfileProvider extends PresidentTransferStrategyProfileProvider {
  const _StaticProfileProvider(this.profiles);

  final Map<String, PresidentManagementProfile> profiles;

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) =>
      profiles;
}

class _NeutralWorldProfileProvider
    extends PresidentTransferStrategyProfileProvider {
  const _NeutralWorldProfileProvider();

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) =>
      {
        for (final club in context.clubs)
          club.id: _profile('${club.id}_neutral', youthOrientation: 60),
      };
}

class _ThrowingProfileProvider extends PresidentTransferStrategyProfileProvider {
  const _ThrowingProfileProvider();

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) {
    throw StateError('AI profile provider must not run.');
  }
}

class _FixedDecisionProvider extends PlayerTransferStrategyDecisionProvider {
  const _FixedDecisionProvider(this.choice);

  final PlayerTransferStrategyChoice choice;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      choice;
}

class _AiParityDecisionProvider extends PlayerTransferStrategyDecisionProvider {
  const _AiParityDecisionProvider();

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
}

class _ThrowingDecisionProvider extends PlayerTransferStrategyDecisionProvider {
  const _ThrowingDecisionProvider();

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    throw StateError('Player decision provider must not run.');
  }
}

PresidentManagementProfile _profile(
  String presidentId, {
  required int youthOrientation,
}) =>
    PresidentManagementProfile(
      presidentId: presidentId,
      archetype: PresidentManagementArchetype.balanced,
      financialDiscipline: 60,
      riskAppetite: 60,
      transferAmbition: 60,
      youthOrientation: youthOrientation,
      managerPatience: 60,
    );

({List<Club> clubs, List<Player> players, List<ClubFinanceState> finances})
    _fixture() {
  const buyer = Club(id: 'a_buyer', name: 'Buyer', strength: 65);
  const seller = Club(id: 'z_seller', name: 'Seller', strength: 70);
  final players = <Player>[
    for (var i = 0; i < 2; i++)
      _player('buyer_gk_$i', buyer.id, PlayerPosition.goalkeeper, 65),
    for (var i = 0; i < 6; i++)
      _player('buyer_def_$i', buyer.id, PlayerPosition.defender, 65),
    for (var i = 0; i < 6; i++)
      _player('buyer_mid_$i', buyer.id, PlayerPosition.midfielder, 65),
    const Player(
      id: 'ready_forward',
      name: 'Ready Forward',
      clubId: 'z_seller',
      position: PlayerPosition.forward,
      age: 27,
      ability: 79,
      potential: 79,
      retirementAge: 36,
      isAcademyGraduate: false,
    ),
    const Player(
      id: 'young_forward',
      name: 'Young Forward',
      clubId: 'z_seller',
      position: PlayerPosition.forward,
      age: 20,
      ability: 72,
      potential: 92,
      retirementAge: 36,
      isAcademyGraduate: false,
    ),
    for (var i = 0; i < 3; i++)
      _player('seller_fwd_$i', seller.id, PlayerPosition.forward, 50),
    for (var i = 0; i < 2; i++)
      _player('seller_gk_$i', seller.id, PlayerPosition.goalkeeper, 65),
    for (var i = 0; i < 5; i++)
      _player('seller_def_$i', seller.id, PlayerPosition.defender, 65),
    for (var i = 0; i < 4; i++)
      _player('seller_mid_$i', seller.id, PlayerPosition.midfielder, 65),
  ];
  return (
    clubs: const [buyer, seller],
    players: players,
    finances: const [
      ClubFinanceState(
        clubId: 'a_buyer',
        cash: Money.fromUnits(500000000),
        debt: Money.zero,
      ),
      ClubFinanceState(
        clubId: 'z_seller',
        cash: Money.fromUnits(100000000),
        debt: Money.zero,
      ),
    ],
  );
}

Player _player(
  String id,
  String clubId,
  PlayerPosition position,
  double ability,
) =>
    Player(
      id: id,
      name: id,
      clubId: clubId,
      position: position,
      age: 27,
      ability: ability,
      potential: ability,
      retirementAge: 36,
      isAcademyGraduate: false,
    );
