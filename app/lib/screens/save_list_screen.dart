import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';

import '../composition/app_composition.dart';
import 'president_home_screen.dart';

class SaveListScreen extends StatefulWidget {
  const SaveListScreen({
    super.key,
    required this.composition,
  });

  final AppComposition composition;

  @override
  State<SaveListScreen> createState() => _SaveListScreenState();
}

class _SaveListScreenState extends State<SaveListScreen> {
  List<PlayerPresidentInteractiveDecisionMixedSaveSlotSummary> _summaries =
      const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    try {
      setState(() {
        _summaries = widget.composition.saveSlots.list();
        _errorMessage = null;
      });
    } catch (_) {
      setState(() {
        _summaries = const [];
        _errorMessage = 'Kayıt listesi okunamadı.';
      });
    }
  }

  void _open(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) {
    try {
      final binding =
          PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding
              .openSummary(
        service: widget.composition.saveSlots,
        summary: summary,
      );
      if (binding == null) {
        _showMessage('Bu kayıt artık mevcut değil.');
        _refresh();
        return;
      }

      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => PresidentHomeScreen.loaded(
                composition: widget.composition,
                binding: binding,
              ),
            ),
          )
          .then((_) {
        if (mounted) _refresh();
      });
    } catch (_) {
      _showMessage('Kayıt açılamadı.');
      _refresh();
    }
  }

  void _delete(
    PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
  ) {
    try {
      final deleted = widget.composition.saveSlots.deleteSummary(summary);
      if (!deleted) {
        _showMessage('Kayıt silinemedi; dosya artık mevcut olmayabilir.');
      } else {
        _showMessage('Kayıt silindi.');
      }
      _refresh();
    } catch (_) {
      _showMessage('Kayıt silinemedi.');
      _refresh();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıtlar')),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  key: const Key('save-list-error'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _summaries.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz kayıt yok.',
                    key: Key('empty-save-list'),
                  ),
                )
              : ListView.separated(
                  key: const Key('save-list'),
                  padding: const EdgeInsets.all(12),
                  itemCount: _summaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final summary = _summaries[index];
                    return Card(
                      key: Key('save-${summary.identity}'),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    summary.controlledClubName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_sourceLabel(summary.source)} • '
                                    '${summary.answeredDecisionCount} karar yanıtlandı',
                                  ),
                                  const SizedBox(height: 2),
                                  Text(_progressLabel(summary)),
                                ],
                              ),
                            ),
                            TextButton(
                              key: Key('continue-${summary.identity}'),
                              onPressed: () => _open(summary),
                              child: const Text('Devam Et'),
                            ),
                            IconButton(
                              key: Key('delete-${summary.identity}'),
                              tooltip: 'Sil',
                              onPressed: () => _delete(summary),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
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

String _progressLabel(
  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary summary,
) {
  if (summary.sessionCompleted) {
    return 'Sezon oturumu tamamlandı';
  }
  final pending = summary.pendingDecisionKind;
  if (pending != null) {
    return 'Karar bekleniyor';
  }
  if (summary.resumeSeasonCount > 0) {
    return 'Devam sezonu: ${summary.resumeSeasonCount}';
  }
  return 'Devam etmeye hazır';
}
