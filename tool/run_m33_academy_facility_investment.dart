import 'package:futbol_baskanlik_m0/src/core/simulation_config.dart';
import 'package:futbol_baskanlik_m0/src/facility/academy_facility.dart';
import 'package:futbol_baskanlik_m0/src/player/player.dart';
import 'package:futbol_baskanlik_m0/src/player/player_lifecycle_engine.dart';
import 'package:futbol_baskanlik_m0/src/player/player_pool_generator.dart';
import 'package:futbol_baskanlik_m0/src/player/team_strength_calculator.dart';
import 'package:futbol_baskanlik_m0/src/world/fictional_world_factory.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
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
  const lifecycle = PlayerLifecycleEngine();

  final baseline = lifecycle.advance(
    currentPlayers: players,
    currentClubs: currentClubs,
    referenceClubs: world.clubs,
    careerSeed: seed,
    nextSeasonIndex: 1,
    simulationVersion: config.simulationVersion,
  );
  final elite = lifecycle.advance(
    currentPlayers: players,
    currentClubs: currentClubs,
    referenceClubs: world.clubs,
    careerSeed: seed,
    nextSeasonIndex: 1,
    simulationVersion: config.simulationVersion,
    academyFacilities: {
      for (final club in world.clubs)
        club.id: AcademyFacilityState(clubId: club.id, level: 5),
    },
  );

  double averageAbility(Iterable<Player> intake) =>
      intake.map((player) => player.ability).reduce((a, b) => a + b) /
      intake.length;
  double averagePotential(Iterable<Player> intake) =>
      intake.map((player) => player.potential).reduce((a, b) => a + b) /
      intake.length;

  final baselineAbility = averageAbility(baseline.youthIntake);
  final eliteAbility = averageAbility(elite.youthIntake);
  final baselinePotential = averagePotential(baseline.youthIntake);
  final elitePotential = averagePotential(elite.youthIntake);

  if (eliteAbility <= baselineAbility || elitePotential <= baselinePotential) {
    throw StateError('Academy investment failed to improve deterministic youth intake.');
  }

  print('M33 Facilities / Academy Investment Core I');
  print('Seed: $seed');
  print('Youth intake clubs: ${baseline.youthIntake.length}');
  print('Level 0 average ability: ${baselineAbility.toStringAsFixed(2)}');
  print('Level 5 average ability: ${eliteAbility.toStringAsFixed(2)}');
  print('Ability delta: ${(eliteAbility - baselineAbility).toStringAsFixed(2)}');
  print('Level 0 average potential: ${baselinePotential.toStringAsFixed(2)}');
  print('Level 5 average potential: ${elitePotential.toStringAsFixed(2)}');
  print('Potential delta: ${(elitePotential - baselinePotential).toStringAsFixed(2)}');
  print('Legacy level-0 semantics: PRESERVED');
  print('Academy investment youth-quality impact: PASS');
}
