import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';

class FacilityDecisionRenderer extends StatefulWidget {
  const FacilityDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerFacilityInvestmentContext context;
  final ValueChanged<PlayerFacilityInvestmentChoice>? onSubmit;

  @override
  State<FacilityDecisionRenderer> createState() =>
      _FacilityDecisionRendererState();
}

class _FacilityDecisionRendererState extends State<FacilityDecisionRenderer> {
  int _academy = 0;
  int _training = 0;
  int _stadium = 0;

  @override
  void didUpdateWidget(covariant FacilityDecisionRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context.signature != widget.context.signature) {
      _academy = 0;
      _training = 0;
      _stadium = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onSubmit != null;
    return Column(
      key: const Key('facility-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mevcut seviyeler: Akademi ${widget.context.academyLevel}, '
          'Antrenman ${widget.context.trainingGroundLevel}, '
          'Stadyum ${widget.context.stadiumLevel}',
        ),
        const SizedBox(height: 16),
        _UpgradeSelector(
          label: 'Akademi yatırımı',
          value: _academy,
          enabled: enabled,
          onChanged: (value) => setState(() => _academy = value),
        ),
        const SizedBox(height: 12),
        _UpgradeSelector(
          label: 'Antrenman tesisi yatırımı',
          value: _training,
          enabled: enabled,
          onChanged: (value) => setState(() => _training = value),
        ),
        const SizedBox(height: 12),
        _UpgradeSelector(
          label: 'Stadyum yatırımı',
          value: _stadium,
          enabled: enabled,
          onChanged: (value) => setState(() => _stadium = value),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          key: const Key('facility-hold'),
          onPressed: enabled
              ? () => widget.onSubmit!(PlayerFacilityInvestmentChoice.hold)
              : null,
          child: const Text('Bu dönem yatırım yapma'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('facility-submit'),
          onPressed: enabled
              ? () => widget.onSubmit!(
                    PlayerFacilityInvestmentChoice(
                      academyUpgrades: _academy,
                      trainingGroundUpgrades: _training,
                      stadiumUpgrades: _stadium,
                    ),
                  )
              : null,
          child: const Text('Yatırım kararını gönder'),
        ),
      ],
    );
  }
}

class _UpgradeSelector extends StatelessWidget {
  const _UpgradeSelector({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('0')),
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: enabled
              ? (values) {
                  if (values.isNotEmpty) onChanged(values.first);
                }
              : null,
        ),
      ],
    );
  }
}
