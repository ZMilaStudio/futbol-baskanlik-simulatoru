import 'package:flutter/material.dart';

import '../composition/app_composition.dart';
import 'president_home_screen.dart';

class ClubSelectionScreen extends StatelessWidget {
  const ClubSelectionScreen({
    super.key,
    required this.composition,
  });

  final AppComposition composition;

  @override
  Widget build(BuildContext context) {
    final clubs = composition.world.clubs;

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
                  'Başkanlık kariyerine başlayacağın kulübü seç.',
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
                final club = clubs[index];
                return Card(
                  key: Key('club-${club.id}'),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(club.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PresidentHomeScreen(
                            composition: composition,
                            club: club,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
