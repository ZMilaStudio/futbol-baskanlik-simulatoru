import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import 'president_tenure.dart';

enum PresidentManagementArchetype {
  balanced,
  prudentBuilder,
  ambitiousSpender,
  youthArchitect,
  patientPlanner,
  interventionist,
}

class PresidentManagementProfile {
  const PresidentManagementProfile({
    required this.presidentId,
    required this.archetype,
    required this.financialDiscipline,
    required this.riskAppetite,
    required this.transferAmbition,
    required this.youthOrientation,
    required this.managerPatience,
  });

  final String presidentId;
  final PresidentManagementArchetype archetype;
  final int financialDiscipline;
  final int riskAppetite;
  final int transferAmbition;
  final int youthOrientation;
  final int managerPatience;

  List<int> get traits => [
        financialDiscipline,
        riskAppetite,
        transferAmbition,
        youthOrientation,
        managerPatience,
      ];

  double distanceTo(PresidentManagementProfile other) {
    var total = 0;
    for (var i = 0; i < traits.length; i++) {
      total += (traits[i] - other.traits[i]).abs();
    }
    return total / traits.length;
  }

  String get signature =>
      '$presidentId:${archetype.name}:'
      'finance=$financialDiscipline:risk=$riskAppetite:'
      'transfer=$transferAmbition:youth=$youthOrientation:'
      'patience=$managerPatience';
}

class PresidentManagementProfileGenerator {
  const PresidentManagementProfileGenerator();

  PresidentManagementProfile generate({
    required PresidentProfile president,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final rng = SeededRng(
      StableHash.combine32([
        careerSeed,
        simulationVersion,
        StableHash.string32(president.id),
        StableHash.string32('president-management-profile-v1'),
      ]),
    );
    final archetypes = PresidentManagementArchetype.values;
    final archetype = archetypes[(rng.nextDouble() * archetypes.length).floor()];
    final centers = _centers(archetype);

    return PresidentManagementProfile(
      presidentId: president.id,
      archetype: archetype,
      financialDiscipline: _withJitter(rng, centers[0]),
      riskAppetite: _withJitter(rng, centers[1]),
      transferAmbition: _withJitter(rng, centers[2]),
      youthOrientation: _withJitter(rng, centers[3]),
      managerPatience: _withJitter(rng, centers[4]),
    );
  }

  List<int> _centers(PresidentManagementArchetype archetype) =>
      switch (archetype) {
        PresidentManagementArchetype.balanced => [60, 55, 58, 60, 60],
        PresidentManagementArchetype.prudentBuilder => [82, 30, 38, 68, 72],
        PresidentManagementArchetype.ambitiousSpender => [38, 80, 84, 42, 40],
        PresidentManagementArchetype.youthArchitect => [68, 48, 38, 86, 76],
        PresidentManagementArchetype.patientPlanner => [72, 38, 45, 68, 88],
        PresidentManagementArchetype.interventionist => [50, 72, 72, 40, 25],
      };

  int _withJitter(SeededRng rng, int center) {
    final jitter = (rng.nextDouble() * 21).floor() - 10;
    return (center + jitter).clamp(20, 90).toInt();
  }
}
