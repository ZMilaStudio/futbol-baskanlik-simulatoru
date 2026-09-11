import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_portfolio_decision_loop.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const loop = PresidentFacilityPortfolioDecisionLoopEngine();
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
    presidentId: 'm39-cautious-president',
    archetype: PresidentManagementArchetype.prudentBuilder,
    financialDiscipline: 90,
    riskAppetite: 20,
    transferAmbition: 20,
    youthOrientation: 20,
    managerPatience: 20,
  );
  const builder = PresidentManagementProfile(
    presidentId: 'm39-portfolio-builder-president',
    archetype: PresidentManagementArchetype.ambitiousSpender,
    financialDiscipline: 60,
    riskAppetite: 90,
    transferAmbition: 90,
    youthOrientation: 90,
    managerPatience: 90,
  );

  PresidentFacilityPortfolioProfileProvider provider =
      ({required seasonIndex, required clubId}) {
    if (clubId != targetClub) return cautious;
    return seasonIndex < 9 ? cautious : builder;
  };

  final direct = loop.run(
    checkpoint: season8,
    seasonCount: 2,
    profileProvider: provider,
  );
  final first = loop.run(
    checkpoint: season8,
    seasonCount: 1,
    profileProvider: provider,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final second = loop.run(
    checkpoint: loaded,
    seasonCount: 1,
    profileProvider: provider,
  );

  final targetDecisions = direct.decisions
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
  final turnoverReplanned = targetDecisions.length == 2 &&
      targetDecisions[0].presidentId == cautious.presidentId &&
      targetDecisions[0].stadiumAppliedUpgrades == 0 &&
      targetDecisions[0].trainingGroundAppliedUpgrades == 0 &&
      targetDecisions[1].presidentId == builder.presidentId &&
      targetDecisions[1].stadiumTargetLevel == 5 &&
      targetDecisions[1].trainingGroundTargetLevel == 5 &&
      targetDecisions[1].stadiumAppliedUpgrades +
              targetDecisions[1].trainingGroundAppliedUpgrades >
          0;

  print('M39 President Facility Portfolio Decision Loop I');
  print('Seed: $seed');
  print('Start checkpoint: season 8');
  print('Target club: $targetClub');
  print('Turnover season: 9');
  print('Decision windows: ${targetDecisions.length}');
  print(
    'Presidents: ${targetDecisions.map((item) => item.presidentId).join(' -> ')}',
  );
  print(
    'Academy path: ${targetDecisions.map((item) => '${item.academyBeforeLevel}->${item.academyAfterLevel}').join(', ')}',
  );
  print(
    'Training targets: ${targetDecisions.map((item) => item.trainingGroundTargetLevel).join(', ')}',
  );
  print(
    'Training path: ${targetDecisions.map((item) => '${item.trainingGroundBeforeLevel}->${item.trainingGroundAfterLevel}').join(', ')}',
  );
  print(
    'Stadium targets: ${targetDecisions.map((item) => item.stadiumTargetLevel).join(', ')}',
  );
  print(
    'Stadium path: ${targetDecisions.map((item) => '${item.stadiumBeforeLevel}->${item.stadiumAfterLevel}').join(', ')}',
  );
  print(
    'Applied portfolio upgrades: ${targetDecisions.map((item) => '${item.trainingGroundAppliedUpgrades}+${item.stadiumAppliedUpgrades}').join(', ')}',
  );
  print(
    'Spend: ${targetDecisions.map((item) => item.spend.toString()).join(', ')}',
  );
  print('Completed seasons: ${direct.checkpoint.completedSeasons}');
  print('Turnover replanned: $turnoverReplanned');
  print('Split decisions match: $splitDecisionMatch');
  print('Youth history match: $youthMatch');
  print('Final checkpoint match: $checkpointMatch');
  print(
    'President facility portfolio decision loop: '
    '${turnoverReplanned && splitDecisionMatch && youthMatch && checkpointMatch ? 'PASS' : 'FAIL'}',
  );

  if (!turnoverReplanned ||
      !splitDecisionMatch ||
      !youthMatch ||
      !checkpointMatch) {
    throw StateError('M39 canonical acceptance failed.');
  }
}
