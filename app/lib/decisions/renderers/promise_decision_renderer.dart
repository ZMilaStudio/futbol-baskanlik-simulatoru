import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';

class PromiseDecisionRenderer extends StatelessWidget {
  const PromiseDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerPromiseDecisionContext context;
  final ValueChanged<PresidentPromiseType>? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('promise-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sezon ${this.context.seasonIndex + 1} için başkanlık vaadini seç.'),
        const SizedBox(height: 12),
        for (final type in this.context.allowedTypes) ...[
          OutlinedButton(
            key: Key('promise-${type.name}'),
            onPressed: onSubmit == null ? null : () => onSubmit!(type),
            child: Text(_promiseLabel(type)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

String _promiseLabel(PresidentPromiseType type) => switch (type) {
      PresidentPromiseType.reduceDebt => 'Borcu azalt',
      PresidentPromiseType.stabilizeFinances => 'Mali yapıyı istikrara kavuştur',
      PresidentPromiseType.finishTopHalf => 'Ligi üst yarıda bitir',
      PresidentPromiseType.avoidRelegation => 'Kümede kal',
      PresidentPromiseType.earnPromotion => 'Üst lige çık',
      PresidentPromiseType.challengeTitle => 'Şampiyonluk için yarış',
    };
