import '../core/simulation_config.dart';
import '../crisis/crisis_decision_core.dart';
import '../crisis/player_president_crisis_control.dart';
import '../crisis/player_president_facility_control.dart';
import '../crisis/player_president_tenure_gated_facility_sponsor_crisis_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../manager/player_president_manager_control.dart';
import '../manager/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import '../media/media_statement.dart';
import '../media/player_president_media_statement_control.dart';
import '../promise/player_president_promise_control.dart';
import '../promise/president_promise.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../world/world_league.dart';

/// Application-facing M72 decision surface for the player-president.
///
/// M49-M71 introduced eight separate runtime decision domains. M72 does not
/// change any of those domain semantics. Instead, it lets an application layer
/// implement one gateway and have it adapted to the existing canonical
/// providers.
///
/// The gateway is runtime-only. It is never persisted, and M65's
/// [PlayerPresidentTicketPricingRuntimeCheckpoint] remains the single save
/// authority.
abstract class PlayerPresidentDecisionGateway {
  const PlayerPresidentDecisionGateway();

  PlayerFacilityInvestmentChoice chooseFacilityInvestment(
    PlayerFacilityInvestmentContext context,
  );

  PlayerSponsorOfferChoice chooseSponsor(
    PlayerSponsorDecisionContext context,
  );

  PlayerCrisisActionChoice chooseCrisisAction(
    PlayerCrisisDecisionContext context,
  );

  PlayerManagerReviewChoice reviewManager(
    PlayerManagerReviewContext context,
  );

  PlayerManagerReplacementChoice chooseManagerReplacement(
    PlayerManagerReplacementContext context,
  );

  PresidentPromiseType choosePromise(
    PlayerPromiseDecisionContext context,
  );

  MediaStance chooseMediaStance(
    PlayerMediaStatementDecisionContext context,
  );

  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  );

  MatchdayTicketPricingChoice chooseTicketPricing(
    PlayerPresidentTicketPricingDecisionContext context,
  );
}

/// M72 adapts one [PlayerPresidentDecisionGateway] to M71's eight existing
/// player-president provider surfaces.
///
/// With no gateway supplied, this engine is exact M71 behavior. With a gateway,
/// only the controlled club and only the currently owned player-president
/// tenure can delegate to the application. All tenure-loss, successor, AI
/// parity, determinism and save/resume behavior remain owned by M58-M71.
class PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine {
  const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine({
    this.gateway,
    this.aiCrisisEngine = const CrisisDecisionEngine(activationThreshold: 55),
    this.ticketAiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.candidateLimit = 5,
  }) : assert(candidateLimit > 0);

  final PlayerPresidentDecisionGateway? gateway;
  final CrisisDecisionEngine aiCrisisEngine;
  final PresidentMatchdayTicketPricingPolicy ticketAiPolicy;
  final int candidateLimit;

  PlayerPresidentUnifiedManagerRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) =>
      _delegate().simulateWithCheckpoint(
        clubs: clubs,
        leagues: leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: seasonCount,
        electionInterval: electionInterval,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );

  PlayerPresidentUnifiedManagerRuntimeCareerResult resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) =>
      _delegate().resume(
        checkpoint: checkpoint,
        seasonCount: seasonCount,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );

  PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine
      _delegate() {
    final decisionGateway = gateway;
    final source =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      crisisProvider: decisionGateway == null
          ? null
          : _GatewayCrisisProvider(decisionGateway),
      sponsorProvider: decisionGateway == null
          ? null
          : _GatewaySponsorProvider(decisionGateway),
      facilityProvider: decisionGateway == null
          ? null
          : _GatewayFacilityProvider(decisionGateway),
      promiseProvider: decisionGateway == null
          ? null
          : _GatewayPromiseProvider(decisionGateway),
      mediaProvider: decisionGateway == null
          ? null
          : _GatewayMediaProvider(decisionGateway),
      transferStrategyProvider: decisionGateway == null
          ? null
          : _GatewayTransferProvider(decisionGateway),
      ticketPricingProvider: decisionGateway == null
          ? null
          : _GatewayTicketPricingProvider(decisionGateway),
      aiCrisisEngine: aiCrisisEngine,
      ticketAiPolicy: ticketAiPolicy,
    );
    return PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      managerProvider: decisionGateway == null
          ? null
          : _GatewayManagerProvider(decisionGateway),
      sourceEngine: source,
      candidateLimit: candidateLimit,
    );
  }
}

class _GatewayFacilityProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _GatewayFacilityProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  PlayerFacilityInvestmentChoice choose(
    PlayerFacilityInvestmentContext context,
  ) =>
      gateway.chooseFacilityInvestment(context);
}

class _GatewaySponsorProvider extends PlayerSponsorDecisionProvider {
  const _GatewaySponsorProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) =>
      gateway.chooseSponsor(context);
}

class _GatewayCrisisProvider extends PlayerCrisisDecisionProvider {
  const _GatewayCrisisProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) =>
      gateway.chooseCrisisAction(context);
}

class _GatewayManagerProvider extends PlayerManagerDecisionProvider {
  const _GatewayManagerProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) =>
      gateway.reviewManager(context);

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) =>
      gateway.chooseManagerReplacement(context);
}

class _GatewayPromiseProvider extends PlayerPromiseDecisionProvider {
  const _GatewayPromiseProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      gateway.choosePromise(context);
}

class _GatewayMediaProvider extends PlayerMediaStatementDecisionProvider {
  const _GatewayMediaProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) =>
      gateway.chooseMediaStance(context);
}

class _GatewayTransferProvider extends PlayerTransferStrategyDecisionProvider {
  const _GatewayTransferProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      gateway.chooseTransferStrategy(context);
}

class _GatewayTicketPricingProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  const _GatewayTicketPricingProvider(this.gateway);

  final PlayerPresidentDecisionGateway gateway;

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      gateway.chooseTicketPricing(context);
}
