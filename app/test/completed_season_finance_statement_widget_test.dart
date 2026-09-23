import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/reports/financial_health_label.dart';
import 'package:futbol_baskanlik_app/screens/president_completed_season_finance_statement_screen.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main() {
  ClubFinanceSeason financeFixture({
    Money transferInstallmentIncome = Money.zero,
    Money transferInstallmentExpense = Money.zero,
    Money principalRepaid = Money.zero,
    Money emergencyBorrowing = Money.zero,
  }) =>
      ClubFinanceSeason(
        clubId: 'internal_club_id',
        openingCash: const Money.fromUnits(12000000),
        openingDebt: const Money.fromUnits(4000000),
        centralRevenue: const Money.fromUnits(1000000),
        sponsorRevenue: const Money.fromUnits(2000000),
        matchdayRevenue: const Money.fromUnits(3000000),
        prizeRevenue: const Money.fromUnits(4000000),
        wageExpense: const Money.fromUnits(5000000),
        operatingExpense: const Money.fromUnits(3000000),
        interestExpense: const Money.fromUnits(1000000),
        principalRepaid: principalRepaid,
        emergencyBorrowing: emergencyBorrowing,
        transferInstallmentIncome: transferInstallmentIncome,
        transferInstallmentExpense: transferInstallmentExpense,
        closingCash: const Money.fromUnits(12000000),
        closingDebt: const Money.fromUnits(4000000),
        health: FinancialHealth.balanced,
      );

  void expectFact(
    WidgetTester tester,
    String key,
    String label,
    String value,
  ) {
    final fact = find.byKey(Key(key));
    expect(fact, findsOneWidget);
    expect(
      find.descendant(of: fact, matching: find.text(label)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: fact, matching: find.text(value)),
      findsOneWidget,
    );
  }

  testWidgets('renders authoritative finance statement sections and exact values',
      (tester) async {
    final finance = financeFixture(
      transferInstallmentIncome: const Money.fromUnits(1500000),
      transferInstallmentExpense: const Money.fromUnits(750000),
      principalRepaid: const Money.fromUnits(1000000),
      emergencyBorrowing: const Money.fromUnits(500000),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentCompletedSeasonFinanceStatementScreen(
          finance: finance,
          seasonIndex: 2,
          leagueName: 'Birinci Lig',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('completed-season-finance-statement-screen')),
      findsOneWidget,
    );
    expect(find.text('Sezon Finansları'), findsOneWidget);
    expect(find.text('Sezon 3 • Birinci Lig'), findsOneWidget);

    final list =
        find.byKey(const Key('completed-season-finance-statement-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    Future<void> reveal(String key) async {
      await tester.scrollUntilVisible(
        find.byKey(Key(key)),
        500,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
    }

    await reveal('completed-season-finance-opening-section');
    expect(find.text('Açılış Durumu'), findsOneWidget);
    expectFact(
      tester,
      'completed-season-finance-opening-cash',
      'Sezon başı kasa',
      finance.openingCash.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-opening-debt',
      'Sezon başı borç',
      finance.openingDebt.toString(),
    );

    await reveal('completed-season-finance-revenue-section');
    expect(find.text('Operasyonel Gelirler'), findsOneWidget);
    expectFact(
      tester,
      'completed-season-finance-central-revenue',
      'Merkezi gelir',
      finance.centralRevenue.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-sponsor-revenue',
      'Sponsor geliri',
      finance.sponsorRevenue.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-matchday-revenue',
      'Maç günü geliri',
      finance.matchdayRevenue.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-prize-revenue',
      'Ödül geliri',
      finance.prizeRevenue.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-total-revenue',
      'Toplam operasyonel gelir',
      finance.totalRevenue.toString(),
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('completed-season-finance-revenue-section'),
        ),
        matching: find.text('Transfer taksit girişi'),
      ),
      findsNothing,
    );

    await reveal('completed-season-finance-expense-section');
    expect(find.text('Faaliyet ve Faiz Giderleri'), findsOneWidget);
    expectFact(
      tester,
      'completed-season-finance-wage-expense',
      'Maaş gideri',
      finance.wageExpense.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-operating-expense',
      'İşletme gideri',
      finance.operatingExpense.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-interest-expense',
      'Faiz gideri',
      finance.interestExpense.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-pnl-expenses',
      'Toplam faaliyet ve faiz gideri',
      finance.profitAndLossExpenses.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-operating-result',
      'Faaliyet sonucu (faiz dahil)',
      finance.operatingResult.toString(),
    );

    await reveal('completed-season-finance-cash-flow-section');
    expect(find.text('Finansman / Nakit Hareketleri'), findsOneWidget);
    expectFact(
      tester,
      'completed-season-finance-transfer-installment-income',
      'Transfer taksit girişi',
      finance.transferInstallmentIncome.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-transfer-installment-expense',
      'Transfer taksit ödemesi',
      finance.transferInstallmentExpense.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-principal-repaid',
      'Anapara geri ödemesi',
      finance.principalRepaid.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-emergency-borrowing',
      'Acil borçlanma',
      finance.emergencyBorrowing.toString(),
    );
    expect(
      find.descendant(
        of: find.byKey(
          const Key('completed-season-finance-cash-flow-section'),
        ),
        matching: find.text('Transfer taksit girişi'),
      ),
      findsOneWidget,
    );

    await reveal('completed-season-finance-closing-section');
    expect(find.text('Kapanış Durumu'), findsOneWidget);
    expectFact(
      tester,
      'completed-season-finance-closing-cash',
      'Sezon sonu kasa',
      finance.closingCash.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-closing-debt',
      'Sezon sonu borç',
      finance.closingDebt.toString(),
    );
    expectFact(
      tester,
      'completed-season-finance-health',
      'Finansal durum',
      financialHealthLabel(finance.health),
    );

    expect(find.text(finance.clubId), findsNothing);
    expect(find.text(finance.signature), findsNothing);
    expect(find.text('expectedClosingCash'), findsNothing);
    expect(find.text('expectedClosingDebt'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero financing stays visible and negative operating result keeps sign',
      (tester) async {
    final finance = ClubFinanceSeason(
      clubId: 'internal_negative_result_club',
      openingCash: const Money.fromUnits(10000000),
      openingDebt: const Money.fromUnits(1000000),
      centralRevenue: const Money.fromUnits(1000000),
      sponsorRevenue: const Money.fromUnits(1000000),
      matchdayRevenue: const Money.fromUnits(1000000),
      prizeRevenue: const Money.fromUnits(1000000),
      wageExpense: const Money.fromUnits(3000000),
      operatingExpense: const Money.fromUnits(2000000),
      interestExpense: const Money.fromUnits(1000000),
      principalRepaid: Money.zero,
      emergencyBorrowing: Money.zero,
      transferInstallmentIncome: Money.zero,
      transferInstallmentExpense: Money.zero,
      closingCash: const Money.fromUnits(8000000),
      closingDebt: const Money.fromUnits(1000000),
      health: FinancialHealth.tight,
    );
    expect(finance.operatingResult.isNegative, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: PresidentCompletedSeasonFinanceStatementScreen(
          finance: finance,
          seasonIndex: 0,
          leagueName: 'Test Ligi',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byKey(
        const Key('completed-season-finance-statement-list'),
      ),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('completed-season-finance-operating-result'),
      ),
      500,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expectFact(
      tester,
      'completed-season-finance-operating-result',
      'Faaliyet sonucu (faiz dahil)',
      finance.operatingResult.toString(),
    );

    for (final key in [
      'completed-season-finance-transfer-installment-income',
      'completed-season-finance-transfer-installment-expense',
      'completed-season-finance-principal-repaid',
      'completed-season-finance-emergency-borrowing',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(Key(key)),
        400,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.text('0.00M'),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      '320px textScale 2 large Money supports real vertical scroll without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final finance = ClubFinanceSeason(
      clubId: 'internal_large_money_club',
      openingCash: const Money.fromUnits(999999999999999),
      openingDebt: const Money.fromUnits(888888888888888),
      centralRevenue: const Money.fromUnits(777777777777777),
      sponsorRevenue: const Money.fromUnits(666666666666666),
      matchdayRevenue: const Money.fromUnits(555555555555555),
      prizeRevenue: const Money.fromUnits(444444444444444),
      wageExpense: const Money.fromUnits(333333333333333),
      operatingExpense: const Money.fromUnits(222222222222222),
      interestExpense: const Money.fromUnits(111111111111111),
      principalRepaid: Money.zero,
      emergencyBorrowing: Money.zero,
      transferInstallmentIncome: Money.zero,
      transferInstallmentExpense: Money.zero,
      closingCash: const Money.fromUnits(999999999999999),
      closingDebt: const Money.fromUnits(888888888888888),
      health: FinancialHealth.veryStrong,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2.0),
          ),
          child: PresidentCompletedSeasonFinanceStatementScreen(
            finance: finance,
            seasonIndex: 123456,
            leagueName:
                'Çok Uzun Başkanlık Finans Test Ligi Adı Erişilebilirlik',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Sezon 123457 • Çok Uzun Başkanlık Finans Test Ligi Adı Erişilebilirlik',
      ),
      findsOneWidget,
    );

    final closing =
        find.byKey(const Key('completed-season-finance-closing-section'));
    expect(closing, findsNothing);

    final list =
        find.byKey(const Key('completed-season-finance-statement-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      closing,
      900,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(closing, findsOneWidget);
    expect(tester.getRect(closing).top, lessThan(480));
    expect(
      find.byKey(const Key('completed-season-finance-health')),
      findsOneWidget,
    );
    expect(
      find.text(finance.openingCash.toString()),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
