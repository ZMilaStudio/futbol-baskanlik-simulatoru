import '../core/simulation_config.dart';
import '../crisis/crisis_runtime_integration.dart';
import '../crisis/player_president_facility_control.dart';
import '../crisis/president_facility_investment_runtime_integration.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_tenure.dart';
import '../facility/player_president_tenure_gated_facility_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../facility/stadium_facility.dart';
import '../league/club.dart';
import '../media/player_president_media_statement_control.dart';
import '../promise/player_president_promise_control.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'player_president_sponsor_control.dart';
import 'sponsor_system.dart';

/// M69 adds M50 sponsor selection to M68's unified player-president runtime
/// without creating another checkpoint or save codec.
///
/// M65's [PlayerPresidentTicketPricingRuntimeCheckpoint] remains authoritative.
/// Sponsor choice is delegated only while the captured player-president still
/// owns the real incumbent identity. A persisted loss starts blocked, and an
/// incumbent mismatch becomes sticky inside the runtime-only sponsor provider.
/// Active multi-season contracts remain binding and the other 47 clubs stay on
/// the canonical M42 sponsor policy.
class PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedFacilitySponsorPromiseMediaTransferTicketPricingRuntimeCareerEngine({
    this.sponsorProvider,
    this.facilityProvider,
    this.promiseProvider,
    this.mediaProvider,
    this.transferStrategyProvider,
    this.ticketPricingProvider,
    this.offerEngine = const SponsorOfferEngine(),
    this.aiSponsorPolicy = const PresidentSponsorDecisionPolicy(),
    this.ticketAiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
    this.crisisIntegration = const CrisisRuntimeIntegrationEngine(),
  });

  final PlayerSponsorDecisionProvider? sponsorProvider;
  final PlayerFacilityInvestmentDecisionProvider? facilityProvider;
  final PlayerPromiseDecisionProvider? promiseProvider;
  final PlayerMediaStatementDecisionProvider? mediaProvider;
  final PlayerTransferStrategyDecisionProvider? transferStrategyProvider;
  final PlayerMatchdayTicketPricingDecisionProvider? ticketPricingProvider;
  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy aiSponsorPolicy;
  final PresidentMatchdayTicketPricingPolicy ticketAiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;
  final PlayerPresidentTenureControlGate tenureGate;
  final WorldCareerEngine baseWorldEngine;
  final PresidentFacilityInvestmentRuntimeEngine investment;
  final CrisisRuntimeIntegrationEngine crisisIntegration;

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
    final session = _M69SponsorTenureSession(
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
    final session = _M69SponsorTenureSession(
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

  PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine
      _delegate({
    required String controlledClubId,
    required _M69SponsorTenureSession session,
  }) {
    final decisions = <PlayerPresidentSponsorRuntimeDecision>[];
    final SponsorSystemEngine sponsorSystem;
    if (sponsorProvider == null) {
      sponsorSystem = SponsorSystemEngine(
        offerEngine: offerEngine,
        decisionPolicy: aiSponsorPolicy,
      );
    } else {
      sponsorSystem = PlayerPresidentSponsorSystemEngine(
        controlledClubId: controlledClubId,
        provider: _M69TenureGatedSponsorProvider(
          delegate: sponsorProvider!,
          session: session,
        ),
        decisions: decisions,
        offerEngine: offerEngine,
        decisionPolicy: aiSponsorPolicy,
      );
    }
    return PlayerPresidentTenureGatedFacilityPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      facilityProvider: facilityProvider,
      promiseProvider: promiseProvider,
      mediaProvider: mediaProvider,
      transferStrategyProvider: transferStrategyProvider,
      ticketPricingProvider: ticketPricingProvider,
      ticketAiPolicy: ticketAiPolicy,
      pricingPolicy: pricingPolicy,
      stadiumPolicy: stadiumPolicy,
      tenureGate: tenureGate,
      baseWorldEngine: baseWorldEngine,
      investment: investment,
      sponsorSystem: sponsorSystem,
      crisisIntegration: crisisIntegration,
    );
  }
}

class _M69SponsorTenureSession {
  _M69SponsorTenureSession({
    required this.playerPresidentId,
    required bool blocked,
  }) : _blocked = blocked;

  final String playerPresidentId;
  bool _blocked;

  bool allows(String presidentId) {
    if (_blocked) return false;
    if (presidentId == playerPresidentId) return true;
    _blocked = true;
    return false;
  }
}

class _M69TenureGatedSponsorProvider extends PlayerSponsorDecisionProvider {
  const _M69TenureGatedSponsorProvider({
    required this.delegate,
    required this.session,
  });

  final PlayerSponsorDecisionProvider delegate;
  final _M69SponsorTenureSession session;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    if (session.allows(context.presidentId)) {
      return delegate.choose(context);
    }
    return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
  }

  @override
  void onApplied(
    PlayerPresidentSponsorRuntimeDecision decision,
    SponsorContract contract,
  ) {
    if (session.allows(decision.presidentId)) {
      delegate.onApplied(decision, contract);
    }
  }
}
