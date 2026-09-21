import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_completed_season_league_table_snapshot.dart';

class PresidentCompletedSeasonLeagueTableScreen extends StatelessWidget {
  const PresidentCompletedSeasonLeagueTableScreen({
    super.key,
    required this.snapshot,
    required this.clubNameForId,
  });

  final PlayerPresidentCompletedSeasonLeagueTableSnapshot snapshot;
  final String Function(String clubId) clubNameForId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('completed-season-league-table-screen'),
      appBar: AppBar(title: const Text('Puan Durumu')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Sezon ${snapshot.seasonIndex + 1} • ${snapshot.leagueName}',
                key: const Key('completed-season-league-table-header'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('completed-season-table-vertical-scroll'),
                child: SingleChildScrollView(
                  key: const Key('completed-season-table-horizontal-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    key: const Key('completed-season-league-data-table'),
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 112,
                    columns: const [
                      DataColumn(label: Tooltip(message: 'Sıra', child: Text('#'))),
                      DataColumn(label: Text('Takım')),
                      DataColumn(
                        label: Tooltip(message: 'Oynanan', child: Text('O')),
                      ),
                      DataColumn(
                        label: Tooltip(message: 'Galibiyet', child: Text('G')),
                      ),
                      DataColumn(
                        label: Tooltip(message: 'Beraberlik', child: Text('B')),
                      ),
                      DataColumn(
                        label: Tooltip(message: 'Mağlubiyet', child: Text('M')),
                      ),
                      DataColumn(
                        label: Tooltip(message: 'Atılan Gol', child: Text('AG')),
                      ),
                      DataColumn(
                        label: Tooltip(message: 'Yenilen Gol', child: Text('YG')),
                      ),
                      DataColumn(
                        label: Tooltip(message: 'Averaj', child: Text('AV')),
                      ),
                      DataColumn(
                        label: Tooltip(
                          message: 'Puan',
                          child: Text(
                            'P',
                            key: Key('completed-season-table-header-points'),
                          ),
                        ),
                      ),
                    ],
                    rows: [
                      for (final row in snapshot.rows)
                        _dataRow(context, row),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _dataRow(
    BuildContext context,
    PlayerPresidentCompletedSeasonLeagueTableRow row,
  ) {
    final clubName = clubNameForId(row.clubId);
    final controlled = row.clubId == snapshot.controlledClubId;

    return DataRow(
      key: ValueKey('completed-season-table-row-${row.position}'),
      cells: [
        DataCell(
          Text(
            '${row.position}',
            key: ValueKey('completed-season-table-position-${row.position}'),
          ),
        ),
        DataCell(
          controlled
              ? Semantics(
                  label: 'Senin Kulübün: $clubName',
                  container: true,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          clubName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                )
              : Text(clubName),
        ),
        DataCell(Text('${row.played}')),
        DataCell(Text('${row.wins}')),
        DataCell(Text('${row.draws}')),
        DataCell(Text('${row.losses}')),
        DataCell(Text('${row.goalsFor}')),
        DataCell(Text('${row.goalsAgainst}')),
        DataCell(Text(_signed(row.goalDifference))),
        DataCell(
          Text(
            '${row.points}',
            key: ValueKey('completed-season-table-points-${row.position}'),
          ),
        ),
      ],
    );
  }
}

String _signed(int value) => value > 0 ? '+$value' : '$value';
