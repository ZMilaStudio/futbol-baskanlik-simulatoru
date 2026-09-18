import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

Object canonicalChoiceForRequest(
  PlayerPresidentInteractiveDecisionRequest request,
) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice.hold;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final context = request.contextAs<PlayerSponsorDecisionContext>();
      return PlayerSponsorOfferChoice(offerId: context.offers.first.id);
    case PlayerPresidentInteractiveDecisionKind.crisis:
      final context = request.contextAs<PlayerCrisisDecisionContext>();
      return PlayerCrisisActionChoice(
        action: context.availableDecisions.first.action,
      );
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return PlayerManagerReviewChoice.replace;
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      final context = request.contextAs<PlayerManagerReplacementContext>();
      return PlayerManagerReplacementChoice(
        managerId: context.candidates.first.manager.id,
      );
    case PlayerPresidentInteractiveDecisionKind.promise:
      final context = request.contextAs<PlayerPromiseDecisionContext>();
      return context.allowedTypes.first;
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      final context =
          request.contextAs<PlayerMediaStatementDecisionContext>();
      return context.allowedStances.first;
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      final context =
          request.contextAs<PlayerTransferStrategyDecisionContext>();
      return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      final context =
          request.contextAs<PlayerPresidentTicketPricingDecisionContext>();
      return context.aiChoice;
  }
}

Map<PlayerPresidentInteractiveDecisionKind,
        PlayerPresidentInteractiveDecisionPending>
    collectAllCanonicalDecisionKinds({
  required FictionalWorldSetup world,
  required SimulationConfig config,
}) {
  final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: world.clubs.first.id,
    seasonCount: 4,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
  );

  final result = <PlayerPresidentInteractiveDecisionKind,
      PlayerPresidentInteractiveDecisionPending>{};
  PlayerPresidentInteractiveSessionStep step = session.advance();

  for (var guard = 0; guard < 200; guard++) {
    if (step is PlayerPresidentInteractiveSessionCompleted) break;
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    result.putIfAbsent(pending.request.kind, () => pending);
    step = session.submit(
      request: pending.request,
      choice: canonicalChoiceForRequest(pending.request),
    );
  }

  return result;
}
