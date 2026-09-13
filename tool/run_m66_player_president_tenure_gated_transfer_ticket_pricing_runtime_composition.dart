import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

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

class _PremiumTicketProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  const _PremiumTicketProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
}

class _CountingPremiumTicketProvider
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

class _YouthTransferProvider extends PlayerTransferStrategyDecisionProvider {
  const _YouthTransferProvider();

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      const PlayerTransferStrategyChoice(
        financialDiscipline: 60,
        transferAmbition: 60,
        riskAppetite: 60,
        youthOrientation: 90,
      );
}

class _CountingYouthTransferProvider
    extends PlayerTransferStrategyDecisionProvider {
  int calls = 0;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    calls++;
    return const PlayerTransferStrategyChoice(
      financialDiscipline: 60,
      transferAmbition: 60,
      riskAppetite: 60,
      youthOrientation: 90,
    );
  }
}

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  final controlled = world.clubs.reduce(
    (a, b) => a.strength >= b.strength ? a : b,
  ).id;
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  const m65 = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
    playerProvider: _PremiumTicketProvider(),
    aiPolicy: _AlwaysBalancedPolicy(),
  );
  const parityEngine =
      PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
    ticketPricingProvider: _PremiumTicketProvider(),
    ticketAiPolicy: _AlwaysBalancedPolicy(),
  );
  final baseline = m65.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final parity = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final m65ParityWithoutTransfer =
      codec.encode(parity.checkpoint) == codec.encode(baseline.checkpoint) &&
          parity.signature == baseline.signature;

  final transfer = _CountingYouthTransferProvider();
  final ticket = _CountingPremiumTicketProvider();
  final composedEngine =
      PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
    transferStrategyProvider: transfer,
    ticketPricingProvider: ticket,
    ticketAiPolicy: const _AlwaysBalancedPolicy(),
  );
  final composed = composedEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
  );
  final bothProviders = transfer.calls > 0 &&
      ticket.calls == 1 &&
      composed.boundaries.single.decisionFor(controlled).providerCalled;
  final singleCheckpoint = composed.checkpoint.controlledClubId == controlled &&
      composed.boundaries.single.checkpoint.tenureControl.signature ==
          composed.checkpoint.tenureControl.signature;

  final seedCheckpoint = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;
  final lostCheckpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
    runtime: seedCheckpoint.runtime,
    tenureControl: PlayerPresidentTenureControlState(
      controlledClubId: controlled,
      playerPresidentId: 'm66-former-president',
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: seedCheckpoint.completedSeasons,
      successorPresidentId: 'm66-successor-president',
    ),
  );
  final blockedTransfer = _CountingYouthTransferProvider();
  final blockedTicket = _CountingPremiumTicketProvider();
  final blocked =
      PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
    transferStrategyProvider: blockedTransfer,
    ticketPricingProvider: blockedTicket,
    ticketAiPolicy: const _AlwaysBalancedPolicy(),
  ).resume(
    checkpoint: lostCheckpoint,
    seasonCount: 1,
  );
  final lostBlocksBoth = blockedTransfer.calls == 0 &&
      blockedTicket.calls == 0 &&
      blocked.checkpoint.tenureControl.lost;

  const deterministicEngine =
      PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
    transferStrategyProvider: _YouthTransferProvider(),
    ticketPricingProvider: _PremiumTicketProvider(),
  );
  final direct = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 4,
    electionInterval: 4,
  );
  final first = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final resumed = deterministicEngine.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );
  final saveResume = codec.encode(resumed.checkpoint) ==
          codec.encode(direct.checkpoint) &&
      [...first.boundaries, ...resumed.boundaries]
              .map((item) => item.signature)
              .join('||') ==
          direct.boundaries.map((item) => item.signature).join('||');

  if (!m65ParityWithoutTransfer ||
      !bothProviders ||
      !singleCheckpoint ||
      !lostBlocksBoth ||
      !saveResume) {
    throw StateError(
      'M66 canonical failure: m65Parity=$m65ParityWithoutTransfer '
      'bothProviders=$bothProviders singleCheckpoint=$singleCheckpoint '
      'lostBlocksBoth=$lostBlocksBoth saveResume=$saveResume',
    );
  }

  print(
    'M66_PLAYER_PRESIDENT_TENURE_GATED_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS '
    'controlled=$controlled m65ParityWithoutTransfer=$m65ParityWithoutTransfer '
    'bothProviders=$bothProviders singleCheckpoint=$singleCheckpoint '
    'lostBlocksBoth=$lostBlocksBoth saveResume=$saveResume '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
