import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const worldCodec = WorldSaveCodec();
  const investment = FacilityInvestmentOrchestrator();
  const facilityCareer = FacilityRuntimeCareerEngine();
  const codec = FacilityRuntimeSaveCodec();

  FacilityRuntimeCheckpoint season8() => FacilityRuntimeCheckpoint.initial(
        worldEngine
            .simulateWithCheckpoint(
              clubs: world.clubs,
              leagues: world.leagues,
              config: config,
              seasonCount: 8,
            )
            .checkpoint,
      );

  test('M35 level zero facility runtime preserves legacy world resume', () {
    final checkpoint = season8();
    final legacy = worldEngine.resume(
      checkpoint: checkpoint.world,
      seasonCount: 2,
    );
    final facility = facilityCareer.resumeWithReport(
      checkpoint: checkpoint,
      seasonCount: 2,
    );

    expect(
      worldCodec.encode(facility.checkpoint.world),
      worldCodec.encode(legacy.checkpoint),
    );
    expect(
      facility.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .toList(),
      legacy.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .toList(),
    );
  });

  test('M35 persisted academy level improves real offseason youth intake', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final invested = investment.upgradeTowardTarget(
      checkpoint: before,
      clubId: richest.clubId,
      targetLevel: 2,
    );
    expect(invested.facilityFor(richest.clubId).level, 2);

    final sameFinanceLevelZero = FacilityRuntimeCheckpoint(
      world: invested.world,
      academyFacilities: before.academyFacilities,
      totalInvestmentSpent: invested.totalInvestmentSpent,
    );
    final baseline = facilityCareer.resumeWithReport(
      checkpoint: sameFinanceLevelZero,
      seasonCount: 1,
    );
    final upgraded = facilityCareer.resumeWithReport(
      checkpoint: invested,
      seasonCount: 1,
    );

    final baselineYouth = baseline.report.seasons.single.youthIntakeAfterSeason
        .singleWhere((player) => player.clubId == richest.clubId);
    final upgradedYouth = upgraded.report.seasons.single.youthIntakeAfterSeason
        .singleWhere((player) => player.clubId == richest.clubId);

    expect(upgradedYouth.id, baselineYouth.id);
    expect(upgradedYouth.name, baselineYouth.name);
    expect(upgradedYouth.position, baselineYouth.position);
    expect(upgradedYouth.age, baselineYouth.age);
    expect(upgradedYouth.retirementAge, baselineYouth.retirementAge);
    expect(upgradedYouth.ability, greaterThan(baselineYouth.ability));
    expect(upgradedYouth.potential, greaterThan(baselineYouth.potential));
  });

  test('M35 save load resume preserves facility-driven youth career', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final invested = investment.upgradeTowardTarget(
      checkpoint: before,
      clubId: richest.clubId,
      targetLevel: 2,
    );
    final direct = facilityCareer.resumeWithReport(
      checkpoint: invested,
      seasonCount: 12,
    );
    final loaded = codec.decode(codec.encode(invested));
    final resumed = facilityCareer.resumeWithReport(
      checkpoint: loaded,
      seasonCount: 12,
    );

    expect(resumed.checkpoint.signature, direct.checkpoint.signature);
    expect(resumed.checkpoint.completedSeasons, 20);
    expect(resumed.checkpoint.facilityFor(richest.clubId).level, 2);

    final directYouth = direct.report.seasons
        .expand((season) => season.youthIntakeAfterSeason)
        .map((player) => player.signature)
        .toList();
    final resumedYouth = resumed.report.seasons
        .expand((season) => season.youthIntakeAfterSeason)
        .map((player) => player.signature)
        .toList();
    expect(resumedYouth, directYouth);
  });
}
