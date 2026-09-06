import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_decision_loop.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const loop = PresidentFacilityDecisionLoopEngine();
  const codec = FacilityRuntimeSaveCodec();
  late FacilityRuntimeCheckpoint season8;
  late String targetClub;

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
  });

  PresidentManagementProfile provider({
    required int seasonIndex,
    required String clubId,
    required int turnoverSeason,
  }) {
    if (clubId != targetClub) return cautious;
    return seasonIndex < turnoverSeason ? cautious : youthBuilder;
  }

  test('M37 reevaluates academy investment every season window', () {
    final result = loop.run(
      checkpoint: season8,
      seasonCount: 2,
      profileProvider: ({required seasonIndex, required clubId}) =>
          clubId == targetClub ? youthBuilder : cautious,
    );
    final targetDecisions = result.decisions
        .where((decision) => decision.clubId == targetClub)
        .toList();

    expect(targetDecisions, hasLength(2));
    expect(targetDecisions.first.appliedUpgrades, greaterThan(0));
    expect(
      targetDecisions[1].beforeLevel,
      targetDecisions[0].afterLevel,
    );
    expect(targetDecisions[1].targetLevel, 5);
    expect(result.checkpoint.completedSeasons, 10);
  });

  test('M37 replans immediately after a president turnover', () {
    final result = loop.run(
      checkpoint: season8,
      seasonCount: 4,
      profileProvider: ({required seasonIndex, required clubId}) => provider(
        seasonIndex: seasonIndex,
        clubId: clubId,
        turnoverSeason: 10,
      ),
    );
    final targetDecisions = result.decisions
        .where((decision) => decision.clubId == targetClub)
        .toList();

    expect(targetDecisions, hasLength(4));
    expect(targetDecisions[0].presidentId, cautious.presidentId);
    expect(targetDecisions[1].presidentId, cautious.presidentId);
    expect(targetDecisions[0].appliedUpgrades, 0);
    expect(targetDecisions[1].appliedUpgrades, 0);
    expect(targetDecisions[2].presidentId, youthBuilder.presidentId);
    expect(targetDecisions[2].targetLevel, 5);
    expect(targetDecisions[2].appliedUpgrades, greaterThan(0));
  });

  test('M37 a cautious successor stops predecessor academy expansion', () {
    final result = loop.run(
      checkpoint: season8,
      seasonCount: 2,
      profileProvider: ({required seasonIndex, required clubId}) {
        if (clubId != targetClub) return cautious;
        return seasonIndex == 8 ? youthBuilder : cautious;
      },
    );
    final targetDecisions = result.decisions
        .where((decision) => decision.clubId == targetClub)
        .toList();

    expect(targetDecisions.first.appliedUpgrades, greaterThan(0));
    expect(targetDecisions[1].presidentId, cautious.presidentId);
    expect(targetDecisions[1].appliedUpgrades, 0);
    expect(targetDecisions[1].afterLevel, targetDecisions[1].beforeLevel);
  });

  test('M37 save load resume matches uninterrupted seasonal decision loop', () {
    PresidentFacilityProfileProvider profileProvider =
        ({required seasonIndex, required clubId}) => provider(
              seasonIndex: seasonIndex,
              clubId: clubId,
              turnoverSeason: 10,
            );

    final direct = loop.run(
      checkpoint: season8,
      seasonCount: 4,
      profileProvider: profileProvider,
    );
    final first = loop.run(
      checkpoint: season8,
      seasonCount: 2,
      profileProvider: profileProvider,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final second = loop.run(
      checkpoint: loaded,
      seasonCount: 2,
      profileProvider: profileProvider,
    );

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
