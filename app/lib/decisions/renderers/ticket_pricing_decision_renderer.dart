import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_control.dart';

class TicketPricingDecisionRenderer extends StatelessWidget {
  const TicketPricingDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerPresidentTicketPricingDecisionContext context;
  final ValueChanged<MatchdayTicketPricingChoice>? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ticket-pricing-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Taraftar güveni ${this.context.fanTrust} • '
          'Baz seyirci ${this.context.baseAttendance.attendance}/'
          '${this.context.baseAttendance.capacity}',
        ),
        const SizedBox(height: 12),
        for (final tier in MatchdayTicketPriceTier.values) ...[
          OutlinedButton(
            key: Key('ticket-pricing-${tier.name}'),
            onPressed: onSubmit == null
                ? null
                : () => onSubmit!(MatchdayTicketPricingChoice(tier)),
            child: Text(_tierLabel(tier)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

String _tierLabel(MatchdayTicketPriceTier tier) => switch (tier) {
      MatchdayTicketPriceTier.supporterFriendly => 'Taraftar dostu',
      MatchdayTicketPriceTier.balanced => 'Dengeli',
      MatchdayTicketPriceTier.premium => 'Premium',
    };
