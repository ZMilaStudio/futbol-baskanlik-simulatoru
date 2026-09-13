import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final clubs = world.clubs;
  final controlledClubId = clubs.first.id;
  final positions = <String, int>{};
  final stadiumLevels = <String, int>{};
  final fans = <String, FanState>{};
  final profiles = <String, PresidentManagementProfile>{};
  for (var index = 0; index < clubs.length; index++) {
    final club = clubs[index];
    positions[club.id] = index % 16 + 1;
    stadiumLevels[club.id] = 1;
    fans[club.id] = FanState.initial(club.id, trust: 60);
    profiles[club.id] = _profile('president_${club.id}');
  }

  final tenure = PlayerPresidentTenureControlState(
    controlledClubId: controlledClubId,
    playerPresidentId: profiles[controlledClubId]!.presidentId,
    status: PlayerPresidentTenureControlStatus.active,
  );
  final baseline = const PlayerPresidentTenureGatedTicketPricingEngine()
      .resolveSeason(
    seasonIndex: 3,
    clubs: clubs,
    leaguePositionsByClub: positions,
    stadiumLevelsByClub: stadiumLevels,
    fanStatesByClub: fans,
    presidentProfilesByClub: profiles,
    tenureControl: tenure,
  );
  final player = const PlayerPresidentTenureGatedTicketPricingEngine(
    playerProvider: _PremiumProvider(),
  ).resolveSeason(
    seasonIndex: 3,
    clubs: clubs,
    leaguePositionsByClub: positions,
    stadiumLevelsByClub: stadiumLevels,
    fanStatesByClub: fans,
    presidentProfilesByClub: profiles,
    tenureControl: tenure,
  );

  var aiParity = 0;
  for (final club in clubs.skip(1)) {
    if (player.decisionFor(club.id).signature !=
        baseline.decisionFor(club.id).signature) {
      throw StateError('M64 AI parity failed for ${club.id}.');
    }
    aiParity++;
  }
  final activeDelegation =
      player.decisionFor(controlledClubId).providerCalled &&
          player.decisionFor(controlledClubId).choice.tier ==
              MatchdayTicketPriceTier.premium;

  const stadium = StadiumInvestmentPolicy();
  const pricing = MatchdayTicketPricingPolicy();
  final balancedBase = stadium.attendanceProfile(
    level: 3,
    clubStrength: 72,
    leaguePosition: 5,
    fanTrust: 64,
  );
  final balancedParity = pricing
      .apply(
        base: balancedBase,
        tier: MatchdayTicketPriceTier.balanced,
      )
      .preservesLegacyExactly;
  final weakBase = stadium.attendanceProfile(
    level: 5,
    clubStrength: 55,
    leaguePosition: 12,
    fanTrust: 40,
  );
  final friendly = pricing.apply(
    base: weakBase,
    tier: MatchdayTicketPriceTier.supporterFriendly,
  );
  final premium = pricing.apply(
    base: weakBase,
    tier: MatchdayTicketPriceTier.premium,
  );
  final elasticity = friendly.attendance > weakBase.attendance &&
      friendly.ticketYieldBps < weakBase.ticketYieldBps &&
      premium.attendance < weakBase.attendance &&
      premium.ticketYieldBps > weakBase.ticketYieldBps;

  const oneClub = Club(id: 'm64_control', name: 'M64 Control', strength: 72);
  final oneFans = {'m64_control': FanState.initial('m64_control', trust: 60)};
  const onePositions = {'m64_control': 4};
  const oneLevels = {'m64_control': 1};
  final successorProfiles = {'m64_control': _profile('successor')};
  const oldActive = PlayerPresidentTenureControlState(
    controlledClubId: 'm64_control',
    playerPresidentId: 'old-player-president',
    status: PlayerPresidentTenureControlStatus.active,
  );
  final successorBaseline = const PlayerPresidentTenureGatedTicketPricingEngine()
      .resolveSeason(
    seasonIndex: 4,
    clubs: const [oneClub],
    leaguePositionsByClub: onePositions,
    stadiumLevelsByClub: oneLevels,
    fanStatesByClub: oneFans,
    presidentProfilesByClub: successorProfiles,
    tenureControl: oldActive,
  );
  final successorBlocked = const PlayerPresidentTenureGatedTicketPricingEngine(
    playerProvider: _ThrowingProvider(),
  ).resolveSeason(
    seasonIndex: 4,
    clubs: const [oneClub],
    leaguePositionsByClub: onePositions,
    stadiumLevelsByClub: oneLevels,
    fanStatesByClub: oneFans,
    presidentProfilesByClub: successorProfiles,
    tenureControl: oldActive,
  );
  final successorBlocks = successorBlocked.signature == successorBaseline.signature;

  const tenureCodec = PlayerPresidentTenureControlSaveCodec();
  const lost = PlayerPresidentTenureControlState(
    controlledClubId: 'm64_control',
    playerPresidentId: 'old-player-president',
    status: PlayerPresidentTenureControlStatus.lost,
    lostAtCompletedSeason: 4,
    successorPresidentId: 'successor',
  );
  final restored = tenureCodec.decode(tenureCodec.encode(lost));
  final oldProfiles = {'m64_control': _profile('old-player-president')};
  final lostBaseline = const PlayerPresidentTenureGatedTicketPricingEngine()
      .resolveSeason(
    seasonIndex: 8,
    clubs: const [oneClub],
    leaguePositionsByClub: onePositions,
    stadiumLevelsByClub: oneLevels,
    fanStatesByClub: oneFans,
    presidentProfilesByClub: oldProfiles,
    tenureControl: restored,
  );
  final lostBlocked = const PlayerPresidentTenureGatedTicketPricingEngine(
    playerProvider: _ThrowingProvider(),
  ).resolveSeason(
    seasonIndex: 8,
    clubs: const [oneClub],
    leaguePositionsByClub: onePositions,
    stadiumLevelsByClub: oneLevels,
    fanStatesByClub: oneFans,
    presidentProfilesByClub: oldProfiles,
    tenureControl: restored,
  );
  final stickyLoss = restored.lost && lostBlocked.signature == lostBaseline.signature;
  final deterministic = const PlayerPresidentTenureGatedTicketPricingEngine(
        playerProvider: _PremiumProvider(),
      ).resolveSeason(
        seasonIndex: 3,
        clubs: clubs,
        leaguePositionsByClub: positions,
        stadiumLevelsByClub: stadiumLevels,
        fanStatesByClub: fans,
        presidentProfilesByClub: profiles,
        tenureControl: tenure,
      ).signature ==
      player.signature;

  if (!balancedParity ||
      !elasticity ||
      !activeDelegation ||
      !successorBlocks ||
      !stickyLoss ||
      !deterministic ||
      aiParity != 47 ||
      clubs.length != 48) {
    throw StateError('M64 canonical acceptance failed.');
  }

  print(
    'M64_PLAYER_PRESIDENT_TENURE_GATED_TICKET_PRICING_CONTROL_PASS '
    'controlled=$controlledClubId aiParity=$aiParity '
    'balancedParity=$balancedParity elasticity=$elasticity '
    'activeDelegation=$activeDelegation successorBlocks=$successorBlocks '
    'stickyLoss=$stickyLoss deterministic=$deterministic '
    'worldClubs=${clubs.length} seed=$seed',
  );
}

class _PremiumProvider extends PlayerMatchdayTicketPricingDecisionProvider {
  const _PremiumProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
}

class _ThrowingProvider extends PlayerMatchdayTicketPricingDecisionProvider {
  const _ThrowingProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    throw StateError('M64 provider must be blocked.');
  }
}

PresidentManagementProfile _profile(String presidentId) =>
    PresidentManagementProfile(
      presidentId: presidentId,
      archetype: PresidentManagementArchetype.balanced,
      financialDiscipline: 60,
      riskAppetite: 60,
      transferAmbition: 60,
      youthOrientation: 60,
      managerPatience: 60,
    );
