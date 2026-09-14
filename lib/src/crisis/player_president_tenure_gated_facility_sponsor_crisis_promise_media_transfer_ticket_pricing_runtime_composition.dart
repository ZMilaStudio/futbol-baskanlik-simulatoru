import '../core/simulation_config.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_tenure.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../facility/stadium_facility.dart';
import '../league/club.dart';
import '../media/player_president_media_statement_control.dart';
import '../promise/player_president_promise_control.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../sponsor/player_president_tenure_gated_facility_sponsor_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import '../sponsor/sponsor_system.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'crisis_decision_core.dart';
import 'crisis_runtime_integration.dart';
import 'player_president_crisis_control.dart';
import 'player_president_facility_control.dart';
import 'president_facility_investment_runtime_integration.dart';

/// M70 adds M51 crisis response control to M69's unified player-president
/// runtime without creating another checkpoint or save codec.
///
/// M65's [PlayerPresidentTicketPricingRuntimeCheckpoint] remains authoritative.
/// The player crisis provider is consulted only for a real crisis belonging to
/// the controlled club while the captured player-president still owns the real
/// incumbent identity. Persisted loss starts blocked, an incumbent mismatch is
/// sticky for the in-flight runtime, and all other clubs stay on the canonical
/// M43 AI crisis path.
class PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine({
    this.crisisProvider,
    this.sponsorProvider,
    this.facilityProvider,
    this.promiseProvider,
    this.mediaProvider,
    this.transferStrategyProvider,
    this.ticketPricingProvider,
    this.offerEngine = const SponsorOfferEngine(),
    this.aiSponsorPolicy = const PresidentSponsorDecisionPolicy(),
    this.aiCrisisEngine = const CrisisDecisionEngine(activationThreshold: 55),
    this.ticketAiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
  });

  final PlayerCrisisDecisionProvider? crisisProvider;
  final PlayerSponsorDecisionProvider? sponsorProvider;
  final PlayerFacilityInvestmentDecisionProvider? facilityProvider;
  final PlayerPromiseDecisionProvider? promiseProvider;
  final PlayerMediaStatementDecisionProvider? mediaProvider;
  final PlayerTransferStrategyDecisionProvider? transferStrategyProvider;
  final PlayerMatchdayTicketPricingDecisionProvider? ticketPricingProvider;
  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy aiSponsorPolicy;
  final CrisisDecisionEngine aiCrisisEngine;
  final PresidentMatchdayTicketPricingPolicy ticketAiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;
  final PlayerPresidentTenureControlGate tenureGate;
  final WorldCareerEngine baseWorldEngine;
  final PresidentFacilityInvestmentRuntimeEngine investment;

  PlayerPresidentTicketPricingRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }
    final initialPresident = const PresidentProfileGenerator().generateInitial(
      clubId: controlledClubId,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final session = _M70CrisisTenureSession(
      playerPresidentId: initialPresident.id,
      blocked: false,
    );
    return _delegate(
      controlledClubId: controlledClubId,
      session: session,
    ).simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
  }

  PlayerPresidentTicketPricingRuntimeCareerResult resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    final tenure = checkpoint.tenureControl;
    final session = _M70CrisisTenureSession(
      playerPresidentId: tenure.playerPresidentId,
      blocked: tenure.lost,
    );
    return _delegate(
      controlledClubId: tenure.controlledClubId,
      session: session,
    ).resume(
      checkpoint: checkpoint,
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
  }

  PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine
      _delegate({
    required String controlledClubId,
    required _M70CrisisTenureSession session,
  }) {
    final CrisisRuntimeIntegrationEngine crisisIntegration;
    if (crisisProvider == null || session.blocked) {
      crisisIntegration = CrisisRuntimeIntegrationEngine(
        decisionEngine: aiCrisisEngine,
      );
    } else {
      crisisIntegration = CrisisRuntimeIntegrationEngine(
        decisionEngine: _M70PlayerPresidentCrisisDecisionEngine(
          controlledClubId: controlledClubId,
          provider: _M70TenureGatedCrisisProvider(
            delegate: crisisProvider!,
            session: session,
          ),
          aiEngine: aiCrisisEngine,
        ),
      );
    }
    return PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      sponsorProvider: sponsorProvider,
      facilityProvider: facilityProvider,
      promiseProvider: promiseProvider,
      mediaProvider: mediaProvider,
      transferStrategyProvider: transferStrategyProvider,
      ticketPricingProvider: ticketPricingProvider,
      offerEngine: offerEngine,
      aiSponsorPolicy: aiSponsorPolicy,
      ticketAiPolicy: ticketAiPolicy,
      pricingPolicy: pricingPolicy,
      stadiumPolicy: stadiumPolicy,
      tenureGate: tenureGate,
      baseWorldEngine: baseWorldEngine,
      investment: investment,
      crisisIntegration: crisisIntegration,
    );
  }
}

class _M70CrisisTenureSession {
  _M70CrisisTenureSession({
    required this.playerPresidentId,
    required bool blocked,
  }) : _blocked = blocked;

  final String playerPresidentId;
  bool _blocked;

  bool get blocked => _blocked;

  bool allows(String presidentId) {
    if (_blocked) return false;
    if (presidentId == playerPresidentId) return true;
    _blocked = true;
    return false;
  }
}

class _M70TenureGatedCrisisProvider extends PlayerCrisisDecisionProvider {
  const _M70TenureGatedCrisisProvider({
    required this.delegate,
    required this.session,
  });

  final PlayerCrisisDecisionProvider delegate;
  final _M70CrisisTenureSession session;

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    if (session.allows(context.presidentId)) {
      return delegate.choose(context);
    }
    return PlayerCrisisActionChoice(action: context.aiDecision.action);
  }
}

class _M70PlayerPresidentCrisisDecisionEngine extends CrisisDecisionEngine {
  _M70PlayerPresidentCrisisDecisionEngine({
    required this.controlledClubId,
    required this.provider,
    required this.aiEngine,
  }) : super(activationThreshold: aiEngine.activationThreshold);

  final String controlledClubId;
  final PlayerCrisisDecisionProvider provider;
  final CrisisDecisionEngine aiEngine;

  @override
  CrisisResolution? evaluate(CrisisContext context) {
    if (context.clubId != controlledClubId) {
      return aiEngine.evaluate(context);
    }

    final scenario = aiEngine.detect(context);
    if (scenario == null) {
      return null;
    }
    final aiDecision = aiEngine.choose(
      scenario: scenario,
      president: context.president,
    );
    final available = aiEngine.availableDecisions(scenario);
    final playerContext = PlayerCrisisDecisionContext(
      crisis: context,
      scenario: scenario,
      availableDecisions: available,
      aiDecision: aiDecision,
    );
    final choice = provider.choose(playerContext);
    final matches = available
        .where((decision) => decision.action == choice.action)
        .toList(growable: false);
    if (matches.length != 1) {
      throw ArgumentError.value(
        choice.action,
        'action',
        'Player crisis choice must select one action for ${scenario.type.name}.',
      );
    }
    return aiEngine.resolveAction(
      context: context,
      scenario: scenario,
      action: matches.single.action,
    );
  }
}
