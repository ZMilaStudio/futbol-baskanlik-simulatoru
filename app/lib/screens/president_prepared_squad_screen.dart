import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_squad_snapshot.dart';

class PresidentPreparedSquadScreen extends StatelessWidget {
  const PresidentPreparedSquadScreen({
    super.key,
    required this.snapshot,
    required this.clubName,
  });

  final PlayerPresidentPreparedSquadSnapshot snapshot;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('prepared-squad-screen'),
      appBar: AppBar(title: const Text('Kadro')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Sezon ${snapshot.seasonIndex + 1} • $clubName',
                key: const Key('prepared-squad-header'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const Key('prepared-squad-list'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: snapshot.players.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final player = snapshot.players[index];
                  return _PreparedSquadPlayerRow(player: player);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedSquadPlayerRow extends StatelessWidget {
  const _PreparedSquadPlayerRow({required this.player});

  final PlayerPresidentPreparedSquadPlayer player;

  @override
  Widget build(BuildContext context) => ListTile(
        key: ValueKey('prepared-squad-player-${player.playerId}'),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        title: Text(
          player.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_positionLabel(player.position)} • ${player.age} yaş'),
              const SizedBox(height: 2),
              Text(
                'Güç ${player.ability.round()} • '
                'Potansiyel ${player.potential.round()}',
              ),
              if (player.isAcademyGraduate) ...[
                const SizedBox(height: 6),
                const Wrap(
                  children: [
                    Chip(
                      key: Key('prepared-squad-academy-badge'),
                      label: Text('Akademi'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
}

String _positionLabel(PlayerPosition position) => switch (position) {
      PlayerPosition.goalkeeper => 'Kaleci',
      PlayerPosition.defender => 'Defans',
      PlayerPosition.midfielder => 'Orta Saha',
      PlayerPosition.forward => 'Forvet',
    };
