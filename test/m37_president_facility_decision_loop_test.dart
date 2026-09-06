import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_decision_loop.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const loop = PresidentFacilityDecisionLoopEngine();
  const codec = FacilityRuntimeSaveCodec();
  late FacilityRuntimeCheckpoint season8;
  late String targetClub;
  late PresidentFacilityDecisionLoopResult direct;
  late PresidentFacilityDecisionLoopResult first;
  late PresidentFacilityDecisionLoopResult second;
  late List<PresidentFacilitySeasonDecision> targetDecisions;

  const cautious = PresidentManagementProfile(
    presidentId: 'cautious-president',
    archetype: PresidentManagementArchetype.interventionist,
    financialDiscipline: 85,
    riskAppetite: 35,
    transferAmbition: 35,
    youthOrientation: 20,
    managerPatience: 55,
  );
  const youthBuilder = PresidentManagementProfile(
    presidentId: 'youth-builder-president',
    archetype: PresidentManagementArchetype.youthArchitect,
    financialDiscipline: 60,
    riskAppetite: 45,
    transferAmbition: 40,
    youthOrientation: 90,
    managerPatience: 75,
  );

  setUpAll(() {
    final world = const FictionalWorldFactory().build();
    final config = const SimulationConfig(careerSeed: seed);
    final result = const WorldCareerEngine().simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 8,
    );
    season8 = FacilityRuntimeCheckpoint.initial(result.checkpoint);
    targetClub = season8.world.nextSeasonFinanceStates
        .reduce((a, b) => a.cash >= b.cash ? a : b)
        .clubId;

    PresidentFacilityProfileProvider profileProvider =
        ({required seasonIndex, required clubId}) {
      if (clubId != targetClub) return cautious;
      return seasonIndex < 9 ? cautious : youthBuilder;
    };

    direct = loop.run(
      checkpoint: season8,
      seasonCount: 2,
      profileProvider: profileProvider,
    );
    first = loop.run(
      checkpoint: season8,
      seasonCount: 1,
      profileProvider: profileProvider,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    second = loop.run(
      checkpoint: loaded,
      seasonCount: 1,
      profileProvider: profileProvider,
    );
    targetDecisions = direct.decisions
        .where((decision) => decision.clubId == targetClub)
        .toList();
  });

  test('M37 reevaluates academy policy on every season window', () {
    expect(targetDecisions, hasLength(2));
    expect(targetDecisions[0].seasonIndex, 8);
    expect(targetDecisions[1].seasonIndex, 9);
    expect(targetDecisions[1].beforeLevel, targetDecisions[0].afterLevel);
    expect(direct.checkpoint.completedSeasons, 10);
  });

  test('M37 replans immediately after a president turnover', () {
    expect(targetDecisions[0].presidentId, cautious.presidentId);
    expect(targetDecisions[0].appliedUpgrades, 0);
    expect(targetDecisions[1].presidentId, youthBuilder.presidentId);
    expect(targetDecisions[1].targetLevel, 5);
    expect(targetDecisions[1].appliedUpgrades, greaterThan(0));
  });

  test('M37 save load resume matches uninterrupted decision loop', () {
    expect(second.checkpoint.signature, direct.checkpoint.signature);
    expect(
      [...first.decisions, ...second.decisions]
          .map((decision) => decision.signature)
          .toList(),
      direct.decisions.map((decision) => decision.signature).toList(),
    );
    expect(
      [...first.youthIntakeSignatures, ...second.youthIntakeSignatures],
      direct.youthIntakeSignatures,
    );
  });
}
