import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const investment = FacilityInvestmentOrchestrator();
  const career = FacilityRuntimeCareerEngine();
  const codec = FacilityRuntimeSaveCodec();

  final season8 = FacilityRuntimeCheckpoint.initial(
    worldEngine
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: 8,
        )
        .checkpoint,
  );
  final richest = season8.world.nextSeasonFinanceStates.reduce(
    (a, b) => a.cash >= b.cash ? a : b,
  );
  final invested = investment.upgradeTowardTarget(
    checkpoint: season8,
    clubId: richest.clubId,
    targetLevel: 2,
  );
  final levelZero = FacilityRuntimeCheckpoint(
    world: invested.world,
    academyFacilities: season8.academyFacilities,
    totalInvestmentSpent: invested.totalInvestmentSpent,
  );

  final baseline = career.resumeWithReport(
    checkpoint: levelZero,
    seasonCount: 1,
  );
  final upgraded = career.resumeWithReport(
    checkpoint: invested,
    seasonCount: 1,
  );
  final baselineYouth = baseline.report.seasons.single.youthIntakeAfterSeason
      .singleWhere((player) => player.clubId == richest.clubId);
  final upgradedYouth = upgraded.report.seasons.single.youthIntakeAfterSeason
      .singleWhere((player) => player.clubId == richest.clubId);

  final direct20 = career.resumeWithReport(
    checkpoint: invested,
    seasonCount: 12,
  );
  final loaded = codec.decode(codec.encode(invested));
  final resumed20 = career.resumeWithReport(
    checkpoint: loaded,
    seasonCount: 12,
  );
  final youthMatch = direct20.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .join('||') ==
      resumed20.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .join('||');
  final checkpointMatch =
      direct20.checkpoint.signature == resumed20.checkpoint.signature;

  print('M35 Academy Runtime Youth Integration I');
  print('Seed: $seed');
  print('Investment checkpoint: season 8');
  print('Investment club: ${richest.clubId}');
  print('Academy level: ${invested.facilityFor(richest.clubId).level}');
  print('Baseline youth ability: ${baselineYouth.ability.toStringAsFixed(2)}');
  print('Upgraded youth ability: ${upgradedYouth.ability.toStringAsFixed(2)}');
  print('Ability delta: ${(upgradedYouth.ability - baselineYouth.ability).toStringAsFixed(2)}');
  print('Baseline youth potential: ${baselineYouth.potential.toStringAsFixed(2)}');
  print('Upgraded youth potential: ${upgradedYouth.potential.toStringAsFixed(2)}');
  print('Potential delta: ${(upgradedYouth.potential - baselineYouth.potential).toStringAsFixed(2)}');
  print('Completed seasons after resume: ${resumed20.checkpoint.completedSeasons}');
  print('Youth history match: $youthMatch');
  print('Final checkpoint match: $checkpointMatch');
  print('Academy runtime youth integration: ${youthMatch && checkpointMatch ? 'PASS' : 'FAIL'}');

  if (invested.facilityFor(richest.clubId).level != 2 ||
      upgradedYouth.id != baselineYouth.id ||
      upgradedYouth.ability <= baselineYouth.ability ||
      upgradedYouth.potential <= baselineYouth.potential ||
      resumed20.checkpoint.completedSeasons != 20 ||
      !youthMatch ||
      !checkpointMatch) {
    throw StateError('M35 academy runtime youth integration validation failed.');
  }
}
