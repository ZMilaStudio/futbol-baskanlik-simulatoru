import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_world_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('M54 neutral bridge preserves the exact transfer market signature', () {
    final fixture = _fixture();
    final provider = _StaticProfileProvider({
      'a_buyer': _profile('buyer_neutral', youthOrientation: 60),
      'z_seller': _profile('seller_neutral', youthOrientation: 60),
    });
    final bridged = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: provider,
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 54001,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final baseline = const TransferMarketEngine().simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 54001,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    expect(bridged.signature, baseline.signature);
  });

  test('M54 bridge applies M53 youth strategy inside the real market seam', () {
    final fixture = _fixture();
    final low = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: _StaticProfileProvider({
        'a_buyer': _profile('buyer_low', youthOrientation: 20),
        'z_seller': _profile('seller_low', youthOrientation: 60),
      }),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final high = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: _StaticProfileProvider({
        'a_buyer': _profile('buyer_high', youthOrientation: 90),
        'z_seller': _profile('seller_high', youthOrientation: 60),
      }),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    expect(
      low.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId,
      'ready_forward',
    );
    expect(
      high.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId,
      'young_forward',
    );
  });

  test('M54 explicit market policies bypass the president profile bridge', () {
    final fixture = _fixture();
    const activity = TransferActivityPolicy(maxDealsPerWindow: 1);
    final explicit = {'a_buyer': activity};
    final bridged = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: const _ThrowingProfileProvider(),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 54002,
      seasonIndex: 0,
      simulationVersion: 1,
      activityPoliciesByClub: explicit,
    );
    final baseline = const TransferMarketEngine().simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 54002,
      seasonIndex: 0,
      simulationVersion: 1,
      activityPoliciesByClub: explicit,
    );

    expect(bridged.signature, baseline.signature);
  });

  test('M54 bridge wires into a real 48-club WorldCareerEngine with neutral parity', () {
    final world = const FictionalWorldFactory().build();
    final provider = _RecordingNeutralProfileProvider();
    final bridgedEngine = const PresidentTransferStrategyWorldBridge().wrap(
      base: const WorldCareerEngine(),
      profileProvider: provider,
    );
    const config = SimulationConfig(careerSeed: 54003);
    final baseline = const WorldCareerEngine().simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final bridged = bridgedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    const codec = WorldSaveCodec();

    expect(provider.callCount, 1);
    expect(provider.lastContext, isNotNull);
    expect(provider.lastContext!.clubs.length, 48);
    expect(provider.lastContext!.decisionSeasonIndex, 1);
    expect(bridged.report.signature, baseline.report.signature);
    expect(codec.encode(bridged.checkpoint), codec.encode(baseline.checkpoint));
  });

  test('M54 world bridge is deterministic for fixed inputs', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 54004);
    final firstProvider = _RecordingNeutralProfileProvider();
    final secondProvider = _RecordingNeutralProfileProvider();
    final firstEngine = const PresidentTransferStrategyWorldBridge().wrap(
      base: const WorldCareerEngine(),
      profileProvider: firstProvider,
    );
    final secondEngine = const PresidentTransferStrategyWorldBridge().wrap(
      base: const WorldCareerEngine(),
      profileProvider: secondProvider,
    );
    final first = firstEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final second = secondEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    const codec = WorldSaveCodec();

    expect(second.report.signature, first.report.signature);
    expect(codec.encode(second.checkpoint), codec.encode(first.checkpoint));
    expect(secondProvider.lastContext!.signature, firstProvider.lastContext!.signature);
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

class _ThrowingProfileProvider extends PresidentTransferStrategyProfileProvider {
  const _ThrowingProfileProvider();

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) {
    throw StateError('Profile provider must not run for explicit policy maps.');
  }
}

class _RecordingNeutralProfileProvider
    extends PresidentTransferStrategyProfileProvider {
  int callCount = 0;
  PresidentTransferStrategyWindowContext? lastContext;

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) {
    callCount += 1;
    lastContext = context;
    return {
      for (final club in context.clubs)
        club.id: _profile('${club.id}_neutral', youthOrientation: 60),
    };
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
