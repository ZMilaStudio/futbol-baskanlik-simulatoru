import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

class TransferStrategyDecisionRenderer extends StatefulWidget {
  const TransferStrategyDecisionRenderer({
    super.key,
    required this.context,
    this.onSubmit,
  });

  final PlayerTransferStrategyDecisionContext context;
  final ValueChanged<PlayerTransferStrategyChoice>? onSubmit;

  @override
  State<TransferStrategyDecisionRenderer> createState() =>
      _TransferStrategyDecisionRendererState();
}

class _TransferStrategyDecisionRendererState
    extends State<TransferStrategyDecisionRenderer> {
  late int _financial;
  late int _ambition;
  late int _risk;
  late int _youth;

  @override
  void initState() {
    super.initState();
    _resetFromContext();
  }

  @override
  void didUpdateWidget(covariant TransferStrategyDecisionRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context.signature != widget.context.signature) {
      _resetFromContext();
    }
  }

  void _resetFromContext() {
    final profile = widget.context.aiProfile;
    _financial = profile.financialDiscipline;
    _ambition = profile.transferAmbition;
    _risk = profile.riskAppetite;
    _youth = profile.youthOrientation;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onSubmit != null;
    return Column(
      key: const Key('transfer-strategy-decision-renderer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sezon ${widget.context.decisionSeasonIndex + 1} transfer yaklaşımı',
        ),
        const SizedBox(height: 8),
        _TraitSlider(
          label: 'Mali disiplin',
          value: _financial,
          enabled: enabled,
          onChanged: (value) => setState(() => _financial = value),
        ),
        _TraitSlider(
          label: 'Transfer hırsı',
          value: _ambition,
          enabled: enabled,
          onChanged: (value) => setState(() => _ambition = value),
        ),
        _TraitSlider(
          label: 'Risk iştahı',
          value: _risk,
          enabled: enabled,
          onChanged: (value) => setState(() => _risk = value),
        ),
        _TraitSlider(
          label: 'Altyapı odağı',
          value: _youth,
          enabled: enabled,
          onChanged: (value) => setState(() => _youth = value),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('transfer-strategy-submit'),
          onPressed: enabled
              ? () => widget.onSubmit!(
                    PlayerTransferStrategyChoice(
                      financialDiscipline: _financial,
                      transferAmbition: _ambition,
                      riskAppetite: _risk,
                      youthOrientation: _youth,
                    ),
                  )
              : null,
          child: const Text('Transfer stratejisini gönder'),
        ),
      ],
    );
  }
}

class _TraitSlider extends StatelessWidget {
  const _TraitSlider({
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
        Text('$label: $value'),
        Slider(
          min: 20,
          max: 90,
          divisions: 70,
          value: value.toDouble(),
          label: '$value',
          onChanged: enabled
              ? (next) => onChanged(next.round().clamp(20, 90))
              : null,
        ),
      ],
    );
  }
}
