import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart'
    show SponsorBonusTarget;
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';

class SponsorDecisionRenderer extends StatelessWidget {
  const SponsorDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerSponsorDecisionContext context;
  final ValueChanged<PlayerSponsorOfferChoice>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('sponsor-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Yeni sponsor seç. Taraftar güveni ${this.context.fanTrust}, '
          'medya güvenilirliği ${this.context.mediaCredibility}.',
        ),
        const SizedBox(height: 12),
        for (final offer in this.context.offers) ...[
          OutlinedButton(
            key: Key('sponsor-offer-${offer.id}'),
            onPressed: onSubmit == null
                ? null
                : () => onSubmit!(PlayerSponsorOfferChoice(offerId: offer.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.sponsorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Yıllık garanti: ${offer.annualGuaranteed}'),
                    Text('Performans bonusu: ${offer.performanceBonus}'),
                    Text('Maksimum yıllık gelir: ${offer.maxAnnualRevenue}'),
                    Text('Sözleşme süresi: ${offer.termSeasons} sezon'),
                    Text(
                      'Bonus hedefi: '
                      '${_sponsorBonusTargetLabel(offer.bonusTarget)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

String _sponsorBonusTargetLabel(SponsorBonusTarget target) => switch (target) {
      SponsorBonusTarget.topHalf => 'İlk 8',
      SponsorBonusTarget.topSix => 'İlk 6',
      SponsorBonusTarget.topFour => 'İlk 4',
      SponsorBonusTarget.champion => 'Şampiyonluk',
    };
