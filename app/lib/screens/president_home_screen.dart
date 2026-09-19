import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_report.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import '../composition/app_composition.dart';
import '../controller/game_flow_controller.dart';
import '../dashboard/president_prepared_season_dashboard_panel.dart';
import '../decisions/decision_panel.dart';
import '../decisions/decision_resolution_panel.dart';
import '../reports/president_season_report_panel.dart';

class PresidentHomeScreen extends StatefulWidget {
  const PresidentHomeScreen({
    super.key,
    required this.composition,
    required Club club,
  })  : _club = club,
        _binding = null;

  const PresidentHomeScreen.loaded({
    super.key,
    required this.composition,
    required PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding binding,
  })  : _club = null,
        _binding = binding;

  final AppComposition composition;
  final Club? _club;
  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding? _binding;

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
      saveSlots: widget.composition.saveSlots,
    );
    final binding = widget._binding;
    if (binding != null) {
      _controller.loadBoundSave(binding);
    } else {
      _controller.startNewGame(widget._club!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final saved = _controller.saveCurrent();
    if (!mounted) return;
    final message = saved
        ? (_controller.persistenceMessage ?? 'Kayıt tamamlandı.')
        : (_controller.persistenceError ?? 'Kayıt tamamlanamadı.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _clubNameForId(String clubId) {
    final matches = widget.composition.world.clubs
        .where((club) => club.id == clubId)
        .toList(growable: false);
    if (matches.length != 1) {
      throw StateError(
        'Canonical club display name requires exactly one match for $clubId.',
      );
    }
    return matches.single.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başkanlık Merkezi'),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IconButton(
              key: const Key('save-game-button'),
              tooltip: 'Kaydet',
              onPressed: _controller.session != null &&
                      !_controller.loading &&
                      !_controller.persistenceBusy
                  ? _save
                  : null,
              icon: _controller.persistenceBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final step = _controller.currentStep;
          final resolution = _controller.currentResolution;
          final errorMessage = _controller.errorMessage;
          final club = _controller.selectedClub;
          final preparedDashboard = _controller.preparedSeasonDashboard;
          final showPreparedDashboard = preparedDashboard != null &&
              (resolution != null ||
                  step is PlayerPresidentInteractiveDecisionPending);
          final busy = _controller.loading || _controller.persistenceBusy;

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
                          club?.name ?? 'Kariyer yükleniyor',
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
                        if (_controller.saveSummary != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Kayıt bağlı • '
                            '${_sourceLabel(_controller.saveSummary!.source)}',
                            key: const Key('bound-save-status'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_controller.loading &&
                            step == null &&
                            resolution == null)
                          const CircularProgressIndicator()
                        else ...[
                          if (busy) ...[
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
                          if (showPreparedDashboard) ...[
                            PresidentPreparedSeasonDashboardPanel(
                              snapshot: preparedDashboard,
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                          ],
                          if (resolution != null)
                            DecisionResolutionPanel(
                              resolution: resolution,
                              busy: busy,
                              onContinue: busy
                                  ? null
                                  : _controller.continueAfterResolution,
                            )
                          else if (step != null)
                            PresidentSessionStateView(
                              step: step,
                              submitting: busy,
                              clubNameForId: _clubNameForId,
                              onSubmit: _controller.submitChoice,
                              onContinueToNextSeason: busy
                                  ? null
                                  : () {
                                      _controller.continueToNextSeason();
                                    },
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
    this.onContinueToNextSeason,
    this.clubNameForId,
  });

  final PlayerPresidentInteractiveSessionStep step;
  final bool submitting;
  final ValueChanged<Object>? onSubmit;
  final VoidCallback? onContinueToNextSeason;
  final ClubDisplayNameResolver? clubNameForId;

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
    final resolver = clubNameForId;
    if (resolver == null) {
      return const _SeasonReportErrorView();
    }

    try {
      final report =
          PlayerPresidentCompletedSeasonReport.fromCompleted(completed);
      return PresidentSeasonReportPanel(
        report: report,
        clubNameForId: resolver,
        onContinueToNextSeason: onContinueToNextSeason,
        busy: submitting,
        decisionCount: completed.decisionCount,
      );
    } on StateError {
      return const _SeasonReportErrorView();
    }
  }
}


class _SeasonReportErrorView extends StatelessWidget {
  const _SeasonReportErrorView();

  @override
  Widget build(BuildContext context) => Text(
        'Sezon raporu authoritative veriden oluşturulamadı. '
        'Kariyer ilerletilmedi.',
        key: const Key('season-report-error'),
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
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

String _sourceLabel(
  PlayerPresidentInteractiveDecisionMixedSaveSlotSource source,
) =>
    switch (source) {
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint =>
        'Kariyer kaydı',
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap =>
        'Yeni oyun kaydı',
    };
