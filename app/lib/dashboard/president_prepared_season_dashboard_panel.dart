import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_season_dashboard_snapshot.dart';

class PresidentPreparedSeasonDashboardPanel extends StatelessWidget {
  const PresidentPreparedSeasonDashboardPanel({
    super.key,
    required this.snapshot,
  });

  final PlayerPresidentPreparedSeasonDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sponsorName =
        snapshot.activeSponsor?.offer.sponsorName ?? 'Aktif sponsor yok';
    final controlLabel =
        snapshot.playerControlActive ? 'Aktif' : 'Kaybedildi';

    return Semantics(
      container: true,
      label: 'Sezona Hazırlık Kulüp Özeti',
      child: Container(
        key: const Key('prepared-season-dashboard'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            final itemWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sezona Hazırlık',
                  key: const Key('prepared-season-title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kulüp Özeti',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sezon ${snapshot.seasonIndex + 1} • ${snapshot.league.name}',
                  key: const Key('prepared-season-league'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Kasa',
                      value: snapshot.cash.toString(),
                      valueKey: const Key('prepared-season-cash'),
                    ),
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Borç',
                      value: snapshot.debt.toString(),
                      valueKey: const Key('prepared-season-debt'),
                    ),
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Taraftar Güveni',
                      value: '${snapshot.fanOverallTrust} / 100',
                      valueKey: const Key('prepared-season-fan-trust'),
                    ),
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Başkanlık Kontrolü',
                      value: controlLabel,
                      valueKey: const Key('prepared-season-player-control'),
                    ),
                    _DashboardFact(
                      width: constraints.maxWidth,
                      label: 'Teknik Direktör',
                      value: snapshot.manager.name,
                      valueKey: const Key('prepared-season-manager'),
                    ),
                    _DashboardFact(
                      width: constraints.maxWidth,
                      label: 'Yönetim İlişkisi',
                      value: '${snapshot.boardRelationship.round()} / 100',
                      valueKey:
                          const Key('prepared-season-board-relationship'),
                    ),
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Akademi',
                      value: 'Seviye ${snapshot.academyLevel}',
                      valueKey: const Key('prepared-season-academy'),
                    ),
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Stadyum',
                      value: 'Seviye ${snapshot.stadiumLevel}',
                      valueKey: const Key('prepared-season-stadium'),
                    ),
                    _DashboardFact(
                      width: itemWidth,
                      label: 'Antrenman Tesisi',
                      value: 'Seviye ${snapshot.trainingGroundLevel}',
                      valueKey:
                          const Key('prepared-season-training-ground'),
                    ),
                    _DashboardFact(
                      width: compact ? constraints.maxWidth : itemWidth,
                      label: 'Sponsor',
                      value: sponsorName,
                      valueKey: const Key('prepared-season-sponsor'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardFact extends StatelessWidget {
  const _DashboardFact({
    required this.width,
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final double width;
  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                key: valueKey,
                softWrap: true,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
