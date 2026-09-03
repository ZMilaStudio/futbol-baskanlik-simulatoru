import '../league/club.dart';
import 'player.dart';
import 'player_position.dart';

class TeamStrengthCalculator {
  const TeamStrengthCalculator();

  static const Map<PlayerPosition, int> _lineupNeeds = {
    PlayerPosition.goalkeeper: 1,
    PlayerPosition.defender: 4,
    PlayerPosition.midfielder: 3,
    PlayerPosition.forward: 3,
  };

  List<Club> deriveClubs({
    required List<Club> baseClubs,
    required List<Player> players,
  }) {
    final byClub = <String, List<Player>>{};
    for (final player in players) {
      byClub.putIfAbsent(player.clubId, () => <Player>[]).add(player);
    }

    return List.unmodifiable(
      baseClubs.map((club) {
        final roster = byClub[club.id] ?? const <Player>[];
        if (roster.length < 11) {
          throw StateError('${club.id} has fewer than 11 active players.');
        }
        return Club(
          id: club.id,
          name: club.name,
          strength: calculate(roster),
        );
      }),
    );
  }

  double calculate(List<Player> roster) {
    if (roster.length < 11) {
      throw ArgumentError('At least 11 players are required.');
    }

    final selected = <Player>[];
    final selectedIds = <String>{};
    var missingPositionSlots = 0;

    for (final entry in _lineupNeeds.entries) {
      final candidates = roster
          .where((player) => player.position == entry.key)
          .toList()
        ..sort((a, b) => b.ability.compareTo(a.ability));
      final take =
          candidates.length < entry.value ? candidates.length : entry.value;
      final chosen = candidates.take(take).toList(growable: false);
      selected.addAll(chosen);
      selectedIds.addAll(chosen.map((player) => player.id));
      missingPositionSlots += entry.value - take;
    }

    if (selected.length < 11) {
      final remaining = roster
          .where((player) => !selectedIds.contains(player.id))
          .toList()
        ..sort((a, b) => b.ability.compareTo(a.ability));
      selected.addAll(remaining.take(11 - selected.length));
    }

    final average = selected.fold<double>(
          0,
          (sum, player) => sum + player.ability,
        ) /
        11.0;
    final penalty = missingPositionSlots * 0.8;
    return (average - penalty).clamp(45.0, 92.0).toDouble();
  }
}
