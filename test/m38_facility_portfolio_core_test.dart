import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/facility_portfolio_investment_orchestrator.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const facilityCareer = FacilityRuntimeCareerEngine();
  const portfolio = FacilityPortfolioInvestmentOrchestrator();
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

  test('M38 initializes complete neutral stadium and training portfolios', () {
    final checkpoint = season8();

    expect(checkpoint.academyFacilities, hasLength(48));
    expect(checkpoint.stadiumFacilities, hasLength(48));
    expect(checkpoint.trainingGroundFacilities, hasLength(48));
    expect(checkpoint.stadiumFacilities.every((state) => state.level == 0), isTrue);
    expect(
      checkpoint.trainingGroundFacilities.every((state) => state.level == 0),
      isTrue,
    );
  });

  test('M38 stadium upgrade uses real cash and raises matchday revenue', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final result = portfolio.upgradeStadium(
      checkpoint: before,
      clubId: richest.clubId,
    );
    final invested = result.checkpoint;
    final financeAfterInvestment = invested.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == richest.clubId);

    expect(result.applied, isTrue);
    expect(invested.stadiumFor(richest.clubId).level, 1);
    expect(result.cost, Money.fromUnits(5000000));
    expect(richest.cash - financeAfterInvestment.cash, result.cost);
    expect(financeAfterInvestment.debt, richest.debt);

    final neutral = FacilityRuntimeCheckpoint(
      world: invested.world,
      academyFacilities: invested.academyFacilities,
      stadiumFacilities: before.stadiumFacilities,
      trainingGroundFacilities: invested.trainingGroundFacilities,
      totalInvestmentSpent: invested.totalInvestmentSpent,
    );
    final baseline = facilityCareer.resumeWithReport(
      checkpoint: neutral,
      seasonCount: 1,
    );
    final upgraded = facilityCareer.resumeWithReport(
      checkpoint: invested,
      seasonCount: 1,
    );
    final baselineFinance = baseline.report.seasons.single.finances
        .firstWhere((state) => state.clubId == richest.clubId);
    final upgradedFinance = upgraded.report.seasons.single.finances
        .firstWhere((state) => state.clubId == richest.clubId);

    expect(
      upgradedFinance.matchdayRevenue,
      greaterThan(baselineFinance.matchdayRevenue),
    );
  });

  test('M38 training ground improves real positive player development', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final result = portfolio.upgradeTrainingGround(
      checkpoint: before,
      clubId: richest.clubId,
    );
    final invested = result.checkpoint;
    final candidate = invested.world.nextSeasonPlayers.firstWhere(
      (player) =>
          player.clubId == richest.clubId &&
          player.age <= 22 &&
          player.potential > player.ability,
    );

    expect(result.applied, isTrue);
    expect(invested.trainingGroundFor(richest.clubId).level, 1);
    expect(result.cost, Money.fromUnits(4000000));

    final neutral = FacilityRuntimeCheckpoint(
      world: invested.world,
      academyFacilities: invested.academyFacilities,
      stadiumFacilities: invested.stadiumFacilities,
      trainingGroundFacilities: before.trainingGroundFacilities,
      totalInvestmentSpent: invested.totalInvestmentSpent,
    );
    final baseline = facilityCareer.resume(checkpoint: neutral, seasonCount: 1);
    final upgraded = facilityCareer.resume(checkpoint: invested, seasonCount: 1);
    final baselinePlayer = baseline.world.nextSeasonPlayers
        .firstWhere((player) => player.id == candidate.id);
    final upgradedPlayer = upgraded.world.nextSeasonPlayers
        .firstWhere((player) => player.id == candidate.id);

    expect(upgradedPlayer.ability, greaterThan(baselinePlayer.ability));
  });

  test('M38 full portfolio survives save load resume deterministically', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final stadium = portfolio.upgradeStadium(
      checkpoint: before,
      clubId: richest.clubId,
    );
    final training = portfolio.upgradeTrainingGround(
      checkpoint: stadium.checkpoint,
      clubId: richest.clubId,
    );
    final invested = training.checkpoint;

    expect(stadium.applied, isTrue);
    expect(training.applied, isTrue);
    expect(invested.totalInvestmentSpent, Money.fromUnits(9000000));
    expect(invested.stadiumFor(richest.clubId).level, 1);
    expect(invested.trainingGroundFor(richest.clubId).level, 1);

    final direct = facilityCareer.resume(checkpoint: invested, seasonCount: 4);
    final loaded = codec.decode(codec.encode(invested));
    final resumed = facilityCareer.resume(checkpoint: loaded, seasonCount: 4);

    expect(loaded.signature, invested.signature);
    expect(resumed.signature, direct.signature);
    expect(resumed.stadiumFor(richest.clubId).level, 1);
    expect(resumed.trainingGroundFor(richest.clubId).level, 1);
  });

  test('M38 migrates v1 facility save to v2 with neutral new facilities', () {
    final source = season8();
    final current = jsonDecode(codec.encode(source)) as Map<String, dynamic>;
    final currentPayload = current['payload'] as Map<String, dynamic>;
    final v1Payload = <String, Object?>{
      'worldSave': currentPayload['worldSave'],
      'academyFacilities': currentPayload['academyFacilities'],
      'totalInvestmentSpentMinorUnits':
          currentPayload['totalInvestmentSpentMinorUnits'],
    };
    final v1 = SaveChecksum.canonicalJson({
      'format': FacilityRuntimeSaveCodec.format,
      'saveVersion': 1,
      'payload': v1Payload,
      'checksum': SaveChecksum.forPayload(saveVersion: 1, payload: v1Payload),
    });

    final migrated = codec.decode(v1);
    expect(migrated.signature, source.signature);
    expect(migrated.stadiumFacilities.every((state) => state.level == 0), isTrue);
    expect(
      migrated.trainingGroundFacilities.every((state) => state.level == 0),
      isTrue,
    );
    final reencoded = jsonDecode(codec.encode(migrated)) as Map<String, dynamic>;
    expect(reencoded['saveVersion'], 2);
  });
}
