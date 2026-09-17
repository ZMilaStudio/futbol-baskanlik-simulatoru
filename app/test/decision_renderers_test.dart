import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

import 'support/decision_test_support.dart';

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();
  late Map<PlayerPresidentInteractiveDecisionKind,
      PlayerPresidentInteractiveDecisionPending> pendingByKind;

  setUpAll(() {
    pendingByKind = collectAllCanonicalDecisionKinds(
      world: world,
      config: config,
    );
    if (pendingByKind.length !=
        PlayerPresidentInteractiveDecisionKind.values.length) {
      final missing = PlayerPresidentInteractiveDecisionKind.values
          .where((kind) => !pendingByKind.containsKey(kind))
          .map((kind) => kind.name)
          .join(',');
      throw StateError('Missing canonical decision fixtures: $missing');
    }
  });

  Future<Object?> pumpAndChoose(
    WidgetTester tester, {
    required PlayerPresidentInteractiveDecisionKind kind,
    required Key actionKey,
  }) async {
    Object? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DecisionPanel(
              pending: pendingByKind[kind]!,
              submitting: false,
              onSubmit: (choice) => captured = choice,
            ),
          ),
        ),
      ),
    );
    final action = find.byKey(actionKey);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();
    return captured;
  }

  testWidgets('facility renderer emits the existing facility choice type',
      (tester) async {
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.facilityInvestment,
      actionKey: const Key('facility-hold'),
    );
    expect(choice, isA<PlayerFacilityInvestmentChoice>());
    expect(
      (choice as PlayerFacilityInvestmentChoice).signature,
      PlayerFacilityInvestmentChoice.hold.signature,
    );
  });

  testWidgets('sponsor renderer uses an authoritative offer', (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.sponsor]!;
    final context = pending.request.contextAs<PlayerSponsorDecisionContext>();
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.sponsor,
      actionKey: Key('sponsor-offer-${context.offers.first.id}'),
    );
    expect(choice, isA<PlayerSponsorOfferChoice>());
    expect(
      (choice as PlayerSponsorOfferChoice).offerId,
      context.offers.first.id,
    );
  });

  testWidgets('crisis renderer uses an authoritative crisis action',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.crisis]!;
    final context = pending.request.contextAs<PlayerCrisisDecisionContext>();
    final action = context.availableDecisions.first.action;
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.crisis,
      actionKey: Key('crisis-action-${action.name}'),
    );
    expect(choice, isA<PlayerCrisisActionChoice>());
    expect((choice as PlayerCrisisActionChoice).action, action);
  });

  testWidgets('manager review renderer emits replace through the public enum',
      (tester) async {
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.managerReview,
      actionKey: const Key('manager-review-replace'),
    );
    expect(choice, PlayerManagerReviewChoice.replace);
  });

  testWidgets('manager replacement renderer uses canonical candidates',
      (tester) async {
    final pending = pendingByKind[
        PlayerPresidentInteractiveDecisionKind.managerReplacement]!;
    final context =
        pending.request.contextAs<PlayerManagerReplacementContext>();
    final manager = context.candidates.first.manager;
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.managerReplacement,
      actionKey: Key('manager-candidate-${manager.id}'),
    );
    expect(choice, isA<PlayerManagerReplacementChoice>());
    expect((choice as PlayerManagerReplacementChoice).managerId, manager.id);
  });

  testWidgets('promise renderer returns an authoritative allowed type',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.promise]!;
    final context = pending.request.contextAs<PlayerPromiseDecisionContext>();
    final type = context.allowedTypes.first;
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.promise,
      actionKey: Key('promise-${type.name}'),
    );
    expect(choice, type);
  });

  testWidgets('media renderer returns an authoritative allowed stance',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.mediaStatement]!;
    final context =
        pending.request.contextAs<PlayerMediaStatementDecisionContext>();
    final stance = context.allowedStances.first;
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.mediaStatement,
      actionKey: Key('media-${stance.name}'),
    );
    expect(choice, stance);
  });

  testWidgets('transfer renderer emits the existing strategy choice type',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.transferStrategy]!;
    final context =
        pending.request.contextAs<PlayerTransferStrategyDecisionContext>();
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.transferStrategy,
      actionKey: const Key('transfer-strategy-submit'),
    );
    expect(choice, isA<PlayerTransferStrategyChoice>());
    final strategy = choice as PlayerTransferStrategyChoice;
    expect(
      strategy.financialDiscipline,
      context.aiProfile.financialDiscipline,
    );
    expect(strategy.transferAmbition, context.aiProfile.transferAmbition);
    expect(strategy.riskAppetite, context.aiProfile.riskAppetite);
    expect(strategy.youthOrientation, context.aiProfile.youthOrientation);
  });

  testWidgets('ticket pricing renderer emits a canonical tier choice',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.ticketPricing]!;
    final context = pending.request
        .contextAs<PlayerPresidentTicketPricingDecisionContext>();
    final tier = MatchdayTicketPriceTier.values.first;
    final choice = await pumpAndChoose(
      tester,
      kind: PlayerPresidentInteractiveDecisionKind.ticketPricing,
      actionKey: Key('ticket-pricing-${tier.name}'),
    );
    expect(choice, isA<MatchdayTicketPricingChoice>());
    expect((choice as MatchdayTicketPricingChoice).tier, tier);
    expect(context.clubId, pending.request.clubId);
  });

  testWidgets('submitting state disables decision actions', (tester) async {
    final pending = pendingByKind[
        PlayerPresidentInteractiveDecisionKind.facilityInvestment]!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionPanel(
            pending: pending,
            submitting: true,
            onSubmit: (_) {},
          ),
        ),
      ),
    );

    final hold = tester.widget<OutlinedButton>(
      find.byKey(const Key('facility-hold')),
    );
    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('facility-submit')),
    );
    expect(hold.onPressed, isNull);
    expect(submit.onPressed, isNull);
  });
}
