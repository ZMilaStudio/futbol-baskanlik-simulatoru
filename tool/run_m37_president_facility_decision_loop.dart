import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_decision_loop.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const loop = PresidentFacilityDecisionLoopEngine();
  const codec = FacilityRuntimeSaveCodec();

  final season8 = FacilityRuntimeCheckpoint.initial(
    const WorldCareerEngine()
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: 8,
        )
        .checkpoint,
  );
  final targetClub = season8.world.nextSeasonFinanceStates
      .reduce((a, b) => a.cash >= b.cash ? a : b)
      .clubId;

  const cautious = PresidentManagementProfile(
    presidentId: 'm37-cautious-president',
    archetype: PresidentManagementArchetype.interventionist,
    financialDiscipline: 85,
    riskAppetite: 35,
    transferAmbition: 35,
    youthOrientation: 20,
    managerPatience: 55,
  );
  const youthBuilder = PresidentManagementProfile(
    presidentId: 'm37-youth-builder-president',
    archetype: PresidentManagementArchetype.youthArchitect,
    financialDiscipline: 60,
    riskAppetite: 45,
    transferAmbition: 40,
    youthOrientation: 90,
    managerPatience: 75,
  );

  PresidentFacilityProfileProvider provider =
      ({required seasonIndex, required clubId}) {
    if (clubId != targetClub) return cautious;
    return seasonIndex < 10 ? cautious : youthBuilder;
  };

  final direct = loop.run(
    checkpoint: season8,
    seasonCount: 4,
    profileProvider: provider,
  );
  final first = loop.run(
    checkpoint: season8,
    seasonCount: 2,
    profileProvider: provider,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final second = loop.run(
    checkpoint: loaded,
    seasonCount: 2,
    profileProvider: provider,
  );

  final directTarget = direct.decisions
      .where((decision) => decision.clubId == targetClub)
      .toList();
  final splitDecisionMatch = [
        ...first.decisions,
        ...second.decisions,
      ].map((decision) => decision.signature).join('|') ==
      direct.decisions.map((decision) => decision.signature).join('|');
  final youthMatch = [
        ...first.youthIntakeSignatures,
        ...second.youthIntakeSignatures,
      ].join('|') ==
      direct.youthIntakeSignatures.join('|');
  final checkpointMatch =
      second.checkpoint.signature == direct.checkpoint.signature;
  final turnoverReplanned = directTarget.length == 4 &&
      directTarget[0].appliedUpgrades == 0 &&
      directTarget[1].appliedUpgrades == 0 &&
      directTarget[2].presidentId == youthBuilder.presidentId &&
      directTarget[2].targetLevel == 5 &&
      directTarget[2].appliedUpgrades > 0;

  print('M37 President Facility Decision Loop / Turnover Replanning I');
  print('Seed: $seed');
  print('Start checkpoint: season 8');
  print('Target club: $targetClub');
  print('Turnover season: 10');
  print('Decision windows: ${directTarget.length}');
  print(
    'Target levels: ${directTarget.map((item) => item.targetLevel).join(', ')}',
  );
  print(
    'Applied upgrades: ${directTarget.map((item) => item.appliedUpgrades).join(', ')}',
  );
  print(
    'Academy path: ${directTarget.map((item) => '${item.beforeLevel}->${item.afterLevel}').join(', ')}',
  );
  print('Completed seasons: ${direct.checkpoint.completedSeasons}');
  print('Turnover replanned: $turnoverReplanned');
  print('Split decisions match: $splitDecisionMatch');
  print('Youth history match: $youthMatch');
  print('Final checkpoint match: $checkpointMatch');
  print(
    'Seasonal president facility decision loop: '
    '${turnoverReplanned && splitDecisionMatch && youthMatch && checkpointMatch ? 'PASS' : 'FAIL'}',
  );

  if (!turnoverReplanned ||
      !splitDecisionMatch ||
      !youthMatch ||
      !checkpointMatch) {
    throw StateError('M37 canonical acceptance failed.');
  }
}
