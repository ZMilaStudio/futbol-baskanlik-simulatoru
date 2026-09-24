import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/renderers/sponsor_decision_renderer.dart';
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

  testWidgets('sponsor renderer shows authoritative terms in source order',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.sponsor]!;
    final context = pending.request.contextAs<PlayerSponsorDecisionContext>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DecisionPanel(
              pending: pending,
              submitting: false,
              onSubmit: (_) {},
            ),
          ),
        ),
      ),
    );

    final renderer = find.byKey(const Key('sponsor-decision-renderer'));
    final buttons = find.descendant(
      of: renderer,
      matching: find.byType(OutlinedButton),
    );
    final actualKeys = tester
        .widgetList<OutlinedButton>(buttons)
        .map((button) => button.key)
        .toList(growable: false);
    final expectedKeys = context.offers
        .map((offer) => Key('sponsor-offer-${offer.id}'))
        .toList(growable: false);
    expect(actualKeys, expectedKeys);

    for (final offer in context.offers) {
      final targetLabel = switch (offer.bonusTarget) {
        SponsorBonusTarget.topHalf => 'İlk 8',
        SponsorBonusTarget.topSix => 'İlk 6',
        SponsorBonusTarget.topFour => 'İlk 4',
        SponsorBonusTarget.champion => 'Şampiyonluk',
      };
      final button = tester.widget<OutlinedButton>(
        find.byKey(Key('sponsor-offer-${offer.id}')),
      );
      expect(button.onPressed, isNotNull);
      expect(find.text(offer.sponsorName), findsWidgets);
      expect(
        find.text('Yıllık garanti: ${offer.annualGuaranteed}'),
        findsOneWidget,
      );
      expect(
        find.text('Performans bonusu: ${offer.performanceBonus}'),
        findsOneWidget,
      );
      expect(
        find.text('Maksimum yıllık gelir: ${offer.maxAnnualRevenue}'),
        findsOneWidget,
      );
      expect(
        find.text('Sözleşme süresi: ${offer.termSeasons} sezon'),
        findsOneWidget,
      );
      expect(find.text('Bonus hedefi: $targetLabel'), findsOneWidget);
      expect(find.text(offer.bonusTarget.name), findsNothing);
      expect(find.text(offer.id), findsNothing);
      expect(find.text(offer.clubId), findsNothing);
    }

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

  testWidgets('sponsor submitting state disables every authoritative offer',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.sponsor]!;
    final context = pending.request.contextAs<PlayerSponsorDecisionContext>();

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

    for (final offer in context.offers) {
      final button = tester.widget<OutlinedButton>(
        find.byKey(Key('sponsor-offer-${offer.id}')),
      );
      expect(button.onPressed, isNull);
    }
  });

  testWidgets(
      'sponsor terms wrap at 320px and TextScale 2 with champion target',
      (tester) async {
    final canonical = pendingByKind[PlayerPresidentInteractiveDecisionKind.sponsor]!
        .request
        .contextAs<PlayerSponsorDecisionContext>();
    final offers = [
      SponsorOffer(
        id: 'm99-edge-stable',
        sponsorName: 'Nova Enerji',
        clubId: canonical.clubId,
        annualGuaranteed: const Money.fromUnits(125000000),
        performanceBonus: const Money.fromUnits(15000000),
        termSeasons: 3,
        bonusTarget: SponsorBonusTarget.topHalf,
      ),
      SponsorOffer(
        id: 'm99-edge-balanced',
        sponsorName: 'Mira Teknoloji',
        clubId: canonical.clubId,
        annualGuaranteed: const Money.fromUnits(250000000),
        performanceBonus: const Money.fromUnits(50000000),
        termSeasons: 2,
        bonusTarget: SponsorBonusTarget.topSix,
      ),
      SponsorOffer(
        id: 'm99-edge-champion',
        sponsorName:
            'Anadolu Uluslararası Sürdürülebilir Enerji ve Teknoloji '
            'Yatırımları Grubu',
        clubId: canonical.clubId,
        annualGuaranteed: const Money.fromUnits(987654321),
        performanceBonus: const Money.fromUnits(123456789),
        termSeasons: 1,
        bonusTarget: SponsorBonusTarget.champion,
      ),
    ];
    final context = PlayerSponsorDecisionContext(
      seasonIndex: canonical.seasonIndex,
      clubId: canonical.clubId,
      presidentId: canonical.presidentId,
      managementProfile: canonical.managementProfile,
      leaguePosition: canonical.leaguePosition,
      fanTrust: canonical.fanTrust,
      mediaCredibility: canonical.mediaCredibility,
      offers: offers,
      aiChoice: offers.first,
    );

    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SponsorDecisionRenderer(
                context: context,
                onSubmit: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final longName = offers.last.sponsorName;
    final lastTerm = 'Bonus hedefi: Şampiyonluk';
    expect(find.text(longName), findsOneWidget);
    expect(find.text('champion'), findsNothing);
    expect(find.text(offers.last.id), findsNothing);
    expect(find.text(offers.last.clubId), findsNothing);
    expect(
      find.text('Yıllık garanti: ${offers.last.annualGuaranteed}'),
      findsOneWidget,
    );
    expect(
      find.text('Performans bonusu: ${offers.last.performanceBonus}'),
      findsOneWidget,
    );
    expect(
      find.text('Maksimum yıllık gelir: ${offers.last.maxAnnualRevenue}'),
      findsOneWidget,
    );
    expect(find.text(lastTerm), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );

    await tester.ensureVisible(find.text(lastTerm));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(Key('sponsor-offer-${offers.last.id}')),
      findsOneWidget,
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
