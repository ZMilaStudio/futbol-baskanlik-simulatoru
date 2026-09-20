import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';

typedef ClubDisplayNameResolver = String Function(String clubId);

class PresidentSeasonReportPanel extends StatelessWidget {
  PresidentSeasonReportPanel({
    super.key,
    required this.report,
    required ClubDisplayNameResolver clubNameForId,
    required this.onContinueToNextSeason,
    this.canContinueToNextSeason = true,
    this.busy = false,
    this.decisionCount,
  })  : controlledClubName = clubNameForId(report.controlledClubId),
        championClubName = clubNameForId(report.championClubId);

  final PlayerPresidentCompletedSeasonReport report;
  final String controlledClubName;
  final String championClubName;
  final VoidCallback? onContinueToNextSeason;
  final bool canContinueToNextSeason;
  final bool busy;
  final int? decisionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standing = report.standing;
    final finance = report.finance;
    final movement = report.movement;
    final promise = report.promise;

    return Column(
      key: const Key('president-season-report-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Başkanlık Sezon Raporu',
          key: const Key('season-report-title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sezon ${report.seasonIndex + 1} tamamlandı',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '$controlledClubName • ${report.leagueName}',
          key: const Key('season-report-league'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Sportif Sonuç',
          children: [
            _ReportLine(
              key: const Key('season-report-position'),
              text: '${report.finalPosition}. sıra',
            ),
            _ReportLine(
              key: const Key('season-report-record'),
              text:
                  '${standing.played} maç • ${standing.wins}G / ${standing.draws}B / ${standing.losses}M',
            ),
            _ReportLine(
              key: const Key('season-report-goals'),
              text:
                  '${standing.goalsFor}-${standing.goalsAgainst} gol • ${_signed(standing.goalDifference)} averaj',
            ),
            _ReportLine(
              key: const Key('season-report-points'),
              text: '${standing.points} puan',
            ),
            _ReportLine(
              key: const Key('season-report-champion'),
              text: 'Şampiyon: $championClubName',
            ),
            if (movement != null)
              _ReportLine(
                key: const Key('season-report-movement'),
                text:
                    'Lig hareketi: ${movement.from.displayName} → ${movement.to.displayName}',
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          key: const Key('season-report-finance'),
          title: 'Finansal Özet',
          children: [
            _ReportLine(
              key: const Key('season-report-closing-cash'),
              text: 'Sezon sonu kasa: ${finance.closingCash}',
            ),
            _ReportLine(
              key: const Key('season-report-closing-debt'),
              text: 'Sezon sonu borç: ${finance.closingDebt}',
            ),
            _ReportLine(
              key: const Key('season-report-total-revenue'),
              text: 'Toplam gelir: ${finance.totalRevenue}',
            ),
            _ReportLine(
              key: const Key('season-report-operating-result'),
              text: 'Faaliyet sonucu: ${finance.operatingResult}',
            ),
            _ReportLine(
              key: const Key('season-report-sponsor-revenue'),
              text: 'Sponsor geliri: ${finance.sponsorRevenue}',
            ),
            _ReportLine(
              key: const Key('season-report-matchday-revenue'),
              text: 'Maç günü geliri: ${finance.matchdayRevenue}',
            ),
            _ReportLine(
              key: const Key('season-report-financial-health'),
              text: 'Finansal durum: ${_financialHealthLabel(finance.health)}',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Teknik Direktör',
          children: [
            _ReportLine(
              key: const Key('season-report-manager'),
              text: report.manager.name,
            ),
            _ReportLine(
              key: const Key('season-report-manager-expectation'),
              text: 'Beklenti: ${report.managerSeason.expectedPosition}. sıra',
            ),
            _ReportLine(
              key: const Key('season-report-manager-actual'),
              text: 'Gerçekleşen: ${report.managerSeason.actualPosition}. sıra',
            ),
          ],
        ),
        const SizedBox(height: 18),
        PresidentSeasonPromiseSection(promise: promise),
        if (decisionCount != null) ...[
          const SizedBox(height: 16),
          Text(
            'Bu sezon $decisionCount başkanlık kararı verdin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (canContinueToNextSeason) ...[
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('continue-next-season-button'),
            onPressed: busy ? null : onContinueToNextSeason,
            icon: const Icon(Icons.skip_next),
            label: const Text('Sonraki Sezona Geç'),
          ),
        ],
      ],
    );
  }
}


class PresidentSeasonPromiseSection extends StatelessWidget {
  const PresidentSeasonPromiseSection({
    super.key,
    required this.promise,
  });

  final PromiseSeasonSnapshot? promise;

  @override
  Widget build(BuildContext context) {
    final current = promise;
    return _Section(
      title: 'Başkanlık Vaadi',
      children: [
        if (current == null)
          const _ReportLine(
            key: Key('season-report-promise'),
            text: 'Bu sezon değerlendirilen başkanlık vaadi yok.',
          )
        else ...[
          _ReportLine(
            key: const Key('season-report-promise'),
            text: _promiseTypeLabel(current.promise.type),
          ),
          _ReportLine(
            text: 'Sonuç: ${_promiseStatusLabel(current.resolution.status)}',
          ),
          _ReportLine(
            text: 'Gerekçe: ${_promiseReasonLabel(current.resolution.reason)}',
          ),
          _ReportLine(
            text: 'Değerlendirme puanı: ${current.resolution.score}',
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      );
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text),
      );
}

String _signed(int value) => value > 0 ? '+$value' : '$value';

String _financialHealthLabel(FinancialHealth health) => switch (health) {
      FinancialHealth.veryStrong => 'Çok güçlü',
      FinancialHealth.solid => 'Sağlam',
      FinancialHealth.balanced => 'Dengeli',
      FinancialHealth.tight => 'Sıkışık',
      FinancialHealth.debtCrisis => 'Borç krizi',
    };

String _promiseStatusLabel(PromiseStatus status) => switch (status) {
      PromiseStatus.fulfilled => 'Gerçekleşti',
      PromiseStatus.partial => 'Kısmen gerçekleşti',
      PromiseStatus.broken => 'Gerçekleşmedi',
    };

String _promiseTypeLabel(PresidentPromiseType type) => switch (type) {
      PresidentPromiseType.reduceDebt => 'Borcu azalt',
      PresidentPromiseType.stabilizeFinances => 'Finansları istikrara kavuştur',
      PresidentPromiseType.finishTopHalf => 'Ligi üst yarıda bitir',
      PresidentPromiseType.avoidRelegation => 'Kümede kal',
      PresidentPromiseType.earnPromotion => 'Üst lige yüksel',
      PresidentPromiseType.challengeTitle => 'Şampiyonluk yarışına gir',
    };

String _promiseReasonLabel(PromiseResolutionReason reason) => switch (reason) {
      PromiseResolutionReason.debtTargetMet => 'Borç hedefi karşılandı',
      PromiseResolutionReason.debtReduced => 'Borç azaltıldı',
      PromiseResolutionReason.debtNotReduced => 'Borç azaltılamadı',
      PromiseResolutionReason.financesStable => 'Finansal denge korundu',
      PromiseResolutionReason.financesMixed => 'Finansal sonuçlar karışık',
      PromiseResolutionReason.financesWorsened => 'Finansal durum kötüleşti',
      PromiseResolutionReason.topHalfMet => 'Üst yarı hedefi karşılandı',
      PromiseResolutionReason.nearTopHalf => 'Üst yarı hedefi kıl payı kaçtı',
      PromiseResolutionReason.missedTopHalf => 'Üst yarı hedefi kaçtı',
      PromiseResolutionReason.survived => 'Ligden düşülmedi',
      PromiseResolutionReason.relegated => 'Ligden düşüldü',
      PromiseResolutionReason.promoted => 'Üst lige yükselindi',
      PromiseResolutionReason.promotionNearMiss => 'Yükselme hedefi kıl payı kaçtı',
      PromiseResolutionReason.missedPromotion => 'Yükselme hedefi kaçtı',
      PromiseResolutionReason.champion => 'Şampiyon olundu',
      PromiseResolutionReason.titlePodium => 'Şampiyonluk yarışında üst sıralar',
      PromiseResolutionReason.titleMissed => 'Şampiyonluk hedefi kaçtı',
    };
