import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_academy_investment_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const presidentInvestment = PresidentAcademyInvestmentOrchestrator();
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

  PresidentManagementProfile profile({
    required String id,
    required int youth,
    int finance = 55,
  }) =>
      PresidentManagementProfile(
        presidentId: id,
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: finance,
        riskAppetite: 50,
        transferAmbition: 50,
        youthOrientation: youth,
        managerPatience: 50,
      );

  test('M36 youth orientation maps monotonically to academy ambition', () {
    final low = presidentInvestment.planFor(profile(id: 'low', youth: 20));
    final mid = presidentInvestment.planFor(profile(id: 'mid', youth: 60));
    final high = presidentInvestment.planFor(profile(id: 'high', youth: 90));

    expect(low.targetLevel, lessThan(mid.targetLevel));
    expect(mid.targetLevel, lessThan(high.targetLevel));
    expect(low.maxUpgradesThisWindow, 0);
    expect(mid.maxUpgradesThisWindow, 1);
    expect(high.maxUpgradesThisWindow, 2);
    expect(high.cashReserveBasisPoints, lessThan(mid.cashReserveBasisPoints));
  });

  test('M36 high youth president invests more aggressively on same club', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );

    final low = presidentInvestment.apply(
      checkpoint: before,
      clubId: richest.clubId,
      profile: profile(id: 'low', youth: 20),
    );
    final high = presidentInvestment.apply(
      checkpoint: before,
      clubId: richest.clubId,
      profile: profile(id: 'high', youth: 90),
    );

    expect(low.afterLevel, 0);
    expect(low.spend, Money.zero);
    expect(high.afterLevel, 2);
    expect(high.appliedUpgrades, 2);
    expect(high.spend, greaterThan(low.spend));
  });

  test('M36 stricter finance profile retains at least as much cash', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final relaxed = presidentInvestment.apply(
      checkpoint: before,
      clubId: richest.clubId,
      profile: profile(id: 'relaxed', youth: 90, finance: 20),
    );
    final strict = presidentInvestment.apply(
      checkpoint: before,
      clubId: richest.clubId,
      profile: profile(id: 'strict', youth: 90, finance: 90),
    );
    final relaxedCash = relaxed.checkpoint.world.nextSeasonFinanceStates
        .singleWhere((state) => state.clubId == richest.clubId)
        .cash;
    final strictCash = strict.checkpoint.world.nextSeasonFinanceStates
        .singleWhere((state) => state.clubId == richest.clubId)
        .cash;

    expect(strictCash, greaterThanOrEqualTo(relaxedCash));
    expect(strict.spend, lessThanOrEqualTo(relaxed.spend));
  });

  test('M36 profile-driven investment survives save load resume deterministically', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final invested = presidentInvestment.apply(
      checkpoint: before,
      clubId: richest.clubId,
      profile: profile(id: 'academy-president', youth: 90),
    );
    expect(invested.afterLevel, 2);

    final direct = facilityCareer.resumeWithReport(
      checkpoint: invested.checkpoint,
      seasonCount: 12,
    );
    final loaded = codec.decode(codec.encode(invested.checkpoint));
    final resumed = facilityCareer.resumeWithReport(
      checkpoint: loaded,
      seasonCount: 12,
    );

    expect(resumed.checkpoint.signature, direct.checkpoint.signature);
    expect(resumed.checkpoint.completedSeasons, 20);
    expect(resumed.checkpoint.facilityFor(richest.clubId).level, 2);
    expect(
      resumed.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .toList(),
      direct.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .toList(),
    );
  });
}
