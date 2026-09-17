import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';

class MediaDecisionRenderer extends StatelessWidget {
  const MediaDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerMediaStatementDecisionContext context;
  final ValueChanged<MediaStance>? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('media-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Teknik direktör gündemi için basın yaklaşımını seç. '
          'Hedef: ${this.context.aiStatement.targetManagerId}',
        ),
        const SizedBox(height: 12),
        for (final stance in this.context.allowedStances) ...[
          OutlinedButton(
            key: Key('media-${stance.name}'),
            onPressed: onSubmit == null ? null : () => onSubmit!(stance),
            child: Text(_stanceLabel(stance)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

String _stanceLabel(MediaStance stance) => switch (stance) {
      MediaStance.strongSupport => 'Güçlü destek',
      MediaStance.measuredSupport => 'Ölçülü destek',
      MediaStance.pressure => 'Baskıyı artır',
      MediaStance.noComment => 'Yorum yapma',
    };
