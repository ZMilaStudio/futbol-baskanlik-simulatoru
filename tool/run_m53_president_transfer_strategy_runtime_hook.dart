import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_runtime.dart';

void main() {
  final fixture = _fixture();
  const engine = PresidentTransferStrategyRuntimeEngine();

  final neutralProfiles = {
    'a_buyer': _profile('buyer_neutral', youthOrientation: 60),
    'z_seller': _profile('seller_neutral', youthOrientation: 60),
  };
  final hookedNeutral = engine.simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    presidentProfilesByClub: neutralProfiles,
    careerSeed: 53053,
    seasonIndex: 0,
    simulationVersion: 1,
  );
  final baseline = const TransferMarketEngine().simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    careerSeed: 53053,
    seasonIndex: 0,
    simulationVersion: 1,
  );
  if (hookedNeutral.market.signature != baseline.signature) {
    throw StateError('M53 neutral strategy changed the neutral market.');
  }

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
  final lowBuyer = low.market.deals
      .where((deal) => deal.toClubId == 'a_buyer')
      .toList(growable: false);
  final highBuyer = high.market.deals
      .where((deal) => deal.toClubId == 'a_buyer')
      .toList(growable: false);
  if (lowBuyer.isEmpty || highBuyer.isEmpty) {
    throw StateError('M53 fixture did not produce buyer transfers.');
  }
  if (lowBuyer.first.playerId != 'ready_forward' ||
      highBuyer.first.playerId != 'young_forward') {
    throw StateError(
      'M53 youth strategy did not change the expected real candidate: '
      '${lowBuyer.first.playerId} -> ${highBuyer.first.playerId}.',
    );
  }

  final deterministicA = engine.simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    presidentProfilesByClub: {
      'a_buyer': _profile('buyer_det', youthOrientation: 90),
      'z_seller': _profile('seller_det', youthOrientation: 20),
    },
    careerSeed: 53054,
    seasonIndex: 2,
    simulationVersion: 1,
  );
  final deterministicB = engine.simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    presidentProfilesByClub: {
      'a_buyer': _profile('buyer_det', youthOrientation: 90),
      'z_seller': _profile('seller_det', youthOrientation: 20),
    },
    careerSeed: 53054,
    seasonIndex: 2,
    simulationVersion: 1,
  );
  if (deterministicA.signature != deterministicB.signature) {
    throw StateError('M53 runtime hook is not deterministic.');
  }

  final highPolicy = engine.resolvePolicy(
    clubId: 'a_buyer',
    decisionSeasonIndex: 3,
    profile: const PresidentManagementProfile(
      presidentId: 'policy_high',
      archetype: PresidentManagementArchetype.ambitiousSpender,
      financialDiscipline: 90,
      riskAppetite: 90,
      transferAmbition: 90,
      youthOrientation: 90,
      managerPatience: 60,
    ),
  );
  if (highPolicy.budget.reserveCash != const Money.fromUnits(2900000) ||
      highPolicy.budget.windowSpendCapBps != 2750 ||
      highPolicy.budget.totalCommitmentCapBps != 7500 ||
      highPolicy.activity.maxDealsPerWindow != 3 ||
      highPolicy.negotiation.maxBidAdjustmentBps != 600 ||
      highPolicy.youthPreference.youthSignalScaleBps != 13000) {
    throw StateError('M53 president trait mapping is incorrect.');
  }

  print(
    'M53_PRESIDENT_TRANSFER_STRATEGY_RUNTIME_PASS '
    'neutralParity=true low=${lowBuyer.first.playerId} '
    'high=${highBuyer.first.playerId} deterministic=true '
    'policyCoverage=${high.policies.length}',
  );
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
