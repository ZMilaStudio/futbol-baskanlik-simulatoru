import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';

class ManagerReviewDecisionRenderer extends StatelessWidget {
  const ManagerReviewDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerManagerReviewContext context;
  final ValueChanged<PlayerManagerReviewChoice>? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('manager-review-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Teknik direktör: ${this.context.currentManager.name}\n'
          'Beklenen sıra: ${this.context.season.expectedPosition} • '
          'Gerçekleşen: ${this.context.season.actualPosition}',
        ),
        if (this.context.forcedRetirement) ...[
          const SizedBox(height: 8),
          const Text('Teknik direktör emeklilik nedeniyle görevden ayrılıyor.'),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('manager-review-retain'),
          onPressed: onSubmit != null && this.context.canRetain
              ? () => onSubmit!(PlayerManagerReviewChoice.retain)
              : null,
          child: const Text('Teknik direktörle devam et'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('manager-review-replace'),
          onPressed: onSubmit == null
              ? null
              : () => onSubmit!(PlayerManagerReviewChoice.replace),
          child: const Text('Yeni teknik direktör seç'),
        ),
      ],
    );
  }
}
