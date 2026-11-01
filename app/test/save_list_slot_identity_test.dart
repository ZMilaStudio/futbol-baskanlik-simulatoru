import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/dashboard/president_prepared_season_dashboard_panel.dart';
import 'package:futbol_baskanlik_app/decisions/decision_panel.dart';
import 'package:futbol_baskanlik_app/screens/president_home_screen.dart';
import 'package:futbol_baskanlik_app/screens/save_list_screen.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';

import 'support/decision_test_support.dart';

void main() {
  late Directory directory;
  late AppComposition composition;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fbs-save-list-identity-');
    composition = AppComposition.withSaveDirectory(directory);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  PlayerPresidentInteractiveDecisionApplicationSession bootstrap(int club) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: composition.world.clubs,
        leagues: composition.world.leagues,
        config: composition.simulationConfig,
        controlledClubId: composition.world.clubs[club].id,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
      );

  PlayerPresidentInteractiveDecisionApplicationSession checkpoint(int club) {
    final result =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine()
            .simulateWithCheckpoint(
      clubs: composition.world.clubs,
      leagues: composition.world.leagues,
      config: composition.simulationConfig,
      controlledClubId: composition.world.clubs[club].id,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    return PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: result.checkpoint,
      resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      ),
    );
  }

  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary save(
    PlayerPresidentInteractiveDecisionApplicationSession session, {
    String slotId = 'target',
  }) {
    final source = composition.saveSlots.save(slotId: slotId, session: session);
    return composition.saveSlots.inspect(source: source, slotId: slotId)!;
  }

  Map<String, List<int>> bytes() => {
        for (final file
            in directory.listSync(recursive: true).whereType<File>())
          file.path.substring(directory.path.length): file.readAsBytesSync(),
      };

  Future<void> render(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SaveListScreen(composition: composition)),
    );
    await tester.pumpAndSettle();
  }

  void expectRenderedClub(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
    int club,
  ) {
    expect(
      find.descendant(
        of: find.byKey(Key('save-${summary.identity}')),
        matching: find.text(composition.world.clubs[club].name),
      ),
      findsOneWidget,
    );
  }

  Future<void> act(
    WidgetTester tester,
    String action,
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) async {
    await tester.tap(find.byKey(Key('$action-${summary.identity}')));
    await tester.pumpAndSettle();
  }

  void expectStillOnList() {
    expect(find.byType(SaveListScreen), findsOneWidget);
    expect(find.byType(PresidentHomeScreen), findsNothing);
  }

  testWidgets('stale wrong-club Continue does not open the overwritten career',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    save(bootstrap(1));
    expectRenderedClub(summary, 0);
    final before = bytes();

    await act(tester, 'continue', summary);

    expectStillOnList();
    expect(find.text('Kayıt açılamadı.'), findsOneWidget);
    expectRenderedClub(summary, 1);
    expect(bytes(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale wrong-club Delete does not remove the overwritten career',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    save(bootstrap(1));
    expectRenderedClub(summary, 0);
    final before = bytes();

    await act(tester, 'delete', summary);

    expectStillOnList();
    expect(find.text('Kayıt silinemedi.'), findsOneWidget);
    expectRenderedClub(summary, 1);
    expect(bytes(), before);
    expect(
        composition.saveSlots
            .inspect(source: summary.source, slotId: summary.slotId)!
            .controlledClubId,
        composition.world.clubs[1].id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matching Continue opens the genuine displayed career',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    final before = bytes();

    await act(tester, 'continue', summary);

    expect(find.byType(PresidentHomeScreen), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('selected-club-name'))).data,
        composition.world.clubs[0].name);
    final panel = tester.widget<DecisionPanel>(find.byType(DecisionPanel));
    expect(panel.pending.request.clubId, composition.world.clubs[0].id);
    expect(bytes(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matching Delete removes only its displayed typed slot',
      (tester) async {
    save(bootstrap(1), slotId: 'unrelated');
    final unrelated = bytes();
    final summary = save(bootstrap(0));
    await render(tester);

    await act(tester, 'delete', summary);

    expectStillOnList();
    expect(find.text('Kayıt silindi.'), findsOneWidget);
    expect(bytes(), unrelated);
    expect(
        composition.saveSlots
            .inspect(source: summary.source, slotId: summary.slotId),
        isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'same-club updated history remains loadable from the rendered row',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    final updated = bootstrap(0);
    final pending =
        updated.advance() as PlayerPresidentInteractiveDecisionPending;
    final next = updated.submit(
            request: pending.request,
            choice: canonicalChoiceForRequest(pending.request))
        as PlayerPresidentInteractiveDecisionPending;
    final current = save(updated);
    expect(summary.answeredDecisionCount, 0);
    expect(current.answeredDecisionCount, 1);
    final before = bytes();

    await act(tester, 'continue', summary);

    expect(find.byType(PresidentHomeScreen), findsOneWidget);
    final panel = tester.widget<DecisionPanel>(find.byType(DecisionPanel));
    expect(panel.pending.request.key, next.request.key);
    expect(panel.pending.request.sequence, 2);
    expect(bytes(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'same-club updated history remains deletable from the rendered row',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    final updated = bootstrap(0);
    final pending =
        updated.advance() as PlayerPresidentInteractiveDecisionPending;
    updated.submit(
        request: pending.request,
        choice: canonicalChoiceForRequest(pending.request));
    expect(save(updated).answeredDecisionCount, 1);

    await act(tester, 'delete', summary);

    expect(find.byKey(const Key('empty-save-list')), findsOneWidget);
    expect(find.text('Kayıt silindi.'), findsOneWidget);
    expect(bytes(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'wrong-club guard and later valid deletion preserve typed sibling',
      (tester) async {
    final sibling = save(checkpoint(0));
    final siblingBytes = bytes();
    final summary = save(bootstrap(0));
    expect(sibling.slotId, summary.slotId);
    expect(sibling.source, isNot(summary.source));
    await render(tester);
    save(bootstrap(1));
    final before = bytes();

    await act(tester, 'delete', summary);

    expect(bytes(), before);
    expectRenderedClub(summary, 1);
    expectRenderedClub(sibling, 0);
    // The refreshed row now accurately names club 1, so the existing delete
    // action can remove that exact source while preserving the sibling.
    await act(tester, 'delete', summary);
    expect(bytes(), siblingBytes);
    expectRenderedClub(sibling, 0);
    expect(
        composition.saveSlots
            .inspect(source: sibling.source, slotId: sibling.slotId),
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'checkpoint Continue reads its own namespace beside bootstrap sibling',
      (tester) async {
    final summary = save(checkpoint(0));
    save(bootstrap(1));
    await render(tester);
    final before = bytes();

    await act(tester, 'continue', summary);

    expect(find.byType(PresidentHomeScreen), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('selected-club-name'))).data,
        composition.world.clubs[0].name);
    final panel = tester.widget<PresidentPreparedSeasonDashboardPanel>(
        find.byType(PresidentPreparedSeasonDashboardPanel));
    expect(panel.snapshot.seasonIndex, 1);
    expect(bytes(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'corrupt stale Delete fails closed without changing generic raw delete',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    final file = directory.listSync().whereType<File>().single;
    final corrupt = file.readAsBytesSync();
    corrupt[0] ^= 1;
    file.writeAsBytesSync(corrupt);

    await act(tester, 'delete', summary);

    expectStillOnList();
    expect(find.text('Kayıt silinemedi.'), findsOneWidget);
    expect(find.byKey(const Key('save-list-error')), findsOneWidget);
    expect(file.readAsBytesSync(), corrupt);
    // This is only a rendered-row safety check. The protected M86 raw typed
    // deletion contract still permits explicit cleanup of a corrupt save.
    expect(composition.saveSlots.deleteSummary(summary), isTrue);
    expect(file.existsSync(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing stale Delete keeps unrelated saves and existing error flow',
      (tester) async {
    save(bootstrap(1), slotId: 'unrelated');
    final summary = save(bootstrap(0));
    await render(tester);
    composition.saveSlots.deleteSummary(summary);
    final before = bytes();

    await act(tester, 'delete', summary);

    expectStillOnList();
    expect(find.text('Kayıt silinemedi.'), findsOneWidget);
    expect(bytes(), before);
    expect(find.byKey(Key('save-${summary.identity}')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing stale Continue preserves its existing missing-slot handling',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    composition.saveSlots.deleteSummary(summary);

    await act(tester, 'continue', summary);

    expectStillOnList();
    expect(find.text('Bu kayıt artık mevcut değil.'), findsOneWidget);
    expect(find.byKey(const Key('empty-save-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed Delete callback preserves a new same-club record',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    final retainedDelete = tester
        .widget<IconButton>(find.byKey(Key('delete-${summary.identity}')))
        .onPressed!;
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Current screen'))));
    await tester.pumpAndSettle();
    expect(find.byType(SaveListScreen), findsNothing);

    // A real new career now owns the same typed identity and club. Only the
    // disposed screen boundary distinguishes this event from a mounted one.
    expect(composition.saveSlots.deleteSummary(summary), isTrue);
    final replacement = bootstrap(0);
    final first =
        replacement.advance() as PlayerPresidentInteractiveDecisionPending;
    replacement.submit(
        request: first.request,
        choice: canonicalChoiceForRequest(first.request));
    expect(save(replacement).source, summary.source);
    final before = bytes();
    final sessionBefore = replacement.encodeNewGameBootstrapSnapshot();
    final pendingBefore = replacement.pendingDecision;

    expect(retainedDelete, returnsNormally);
    await tester.pump();

    expect(bytes(), before);
    expect(
        composition.saveSlots
            .inspect(source: summary.source, slotId: summary.slotId)!
            .answeredDecisionCount,
        1);
    expect(replacement.encodeNewGameBootstrapSnapshot(), sessionBefore);
    expect(replacement.pendingDecision, same(pendingBefore));
    expect(find.text('Current screen'), findsOneWidget);
    expect(find.byType(PresidentHomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed Continue callback cannot open a new same-club record',
      (tester) async {
    final summary = save(bootstrap(0));
    await render(tester);
    final retainedContinue = tester
        .widget<TextButton>(find.byKey(Key('continue-${summary.identity}')))
        .onPressed!;
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Current screen'))));
    await tester.pumpAndSettle();
    expect(find.byType(SaveListScreen), findsNothing);

    expect(composition.saveSlots.deleteSummary(summary), isTrue);
    final replacement = bootstrap(0);
    final first =
        replacement.advance() as PlayerPresidentInteractiveDecisionPending;
    replacement.submit(
        request: first.request,
        choice: canonicalChoiceForRequest(first.request));
    expect(save(replacement).source, summary.source);
    final before = bytes();
    final sessionBefore = replacement.encodeNewGameBootstrapSnapshot();
    final pendingBefore = replacement.pendingDecision;

    expect(retainedContinue, returnsNormally);
    await tester.pumpAndSettle();

    expect(bytes(), before);
    expect(
        composition.saveSlots
            .inspect(source: summary.source, slotId: summary.slotId)!
            .answeredDecisionCount,
        1);
    expect(replacement.encodeNewGameBootstrapSnapshot(), sessionBefore);
    expect(replacement.pendingDecision, same(pendingBefore));
    expect(find.text('Current screen'), findsOneWidget);
    expect(find.byType(PresidentHomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
