import 'package:futbol_baskanlik_m0/src/core/simulation_config.dart';
import 'package:futbol_baskanlik_m0/src/facility/academy_facility.dart';
import 'package:futbol_baskanlik_m0/src/player/player_lifecycle_engine.dart';
import 'package:futbol_baskanlik_m0/src/player/player_pool_generator.dart';
import 'package:futbol_baskanlik_m0/src/player/team_strength_calculator.dart';
import 'package:futbol_baskanlik_m0/src/world/fictional_world_factory.dart';
import 'package:test/test.dart';

void main() {
  const policy = AcademyInvestmentPolicy();
  const lifecycle = PlayerLifecycleEngine();
  const config = SimulationConfig(careerSeed: 20260903);

  test('M33 academy investment cost and target level are bounded', () {
    final state = AcademyFacilityState(clubId: 'club', level: 0);
    var current = state;
    var total = 0;
    for (var level = 1; level <= AcademyInvestmentPolicy.maxLevel; level++) {
      final decision = policy.upgrade(current);
      expect(decision.upgraded, isTrue);
      expect(decision.after.level, level);
      expect(decision.cost.isNegative, isFalse);
      total += decision.cost.minorUnits;
      current = decision.after;
    }
    final capped = policy.upgrade(current);
    expect(capped.upgraded, isFalse);
    expect(capped.cost.isZero, isTrue);
    expect(total, greaterThan(0));
    expect(policy.targetLevelForYouthOrientation(0), 0);
    expect(policy.targetLevelForYouthOrientation(50), 2);
    expect(policy.targetLevelForYouthOrientation(90), 5);
  });

  test('M33 academy level zero preserves legacy youth intake exactly', () {
    final world = const FictionalWorldFactory().build();
    final players = const PlayerPoolGenerator().generate(
      clubs: world.clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final currentClubs = const TeamStrengthCalculator().deriveClubs(
      baseClubs: world.clubs,
      players: players,
    );
    final baseline = lifecycle.advance(
      currentPlayers: players,
      currentClubs: currentClubs,
      referenceClubs: world.clubs,
      careerSeed: config.careerSeed,
      nextSeasonIndex: 1,
      simulationVersion: config.simulationVersion,
    );
    final explicitZero = lifecycle.advance(
      currentPlayers: players,
      currentClubs: currentClubs,
      referenceClubs: world.clubs,
      careerSeed: config.careerSeed,
      nextSeasonIndex: 1,
      simulationVersion: config.simulationVersion,
      academyFacilities: {
        for (final club in world.clubs)
          club.id: AcademyFacilityState(clubId: club.id, level: 0),
      },
    );
    expect(
      explicitZero.youthIntake.map((player) => player.signature).toList(),
      baseline.youthIntake.map((player) => player.signature).toList(),
    );
    expect(
      explicitZero.activePlayers.map((player) => player.signature).toList(),
      baseline.activePlayers.map((player) => player.signature).toList(),
    );
  });

  test('M33 stronger academies materially improve the same deterministic intake', () {
    final world = const FictionalWorldFactory().build();
    final players = const PlayerPoolGenerator().generate(
      clubs: world.clubs,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final currentClubs = const TeamStrengthCalculator().deriveClubs(
      baseClubs: world.clubs,
      players: players,
    );
    final baseline = lifecycle.advance(
      currentPlayers: players,
      currentClubs: currentClubs,
      referenceClubs: world.clubs,
      careerSeed: config.careerSeed,
      nextSeasonIndex: 1,
      simulationVersion: config.simulationVersion,
    );
    final elite = lifecycle.advance(
      currentPlayers: players,
      currentClubs: currentClubs,
      referenceClubs: world.clubs,
      careerSeed: config.careerSeed,
      nextSeasonIndex: 1,
      simulationVersion: config.simulationVersion,
      academyFacilities: {
        for (final club in world.clubs)
          club.id: AcademyFacilityState(clubId: club.id, level: 5),
      },
    );

    expect(elite.youthIntake.length, baseline.youthIntake.length);
    for (var i = 0; i < baseline.youthIntake.length; i++) {
      expect(elite.youthIntake[i].id, baseline.youthIntake[i].id);
      expect(elite.youthIntake[i].position, baseline.youthIntake[i].position);
      expect(elite.youthIntake[i].age, baseline.youthIntake[i].age);
      expect(
        elite.youthIntake[i].ability,
        greaterThanOrEqualTo(baseline.youthIntake[i].ability),
      );
      expect(
        elite.youthIntake[i].potential,
        greaterThanOrEqualTo(baseline.youthIntake[i].potential),
      );
    }
    final baselineAbility = baseline.youthIntake
            .map((player) => player.ability)
            .reduce((a, b) => a + b) /
        baseline.youthIntake.length;
    final eliteAbility = elite.youthIntake
            .map((player) => player.ability)
            .reduce((a, b) => a + b) /
        elite.youthIntake.length;
    final baselinePotential = baseline.youthIntake
            .map((player) => player.potential)
            .reduce((a, b) => a + b) /
        baseline.youthIntake.length;
    final elitePotential = elite.youthIntake
            .map((player) => player.potential)
            .reduce((a, b) => a + b) /
        elite.youthIntake.length;

    expect(eliteAbility - baselineAbility, greaterThan(2.0));
    expect(elitePotential - baselinePotential, greaterThan(6.0));
  });
}
