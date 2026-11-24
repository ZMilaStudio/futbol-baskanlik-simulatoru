import 'player_president_prepared_squad_snapshot.dart';

/// Event-time playing-club observations, not legal contract ownership.
/// Intake stays with its generating club even if the player later moves.
final class PlayerPresidentCompletedRosterLifecycleSnapshot {
  PlayerPresidentCompletedRosterLifecycleSnapshot({
    required this.completedSeasonIndex,
    required this.targetSeasonIndex,
    required this.controlledClubId,
    required Iterable<PlayerPresidentPreparedSquadPlayer> retiredPlayers,
    required Iterable<PlayerPresidentPreparedSquadPlayer> youthIntake,
  })  : retiredPlayers = List.unmodifiable(retiredPlayers),
        youthIntake = List.unmodifiable(youthIntake);
  final int completedSeasonIndex;
  final int targetSeasonIndex;
  final String controlledClubId;
  final List<PlayerPresidentPreparedSquadPlayer> retiredPlayers;
  final List<PlayerPresidentPreparedSquadPlayer> youthIntake;
  String get signature =>
      '$completedSeasonIndex|$targetSeasonIndex|$controlledClubId|'
      'retired:${retiredPlayers.map((row) => row.signature).join('||')}|'
      'youth:${youthIntake.map((row) => row.signature).join('||')}';
}
