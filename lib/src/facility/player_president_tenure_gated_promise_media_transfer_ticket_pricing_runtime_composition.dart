import '../core/simulation_config.dart';
import '../crisis/president_facility_investment_runtime_integration.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_management_profile.dart';
import '../election/president_tenure.dart';
import '../league/club.dart';
import '../media/media_career_engine.dart';
import '../media/player_president_media_statement_control.dart';
import '../promise/player_president_promise_control.dart';
import '../promise/promise_career_engine.dart';
import '../promise/promise_media_career_engine.dart';
import '../transfer/player_president_tenure_gated_transfer_strategy_control.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../transfer/president_transfer_strategy_world_bridge.dart';
import '../world/world_career_engine.dart';
import '../world/world_league.dart';
import 'player_president_tenure_gated_ticket_pricing_control.dart';
import 'player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'stadium_facility.dart';

/// M67 composes M63 promise/media control with M66 transfer/ticket-pricing
/// control on M65's authoritative real-economy checkpoint and save path.
///
/// No new checkpoint or save codec is introduced. Every season uses the same
/// persisted [PlayerPresidentTenureControlState] for all four external decision
/// providers. Promise/media adapters are rebuilt from that state before each
/// season, while M60 still owns the real transfer-market seam and M65 still owns
/// the ticket-pricing/economy seam. A persisted loss or incumbent mismatch
/// therefore blocks promise, media, transfer, and ticket decisions together.
class PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine({
    this.promiseProvider,
    this.mediaProvider,
    this.transferStrategyProvider,
    this.ticketPricingProvider,
    this.ticketAiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.tenureGate = const PlayerPresidentTenureControlGate(),
    this.baseWorldEngine = const WorldCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
  });

  final PlayerPromiseDecisionProvider? promiseProvider;
  final PlayerMediaStatementDecisionProvider? mediaProvider;
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
    final transferProvider = transferStrategyProvider;
    final world = transferProvider == null
        ? baseWorldEngine
        : const PlayerPresidentTenureGatedTransferStrategyWorldBridge().wrap(
            base: baseWorldEngine,
            aiProfileProvider: _ResolvedPresidentProfileProvider(profiles),
            tenureControl: tenure,
            decisionProvider: transferProvider,
          );
    final controlledProfile = profiles[tenure.controlledClubId];
    if (controlledProfile == null) {
      throw StateError(
        'Missing controlled president profile for ${tenure.controlledClubId}.',
      );
    }
    final ownsIncumbency = tenure.active &&
        controlledProfile.presidentId == tenure.playerPresidentId;
    final sourceEngine = PromiseMediaCareerEngine(
      promiseEngine: PromiseCareerEngine(
        generator: PlayerPresidentPromiseGenerator(
          controlledClubId: tenure.controlledClubId,
          decisionProvider: ownsIncumbency ? promiseProvider : null,
        ),
      ),
      mediaEngine: MediaCareerEngine(
        statementEngine: PlayerPresidentMediaStatementEngine(
          controlledClubId: tenure.controlledClubId,
          decisionProvider: ownsIncumbency ? mediaProvider : null,
        ),
      ),
    );
    return PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      playerProvider: ticketPricingProvider,
      aiPolicy: ticketAiPolicy,
      pricingPolicy: pricingPolicy,
      stadiumPolicy: stadiumPolicy,
      tenureGate: tenureGate,
      baseWorldEngine: world,
      investment: investment,
      sourceEngine: sourceEngine,
    );
  }

  _M67CompositionState _initialCompositionState({
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
    return _M67CompositionState(
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

class _M67CompositionState {
  const _M67CompositionState({
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
