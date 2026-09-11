import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_decision_loop.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_portfolio_decision_loop.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_portfolio_investment_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const loop = PresidentFacilityPortfolioDecisionLoopEngine();
  const portfolioInvestment =
      PresidentFacilityPortfolioInvestmentOrchestrator();
  const codec = FacilityRuntimeSaveCodec();
  late FacilityRuntimeCheckpoint season8;
  late String targetClub;

  const cautious = PresidentManagementProfile(
    presidentId: 'cautious-president',
    archetype: PresidentManagementArchetype.prudentBuilder,
    financialDiscipline: 90,
    riskAppetite: 20,
    transferAmbition: 20,
    youthOrientation: 20,
    managerPatience: 20,
  );
  const builder = PresidentManagementProfile(
    presidentId: 'portfolio-builder-president',
    archetype: PresidentManagementArchetype.ambitiousSpender,
    financialDiscipline: 60,
    riskAppetite: 90,
    transferAmbition: 90,
    youthOrientation: 90,
    managerPatience: 90,
  );
  const stadiumFirst = PresidentManagementProfile(
    presidentId: 'stadium-first',
    archetype: PresidentManagementArchetype.ambitiousSpender,
    financialDiscipline: 50,
    riskAppetite: 90,
    transferAmbition: 90,
    youthOrientation: 30,
    managerPatience: 30,
  );
  const trainingFirst = PresidentManagementProfile(
    presidentId: 'training-first',
    archetype: PresidentManagementArchetype.youthArchitect,
    financialDiscipline: 50,
    riskAppetite: 30,
    transferAmbition: 30,
    youthOrientation: 90,
    managerPatience: 90,
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

  test('M39 profile traits create distinct stadium and training priorities', () {
    final stadiumPlan = portfolioInvestment.planFor(stadiumFirst);
    final trainingPlan = portfolioInvestment.planFor(trainingFirst);

    expect(
      stadiumPlan.stadiumPriorityScore,
      greaterThan(stadiumPlan.trainingGroundPriorityScore),
    );
    expect(stadiumPlan.stadiumTargetLevel, 5);
    expect(
      trainingPlan.trainingGroundPriorityScore,
      greaterThan(trainingPlan.stadiumPriorityScore),
    );
    expect(trainingPlan.trainingGroundTargetLevel, 5);
  });

  test('M39 portfolio spending uses real cash and does not create debt', () {
    final beforeFinance = season8.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == targetClub);
    final result = portfolioInvestment.apply(
      checkpoint: season8,
      clubId: targetClub,
      profile: builder,
    );
    final afterFinance = result.checkpoint.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == targetClub);

    expect(result.appliedTrainingGroundUpgrades, greaterThan(0));
    expect(result.appliedStadiumUpgrades, greaterThan(0));
    expect(beforeFinance.cash - afterFinance.cash, result.spend);
    expect(afterFinance.debt, beforeFinance.debt);
    expect(result.afterTrainingGroundLevel, greaterThanOrEqualTo(0));
    expect(result.afterStadiumLevel, greaterThanOrEqualTo(0));
  });

  test('M39 preserves the M37 academy decision before portfolio spending', () {
    PresidentFacilityProfileProvider legacyProvider =
        ({required seasonIndex, required clubId}) =>
            clubId == targetClub ? builder : cautious;
    PresidentFacilityPortfolioProfileProvider portfolioProvider =
        ({required seasonIndex, required clubId}) =>
            clubId == targetClub ? builder : cautious;

    final legacy = const PresidentFacilityDecisionLoopEngine().run(
      checkpoint: season8,
      seasonCount: 1,
      profileProvider: legacyProvider,
    );
    final expanded = loop.run(
      checkpoint: season8,
      seasonCount: 1,
      profileProvider: portfolioProvider,
    );
    final legacyDecision =
        legacy.decisions.firstWhere((item) => item.clubId == targetClub);
    final expandedDecision =
        expanded.decisions.firstWhere((item) => item.clubId == targetClub);

    expect(expandedDecision.academyTargetLevel, legacyDecision.targetLevel);
    expect(expandedDecision.academyBeforeLevel, legacyDecision.beforeLevel);
    expect(expandedDecision.academyAfterLevel, legacyDecision.afterLevel);
    expect(
      expandedDecision.academyAppliedUpgrades,
      legacyDecision.appliedUpgrades,
    );
    expect(
      expandedDecision.academyCashReserveBasisPoints,
      legacyDecision.cashReserveBasisPoints,
    );
  });

  test('M39 replans stadium and training after president turnover', () {
    PresidentFacilityPortfolioProfileProvider provider =
        ({required seasonIndex, required clubId}) {
      if (clubId != targetClub) return cautious;
      return seasonIndex < 9 ? cautious : builder;
    };

    final result = loop.run(
      checkpoint: season8,
      seasonCount: 2,
      profileProvider: provider,
    );
    final decisions =
        result.decisions.where((item) => item.clubId == targetClub).toList();

    expect(decisions, hasLength(2));
    expect(decisions[0].presidentId, cautious.presidentId);
    expect(decisions[0].stadiumAppliedUpgrades, 0);
    expect(decisions[0].trainingGroundAppliedUpgrades, 0);
    expect(decisions[1].presidentId, builder.presidentId);
    expect(decisions[1].stadiumTargetLevel, 5);
    expect(decisions[1].trainingGroundTargetLevel, 5);
    expect(
      decisions[1].stadiumAppliedUpgrades +
          decisions[1].trainingGroundAppliedUpgrades,
      greaterThan(0),
    );
  });

  test('M39 save load resume matches uninterrupted portfolio loop', () {
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
