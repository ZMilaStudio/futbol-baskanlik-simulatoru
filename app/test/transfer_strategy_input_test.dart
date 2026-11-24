import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

import 'support/decision_test_support.dart';

({
  PlayerPresidentInteractiveDecisionApplicationSession session,
  PlayerPresidentInteractiveDecisionPending pending,
})
_transferPending() {
  final world = const FictionalWorldFactory().build();
  final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: world.clubs.first.id,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  var step = session.advance();
  for (var guard = 0; guard < 100; guard++) {
    if (step is! PlayerPresidentInteractiveDecisionPending) break;
    if (step.request.kind ==
        PlayerPresidentInteractiveDecisionKind.transferStrategy) {
      return (session: session, pending: step);
    }
    step = session.submit(
      request: step.request,
      choice: canonicalChoiceForRequest(step.request),
    );
  }
  throw StateError('Canonical session did not produce a transfer Pending.');
}

Future<void> _pumpPanel(
  WidgetTester tester,
  PlayerPresidentInteractiveDecisionPending pending, {
  bool submitting = false,
  ValueChanged<Object>? onSubmit,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: DecisionPanel(
          pending: pending,
          submitting: submitting,
          onSubmit: onSubmit,
        ),
      ),
    ),
  ),
);

List<double> _values(WidgetTester tester) => tester
    .widgetList<Slider>(find.byType(Slider))
    .map((slider) => slider.value)
    .toList();

void main() {
  testWidgets(
    'touch-selected transfer traits reach the real session unchanged',
    (tester) async {
      final fixture = _transferPending();
      final pending = fixture.pending;
      final context = pending.request
          .contextAs<PlayerTransferStrategyDecisionContext>();
      final before = fixture.session.answeredDecisionCount;
      final choices = <PlayerTransferStrategyChoice>[];
      PlayerPresidentInteractiveDecisionSubmissionResult? submitted;
      await _pumpPanel(
        tester,
        pending,
        onSubmit: (value) {
          choices.add(value as PlayerTransferStrategyChoice);
          submitted = fixture.session.submitWithResolution(
            request: pending.request,
            choice: value,
          );
        },
      );
      expect(find.byType(Slider), findsNWidgets(4));
      final targets = [20, 90, 90, 20];
      for (var i = 0; i < targets.length; i++) {
        final slider = find.byType(Slider).at(i);
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        final width = tester.getSize(slider).width;
        final delta = targets[i] == 90 ? width / 2 - 1 : 1 - width / 2;
        // Rebuild between touch frames before sending the next pointer position.
        final gesture = await tester.startGesture(tester.getCenter(slider));
        await tester.pump();
        await gesture.moveBy(Offset(delta / 2, 0));
        await tester.pump();
        await gesture.moveBy(Offset(delta / 2, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          tester.widget<Slider>(slider).value,
          targets[i],
          reason: 'trait $i',
        );
      }
      expect(find.text('Mali disiplin: 20'), findsOneWidget);
      expect(find.text('Transfer hırsı: 90'), findsOneWidget);
      expect(find.text('Risk iştahı: 90'), findsOneWidget);
      expect(find.text('Altyapı odağı: 20'), findsOneWidget);
      expect(fixture.session.answeredDecisionCount, before);
      final submit = find.byKey(const Key('transfer-strategy-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      expect(choices, hasLength(1));
      final choice = choices.single;
      expect(choice.financialDiscipline, 20);
      expect(choice.transferAmbition, 90);
      expect(choice.riskAppetite, 90);
      expect(choice.youthOrientation, 20);
      expect(
        choice.signature,
        isNot(
          PlayerTransferStrategyChoice.fromProfile(context.aiProfile).signature,
        ),
      );
      final consequence =
          submitted!.resolution.consequence
              as PlayerPresidentTransferStrategyConsequence;
      expect(consequence.context.signature, context.signature);
      expect(consequence.effectiveProfile.financialDiscipline, 20);
      expect(consequence.effectiveProfile.transferAmbition, 90);
      expect(consequence.effectiveProfile.riskAppetite, 90);
      expect(consequence.effectiveProfile.youthOrientation, 20);
      expect(fixture.session.answeredDecisionCount, before + 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard transfer adjustment uses bounded discrete trait values',
    (tester) async {
      final fixture = _transferPending();
      PlayerTransferStrategyChoice? captured;
      await _pumpPanel(
        tester,
        fixture.pending,
        onSubmit: (value) => captured = value as PlayerTransferStrategyChoice,
      );
      final initial = _values(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      for (var i = 0; i < 75; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      expect(_values(tester).first, 90);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(_values(tester).first, 89);
      for (var i = 0; i < 75; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
      }
      expect(_values(tester).first, 20);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_values(tester), [21, ...initial.skip(1)]);
      final submit = find.byKey(const Key('transfer-strategy-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      expect(captured!.financialDiscipline, 21);
      expect(captured!.transferAmbition, initial[1]);
      expect(captured!.riskAppetite, initial[2]);
      expect(captured!.youthOrientation, initial[3]);
      final accepted = fixture.session.submitWithResolution(
        request: fixture.pending.request,
        choice: captured!,
      );
      final consequence =
          accepted.resolution.consequence
              as PlayerPresidentTransferStrategyConsequence;
      expect(consequence.effectiveProfile.financialDiscipline, 21);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disabled transfer panels ignore pointer input and submission', (
    tester,
  ) async {
    final fixture = _transferPending();
    final before = fixture.session.answeredDecisionCount;
    var emissions = 0;
    for (final submitting in [true, false]) {
      await _pumpPanel(
        tester,
        fixture.pending,
        submitting: submitting,
        onSubmit: submitting ? (_) => emissions++ : null,
      );
      final initial = _values(tester);
      for (var i = 0; i < 4; i++) {
        final slider = find.byType(Slider).at(i);
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        await tester.drag(
          slider,
          Offset(tester.getSize(slider).width / 2 - 1, 0),
        );
        await tester.pump();
      }
      final submit = find.byKey(const Key('transfer-strategy-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      expect(_values(tester), initial);
      expect(emissions, 0);
      expect(fixture.session.pendingDecision, same(fixture.pending.request));
      expect(fixture.session.answeredDecisionCount, before);
      expect(tester.takeException(), isNull);
    }
  });
}
