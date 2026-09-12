import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/facility_sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const runtimeCodec = SponsorPresidentRuntimeSaveCodec();
  const codec = FacilitySponsorCrisisRuntimeSaveCodec();
  const neutralCrisis = CrisisRuntimeIntegrationEngine(
    decisionEngine: CrisisDecisionEngine(activationThreshold: 101),
  );
  const forcedCrisis = CrisisRuntimeIntegrationEngine(
    decisionEngine: CrisisDecisionEngine(activationThreshold: 0),
  );
  const legacyNeutral = SponsorCrisisRuntimeCareerEngine(
    crisisIntegration: neutralCrisis,
  );
  const combinedNeutral = FacilitySponsorCrisisRuntimeCareerEngine(
    crisisIntegration: neutralCrisis,
  );

  test('M47 neutral facilities preserve M46 runtime exactly', () {
    final world = const FictionalWorldFactory().build();
    final legacy = legacyNeutral.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 2,
    );
    final combined = combinedNeutral.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 2,
    );

    expect(combined.crisisCount, 0);
    expect(
      runtimeCodec.encode(combined.checkpoint.runtime),
      runtimeCodec.encode(legacy.checkpoint),
    );
    expect(
      combined.boundaries.map((item) => item.sponsor.signature).toList(),
      legacy.boundaries.map((item) => item.sponsor.signature).toList(),
    );
    expect(
      combined.checkpoint.facilities.academyFacilities
          .every((state) => state.level == 0),
      isTrue,
    );
    expect(
      combined.checkpoint.facilities.stadiumFacilities
          .every((state) => state.level == 0),
      isTrue,
    );
    expect(
      combined.checkpoint.facilities.trainingGroundFacilities
          .every((state) => state.level == 0),
      isTrue,
    );
  });

  test('M47 stadium facility changes real sponsor-aware matchday revenue', () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.reduce(
      (a, b) => a.strength >= b.strength ? a : b,
    );
    final neutral = combinedNeutral.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final upgraded = combinedNeutral.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      stadiumFacilities: world.clubs.map(
        (club) => StadiumFacilityState(
          clubId: club.id,
          level: club.id == target.id ? 5 : 0,
        ),
      ),
    );
    final neutralFinance = neutral.boundaries.single.sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == target.id);
    final upgradedBoundary = upgraded.boundaries.single;
    final upgradedFinance = upgradedBoundary.sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == target.id);

    expect(
      upgradedFinance.matchdayRevenue,
      greaterThan(neutralFinance.matchdayRevenue),
    );
    expect(
      upgradedFinance.sponsorRevenue,
      upgradedBoundary.sponsor.revenueByClub[target.id],
    );
    expect(upgraded.checkpoint.facilities.stadiumFor(target.id).level, 5);
  });

  test('M47 training ground changes real player development', () {
    final world = const FictionalWorldFactory().build();
    final neutral = combinedNeutral.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final neutralPlayers = neutral.checkpoint.runtime.domain.presidentRuntime
        .runtime.runtime.world.nextSeasonPlayers;
    final candidate = neutralPlayers.firstWhere(
      (player) =>
          !player.isFreeAgent &&
          player.age <= 22 &&
          player.potential > player.ability,
    );
    final upgraded = combinedNeutral.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
      trainingGroundFacilities: world.clubs.map(
        (club) => TrainingGroundFacilityState(
          clubId: club.id,
          level: club.id == candidate.clubId ? 5 : 0,
        ),
      ),
    );
    final upgradedPlayer = upgraded.checkpoint.runtime.domain.presidentRuntime
        .runtime.runtime.world.nextSeasonPlayers
        .firstWhere((player) => player.id == candidate.id);

    expect(upgradedPlayer.ability, greaterThan(candidate.ability));
    expect(
      upgraded.checkpoint.facilities.trainingGroundFor(candidate.clubId).level,
      5,
    );
  });

  test('M47 crisis applies after facility and sponsor economy without new debt', () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.first;
    const runtime = FacilitySponsorCrisisRuntimeCareerEngine(
      crisisIntegration: forcedCrisis,
    );
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      stadiumFacilities: world.clubs.map(
        (club) => StadiumFacilityState(
          clubId: club.id,
          level: club.id == target.id ? 3 : 0,
        ),
      ),
    );
    final boundary = result.boundaries.single;
    final preFinance = {
      for (final state in boundary.sponsor.checkpoint.domain.presidentRuntime
          .runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final postFinance = {
      for (final state in boundary.checkpoint.runtime.domain.presidentRuntime
          .runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final worldSeason = boundary.sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single;

    expect(boundary.crisisCount, 48);
    expect(
      boundary.checkpoint.runtime.sponsor.signature,
      boundary.sponsor.checkpoint.sponsor.signature,
    );
    for (final finance in worldSeason.finances) {
      expect(finance.sponsorRevenue, boundary.sponsor.revenueByClub[finance.clubId]);
    }
    for (final snapshot in boundary.crisis.clubs) {
      final resolution = snapshot.resolution!;
      expect(preFinance[snapshot.clubId]!.debt, postFinance[snapshot.clubId]!.debt);
      expect(postFinance[snapshot.clubId]!.signature, resolution.finance.signature);
    }
  });

  test('M47 non-zero facilities survive save load and 2 plus 2 parity', () {
    final world = const FictionalWorldFactory().build();
    final target = world.clubs.first.id;
    final academies = world.clubs
        .map(
          (club) => AcademyFacilityState(
            clubId: club.id,
            level: club.id == target ? 2 : 0,
          ),
        )
        .toList();
    final stadiums = world.clubs
        .map(
          (club) => StadiumFacilityState(
            clubId: club.id,
            level: club.id == target ? 2 : 0,
          ),
        )
        .toList();
    final training = world.clubs
        .map(
          (club) => TrainingGroundFacilityState(
            clubId: club.id,
            level: club.id == target ? 2 : 0,
          ),
        )
        .toList();
    const runtime = FacilitySponsorCrisisRuntimeCareerEngine();
    final direct = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
      academyFacilities: academies,
      stadiumFacilities: stadiums,
      trainingGroundFacilities: training,
      totalInvestmentSpent: Money.fromUnits(12300000),
    );
    final first = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
      academyFacilities: academies,
      stadiumFacilities: stadiums,
      trainingGroundFacilities: training,
      totalInvestmentSpent: Money.fromUnits(12300000),
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final resumed = runtime.resume(checkpoint: loaded, seasonCount: 2);

    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(loaded.facilities.academyFor(target).level, 2);
    expect(loaded.facilities.stadiumFor(target).level, 2);
    expect(loaded.facilities.trainingGroundFor(target).level, 2);
    expect(loaded.facilities.totalInvestmentSpent, Money.fromUnits(12300000));
  });
}
