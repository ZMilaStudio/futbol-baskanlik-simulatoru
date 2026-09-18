import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

import 'renderers/crisis_decision_renderer.dart';
import 'renderers/facility_decision_renderer.dart';
import 'renderers/manager_replacement_decision_renderer.dart';
import 'renderers/manager_review_decision_renderer.dart';
import 'renderers/media_decision_renderer.dart';
import 'renderers/promise_decision_renderer.dart';
import 'renderers/sponsor_decision_renderer.dart';
import 'renderers/ticket_pricing_decision_renderer.dart';
import 'renderers/transfer_strategy_decision_renderer.dart';

/// Presentation-only dispatch for an authoritative M73 pending request.
class DecisionPanel extends StatelessWidget {
  const DecisionPanel({
    super.key,
    required this.pending,
    required this.submitting,
    this.onSubmit,
  });

  final PlayerPresidentInteractiveDecisionPending pending;
  final bool submitting;
  final ValueChanged<Object>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final request = pending.request;
    final enabled = !submitting && onSubmit != null;

    return switch (request.kind) {
      PlayerPresidentInteractiveDecisionKind.facilityInvestment =>
        FacilityDecisionRenderer(
          context: request.contextAs<PlayerFacilityInvestmentContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.sponsor => SponsorDecisionRenderer(
          context: request.contextAs<PlayerSponsorDecisionContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.crisis => CrisisDecisionRenderer(
          context: request.contextAs<PlayerCrisisDecisionContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.managerReview =>
        ManagerReviewDecisionRenderer(
          context: request.contextAs<PlayerManagerReviewContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.managerReplacement =>
        ManagerReplacementDecisionRenderer(
          context: request.contextAs<PlayerManagerReplacementContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.promise => PromiseDecisionRenderer(
          context: request.contextAs<PlayerPromiseDecisionContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.mediaStatement =>
        MediaDecisionRenderer(
          context: request.contextAs<PlayerMediaStatementDecisionContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.transferStrategy =>
        TransferStrategyDecisionRenderer(
          context: request.contextAs<PlayerTransferStrategyDecisionContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
      PlayerPresidentInteractiveDecisionKind.ticketPricing =>
        TicketPricingDecisionRenderer(
          context:
              request.contextAs<PlayerPresidentTicketPricingDecisionContext>(),
          onSubmit: enabled ? (choice) => onSubmit!(choice) : null,
        ),
    };
  }
}
