import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_world_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('M60 active incumbent delegates transfer strategy to player', () {
    final fixture = _fixture();
    final aiProvider = _StaticProfileProvider({
      'a_buyer': _profile('buyer_ai', youthOrientation: 20),
      'z_seller': _profile('seller_ai', youthOrientation: 60),
    });
    final player = PresidentTransferStrategyWorldMarketEngine(
      profileProvider:
          PlayerPresidentTenureGatedTransferStrategyProfileProvider(
        aiProfileProvider: aiProvider,
        tenureControl: _activeState('a_buyer', 'buyer_ai'),
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
      player.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId,
      'young_forward',
    );
  });

  test('M60 real successor identity blocks player and preserves AI path', () {
    final fixture = _fixture();
    final aiProvider = _StaticProfileProvider({
      'a_buyer': _profile('successor_ai', youthOrientation: 20),
      'z_seller': _profile('seller_ai', youthOrientation: 60),
    });
    final baseline = PresidentTransferStrategyWorldMarketEngine(
      profileProvider: aiProvider,
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final gated = PresidentTransferStrategyWorldMarketEngine(
      profileProvider:
          PlayerPresidentTenureGatedTransferStrategyProfileProvider(
        aiProfileProvider: aiProvider,
        tenureControl: _activeState('a_buyer', 'buyer_ai'),
        decisionProvider: const _ThrowingDecisionProvider(),
      ),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    expect(gated.signature, baseline.signature);
    expect(
      gated.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId,
      'ready_forward',
    );
  });

  test('M60 reelected incumbent changes only controlled club profile', () {
    final world = const FictionalWorldFactory().build();
    final controlledClubId = world.clubs.first.id;
    final profiles = {
      for (final club in world.clubs)
        club.id: _profile(
          club.id == controlledClubId ? 'player_incumbent' : '${club.id}_ai',
          youthOrientation: 60,
        ),
    };
    final provider = PlayerPresidentTenureGatedTransferStrategyProfileProvider(
      aiProfileProvider: _StaticProfileProvider(profiles),
      tenureControl: _activeState(controlledClubId, 'player_incumbent'),
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
      careerSeed: 60003,
      seasonIndex: 4,
      simulationVersion: 1,
    );
    final effective = provider.profilesForWindow(context);

    expect(effective[controlledClubId]!.presidentId, 'player_incumbent');
    expect(effective[controlledClubId]!.financialDiscipline, 90);
    expect(effective[controlledClubId]!.transferAmbition, 20);
    expect(effective[controlledClubId]!.riskAppetite, 20);
    expect(effective[controlledClubId]!.youthOrientation, 90);
    for (final club in world.clubs.skip(1)) {
      expect(effective[club.id]!.signature, profiles[club.id]!.signature);
    }
  });

  test('M60 persisted lost tenure never reactivates old president identity', () {
    const codec = PlayerPresidentTenureControlSaveCodec();
    const lost = PlayerPresidentTenureControlState(
      controlledClubId: 'a_buyer',
      playerPresidentId: 'buyer_ai',
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: 4,
      successorPresidentId: 'successor_ai',
    );
    final restored = codec.decode(codec.encode(lost));
    final profiles = {
      'a_buyer': _profile('buyer_ai', youthOrientation: 20),
      'z_seller': _profile('seller_ai', youthOrientation: 60),
    };
    final context = PresidentTransferStrategyWindowContext(
      clubs: _fixture().clubs,
      players: const [],
      financeStates: const [],
      careerSeed: 60004,
      seasonIndex: 8,
      simulationVersion: 1,
    );
    final effective = PlayerPresidentTenureGatedTransferStrategyProfileProvider(
      aiProfileProvider: _StaticProfileProvider(profiles),
      tenureControl: restored,
      decisionProvider: const _ThrowingDecisionProvider(),
    ).profilesForWindow(context);

    expect(restored.lost, isTrue);
    expect(effective['a_buyer']!.signature, profiles['a_buyer']!.signature);
    expect(effective['z_seller']!.signature, profiles['z_seller']!.signature);
  });

  test('M60 explicit market policies still bypass all profile providers', () {
    final fixture = _fixture();
    const activity = TransferActivityPolicy(maxDealsPerWindow: 1);
    final explicit = {'a_buyer': activity};
    final gated = PresidentTransferStrategyWorldMarketEngine(
      profileProvider:
          PlayerPresidentTenureGatedTransferStrategyProfileProvider(
        aiProfileProvider: const _ThrowingProfileProvider(),
        tenureControl: _activeState('a_buyer', 'buyer_ai'),
        decisionProvider: const _ThrowingDecisionProvider(),
      ),
    ).simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 60005,
      seasonIndex: 0,
      simulationVersion: 1,
      activityPoliciesByClub: explicit,
    );
    final baseline = const TransferMarketEngine().simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 60005,
      seasonIndex: 0,
      simulationVersion: 1,
      activityPoliciesByClub: explicit,
    );

    expect(gated.signature, baseline.signature);
  });
}

PlayerPresidentTenureControlState _activeState(
  String clubId,
  String presidentId,
) =>
    PlayerPresidentTenureControlState(
      controlledClubId: clubId,
      playerPresidentId: presidentId,
      status: PlayerPresidentTenureControlStatus.active,
    );

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
