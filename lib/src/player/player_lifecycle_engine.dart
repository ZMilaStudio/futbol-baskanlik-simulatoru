import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../league/club.dart';
import 'player.dart';
import 'player_position.dart';

class PlayerLifecycleResult {
  PlayerLifecycleResult({
    required List<Player> activePlayers,
    required List<Player> retiredPlayers,
    required List<Player> youthIntake,
  })  : activePlayers = List.unmodifiable(activePlayers),
        retiredPlayers = List.unmodifiable(retiredPlayers),
        youthIntake = List.unmodifiable(youthIntake);

  final List<Player> activePlayers;
  final List<Player> retiredPlayers;
  final List<Player> youthIntake;
}

class PlayerLifecycleEngine {
  const PlayerLifecycleEngine();

  PlayerLifecycleResult advance({
    required List<Player> currentPlayers,
    required List<Club> currentClubs,
    required List<Club> referenceClubs,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
  }) {
    final evolved = <Player>[];
    final retired = <Player>[];

    for (final player in currentPlayers) {
      final nextAge = player.age + 1;
      final rng = SeededRng(
        StableHash.combine32([
          careerSeed,
          simulationVersion,
          nextSeasonIndex,
          StableHash.string32(player.id),
          StableHash.string32('player-development'),
        ]),
      );
      final nextAbility = _nextAbility(player, nextAge, rng);
      final next = player.copyWith(age: nextAge, ability: nextAbility);
      if (nextAge >= player.retirementAge) {
        retired.add(next);
      } else {
        evolved.add(next);
      }
    }

    final referenceById = {for (final club in referenceClubs) club.id: club};
    final youth = <Player>[];
    for (final club in currentClubs) {
      final referenceClub = referenceById[club.id];
      if (referenceClub == null) {
        throw StateError('Missing reference club ${club.id}.');
      }
      final clubPlayers =
          evolved.where((player) => player.clubId == club.id).toList();
      final intake = _generateYouth(
        club: referenceClub,
        activeClubPlayers: clubPlayers,
        careerSeed: careerSeed,
        nextSeasonIndex: nextSeasonIndex,
        simulationVersion: simulationVersion,
      );
      youth.add(intake);
      evolved.add(intake);
    }

    return PlayerLifecycleResult(
      activePlayers: evolved,
      retiredPlayers: retired,
      youthIntake: youth,
    );
  }

  double _nextAbility(Player player, int nextAge, SeededRng rng) {
    final gap =
        (player.potential - player.ability).clamp(0.0, 30.0).toDouble();
    final gapFactor = (gap / 12.0).clamp(0.0, 1.0).toDouble();
    final roll = rng.nextDouble();

    final delta = switch (nextAge) {
      <= 20 => (0.35 + roll * 1.85) * gapFactor,
      <= 23 => (0.15 + roll * 1.35) * gapFactor,
      <= 26 => (-0.15 + roll * 0.75) * gapFactor,
      <= 29 => -0.25 + roll * 0.55,
      <= 31 => -0.45 + roll * 0.45,
      <= 33 => -0.75 + roll * 0.45,
      _ => -1.35 + roll * 0.55,
    };

    return (player.ability + delta)
        .clamp(35.0, player.potential)
        .toDouble();
  }

  Player _generateYouth({
    required Club club,
    required List<Player> activeClubPlayers,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
  }) {
    final seed = StableHash.combine32([
      careerSeed,
      simulationVersion,
      nextSeasonIndex,
      StableHash.string32(club.id),
      StableHash.string32('youth-intake'),
    ]);
    final rng = SeededRng(seed);
    final position = _chooseYouthPosition(activeClubPlayers, rng);
    final age = 16 + (rng.nextDouble() * 3).floor();
    final rareTalent = rng.nextDouble() > 0.94;
    final ability =
        (club.strength - 7.0 + (rng.nextDouble() * 8.0 - 4.0) +
                (rareTalent ? 2.5 : 0.0))
            .clamp(42.0, 78.0)
            .toDouble();
    final potential =
        (ability + 8.0 + rng.nextDouble() * 15.0 +
                (rareTalent ? 5.0 : 0.0))
            .clamp(ability, 95.0)
            .toDouble();
    final retirementAge = 34 + (rng.nextDouble() * 5).floor();

    return Player(
      id: 'y_${club.id}_s$nextSeasonIndex',
      name: _youthName(rng, nextSeasonIndex),
      clubId: club.id,
      position: position,
      age: age,
      ability: ability,
      potential: potential,
      retirementAge: retirementAge,
      isAcademyGraduate: true,
    );
  }

  PlayerPosition _chooseYouthPosition(
    List<Player> roster,
    SeededRng rng,
  ) {
    const targets = {
      PlayerPosition.goalkeeper: 2,
      PlayerPosition.defender: 6,
      PlayerPosition.midfielder: 6,
      PlayerPosition.forward: 4,
    };
    PlayerPosition? mostNeeded;
    var lowestRatio = double.infinity;
    for (final entry in targets.entries) {
      final count =
          roster.where((player) => player.position == entry.key).length;
      final ratio = count / entry.value;
      if (ratio < lowestRatio) {
        lowestRatio = ratio;
        mostNeeded = entry.key;
      }
    }
    if (lowestRatio < 0.75) {
      return mostNeeded!;
    }

    final roll = rng.nextDouble();
    if (roll < 0.11) return PlayerPosition.goalkeeper;
    if (roll < 0.44) return PlayerPosition.defender;
    if (roll < 0.78) return PlayerPosition.midfielder;
    return PlayerPosition.forward;
  }

  String _youthName(SeededRng rng, int salt) {
    const firstNames = [
      'Alp',
      'Aras',
      'Arel',
      'Atlas',
      'Berk',
      'Cem',
      'Demir',
      'Ege',
      'Eren',
      'Kuzey',
      'Miran',
      'Poyraz',
      'Toprak',
      'Uras',
      'Utku',
      'Yaman',
    ];
    const lastNames = [
      'Acar',
      'Akın',
      'Bulut',
      'Doğan',
      'Ersoy',
      'Güler',
      'Korkmaz',
      'Oral',
      'Özkan',
      'Sağlam',
      'Sönmez',
      'Tan',
      'Turan',
      'Varol',
      'Yalçın',
      'Yolcu',
    ];
    final first = firstNames[
        ((rng.nextDouble() * firstNames.length).floor() + salt) %
            firstNames.length];
    final last = lastNames[
        (rng.nextDouble() * lastNames.length).floor() % lastNames.length];
    return '$first $last';
  }
}
