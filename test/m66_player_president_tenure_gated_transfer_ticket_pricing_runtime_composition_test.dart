import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
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

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  test('M66 without transfer provider preserves M65 exactly', () {
    final world = const FictionalWorldFactory().build();
    final controlledClubId = world.clubs.first.id;
    const m65 = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: _PremiumTicketProvider(),
      aiPolicy: _AlwaysBalancedPolicy(),
    );
    const m66 =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = m65.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 2,
    );
    final composed = m66.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 2,
    );

    expect(codec.encode(composed.checkpoint), codec.encode(baseline.checkpoint));
    expect(
      composed.boundaries.map((item) => item.signature).toList(),
      baseline.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M66 composes transfer and ticket decisions in one real season', () {
    final world = const FictionalWorldFactory().build();
    final controlled = world.clubs.reduce(
      (a, b) => a.strength >= b.strength ? a : b,
    ).id;
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    const balanced =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: _YouthTransferProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    final premium =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    );

    final baseline = balanced.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );
    final composed = premium.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );
    final baselineFinance = baseline.boundaries.single.financeFor(controlled);
    final boundary = composed.boundaries.single;
    final composedFinance = boundary.financeFor(controlled);

    expect(transfer.calls, greaterThan(0));
    expect(ticket.calls, 1);
    expect(boundary.decisionFor(controlled).providerCalled, isTrue);
    expect(boundary.decisionFor(controlled).choice.tier,
        MatchdayTicketPriceTier.premium);
    expect(composedFinance.matchdayRevenue,
        greaterThan(baselineFinance.matchdayRevenue));
    expect(composed.checkpoint.tenureControl.signature,
        boundary.checkpoint.tenureControl.signature);
  });

  test('M66 one persisted lost tenure blocks both external providers', () {
    final world = const FictionalWorldFactory().build();
    final controlled = world.clubs.first.id;
    const seedEngine =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    final first = seedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final lost = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: first.checkpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: controlled,
        playerPresidentId: 'm66-former-president',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: first.checkpoint.completedSeasons,
        successorPresidentId: 'm66-successor-president',
      ),
    );
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final resumed =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: lost,
      seasonCount: 1,
    );

    expect(transfer.calls, 0);
    expect(ticket.calls, 0);
    expect(resumed.boundaries.single.decisionFor(controlled).providerCalled,
        isFalse);
    expect(resumed.checkpoint.tenureControl.lost, isTrue);
  });

  test('M66 successor mismatch blocks both providers and becomes sticky loss', () {
    final world = const FictionalWorldFactory().build();
    final controlled = world.clubs.first.id;
    const seedEngine =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    final first = seedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final mismatch = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: first.checkpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: controlled,
        playerPresidentId: 'm66-non-incumbent-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final resumed =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: mismatch,
      seasonCount: 1,
    );

    expect(transfer.calls, 0);
    expect(ticket.calls, 0);
    expect(resumed.checkpoint.tenureControl.lost, isTrue);
  });

  test('M66 save round trip and 2 plus 2 resume match four seasons', () {
    final world = const FictionalWorldFactory().build();
    final controlled = world.clubs.first.id;
    const engine =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 4,
      electionInterval: 4,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final resumed = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
