import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import '../composition/app_composition.dart';
import '../controller/game_flow_controller.dart';
import '../decisions/decision_panel.dart';

class PresidentHomeScreen extends StatefulWidget {
  const PresidentHomeScreen({
    super.key,
    required this.composition,
    required this.club,
  });

  final AppComposition composition;
  final Club club;

  @override
  State<PresidentHomeScreen> createState() => _PresidentHomeScreenState();
}

class _PresidentHomeScreenState extends State<PresidentHomeScreen> {
  late final GameFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameFlowController(
      world: widget.composition.world,
      config: widget.composition.simulationConfig,
    );
    _controller.startNewGame(widget.club);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başkanlık Merkezi'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final step = _controller.currentStep;
          final errorMessage = _controller.errorMessage;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 52,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.club.name,
                          key: const Key('selected-club-name'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Başkanlık Merkezi',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_controller.loading && step == null)
                          const CircularProgressIndicator()
                        else ...[
                          if (_controller.loading) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                          ],
                          if (errorMessage != null) ...[
                            Text(
                              errorMessage,
                              key: const Key('session-error'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (step != null)
                            PresidentSessionStateView(
                              step: step,
                              submitting: _controller.loading,
                              onSubmit: _controller.submitChoice,
                            )
                          else if (errorMessage == null)
                            const Text(
                              'Oyun oturumu hazırlanıyor.',
                              key: Key('session-lifecycle-state'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PresidentSessionStateView extends StatelessWidget {
  const PresidentSessionStateView({
    super.key,
    required this.step,
    this.submitting = false,
    this.onSubmit,
  });

  final PlayerPresidentInteractiveSessionStep step;
  final bool submitting;
  final ValueChanged<Object>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final current = step;
    if (current is PlayerPresidentInteractiveDecisionPending) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Karar bekleniyor',
            key: Key('session-lifecycle-state'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            decisionKindLabel(current.request.kind),
            key: const Key('decision-kind-label'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Karar #${current.request.sequence}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          DecisionPanel(
            pending: current,
            submitting: submitting,
            onSubmit: onSubmit,
          ),
        ],
      );
    }

    final completed = current as PlayerPresidentInteractiveSessionCompleted;
    final boundaries = completed.result.boundaries;
    final completedSeason =
        boundaries.isEmpty ? null : boundaries.last.seasonIndex + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sezon tamamlandı',
          key: Key('session-lifecycle-state'),
        ),
        if (completedSeason != null) ...[
          const SizedBox(height: 8),
          Text(
            'Tamamlanan sezon: $completedSeason',
            key: const Key('completed-season-info'),
          ),
        ],
        const SizedBox(height: 4),
        Text('Yanıtlanan karar: ${completed.decisionCount}'),
      ],
    );
  }
}

String decisionKindLabel(PlayerPresidentInteractiveDecisionKind kind) {
  switch (kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return 'Tesis yatırımı kararı';
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      return 'Sponsorluk kararı';
    case PlayerPresidentInteractiveDecisionKind.crisis:
      return 'Kriz yönetimi kararı';
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return 'Teknik direktör değerlendirmesi';
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      return 'Teknik direktör seçimi';
    case PlayerPresidentInteractiveDecisionKind.promise:
      return 'Başkanlık vaadi kararı';
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      return 'Medya açıklaması kararı';
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      return 'Transfer stratejisi kararı';
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return 'Bilet fiyatlandırma kararı';
  }
}
