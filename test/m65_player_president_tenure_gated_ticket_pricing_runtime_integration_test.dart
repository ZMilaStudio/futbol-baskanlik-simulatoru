import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';

class _AlwaysBalancedPolicy extends PresidentMatchdayTicketPricingPolicy {
  const _AlwaysBalancedPolicy();

  @override
  MatchdayTicketPricingChoice choose({
    required PresidentManagementProfile profile,
    required int fanTrust,
    required StadiumAttendanceProfile base,
  }) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced);
}

class _PremiumProvider extends PlayerMatchdayTicketPricingDecisionProvider {
  const _PremiumProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
}

class _DifferentTierProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  const _DifferentTierProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      MatchdayTicketPricingChoice(
        context.aiChoice.tier == MatchdayTicketPriceTier.premium
            ? MatchdayTicketPriceTier.supporterFriendly
            : MatchdayTicketPriceTier.premium,
      );
}

class _CountingPremiumProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  int calls = 0;

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    calls++;
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
  }
}

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const runtimeCodec = FacilitySponsorCrisisRuntimeSaveCodec();
  const m65Codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  test('M65 forced balanced pricing preserves M48 runtime exactly', () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.first.id;
    const baselineEngine = PresidentFacilityInvestmentRuntimeCareerEngine();
    const integratedEngine =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      aiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = baselineEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final integrated = integratedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target,
      seasonCount: 1,
    );

    expect(
      runtimeCodec.encode(integrated.checkpoint.runtime),
      runtimeCodec.encode(baseline.checkpoint),
    );
    expect(integrated.boundaries.single.source.signature,
        baseline.boundaries.single.signature);
    expect(
      integrated.boundaries.single.pricingDecisions
          .every((item) => item.outcome.preservesLegacyExactly),
      isTrue,
    );
  });

  test('M65 premium player pricing changes real matchday finance row', () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.reduce(
      (a, b) => a.strength >= b.strength ? a : b,
    );
    const balancedEngine =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      aiPolicy: _AlwaysBalancedPolicy(),
    );
    const premiumEngine =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: _PremiumProvider(),
      aiPolicy: _AlwaysBalancedPolicy(),
    );

    final balanced = balancedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target.id,
      seasonCount: 1,
    );
    final premium = premiumEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target.id,
      seasonCount: 1,
    );
    final balancedFinance = balanced.boundaries.single.financeFor(target.id);
    final premiumBoundary = premium.boundaries.single;
    final premiumFinance = premiumBoundary.financeFor(target.id);
    final decision = premiumBoundary.decisionFor(target.id);

    expect(decision.providerCalled, isTrue);
    expect(decision.choice.tier, MatchdayTicketPriceTier.premium);
    expect(decision.outcome.revenueMultiplierBps, inInclusiveRange(6500, 16000));
    expect(premiumFinance.matchdayRevenue,
        greaterThan(balancedFinance.matchdayRevenue));
    expect(premiumFinance.sponsorRevenue, balancedFinance.sponsorRevenue);
  });

  test('M65 active incumbent changes one club and keeps 47 AI finance rows exact',
      () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.reduce(
      (a, b) => a.strength >= b.strength ? a : b,
    );
    const aiEngine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    const playerEngine =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: _DifferentTierProvider(),
    );

    final ai = aiEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target.id,
      seasonCount: 1,
    );
    final player = playerEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target.id,
      seasonCount: 1,
    );
    final aiBoundary = ai.boundaries.single;
    final playerBoundary = player.boundaries.single;
    var exactAiFinanceRows = 0;
    for (final club in world.clubs) {
      final aiFinance = aiBoundary.financeFor(club.id);
      final playerFinance = playerBoundary.financeFor(club.id);
      if (club.id == target.id) {
        expect(playerBoundary.decisionFor(club.id).providerCalled, isTrue);
        expect(playerFinance.matchdayRevenue, isNot(aiFinance.matchdayRevenue));
      } else {
        expect(playerBoundary.decisionFor(club.id).providerCalled, isFalse);
        expect(playerFinance.signature, aiFinance.signature);
        exactAiFinanceRows++;
      }
    }
    expect(exactAiFinanceRows, 47);
  });

  test('M65 successor mismatch and persisted loss both block player provider',
      () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.first.id;
    const seedEngine =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      aiPolicy: _AlwaysBalancedPolicy(),
    );
    final first = seedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    final mismatchProvider = _CountingPremiumProvider();
    final mismatchCheckpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: first.checkpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: target,
        playerPresidentId: 'm65-old-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    final mismatch = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: mismatchProvider,
      aiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: mismatchCheckpoint,
      seasonCount: 1,
    );

    final lostProvider = _CountingPremiumProvider();
    final lostCheckpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: first.checkpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: target,
        playerPresidentId: 'm65-old-president',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: first.checkpoint.completedSeasons,
        successorPresidentId: 'm65-successor-president',
      ),
    );
    final lost = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: lostProvider,
      aiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: lostCheckpoint,
      seasonCount: 1,
    );

    expect(mismatchProvider.calls, 0);
    expect(mismatch.boundaries.single.decisionFor(target).providerCalled, isFalse);
    expect(mismatch.checkpoint.tenureControl.lost, isTrue);
    expect(lostProvider.calls, 0);
    expect(lost.boundaries.single.decisionFor(target).providerCalled, isFalse);
    expect(lost.checkpoint.tenureControl.lost, isTrue);
  });

  test('M65 save round trip and 2 plus 2 resume match four seasons', () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.reduce(
      (a, b) => a.strength >= b.strength ? a : b,
    ).id;
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: _DifferentTierProvider(),
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target,
      seasonCount: 4,
      electionInterval: 4,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: target,
      seasonCount: 2,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final loaded = m65Codec.decode(m65Codec.encode(first.checkpoint));
    final resumed = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(m65Codec.encode(resumed.checkpoint), m65Codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
