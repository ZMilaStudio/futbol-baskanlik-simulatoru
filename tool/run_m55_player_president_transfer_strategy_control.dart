import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_world_bridge.dart';

void main() {
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
  final playerProvider = PlayerPresidentTransferStrategyProfileProvider(
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
  );
  final player = PresidentTransferStrategyWorldMarketEngine(
    profileProvider: playerProvider,
  ).simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    careerSeed: 24001,
    seasonIndex: 0,
    simulationVersion: 1,
  );
  final replay = PresidentTransferStrategyWorldMarketEngine(
    profileProvider: playerProvider,
  ).simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    careerSeed: 24001,
    seasonIndex: 0,
    simulationVersion: 1,
  );
  final aiTarget = ai.deals
      .firstWhere((deal) => deal.toClubId == 'a_buyer')
      .playerId;
  final playerTarget = player.deals
      .firstWhere((deal) => deal.toClubId == 'a_buyer')
      .playerId;

  final world = const FictionalWorldFactory().build();
  final profiles = {
    for (final club in world.clubs)
      club.id: _profile('${club.id}_ai', youthOrientation: 60),
  };
  final controlledClubId = world.clubs.first.id;
  final effective = PlayerPresidentTransferStrategyProfileProvider(
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
  ).profilesForWindow(
    PresidentTransferStrategyWindowContext(
      clubs: world.clubs,
      players: const [],
      financeStates: const [],
      careerSeed: 55055,
      seasonIndex: 0,
      simulationVersion: 1,
    ),
  );
  final aiParityCount = world.clubs
      .skip(1)
      .where((club) => effective[club.id]!.signature == profiles[club.id]!.signature)
      .length;
  final controlled = effective[controlledClubId]!;
  final original = profiles[controlledClubId]!;

  final passed = aiTarget == 'ready_forward' &&
      playerTarget == 'young_forward' &&
      player.signature == replay.signature &&
      aiParityCount == 47 &&
      controlled.presidentId == original.presidentId &&
      controlled.archetype == original.archetype &&
      controlled.managerPatience == original.managerPatience &&
      controlled.youthOrientation == 90;

  if (!passed) {
    throw StateError(
      'M55 canonical failure: ai=$aiTarget player=$playerTarget '
      'aiParity=$aiParityCount deterministic=${player.signature == replay.signature}',
    );
  }

  print(
    'M55_PLAYER_TRANSFER_STRATEGY_CONTROL_PASS '
    'controlled=$controlledClubId aiParity=$aiParityCount '
    'ai=$aiTarget player=$playerTarget deterministic=true '
    'identityPreserved=true worldClubs=${world.clubs.length}',
  );
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

class _FixedDecisionProvider extends PlayerTransferStrategyDecisionProvider {
  const _FixedDecisionProvider(this.choice);

  final PlayerTransferStrategyChoice choice;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      choice;
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
