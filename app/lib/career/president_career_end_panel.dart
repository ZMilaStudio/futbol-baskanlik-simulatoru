import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';

class PresidentCareerEndPanel extends StatelessWidget {
  const PresidentCareerEndPanel({
    super.key,
    required this.tenureControl,
    required this.onReturnToMainMenu,
  });

  final PlayerPresidentTenureControlState tenureControl;
  final VoidCallback onReturnToMainMenu;

  @override
  Widget build(BuildContext context) {
    tenureControl.validate();
    if (!tenureControl.lost) {
      throw StateError(
        'PresidentCareerEndPanel requires authoritative lost tenure control.',
      );
    }

    final lostAtCompletedSeason = tenureControl.lostAtCompletedSeason!;
    final theme = Theme.of(context);

    return Column(
      key: const Key('president-career-end-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Başkanlık Görevin Sona Erdi',
          key: const Key('career-end-title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kulüp yönetimindeki görevin bu sezon sonunda sona erdi.',
          key: Key('career-end-message'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$lostAtCompletedSeason. sezon sonunda.',
          key: const Key('career-end-season'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('career-end-main-menu-button'),
          onPressed: onReturnToMainMenu,
          icon: const Icon(Icons.home_outlined),
          label: const Text('Ana Menü'),
        ),
      ],
    );
  }
}
