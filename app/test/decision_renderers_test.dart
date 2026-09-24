import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/decisions/renderers/crisis_decision_renderer.dart';
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

  testWidgets(
      'crisis renderer shows authoritative effects for all crisis families in source order',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.crisis]!;
    final canonical =
        pending.request.contextAs<PlayerCrisisDecisionContext>();
    const engine = CrisisDecisionEngine();

    var totalActions = 0;
    var hasPositiveMoney = false;
    var hasNegativeMoney = false;
    var hasZeroMoney = false;
    var hasPositiveInt = false;
    var hasNegativeInt = false;
    var hasZeroInt = false;

    for (final type in CrisisType.values) {
      final scenario = CrisisScenario(type: type, severity: 55);
      final decisions = engine.availableDecisions(scenario);
      final context = PlayerCrisisDecisionContext(
        crisis: canonical.crisis,
        scenario: scenario,
        availableDecisions: decisions,
        aiDecision: decisions.last,
      );

      Object? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrisisDecisionRenderer(
                context: context,
                onSubmit: (choice) => captured = choice,
              ),
            ),
          ),
        ),
      );

      final renderer = find.byKey(const Key('crisis-decision-renderer'));
      final buttons = find.descendant(
        of: renderer,
        matching: find.byType(OutlinedButton),
      );
      final actualKeys = tester
          .widgetList<OutlinedButton>(buttons)
          .map((button) => button.key)
          .toList(growable: false);
      final expectedKeys = decisions
          .map((decision) => Key('crisis-action-${decision.action.name}'))
          .toList(growable: false);
      expect(actualKeys, expectedKeys);

      expect(
        find.text(
          '${_crisisTypeLabelForTest(type)} • Şiddet: ${scenario.severity}',
        ),
        findsOneWidget,
      );
      expect(find.text(type.name), findsNothing);
      expect(find.text('AI seçimi'), findsNothing);
      expect(find.text('Önerilen seçenek'), findsNothing);
      expect(find.text('En iyi seçenek'), findsNothing);

      for (final decision in decisions) {
        totalActions++;
        final effect = decision.effect;
        final buttonFinder =
            find.byKey(Key('crisis-action-${decision.action.name}'));
        final button = tester.widget<OutlinedButton>(buttonFinder);

        expect(button.onPressed, isNotNull);
        expect(
          find.text(_crisisActionLabelForTest(decision.action)),
          findsOneWidget,
        );
        expect(
          find.text(
            'Nakit etkisi: ${_signedMoneyForTest(effect.cashDelta)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Taraftar etkisi: ${_signedIntForTest(effect.fanTrustDelta)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Medya etkisi: '
            '${_signedIntForTest(effect.mediaCredibilityDelta)}',
          ),
          findsOneWidget,
        );
        expect(find.text(decision.action.name), findsNothing);

        if (effect.cashDelta > Money.zero) {
          hasPositiveMoney = true;
        } else if (effect.cashDelta < Money.zero) {
          hasNegativeMoney = true;
        } else {
          hasZeroMoney = true;
        }
        for (final value in [
          effect.fanTrustDelta,
          effect.mediaCredibilityDelta,
        ]) {
          if (value > 0) {
            hasPositiveInt = true;
          } else if (value < 0) {
            hasNegativeInt = true;
          } else {
            hasZeroInt = true;
          }
        }

        captured = null;
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(captured, isA<PlayerCrisisActionChoice>());
        expect(
          (captured as PlayerCrisisActionChoice).action,
          decision.action,
        );
      }
    }

    expect(totalActions, 9);
    expect(hasPositiveMoney, isTrue);
    expect(hasNegativeMoney, isTrue);
    expect(hasZeroMoney, isTrue);
    expect(hasPositiveInt, isTrue);
    expect(hasNegativeInt, isTrue);
    expect(hasZeroInt, isTrue);
  });

  testWidgets('crisis submitting state disables every authoritative option',
      (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.crisis]!;
    final context = pending.request.contextAs<PlayerCrisisDecisionContext>();

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

    for (final decision in context.availableDecisions) {
      final button = tester.widget<OutlinedButton>(
        find.byKey(Key('crisis-action-${decision.action.name}')),
      );
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('crisis terms wrap at 320px and TextScale 2', (tester) async {
    final pending =
        pendingByKind[PlayerPresidentInteractiveDecisionKind.crisis]!;
    final canonical =
        pending.request.contextAs<PlayerCrisisDecisionContext>();
    const edgeDecision = CrisisDecision(
      action: CrisisAction.measuredMediaResponse,
      effect: CrisisEffect(
        cashDelta: Money.fromUnits(-987654321),
        fanTrustDelta: -123456,
        mediaCredibilityDelta: 123456789,
      ),
    );
    final context = PlayerCrisisDecisionContext(
      crisis: canonical.crisis,
      scenario: const CrisisScenario(
        type: CrisisType.mediaBacklash,
        severity: 99,
      ),
      availableDecisions: const [edgeDecision],
      aiDecision: edgeDecision,
    );

    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Object? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: CrisisDecisionRenderer(
                context: context,
                onSubmit: (choice) => captured = choice,
              ),
            ),
          ),
        ),
      ),
    );

    const lastEffect = 'Medya etkisi: +123456789';
    expect(find.text('Nakit etkisi: -987.65M'), findsOneWidget);
    expect(find.text('Taraftar etkisi: -123456'), findsOneWidget);
    expect(find.text(lastEffect), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );

    await tester.ensureVisible(find.text(lastEffect));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final buttonFinder = find.byKey(
      const Key('crisis-action-measuredMediaResponse'),
    );
    final button = tester.widget<OutlinedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pump();
    expect(captured, isA<PlayerCrisisActionChoice>());
    expect(
      (captured as PlayerCrisisActionChoice).action,
      CrisisAction.measuredMediaResponse,
    );
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

String _crisisTypeLabelForTest(CrisisType type) => switch (type) {
      CrisisType.liquiditySqueeze => 'Likidite krizi',
      CrisisType.supporterUnrest => 'Taraftar huzursuzluğu',
      CrisisType.mediaBacklash => 'Medya krizi',
    };

String _crisisActionLabelForTest(CrisisAction action) => switch (action) {
      CrisisAction.austerityPlan => 'Tasarruf planı',
      CrisisAction.bridgeSpending => 'Geçiş harcaması',
      CrisisAction.balancedRecovery => 'Dengeli toparlanma',
      CrisisAction.ambitionReset => 'Hedefleri yeniden belirle',
      CrisisAction.listeningTour => 'Taraftarı dinle',
      CrisisAction.supporterReassurance => 'Taraftara güven ver',
      CrisisAction.transparentBriefing => 'Şeffaf bilgilendirme',
      CrisisAction.confrontNarrative => 'Anlatıya karşı çık',
      CrisisAction.measuredMediaResponse => 'Ölçülü medya yanıtı',
    };

String _signedMoneyForTest(Money money) =>
    money > Money.zero ? '+${money.toString()}' : money.toString();

String _signedIntForTest(int value) => value > 0 ? '+$value' : '$value';

