import 'package:flutter/material.dart';
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
              child: Text(
                '${offer.sponsorName} • ${offer.termSeasons} sezon • '
                '${offer.bonusTarget.name}',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
