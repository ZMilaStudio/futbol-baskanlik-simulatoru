import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';

class ManagerReplacementDecisionRenderer extends StatelessWidget {
  const ManagerReplacementDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerManagerReplacementContext context;
  final ValueChanged<PlayerManagerReplacementChoice>? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('manager-replacement-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${this.context.outgoingManager.name} sonrası yeni teknik direktörü seç.',
        ),
        const SizedBox(height: 12),
        for (final candidate in this.context.candidates) ...[
          OutlinedButton(
            key: Key('manager-candidate-${candidate.manager.id}'),
            onPressed: onSubmit == null
                ? null
                : () => onSubmit!(
                      PlayerManagerReplacementChoice(
                        managerId: candidate.manager.id,
                      ),
                    ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${candidate.manager.name} • '
                'uyum ${candidate.fitScore.toStringAsFixed(1)}',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
