import '../core/simulation_config.dart';
import '../crisis/president_facility_investment_runtime_integration.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_management_profile.dart';
import '../election/president_tenure.dart';
import '../league/club.dart';
import '../transfer/player_president_tenure_gated_transfer_strategy_control.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../transfer/president_transfer_strategy_world_bridge.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'player_president_tenure_gated_ticket_pricing_control.dart';
import 'player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'stadium_facility.dart';

/// M66 composes M60 transfer-strategy control into M65's real matchday economy
/// runtime without introducing another checkpoint or another tenure-state copy.
///
/// M65 remains the authoritative season/checkpoint/save path. M66 advances that
/// path one season at a time and rebuilds M60's transfer-market bridge from the
/// exact incumbent management profiles and tenure state stored in the current
/// M65 checkpoint. Transfer and ticket-pricing providers are therefore gated by
/// the same persisted presidency ownership state.
class PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine({
    this.transferStrategyProvider,
    this.ticketPricingProvider,
    this.ticketAiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
  });

  final PlayerTransferStrategyDecisionProvider? transferStrategyProvider;
  final PlayerMatchdayTicketPricingDecisionProvider? ticketPricingProvider;
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
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }

    final initial = _initialCompositionState(
      clubs: clubs,
      config: config,
      controlledClubId: controlledClubId,
    );
    PlayerPresidentTicketPricingRuntimeCheckpoint? current;
    var tenure = initial.tenure;
    var profiles = initial.profiles;
    final boundaries = <PlayerPresidentTicketPricingRuntimeSeasonBoundary>[];

    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final engine = _seasonEngine(
        tenure: tenure,
        profiles: profiles,
      );
      final PlayerPresidentTicketPricingRuntimeCareerResult segment;
      if (current == null) {
        segment = engine.simulateWithCheckpoint(
          clubs: clubs,
          leagues: leagues,
          config: config,
          controlledClubId: controlledClubId,
          seasonCount: 1,
          electionInterval: electionInterval,
          hasFutureSeasonAfterReport: hasFuture,
        );
      } else {
        segment = engine.resume(
          checkpoint: current,
          seasonCount: 1,
          hasFutureSeasonAfterReport: hasFuture,
        );
      }
      boundaries.add(segment.boundaries.single);
      current = segment.checkpoint;
      tenure = current.tenureControl;
      profiles = _profilesFromCheckpoint(current);
    }

    return PlayerPresidentTicketPricingRuntimeCareerResult(
      checkpoint: current!,
      boundaries: boundaries,
    );
  }

  PlayerPresidentTicketPricingRuntimeCareerResult resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint;
    final boundaries = <PlayerPresidentTicketPricingRuntimeSeasonBoundary>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final segment = _seasonEngine(
        tenure: current.tenureControl,
        profiles: _profilesFromCheckpoint(current),
      ).resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      boundaries.add(segment.boundaries.single);
      current = segment.checkpoint;
    }

    return PlayerPresidentTicketPricingRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine _seasonEngine({
    required PlayerPresidentTenureControlState tenure,
    required Map<String, PresidentManagementProfile> profiles,
  }) {
    final provider = transferStrategyProvider;
    final world = provider == null
        ? baseWorldEngine
        : const PlayerPresidentTenureGatedTransferStrategyWorldBridge().wrap(
            base: baseWorldEngine,
            aiProfileProvider: _ResolvedPresidentProfileProvider(profiles),
            tenureControl: tenure,
            decisionProvider: provider,
          );
    return PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: ticketPricingProvider,
      aiPolicy: ticketAiPolicy,
      pricingPolicy: pricingPolicy,
      stadiumPolicy: stadiumPolicy,
      tenureGate: tenureGate,
      baseWorldEngine: world,
      investment: investment,
    );
  }

  _M66CompositionState _initialCompositionState({
    required List<Club> clubs,
    required SimulationConfig config,
    required String controlledClubId,
  }) {
    const presidentGenerator = PresidentProfileGenerator();
    const managementGenerator = PresidentManagementProfileGenerator();
    final profiles = <String, PresidentManagementProfile>{};
    String? playerPresidentId;
    for (final club in clubs) {
      final president = presidentGenerator.generateInitial(
        clubId: club.id,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      profiles[club.id] = managementGenerator.generate(
        president: president,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      );
      if (club.id == controlledClubId) {
        playerPresidentId = president.id;
      }
    }
    return _M66CompositionState(
      profiles: profiles,
      tenure: PlayerPresidentTenureControlState(
        controlledClubId: controlledClubId,
        playerPresidentId: playerPresidentId!,
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
  }

  Map<String, PresidentManagementProfile> _profilesFromCheckpoint(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
  ) {
    final presidentRuntime = checkpoint.runtime.runtime.domain.presidentRuntime;
    return {
      for (final state in presidentRuntime.clubs)
        state.clubId: state.managementProfile,
    };
  }
}

class _M66CompositionState {
  const _M66CompositionState({
    required this.profiles,
    required this.tenure,
  });

  final Map<String, PresidentManagementProfile> profiles;
  final PlayerPresidentTenureControlState tenure;
}

class _ResolvedPresidentProfileProvider
    extends PresidentTransferStrategyProfileProvider {
  const _ResolvedPresidentProfileProvider(this.profiles);

  final Map<String, PresidentManagementProfile> profiles;

  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) =>
      profiles;
}
