import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_season_fixtures_snapshot.dart';

class PresidentPreparedSeasonFixturesScreen extends StatelessWidget {
  const PresidentPreparedSeasonFixturesScreen({
    super.key,
    required this.snapshot,
    required this.clubNameForId,
  });

  final PlayerPresidentPreparedSeasonFixturesSnapshot snapshot;
  final String Function(String clubId) clubNameForId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controlledClubName = clubNameForId(snapshot.controlledClubId);

    return Scaffold(
      key: const Key('prepared-season-fixtures-screen'),
      appBar: AppBar(title: const Text('Fikstür')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sezon ${snapshot.seasonIndex + 1} • ${controlledClubName}',
                    key: const Key('prepared-season-fixtures-header'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.leagueTier.displayName,
                    key: const Key('prepared-season-fixtures-league'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const Key('prepared-season-fixtures-list'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: snapshot.fixtures.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final fixture = snapshot.fixtures[index];
                  return _PreparedSeasonFixtureRow(
                    fixture: fixture,
                    opponentName: clubNameForId(fixture.opponentClubId),
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

class _PreparedSeasonFixtureRow extends StatelessWidget {
  const _PreparedSeasonFixtureRow({
    required this.fixture,
    required this.opponentName,
  });

  final PlayerPresidentPreparedSeasonFixture fixture;
  final String opponentName;

  @override
  Widget build(BuildContext context) => Padding(
        key: ValueKey('prepared-season-fixture-round-${fixture.round}'),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${fixture.round}. Hafta',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              opponentName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(fixture.isHome ? 'Ev' : 'Deplasman'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      );
}
