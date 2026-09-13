import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:test/test.dart';

void main() {
  test('M64 balanced pricing preserves M40/M41 attendance exactly', () {
    const stadium = StadiumInvestmentPolicy();
    const pricing = MatchdayTicketPricingPolicy();
    final base = stadium.attendanceProfile(
      level: 3,
      clubStrength: 72,
      leaguePosition: 5,
      fanTrust: 64,
    );
    final result = pricing.apply(
      base: base,
      tier: MatchdayTicketPriceTier.balanced,
    );

    expect(result.preservesLegacyExactly, isTrue);
    expect(result.adjustedDemand, base.demand);
    expect(result.attendance, base.attendance);
    expect(result.occupancyBps, base.occupancyBps);
    expect(result.ticketYieldBps, base.ticketYieldBps);
    expect(result.revenueMultiplierBps, base.revenueMultiplierBps);
  });

  test('M64 pricing creates bounded demand and yield elasticity', () {
    const stadium = StadiumInvestmentPolicy();
    const pricing = MatchdayTicketPricingPolicy();
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
    final weakPremium = pricing.apply(
      base: weakBase,
      tier: MatchdayTicketPriceTier.premium,
    );

    expect(friendly.attendance, greaterThan(weakBase.attendance));
    expect(friendly.ticketYieldBps, lessThan(weakBase.ticketYieldBps));
    expect(weakPremium.attendance, lessThan(weakBase.attendance));
    expect(weakPremium.ticketYieldBps, greaterThan(weakBase.ticketYieldBps));
    expect(friendly.revenueMultiplierBps, inInclusiveRange(6500, 16000));
    expect(weakPremium.revenueMultiplierBps, inInclusiveRange(6500, 16000));

    final strongBase = stadium.attendanceProfile(
      level: 1,
      clubStrength: 90,
      leaguePosition: 1,
      fanTrust: 90,
    );
    final strongPremium = pricing.apply(
      base: strongBase,
      tier: MatchdayTicketPriceTier.premium,
    );
    expect(strongPremium.attendance, strongBase.attendance);
    expect(
      strongPremium.revenueMultiplierBps,
      greaterThan(strongBase.revenueMultiplierBps),
    );
  });

  test('M64 AI pricing responds to trust, occupancy and finance profile', () {
    const stadium = StadiumInvestmentPolicy();
    const policy = PresidentMatchdayTicketPricingPolicy();
    final lowTrustBase = stadium.attendanceProfile(
      level: 4,
      clubStrength: 55,
      leaguePosition: 12,
      fanTrust: 40,
    );
    final highTrustBase = stadium.attendanceProfile(
      level: 1,
      clubStrength: 90,
      leaguePosition: 1,
      fanTrust: 85,
    );
    final middleBase = stadium.attendanceProfile(
      level: 1,
      clubStrength: 68,
      leaguePosition: 7,
      fanTrust: 60,
    );

    expect(
      policy
          .choose(
            profile: _profile('low', financialDiscipline: 80),
            fanTrust: 40,
            base: lowTrustBase,
          )
          .tier,
      MatchdayTicketPriceTier.supporterFriendly,
    );
    expect(
      policy
          .choose(
            profile: _profile('high', financialDiscipline: 80),
            fanTrust: 85,
            base: highTrustBase,
          )
          .tier,
      MatchdayTicketPriceTier.premium,
    );
    expect(
      policy
          .choose(
            profile: _profile('middle', financialDiscipline: 60),
            fanTrust: 60,
            base: middleBase,
          )
          .tier,
      MatchdayTicketPriceTier.balanced,
    );
  });

  test('M64 active incumbent overrides one club and keeps 47 AI clubs exact', () {
    final fixture = _worldFixture();
    final controlledClubId = fixture.clubs.first.id;
    final tenure = PlayerPresidentTenureControlState(
      controlledClubId: controlledClubId,
      playerPresidentId: fixture.profiles[controlledClubId]!.presidentId,
      status: PlayerPresidentTenureControlStatus.active,
    );
    final baseline = const PlayerPresidentTenureGatedTicketPricingEngine()
        .resolveSeason(
      seasonIndex: 3,
      clubs: fixture.clubs,
      leaguePositionsByClub: fixture.positions,
      stadiumLevelsByClub: fixture.stadiumLevels,
      fanStatesByClub: fixture.fans,
      presidentProfilesByClub: fixture.profiles,
      tenureControl: tenure,
    );
    final player = const PlayerPresidentTenureGatedTicketPricingEngine(
      playerProvider: _FixedPricingProvider(MatchdayTicketPriceTier.premium),
    ).resolveSeason(
      seasonIndex: 3,
      clubs: fixture.clubs,
      leaguePositionsByClub: fixture.positions,
      stadiumLevelsByClub: fixture.stadiumLevels,
      fanStatesByClub: fixture.fans,
      presidentProfilesByClub: fixture.profiles,
      tenureControl: tenure,
    );

    final controlled = player.decisionFor(controlledClubId);
    expect(controlled.providerCalled, isTrue);
    expect(controlled.choice.tier, MatchdayTicketPriceTier.premium);
    expect(controlled.changedFromAi, isTrue);

    var aiParity = 0;
    for (final club in fixture.clubs.skip(1)) {
      expect(
        player.decisionFor(club.id).signature,
        baseline.decisionFor(club.id).signature,
      );
      aiParity++;
    }
    expect(aiParity, 47);
  });

  test('M64 successor mismatch and persisted loss both block the provider', () {
    const club = Club(id: 'club_a', name: 'Club A', strength: 72);
    final fans = {'club_a': FanState.initial('club_a', trust: 60)};
    const positions = {'club_a': 4};
    const levels = {'club_a': 1};
    final successorProfiles = {
      'club_a': _profile('successor', financialDiscipline: 60),
    };
    const activeOld = PlayerPresidentTenureControlState(
      controlledClubId: 'club_a',
      playerPresidentId: 'player-president',
      status: PlayerPresidentTenureControlStatus.active,
    );
    final baselineSuccessor = const PlayerPresidentTenureGatedTicketPricingEngine()
        .resolveSeason(
      seasonIndex: 4,
      clubs: const [club],
      leaguePositionsByClub: positions,
      stadiumLevelsByClub: levels,
      fanStatesByClub: fans,
      presidentProfilesByClub: successorProfiles,
      tenureControl: activeOld,
    );
    final blockedSuccessor = const PlayerPresidentTenureGatedTicketPricingEngine(
      playerProvider: _ThrowingPricingProvider(),
    ).resolveSeason(
      seasonIndex: 4,
      clubs: const [club],
      leaguePositionsByClub: positions,
      stadiumLevelsByClub: levels,
      fanStatesByClub: fans,
      presidentProfilesByClub: successorProfiles,
      tenureControl: activeOld,
    );
    expect(blockedSuccessor.signature, baselineSuccessor.signature);
    expect(blockedSuccessor.decisionFor('club_a').providerCalled, isFalse);

    const codec = PlayerPresidentTenureControlSaveCodec();
    const lost = PlayerPresidentTenureControlState(
      controlledClubId: 'club_a',
      playerPresidentId: 'player-president',
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: 4,
      successorPresidentId: 'successor',
    );
    final restored = codec.decode(codec.encode(lost));
    final oldIdentityProfiles = {
      'club_a': _profile('player-president', financialDiscipline: 60),
    };
    final baselineLost = const PlayerPresidentTenureGatedTicketPricingEngine()
        .resolveSeason(
      seasonIndex: 8,
      clubs: const [club],
      leaguePositionsByClub: positions,
      stadiumLevelsByClub: levels,
      fanStatesByClub: fans,
      presidentProfilesByClub: oldIdentityProfiles,
      tenureControl: restored,
    );
    final blockedLost = const PlayerPresidentTenureGatedTicketPricingEngine(
      playerProvider: _ThrowingPricingProvider(),
    ).resolveSeason(
      seasonIndex: 8,
      clubs: const [club],
      leaguePositionsByClub: positions,
      stadiumLevelsByClub: levels,
      fanStatesByClub: fans,
      presidentProfilesByClub: oldIdentityProfiles,
      tenureControl: restored,
    );

    expect(restored.lost, isTrue);
    expect(blockedLost.signature, baselineLost.signature);
    expect(blockedLost.decisionFor('club_a').providerCalled, isFalse);
    expect(
      const PlayerPresidentTenureGatedTicketPricingEngine(
        playerProvider: _ThrowingPricingProvider(),
      )
          .resolveSeason(
            seasonIndex: 8,
            clubs: const [club],
            leaguePositionsByClub: positions,
            stadiumLevelsByClub: levels,
            fanStatesByClub: fans,
            presidentProfilesByClub: oldIdentityProfiles,
            tenureControl: restored,
          )
          .signature,
      blockedLost.signature,
    );
  });
}

class _FixedPricingProvider extends PlayerMatchdayTicketPricingDecisionProvider {
  const _FixedPricingProvider(this.tier);

  final MatchdayTicketPriceTier tier;

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      MatchdayTicketPricingChoice(tier);
}

class _ThrowingPricingProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  const _ThrowingPricingProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    throw StateError('Player ticket-pricing provider must not run.');
  }
}

PresidentManagementProfile _profile(
  String presidentId, {
  required int financialDiscipline,
}) =>
    PresidentManagementProfile(
      presidentId: presidentId,
      archetype: PresidentManagementArchetype.balanced,
      financialDiscipline: financialDiscipline,
      riskAppetite: 60,
      transferAmbition: 60,
      youthOrientation: 60,
      managerPatience: 60,
    );

({
  List<Club> clubs,
  Map<String, int> positions,
  Map<String, int> stadiumLevels,
  Map<String, FanState> fans,
  Map<String, PresidentManagementProfile> profiles,
}) _worldFixture() {
  final world = const FictionalWorldFactory().build();
  final clubs = world.clubs;
  final positions = <String, int>{};
  final stadiumLevels = <String, int>{};
  final fans = <String, FanState>{};
  final profiles = <String, PresidentManagementProfile>{};
  for (var index = 0; index < clubs.length; index++) {
    final club = clubs[index];
    positions[club.id] = index % 16 + 1;
    stadiumLevels[club.id] = 1;
    fans[club.id] = FanState.initial(club.id, trust: 60);
    profiles[club.id] = _profile(
      'president_${club.id}',
      financialDiscipline: 60,
    );
  }
  return (
    clubs: clubs,
    positions: positions,
    stadiumLevels: stadiumLevels,
    fans: fans,
    profiles: profiles,
  );
}
