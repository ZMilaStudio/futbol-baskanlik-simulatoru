import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('M53 resolves all four president transfer traits into runtime policies', () {
    const profile = PresidentManagementProfile(
      presidentId: 'president_high',
      archetype: PresidentManagementArchetype.ambitiousSpender,
      financialDiscipline: 90,
      riskAppetite: 90,
      transferAmbition: 90,
      youthOrientation: 90,
      managerPatience: 60,
    );
    final policy = const PresidentTransferStrategyRuntimeEngine().resolvePolicy(
      clubId: 'club_a',
      decisionSeasonIndex: 4,
      profile: profile,
    );

    expect(policy.budget.reserveCash, const Money.fromUnits(2900000));
    expect(policy.budget.windowSpendCapBps, 2750);
    expect(policy.budget.totalCommitmentCapBps, 7500);
    expect(policy.activity.maxDealsPerWindow, 3);
    expect(policy.negotiation.maxBidAdjustmentBps, 600);
    expect(policy.youthPreference.youthSignalScaleBps, 13000);
  });

  test('M53 requires exact president profile coverage for every market club', () {
    final fixture = _fixture();
    expect(
      () => const PresidentTransferStrategyRuntimeEngine().simulateWindow(
        clubs: fixture.clubs,
        players: fixture.players,
        financeStates: fixture.finances,
        presidentProfilesByClub: {
          'a_buyer': _profile('buyer', youthOrientation: 60),
        },
        careerSeed: 53001,
        seasonIndex: 0,
        simulationVersion: 1,
      ),
      throwsArgumentError,
    );
  });

  test('M53 youth strategy changes a real transfer candidate through the hook', () {
    final fixture = _fixture();
    const engine = PresidentTransferStrategyRuntimeEngine();
    final low = engine.simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      presidentProfilesByClub: {
        'a_buyer': _profile('buyer_low', youthOrientation: 20),
        'z_seller': _profile('seller_low', youthOrientation: 60),
      },
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final high = engine.simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      presidentProfilesByClub: {
        'a_buyer': _profile('buyer_high', youthOrientation: 90),
        'z_seller': _profile('seller_high', youthOrientation: 60),
      },
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    final lowBuyerDeals =
        low.market.deals.where((deal) => deal.toClubId == 'a_buyer').toList();
    final highBuyerDeals =
        high.market.deals.where((deal) => deal.toClubId == 'a_buyer').toList();
    expect(lowBuyerDeals, isNotEmpty);
    expect(highBuyerDeals, isNotEmpty);
    expect(lowBuyerDeals.first.playerId, 'ready_forward');
    expect(highBuyerDeals.first.playerId, 'young_forward');
  });

  test('M53 neutral president strategy preserves the neutral transfer market', () {
    final fixture = _fixture();
    final profiles = {
      'a_buyer': _profile('buyer_neutral', youthOrientation: 60),
      'z_seller': _profile('seller_neutral', youthOrientation: 60),
    };
    final hooked = const PresidentTransferStrategyRuntimeEngine().simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      presidentProfilesByClub: profiles,
      careerSeed: 53002,
      seasonIndex: 0,
      simulationVersion: 1,
    );
    final baseline = const TransferMarketEngine().simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      careerSeed: 53002,
      seasonIndex: 0,
      simulationVersion: 1,
    );

    expect(hooked.market.signature, baseline.signature);
  });

  test('M53 transfer strategy runtime is deterministic for fixed inputs', () {
    final fixture = _fixture();
    final profiles = {
      'a_buyer': _profile('buyer_deterministic', youthOrientation: 90),
      'z_seller': _profile('seller_deterministic', youthOrientation: 20),
    };
    const engine = PresidentTransferStrategyRuntimeEngine();
    final first = engine.simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      presidentProfilesByClub: profiles,
      careerSeed: 53003,
      seasonIndex: 2,
      simulationVersion: 1,
    );
    final second = engine.simulateWindow(
      clubs: fixture.clubs,
      players: fixture.players,
      financeStates: fixture.finances,
      presidentProfilesByClub: profiles,
      careerSeed: 53003,
      seasonIndex: 2,
      simulationVersion: 1,
    );

    expect(second.signature, first.signature);
  });
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
