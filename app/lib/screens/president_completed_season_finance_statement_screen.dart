import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import '../reports/financial_health_label.dart';

class PresidentCompletedSeasonFinanceStatementScreen extends StatelessWidget {
  const PresidentCompletedSeasonFinanceStatementScreen({
    super.key,
    required this.finance,
    required this.seasonIndex,
    required this.leagueName,
  });

  final ClubFinanceSeason finance;
  final int seasonIndex;
  final String leagueName;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const Key('completed-season-finance-statement-screen'),
        appBar: AppBar(
          title: const Text('Sezon Finansları'),
        ),
        body: SafeArea(
          child: ListView(
            key: const Key('completed-season-finance-statement-list'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Sezon ${seasonIndex + 1} • $leagueName',
                key: const Key('completed-season-finance-statement-header'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _FinanceSection(
                key: const Key('completed-season-finance-opening-section'),
                title: 'Açılış Durumu',
                facts: [
                  _FinanceFact(
                    key: const Key('completed-season-finance-opening-cash'),
                    label: 'Sezon başı kasa',
                    value: finance.openingCash.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-opening-debt'),
                    label: 'Sezon başı borç',
                    value: finance.openingDebt.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FinanceSection(
                key: const Key('completed-season-finance-revenue-section'),
                title: 'Operasyonel Gelirler',
                facts: [
                  _FinanceFact(
                    key: const Key('completed-season-finance-central-revenue'),
                    label: 'Merkezi gelir',
                    value: finance.centralRevenue.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-sponsor-revenue'),
                    label: 'Sponsor geliri',
                    value: finance.sponsorRevenue.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-matchday-revenue'),
                    label: 'Maç günü geliri',
                    value: finance.matchdayRevenue.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-prize-revenue'),
                    label: 'Ödül geliri',
                    value: finance.prizeRevenue.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-total-revenue'),
                    label: 'Toplam operasyonel gelir',
                    value: finance.totalRevenue.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FinanceSection(
                key: const Key('completed-season-finance-expense-section'),
                title: 'Faaliyet ve Faiz Giderleri',
                facts: [
                  _FinanceFact(
                    key: const Key('completed-season-finance-wage-expense'),
                    label: 'Maaş gideri',
                    value: finance.wageExpense.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-operating-expense'),
                    label: 'İşletme gideri',
                    value: finance.operatingExpense.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-interest-expense'),
                    label: 'Faiz gideri',
                    value: finance.interestExpense.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-pnl-expenses'),
                    label: 'Toplam faaliyet ve faiz gideri',
                    value: finance.profitAndLossExpenses.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-operating-result'),
                    label: 'Faaliyet sonucu (faiz dahil)',
                    value: finance.operatingResult.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FinanceSection(
                key: const Key('completed-season-finance-cash-flow-section'),
                title: 'Finansman / Nakit Hareketleri',
                facts: [
                  _FinanceFact(
                    key: const Key(
                      'completed-season-finance-transfer-installment-income',
                    ),
                    label: 'Transfer taksit girişi',
                    value: finance.transferInstallmentIncome.toString(),
                  ),
                  _FinanceFact(
                    key: const Key(
                      'completed-season-finance-transfer-installment-expense',
                    ),
                    label: 'Transfer taksit ödemesi',
                    value: finance.transferInstallmentExpense.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-principal-repaid'),
                    label: 'Anapara geri ödemesi',
                    value: finance.principalRepaid.toString(),
                  ),
                  _FinanceFact(
                    key: const Key(
                      'completed-season-finance-emergency-borrowing',
                    ),
                    label: 'Acil borçlanma',
                    value: finance.emergencyBorrowing.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FinanceSection(
                key: const Key('completed-season-finance-closing-section'),
                title: 'Kapanış Durumu',
                facts: [
                  _FinanceFact(
                    key: const Key('completed-season-finance-closing-cash'),
                    label: 'Sezon sonu kasa',
                    value: finance.closingCash.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-closing-debt'),
                    label: 'Sezon sonu borç',
                    value: finance.closingDebt.toString(),
                  ),
                  _FinanceFact(
                    key: const Key('completed-season-finance-health'),
                    label: 'Finansal durum',
                    value: financialHealthLabel(finance.health),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _FinanceSection extends StatelessWidget {
  const _FinanceSection({
    super.key,
    required this.title,
    required this.facts,
  });

  final String title;
  final List<_FinanceFact> facts;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...facts,
            ],
          ),
        ),
      );
}

class _FinanceFact extends StatelessWidget {
  const _FinanceFact({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
}
