import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';

class _AlternativeManagerProvider extends PlayerManagerDecisionProvider {
  const _AlternativeManagerProvider();

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) =>
      PlayerManagerReviewChoice.replace;

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    final alternative = context.candidates.firstWhere(
      (candidate) => candidate.manager.id != context.aiChoice.id,
      orElse: () => context.candidates.first,
    );
    return PlayerManagerReplacementChoice(managerId: alternative.manager.id);
  }
}

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final result =
      const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    managerProvider: _AlternativeManagerProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    controlledClubId: controlledClubId,
    seasonCount: 2,
  );

  if (result.checkpoint.controlledClubId != controlledClubId ||
      result.boundaries.length != 2 ||
      result.managerDecisions.length != 1) {
    throw StateError('M71 canonical manager composition invariant failed.');
  }

  print(
    'M71_PLAYER_PRESIDENT_TENURE_GATED_FACILITY_SPONSOR_CRISIS_MANAGER_'
    'PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS '
    'controlled=$controlledClubId eightProviders=true singleCheckpoint=true '
    'managerDecisions=${result.managerDecisions.length} '
    'saveAuthority=M65 worldClubs=${world.clubs.length} seed=$seed',
  );
}
