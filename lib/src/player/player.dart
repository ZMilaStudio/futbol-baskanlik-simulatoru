import 'player_position.dart';

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.clubId,
    required this.position,
    required this.age,
    required this.ability,
    required this.potential,
    required this.retirementAge,
    required this.isAcademyGraduate,
  });

  final String id;
  final String name;
  final String clubId;
  final PlayerPosition position;
  final int age;
  final double ability;
  final double potential;
  final int retirementAge;
  final bool isAcademyGraduate;

  Player copyWith({
    String? clubId,
    int? age,
    double? ability,
    double? potential,
  }) =>
      Player(
        id: id,
        name: name,
        clubId: clubId ?? this.clubId,
        position: position,
        age: age ?? this.age,
        ability: ability ?? this.ability,
        potential: potential ?? this.potential,
        retirementAge: retirementAge,
        isAcademyGraduate: isAcademyGraduate,
      );

  String get signature =>
      '$id|$clubId|${position.name}|$age|${ability.toStringAsFixed(4)}|'
      '${potential.toStringAsFixed(4)}|$retirementAge|$isAcademyGraduate';
}
