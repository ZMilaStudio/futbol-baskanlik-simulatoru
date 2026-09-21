import '../world/league_tier.dart';

/// Immutable read-only projection of one controlled-club league fixture.
class PlayerPresidentPreparedSeasonFixture {
  const PlayerPresidentPreparedSeasonFixture({
    required this.fixtureId,
    required this.round,
    required this.opponentClubId,
    required this.isHome,
  });

  /// Internal fixture identity only. Never display raw.
  final String fixtureId;

  /// Canonical one-based league round.
  final int round;

  /// Internal canonical club reference only. Never display raw.
  final String opponentClubId;

  final bool isHome;

  /// Runtime-only deterministic observation aid. Never persisted.
  String get signature =>
      '${fixtureId}|${round}|${opponentClubId}|${isHome ? 'home' : 'away'}';
}

/// Immutable application-facing observation of the league fixtures prepared to
/// play the application session's opening season.
///
/// This projection is derived-only, non-persisted and never gameplay authority.
class PlayerPresidentPreparedSeasonFixturesSnapshot {
  PlayerPresidentPreparedSeasonFixturesSnapshot({
    required this.controlledClubId,
    required this.seasonIndex,
    required this.leagueTier,
    required Iterable<PlayerPresidentPreparedSeasonFixture> fixtures,
  }) : fixtures = List.unmodifiable(_ordered(fixtures)) {
    _validate();
  }

  final String controlledClubId;

  /// The zero-based simulation season that is about to be played.
  final int seasonIndex;

  final LeagueTier leagueTier;

  /// Deterministic presentation order only.
  final List<PlayerPresidentPreparedSeasonFixture> fixtures;

  /// Runtime-only deterministic observation aid. Never persisted.
  String get signature => [
        controlledClubId,
        seasonIndex,
        leagueTier.name,
        ...fixtures.map((fixture) => fixture.signature),
      ].join('||');

  void _validate() {
    if (controlledClubId.isEmpty) {
      throw StateError('Prepared fixtures controlled club cannot be empty.');
    }
    if (seasonIndex < 0) {
      throw StateError('Prepared fixtures season index cannot be negative.');
    }
    if (fixtures.isEmpty) {
      throw StateError('Prepared fixtures cannot be empty.');
    }

    final fixtureIds = <String>{};
    final rounds = <int>{};
    for (final fixture in fixtures) {
      if (fixture.fixtureId.isEmpty) {
        throw StateError('Prepared fixture IDs cannot be empty.');
      }
      if (!fixtureIds.add(fixture.fixtureId)) {
        throw StateError('Prepared fixture IDs must be unique.');
      }
      if (fixture.opponentClubId.isEmpty) {
        throw StateError('Prepared fixture opponent IDs cannot be empty.');
      }
      if (fixture.round <= 0) {
        throw StateError('Prepared fixture rounds must be positive.');
      }
      if (!rounds.add(fixture.round)) {
        throw StateError('Prepared fixture rounds must be unique.');
      }
    }
  }

  static List<PlayerPresidentPreparedSeasonFixture> _ordered(
    Iterable<PlayerPresidentPreparedSeasonFixture> source,
  ) {
    final result = source.toList(growable: false);
    result.sort((a, b) {
      final byRound = a.round.compareTo(b.round);
      if (byRound != 0) return byRound;
      return a.fixtureId.compareTo(b.fixtureId);
    });
    return result;
  }
}
