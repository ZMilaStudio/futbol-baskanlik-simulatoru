import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';

class _CanonicalGateway extends PlayerPresidentDecisionGateway {
  int calls = 0;
  int managerCalls = 0;

  @override
  PlayerFacilityInvestmentChoice chooseFacilityInvestment(
    PlayerFacilityInvestmentContext context,
  ) {
    calls++;
    return PlayerFacilityInvestmentChoice.hold;
  }

  @override
  PlayerSponsorOfferChoice chooseSponsor(PlayerSponsorDecisionContext context) {
    calls++;
    return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
  }

  @override
  PlayerCrisisActionChoice chooseCrisisAction(
    PlayerCrisisDecisionContext context,
  ) {
    calls++;
    return PlayerCrisisActionChoice(action: context.aiDecision.action);
  }

  @override
  PlayerManagerReviewChoice reviewManager(PlayerManagerReviewContext context) {
    calls++;
    managerCalls++;
    return context.aiWouldReplace
        ? PlayerManagerReviewChoice.replace
        : PlayerManagerReviewChoice.retain;
  }

  @override
  PlayerManagerReplacementChoice chooseManagerReplacement(
    PlayerManagerReplacementContext context,
  ) {
    calls++;
    return PlayerManagerReplacementChoice(managerId: context.aiChoice.id);
  }

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    calls++;
    return context.aiPromise.type;
  }

  @override
  MediaStance chooseMediaStance(
    PlayerMediaStatementDecisionContext context,
  ) {
    calls++;
    return context.aiStatement.stance;
  }

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    calls++;
    return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
  }

  @override
  MatchdayTicketPricingChoice chooseTicketPricing(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    calls++;
    return context.aiChoice;
  }
}

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  final gateway = _CanonicalGateway();
  final result = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
    gateway: gateway,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
    controlledClubId: controlledClubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );

  if (result.checkpoint.controlledClubId != controlledClubId ||
      result.boundaries.length != 1 ||
      gateway.calls == 0 ||
      gateway.managerCalls != 1) {
    throw StateError('M72 canonical unified gateway invariant failed.');
  }

  print(
    'M72_PLAYER_PRESIDENT_UNIFIED_DECISION_GATEWAY_RUNTIME_PASS '
    'controlled=$controlledClubId singleGateway=true '
    'managerCalls=${gateway.managerCalls} gatewayCalls=${gateway.calls} '
    'singleCheckpoint=true saveAuthority=M65 '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
