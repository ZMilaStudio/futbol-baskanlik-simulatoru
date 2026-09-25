import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';

class CrisisDecisionRenderer extends StatelessWidget {
  const CrisisDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerCrisisDecisionContext context;
  final ValueChanged<PlayerCrisisActionChoice>? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('crisis-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_typeLabel(this.context.scenario.type)} • '
          'Şiddet: ${this.context.scenario.severity}',
        ),
        const SizedBox(height: 12),
        for (final decision in this.context.availableDecisions) ...[
          OutlinedButton(
            key: Key('crisis-action-${decision.action.name}'),
            onPressed: onSubmit == null
                ? null
                : () => onSubmit!(
                      PlayerCrisisActionChoice(action: decision.action),
                    ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_actionLabel(decision.action)),
                    const SizedBox(height: 6),
                    Text(
                      'Nakit etkisi: '
                      '${_signedMoney(decision.effect.cashDelta)}',
                    ),
                    Text(
                      'Taraftar etkisi: '
                      '${_signedInt(decision.effect.fanTrustDelta)}',
                    ),
                    Text(
                      'Medya etkisi: '
                      '${_signedInt(decision.effect.mediaCredibilityDelta)}',
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

String _signedMoney(Money money) =>
    money > Money.zero ? '+${money.toString()}' : money.toString();

String _signedInt(int value) => value > 0 ? '+$value' : '$value';

String _typeLabel(CrisisType type) => switch (type) {
      CrisisType.liquiditySqueeze => 'Likidite krizi',
      CrisisType.supporterUnrest => 'Taraftar huzursuzluğu',
      CrisisType.mediaBacklash => 'Medya krizi',
    };

String _actionLabel(CrisisAction action) => switch (action) {
      CrisisAction.austerityPlan => 'Tasarruf planı',
      CrisisAction.bridgeSpending => 'Geçiş harcaması',
      CrisisAction.balancedRecovery => 'Dengeli toparlanma',
      CrisisAction.ambitionReset => 'Hedefleri yeniden belirle',
      CrisisAction.listeningTour => 'Taraftarı dinle',
      CrisisAction.supporterReassurance => 'Taraftara güven ver',
      CrisisAction.transparentBriefing => 'Şeffaf bilgilendirme',
      CrisisAction.confrontNarrative => 'Anlatıya karşı çık',
      CrisisAction.measuredMediaResponse => 'Ölçülü medya yanıtı',
    };
