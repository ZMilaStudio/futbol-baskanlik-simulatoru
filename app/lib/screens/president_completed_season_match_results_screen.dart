import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_match_results_snapshot.dart';

class PresidentCompletedSeasonMatchResultsScreen extends StatelessWidget {
  const PresidentCompletedSeasonMatchResultsScreen({
    super.key,
    required this.snapshot,
    required this.clubNameForId,
  });

  final PlayerPresidentCompletedSeasonMatchResultsSnapshot snapshot;
  final String Function(String clubId) clubNameForId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('completed-season-match-results-screen'),
      appBar: AppBar(title: const Text('Maç Sonuçları')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Sezon ${snapshot.seasonIndex + 1} • ${snapshot.leagueName}',
                key: const Key('completed-season-match-results-header'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const Key('completed-season-match-results-list'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: snapshot.matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final match = snapshot.matches[index];
                  final opponentName = clubNameForId(match.opponentClubId);
                  final venue = match.isHome ? 'Ev' : 'Deplasman';
                  final outcome = _outcome(match);
                  return Card(
                    key: ValueKey(
                      'completed-season-match-result-row-${index + 1}',
                    ),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${match.round}. Hafta',
                            key: ValueKey(
                              'completed-season-match-result-round-${index + 1}',
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            opponentName,
                            key: ValueKey(
                              'completed-season-match-result-opponent-${index + 1}',
                            ),
                            softWrap: true,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${match.goalsFor} - ${match.goalsAgainst}',
                            key: ValueKey(
                              'completed-season-match-result-score-${index + 1}',
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$venue • $outcome',
                            key: ValueKey(
                              'completed-season-match-result-meta-${index + 1}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _outcome(PlayerPresidentCompletedSeasonMatchResult match) {
  if (match.goalsFor > match.goalsAgainst) return 'Galibiyet';
  if (match.goalsFor == match.goalsAgainst) return 'Beraberlik';
  return 'Mağlubiyet';
}
