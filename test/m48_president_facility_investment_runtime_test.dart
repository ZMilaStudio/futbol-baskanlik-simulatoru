import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/president_facility_investment_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_facility_portfolio_investment_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const legacy = FacilitySponsorCrisisRuntimeCareerEngine();
  const runtime = PresidentFacilityInvestmentRuntimeCareerEngine();
  const integration = PresidentFacilityInvestmentRuntimeEngine();
  const codec = FacilitySponsorCrisisRuntimeSaveCodec();

  test('M48 final season without future preserves M47 exactly', () {
    final world = const FictionalWorldFactory().build();
    final m47 = legacy.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final m48 = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );

    expect(m48.boundaries.single.preparedNextSeason, isFalse);
    expect(m48.boundaries.single.decisions, isEmpty);
    expect(codec.encode(m48.checkpoint), codec.encode(m47.checkpoint));
  });

  test('M48 reuses M39 policy and spends real cash without debt', () {
    final world = const FictionalWorldFactory().build();
    final opening = legacy.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final checkpoint = opening.checkpoint;
    final result = integration.apply(checkpoint);
    final states = [...checkpoint.runtime.domain.presidentRuntime.clubs]
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final target = states.first;
    var direct = FacilityRuntimeCheckpoint(
      world: checkpoint.runtime.domain.presidentRuntime.runtime.runtime.world,
      academyFacilities: checkpoint.facilities.academyFacilities,
      stadiumFacilities: checkpoint.facilities.stadiumFacilities,
      trainingGroundFacilities: checkpoint.facilities.trainingGroundFacilities,
      totalInvestmentSpent: checkpoint.facilities.totalInvestmentSpent,
    );
    final academy = const PresidentAcademyInvestmentOrchestrator().apply(
      checkpoint: direct,
      clubId: target.clubId,
      profile: target.managementProfile,
    );
    final portfolio =
        const PresidentFacilityPortfolioInvestmentOrchestrator().apply(
      checkpoint: academy.checkpoint,
      clubId: target.clubId,
      profile: target.managementProfile,
    );
    direct = portfolio.checkpoint;
    final decision = result.decisions.first;

    expect(decision.clubId, target.clubId);
    expect(decision.presidentId, target.managementProfile.presidentId);
    expect(decision.academyTargetLevel, academy.plan.targetLevel);
    expect(decision.academyAfterLevel, academy.afterLevel);
    expect(
      decision.trainingGroundTargetLevel,
      portfolio.plan.trainingGroundTargetLevel,
    );
    expect(decision.trainingGroundAfterLevel, portfolio.afterTrainingGroundLevel);
    expect(decision.stadiumTargetLevel, portfolio.plan.stadiumTargetLevel);
    expect(decision.stadiumAfterLevel, portfolio.afterStadiumLevel);
    expect(decision.spend, academy.spend + portfolio.spend);

    final beforeFinance = checkpoint.runtime.domain.presidentRuntime.runtime
        .runtime.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == target.clubId);
    final directFinance = direct.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == target.clubId);
    final afterFinance = result.checkpoint.runtime.domain.presidentRuntime.runtime
        .runtime.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == target.clubId);
    expect(afterFinance.signature, directFinance.signature);
    expect(afterFinance.debt, beforeFinance.debt);
    expect(beforeFinance.cash - afterFinance.cash, decision.spend);
  });

  test('M48 investment feeds the next real stadium economy', () {
    final world = const FictionalWorldFactory().build();
    final baseline = legacy.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );
    final integrated = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );
    final first = integrated.boundaries.first;
    final stadiumDecision = first.decisions.firstWhere(
      (decision) => decision.stadiumAppliedUpgrades > 0,
    );
    final target = stadiumDecision.clubId;
    final baselineFinance = baseline.boundaries[1].sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == target);
    final integratedFinance = integrated.boundaries[1].source.sponsor.report
        .sourceReport.advancedTransferReport.worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == target);

    expect(first.preparedNextSeason, isTrue);
    expect(first.investment!.totalSpend, greaterThan(Money.zero));
    expect(first.checkpoint.facilities.stadiumFor(target).level, greaterThan(0));
    expect(
      integrated.boundaries[1].source.checkpoint.facilities
          .stadiumFor(target)
          .level,
      first.checkpoint.facilities.stadiumFor(target).level,
    );
    expect(
      integratedFinance.matchdayRevenue,
      greaterThan(baselineFinance.matchdayRevenue),
    );
  });

  test('M48 next-season decision uses the post-election current president', () {
    final world = const FictionalWorldFactory().build();
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 1,
    );
    final first = result.boundaries.first;
    final currentByClub = {
      for (final state
          in first.source.checkpoint.runtime.domain.presidentRuntime.clubs)
        state.clubId: state.managementProfile.presidentId,
    };
    final generator = const PresidentProfileGenerator();
    final initialByClub = {
      for (final club in world.clubs)
        club.id: generator
            .generateInitial(
              clubId: club.id,
              careerSeed: config.careerSeed,
              simulationVersion: config.simulationVersion,
            )
            .id,
    };

    for (final decision in first.decisions) {
      expect(decision.presidentId, currentByClub[decision.clubId]);
    }
    expect(
      first.decisions.any(
        (decision) => decision.presidentId != initialByClub[decision.clubId],
      ),
      isTrue,
    );
  });

  test('M48 2 plus 2 save resume matches uninterrupted four seasons', () {
    final world = const FictionalWorldFactory().build();
    final direct = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
    );
    final first = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final second = runtime.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(
      second.checkpoint.facilities.totalInvestmentSpent,
      greaterThan(Money.zero),
    );
  });
}
