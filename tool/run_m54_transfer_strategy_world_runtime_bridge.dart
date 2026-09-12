import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/president_transfer_strategy_world_bridge.dart';

void main() {
  final fixture = _fixture();
  final neutralProfiles = {
    'a_buyer': _profile('buyer_neutral', youthOrientation: 60),
    'z_seller': _profile('seller_neutral', youthOrientation: 60),
  };
  final neutral = PresidentTransferStrategyWorldMarketEngine(
    profileProvider: _StaticProfileProvider(neutralProfiles),
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
  final neutralParity = neutral.signature == baseline.signature;
  _check(neutralParity, 'neutral bridge must preserve market parity');

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
  final highProvider = _StaticProfileProvider({
    'a_buyer': _profile('buyer_high', youthOrientation: 90),
    'z_seller': _profile('seller_high', youthOrientation: 60),
  });
  final highEngine = PresidentTransferStrategyWorldMarketEngine(
    profileProvider: highProvider,
  );
  final high = highEngine.simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    careerSeed: 24001,
    seasonIndex: 0,
    simulationVersion: 1,
  );
  final highRepeat = highEngine.simulateWindow(
    clubs: fixture.clubs,
    players: fixture.players,
    financeStates: fixture.finances,
    careerSeed: 24001,
    seasonIndex: 0,
    simulationVersion: 1,
  );
  final lowPlayer =
      low.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId;
  final highPlayer =
      high.deals.firstWhere((deal) => deal.toClubId == 'a_buyer').playerId;
  _check(lowPlayer == 'ready_forward', 'low youth target must be ready_forward');
  _check(highPlayer == 'young_forward', 'high youth target must be young_forward');
  final deterministic = highRepeat.signature == high.signature;
  _check(deterministic, 'bridge must be deterministic');

  final world = const FictionalWorldFactory().build();
  final worldProvider = _RecordingNeutralProfileProvider();
  final worldEngine = const PresidentTransferStrategyWorldBridge().wrap(
    base: const WorldCareerEngine(),
    profileProvider: worldProvider,
  );
  final worldResult = worldEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 54004),
    seasonCount: 1,
  );
  worldResult.checkpoint.validate();
  final worldWired = worldProvider.callCount == 1 &&
      worldProvider.lastContext?.clubs.length == 48 &&
      worldProvider.lastContext?.decisionSeasonIndex == 1;
  _check(worldWired, 'bridge must receive the real 48-club world window');

  print(
    'M54_TRANSFER_STRATEGY_WORLD_BRIDGE_PASS '
    'neutralParity=$neutralParity low=$lowPlayer high=$highPlayer '
    'worldWired=$worldWired deterministic=$deterministic worldClubs=48',
  );
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
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
