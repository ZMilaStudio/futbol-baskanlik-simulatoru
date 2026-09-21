import '../player/player_position.dart';

/// Immutable read-only projection of one player in the prepared playing squad.
class PlayerPresidentPreparedSquadPlayer {
  const PlayerPresidentPreparedSquadPlayer({
    required this.playerId,
    required this.name,
    required this.position,
    required this.age,
    required this.ability,
    required this.potential,
    required this.isAcademyGraduate,
  });

  /// Internal identity and deterministic tie-break only. Never display raw.
  final String playerId;
  final String name;
  final PlayerPosition position;
  final int age;
  final double ability;
  final double potential;
  final bool isAcademyGraduate;

  /// Runtime-only deterministic observation aid. Never persisted.
  String get signature => [
        playerId,
        name,
        position.name,
        age,
        ability.toStringAsFixed(4),
        potential.toStringAsFixed(4),
        isAcademyGraduate,
      ].join('|');
}

/// Immutable application-facing observation of the squad prepared to play the
/// application session's opening season.
///
/// This projection is non-persisted and never acts as gameplay authority.
class PlayerPresidentPreparedSquadSnapshot {
  PlayerPresidentPreparedSquadSnapshot({
    required this.controlledClubId,
    required this.seasonIndex,
    required Iterable<PlayerPresidentPreparedSquadPlayer> players,
  }) : players = List.unmodifiable(_ordered(players)) {
    _validate();
  }

  final String controlledClubId;

  /// The season that is about to be played.
  final int seasonIndex;

  /// Canonical deterministic presentation order. Gameplay does not consume it.
  final List<PlayerPresidentPreparedSquadPlayer> players;

  /// Runtime-only deterministic observation aid. Never persisted.
  String get signature => [
        controlledClubId,
        seasonIndex,
        ...players.map((player) => player.signature),
      ].join('||');

  void _validate() {
    if (controlledClubId.isEmpty) {
      throw StateError('Prepared squad controlled club cannot be empty.');
    }
    if (seasonIndex < 0) {
      throw StateError('Prepared squad season index cannot be negative.');
    }
    if (players.isEmpty) {
      throw StateError('Prepared squad cannot be empty.');
    }

    final ids = <String>{};
    for (final player in players) {
      if (player.playerId.isEmpty || player.name.isEmpty) {
        throw StateError('Prepared squad players require non-empty identity.');
      }
      if (!ids.add(player.playerId)) {
        throw StateError('Prepared squad player IDs must be unique.');
      }
      if (player.age < 0) {
        throw StateError('Prepared squad player age cannot be negative.');
      }
      if (!player.ability.isFinite || !player.potential.isFinite) {
        throw StateError('Prepared squad ratings must be finite.');
      }
    }
  }

  static List<PlayerPresidentPreparedSquadPlayer> _ordered(
    Iterable<PlayerPresidentPreparedSquadPlayer> source,
  ) {
    final result = source.toList(growable: false);
    result.sort((a, b) {
      final byPosition = _positionRank(a.position).compareTo(
        _positionRank(b.position),
      );
      if (byPosition != 0) return byPosition;

      final byAbility = b.ability.compareTo(a.ability);
      if (byAbility != 0) return byAbility;

      final byName = a.name.compareTo(b.name);
      if (byName != 0) return byName;

      return a.playerId.compareTo(b.playerId);
    });
    return result;
  }

  static int _positionRank(PlayerPosition position) => switch (position) {
        PlayerPosition.goalkeeper => 0,
        PlayerPosition.defender => 1,
        PlayerPosition.midfielder => 2,
        PlayerPosition.forward => 3,
      };
}
