import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

import '../composition/app_composition.dart';
import 'president_home_screen.dart';

/// Read-only opening-world membership. Missing or ambiguous membership fails closed.
WorldLeague? initialLeagueForClub(
  Club club,
  Iterable<WorldLeague> leagues,
) {
  WorldLeague? match;
  for (final league in leagues) {
    for (final memberId in league.clubIds) {
      if (memberId != club.id) continue;
      if (match != null) return null;
      match = league;
    }
  }
  return match;
}

class ClubSelectionScreen extends StatelessWidget {
  const ClubSelectionScreen({
    super.key,
    required this.composition,
  });

  final AppComposition composition;

  @override
  Widget build(BuildContext context) {
    final clubs = composition.world.clubs;
    final leagues = composition.world.leagues;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulüp Seçimi'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Başkanlık kariyerine başlayacağın kulübü seç. '
                  'Kulüplerin başlangıç ligini inceleyebilirsin.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('${clubs.length} kulüp'),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const Key('club-list'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: clubs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final selectedClub = clubs[index];
                final league = initialLeagueForClub(selectedClub, leagues);
                return ClubSelectionTile(
                  club: selectedClub,
                  league: league,
                  onSelected: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PresidentHomeScreen(
                          composition: composition,
                          club: selectedClub,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation-only tile; invalid league membership cannot start a career.
class ClubSelectionTile extends StatelessWidget {
  const ClubSelectionTile({
    super.key,
    required this.club,
    required this.league,
    required this.onSelected,
  });

  final Club club;
  final WorldLeague? league;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final validLeague = league;
    return Card(
      key: Key('club-${club.id}'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: validLeague == null ? null : onSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      validLeague == null
                          ? 'Lig bilgisi doğrulanamadı.'
                          : 'Başlangıç ligi: ${validLeague.name}',
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                validLeague == null
                    ? Icons.lock_outline
                    : Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
