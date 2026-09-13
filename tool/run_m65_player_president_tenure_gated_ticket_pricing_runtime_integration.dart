import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';

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

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  final target = world.clubs.reduce(
    (a, b) => a.strength >= b.strength ? a : b,
  );

  const baselineEngine = PresidentFacilityInvestmentRuntimeCareerEngine();
  const balancedEngine =
      PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
    aiPolicy: _AlwaysBalancedPolicy(),
  );
  final baseline = baselineEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 1,
  );
  final balanced = balancedEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: target.id,
    seasonCount: 1,
  );
  const runtimeCodec = FacilitySponsorCrisisRuntimeSaveCodec();
  final balancedM48Parity = runtimeCodec.encode(balanced.checkpoint.runtime) ==
      runtimeCodec.encode(baseline.checkpoint);

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
  var aiParity = 0;
  for (final club in world.clubs) {
    if (club.id == target.id) continue;
    if (aiBoundary.financeFor(club.id).signature ==
        playerBoundary.financeFor(club.id).signature) {
      aiParity++;
    }
  }
  final realEconomy = playerBoundary.financeFor(target.id).matchdayRevenue !=
      aiBoundary.financeFor(target.id).matchdayRevenue;
  final activeDelegation = playerBoundary.decisionFor(target.id).providerCalled;
  final bounded = playerBoundary.pricingDecisions.every(
    (decision) => decision.outcome.revenueMultiplierBps >= 6500 &&
        decision.outcome.revenueMultiplierBps <= 16000,
  );

  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  final first = playerEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: target.id,
    seasonCount: 2,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final resumed = playerEngine.resume(checkpoint: loaded, seasonCount: 2);
  final direct = playerEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: target.id,
    seasonCount: 4,
    electionInterval: 4,
  );
  final saveResume = codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint);
  final deterministic =
      [...first.boundaries, ...resumed.boundaries]
              .map((item) => item.signature)
              .join('||') ==
          direct.boundaries.map((item) => item.signature).join('||');

  if (!balancedM48Parity ||
      aiParity != 47 ||
      !realEconomy ||
      !activeDelegation ||
      !bounded ||
      !saveResume ||
      !deterministic) {
    throw StateError(
      'M65 canonical failure: balanced=$balancedM48Parity aiParity=$aiParity '
      'realEconomy=$realEconomy active=$activeDelegation bounded=$bounded '
      'saveResume=$saveResume deterministic=$deterministic',
    );
  }

  print(
    'M65_PLAYER_PRESIDENT_TENURE_GATED_TICKET_PRICING_RUNTIME_INTEGRATION_PASS '
    'controlled=${target.id} aiParity=$aiParity balancedM48Parity=$balancedM48Parity '
    'realEconomy=$realEconomy activeDelegation=$activeDelegation bounded=$bounded '
    'saveResume=$saveResume deterministic=$deterministic worldClubs=${world.clubs.length} '
    'seed=$seed',
  );
}
