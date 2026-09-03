import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../league/club.dart';
import 'player.dart';
import 'player_position.dart';

class PlayerPoolGenerator {
  const PlayerPoolGenerator();

  static const int playersPerClub = 18;

  static const List<PlayerPosition> _positionTemplate = [
    PlayerPosition.goalkeeper,
    PlayerPosition.goalkeeper,
    PlayerPosition.defender,
    PlayerPosition.defender,
    PlayerPosition.defender,
    PlayerPosition.defender,
    PlayerPosition.defender,
    PlayerPosition.defender,
    PlayerPosition.midfielder,
    PlayerPosition.midfielder,
    PlayerPosition.midfielder,
    PlayerPosition.midfielder,
    PlayerPosition.midfielder,
    PlayerPosition.midfielder,
    PlayerPosition.forward,
    PlayerPosition.forward,
    PlayerPosition.forward,
    PlayerPosition.forward,
  ];

  List<Player> generate({
    required List<Club> clubs,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final players = <Player>[];
    for (final club in clubs) {
      final rng = SeededRng(
        StableHash.combine32([
          careerSeed,
          simulationVersion,
          StableHash.string32(club.id),
          StableHash.string32('initial-player-pool'),
        ]),
      );

      for (var i = 0; i < _positionTemplate.length; i++) {
        final age = 17 + (rng.nextDouble() * 17).floor();
        final position = _positionTemplate[i];
        final ageAdjustment = switch (age) {
          <= 19 => -4.0,
          <= 22 => -1.8,
          <= 29 => 0.8,
          _ => -0.4,
        };
        final positionAdjustment = switch (position) {
          PlayerPosition.goalkeeper => -0.5,
          PlayerPosition.defender => 0.0,
          PlayerPosition.midfielder => 0.4,
          PlayerPosition.forward => 0.2,
        };
        final noise = (rng.nextDouble() * 8.0) - 4.0;
        final ability = (club.strength - 0.8 + ageAdjustment +
                positionAdjustment + noise)
            .clamp(42.0, 90.0)
            .toDouble();
        final upside = switch (age) {
          <= 19 => 8.0 + rng.nextDouble() * 12.0,
          <= 22 => 4.0 + rng.nextDouble() * 9.0,
          <= 25 => 1.5 + rng.nextDouble() * 5.0,
          <= 27 => rng.nextDouble() * 2.5,
          _ => 0.0,
        };
        final potential = (ability + upside).clamp(ability, 95.0).toDouble();
        final retirementAge = 34 + (rng.nextDouble() * 5).floor();

        players.add(
          Player(
            id: 'p_${club.id}_${i.toString().padLeft(2, '0')}',
            name: _nameFor(rng, i),
            clubId: club.id,
            position: position,
            age: age,
            ability: ability,
            potential: potential,
            retirementAge: retirementAge,
            isAcademyGraduate: false,
          ),
        );
      }
    }
    return List.unmodifiable(players);
  }

  static String _nameFor(SeededRng rng, int salt) {
    const firstNames = [
      'Arda', 'Bora', 'Can', 'Deniz', 'Efe', 'Emir', 'Kerem', 'Mert',
      'Onur', 'Ozan', 'Rüzgar', 'Selim', 'Tuna', 'Umut', 'Yalın', 'Yiğit',
      'Baran', 'Doruk', 'Kaan', 'Sarp',
    ];
    const lastNames = [
      'Aksoy', 'Aydın', 'Bilgin', 'Çetin', 'Demir', 'Eren', 'Güneş',
      'Işık', 'Kaya', 'Koç', 'Özer', 'Polat', 'Şahin', 'Taş', 'Tekin',
      'Tunç', 'Uçar', 'Yaman', 'Yıldız', 'Yüce',
    ];
    final first = firstNames[
        ((rng.nextDouble() * firstNames.length).floor() + salt) %
            firstNames.length];
    final last = lastNames[
        (rng.nextDouble() * lastNames.length).floor() % lastNames.length];
    return '$first $last';
  }
}
