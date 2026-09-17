import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_app/main.dart';

void main() {
  late Directory tempDirectory;
  late AppComposition composition;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('fbs-m89-widget-');
    composition = AppComposition.withSaveDirectory(
      Directory(
        '${tempDirectory.path}${Platform.pathSeparator}save_slots',
      ),
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(FutbolBaskanlikApp(composition: composition));
  }

  Future<void> openClubSelection(WidgetTester tester) async {
    await tester.tap(find.text('Yeni Oyun'));
    await tester.pumpAndSettle();
  }

  testWidgets('opening screen exposes the two primary actions', (tester) async {
    await pumpApp(tester);

    expect(find.text('Futbol Başkanlık Simülatörü'), findsOneWidget);
    expect(find.text('Yeni Oyun'), findsOneWidget);
    expect(find.text('Kayıt Yükle'), findsOneWidget);

    final loadButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Kayıt Yükle'),
    );
    expect(loadButton.onPressed, isNull);
  });

  testWidgets('Yeni Oyun opens canonical club selection', (tester) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    expect(find.text('Kulüp Seçimi'), findsOneWidget);
    expect(find.text('48 kulüp'), findsOneWidget);
  });

  testWidgets('club selection exposes the canonical 48-club world', (
    tester,
  ) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    final clubs = composition.world.clubs;
    expect(clubs, hasLength(48));
    expect(find.text(clubs.first.name), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(clubs.last.name),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text(clubs.last.name), findsOneWidget);
  });

  testWidgets('selecting a real club opens the President Home placeholder', (
    tester,
  ) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    final selectedClub = composition.world.clubs.first;
    await tester.tap(find.text(selectedClub.name));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected-club-name')), findsOneWidget);
    expect(find.text(selectedClub.name), findsOneWidget);
    expect(find.text('Başkanlık Merkezi'), findsNWidgets(2));
    expect(
      find.text('Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.'),
      findsOneWidget,
    );
  });

  testWidgets('back navigation returns through the Stage 2 flow', (
    tester,
  ) async {
    await pumpApp(tester);
    await openClubSelection(tester);

    final selectedClub = composition.world.clubs.first;
    await tester.tap(find.text(selectedClub.name));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Kulüp Seçimi'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Yeni Oyun'), findsOneWidget);
  });
}
