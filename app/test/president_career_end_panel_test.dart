import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/career/president_career_end_panel.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';

void main() {
  PlayerPresidentTenureControlState lostState() =>
      const PlayerPresidentTenureControlState(
        controlledClubId: 't1_01',
        playerPresidentId: 'president_t1_01_player',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: 4,
        successorPresidentId: 'president_t1_01_successor-private-id',
      );

  testWidgets('career end panel renders exact loss ordinal and main-menu action',
      (tester) async {
    var returned = false;

    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PresidentCareerEndPanel(
              tenureControl: lostState(),
              onReturnToMainMenu: () {
                returned = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('president-career-end-panel')), findsOneWidget);
    expect(find.byKey(const Key('career-end-title')), findsOneWidget);
    expect(find.text('Başkanlık Görevin Sona Erdi'), findsOneWidget);
    expect(
      find.text('Kulüp yönetimindeki görevin bu sezon sonunda sona erdi.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('career-end-season')), findsOneWidget);
    expect(find.text('4. sezon sonunda.'), findsOneWidget);
    expect(find.textContaining('successor-private-id'), findsNothing);

    final mainMenu = find.byKey(const Key('career-end-main-menu-button'));
    expect(mainMenu, findsOneWidget);
    await tester.ensureVisible(mainMenu);
    await tester.tap(mainMenu);
    await tester.pump();
    expect(returned, isTrue);
  });

  testWidgets('career end panel fails closed for active tenure', (tester) async {
    const active = PlayerPresidentTenureControlState(
      controlledClubId: 't1_01',
      playerPresidentId: 'president_t1_01_player',
      status: PlayerPresidentTenureControlStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentCareerEndPanel(
          tenureControl: active,
          onReturnToMainMenu: () {},
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });
}
