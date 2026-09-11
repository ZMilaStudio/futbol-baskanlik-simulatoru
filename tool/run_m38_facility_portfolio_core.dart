import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/facility_portfolio_investment_orchestrator.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const career = FacilityRuntimeCareerEngine();
  const portfolio = FacilityPortfolioInvestmentOrchestrator();
  const codec = FacilityRuntimeSaveCodec();

  final before = FacilityRuntimeCheckpoint.initial(
    worldEngine
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: 8,
        )
        .checkpoint,
  );
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
  final financeAfterInvestment = invested.world.nextSeasonFinanceStates
      .firstWhere((state) => state.clubId == richest.clubId);
  final cashDelta = richest.cash - financeAfterInvestment.cash;

  final stadiumNeutral = FacilityRuntimeCheckpoint(
    world: invested.world,
    academyFacilities: invested.academyFacilities,
    stadiumFacilities: before.stadiumFacilities,
    trainingGroundFacilities: invested.trainingGroundFacilities,
    totalInvestmentSpent: invested.totalInvestmentSpent,
  );
  final stadiumBaseline = career.resumeWithReport(
    checkpoint: stadiumNeutral,
    seasonCount: 1,
  );
  final stadiumUpgraded = career.resumeWithReport(
    checkpoint: invested,
    seasonCount: 1,
  );
  final baselineMatchday = stadiumBaseline.report.seasons.single.finances
      .firstWhere((state) => state.clubId == richest.clubId)
      .matchdayRevenue;
  final upgradedMatchday = stadiumUpgraded.report.seasons.single.finances
      .firstWhere((state) => state.clubId == richest.clubId)
      .matchdayRevenue;

  final candidate = invested.world.nextSeasonPlayers.firstWhere(
    (player) =>
        player.clubId == richest.clubId &&
        player.age <= 22 &&
        player.potential > player.ability,
  );
  final trainingNeutral = FacilityRuntimeCheckpoint(
    world: invested.world,
    academyFacilities: invested.academyFacilities,
    stadiumFacilities: invested.stadiumFacilities,
    trainingGroundFacilities: before.trainingGroundFacilities,
    totalInvestmentSpent: invested.totalInvestmentSpent,
  );
  final trainingBaseline = career.resume(
    checkpoint: trainingNeutral,
    seasonCount: 1,
  );
  final trainingUpgraded = career.resume(
    checkpoint: invested,
    seasonCount: 1,
  );
  final baselinePlayer = trainingBaseline.world.nextSeasonPlayers
      .firstWhere((player) => player.id == candidate.id);
  final upgradedPlayer = trainingUpgraded.world.nextSeasonPlayers
      .firstWhere((player) => player.id == candidate.id);

  final encoded = codec.encode(invested);
  final loaded = codec.decode(encoded);
  final direct = career.resume(checkpoint: invested, seasonCount: 4);
  final resumed = career.resume(checkpoint: loaded, seasonCount: 4);
  final continuationMatch = direct.signature == resumed.signature;

  final neutralCurrent = jsonDecode(codec.encode(before)) as Map<String, dynamic>;
  final neutralPayload = neutralCurrent['payload'] as Map<String, dynamic>;
  final v1Payload = <String, Object?>{
    'worldSave': neutralPayload['worldSave'],
    'academyFacilities': neutralPayload['academyFacilities'],
    'totalInvestmentSpentMinorUnits':
        neutralPayload['totalInvestmentSpentMinorUnits'],
  };
  final v1Save = SaveChecksum.canonicalJson({
    'format': FacilityRuntimeSaveCodec.format,
    'saveVersion': 1,
    'payload': v1Payload,
    'checksum': SaveChecksum.forPayload(saveVersion: 1, payload: v1Payload),
  });
  final migrated = codec.decode(v1Save);
  final migrationNeutral =
      migrated.stadiumFacilities.every((state) => state.level == 0) &&
      migrated.trainingGroundFacilities.every((state) => state.level == 0);

  final envelope = jsonDecode(encoded) as Map<String, dynamic>;
  final stadiumRevenueRaised = upgradedMatchday > baselineMatchday;
  final trainingDevelopmentRaised = upgradedPlayer.ability > baselinePlayer.ability;
  final debtUnchanged = financeAfterInvestment.debt == richest.debt;
  final spendCorrect = invested.totalInvestmentSpent == Money.fromUnits(9000000);
  final cashCorrect = cashDelta == invested.totalInvestmentSpent;

  print('M38 Facility Portfolio Core I');
  print('Seed: $seed');
  print('Investment season checkpoint: 8');
  print('Investment club: ${richest.clubId}');
  print('Stadium level: ${invested.stadiumFor(richest.clubId).level}');
  print('Training ground level: ${invested.trainingGroundFor(richest.clubId).level}');
  print('Total investment spend: ${invested.totalInvestmentSpent.millions.toStringAsFixed(2)}M');
  print('Immediate cash delta: ${cashDelta.millions.toStringAsFixed(2)}M');
  print('Debt unchanged: $debtUnchanged');
  print('Matchday revenue: ${baselineMatchday.millions.toStringAsFixed(2)}M -> ${upgradedMatchday.millions.toStringAsFixed(2)}M');
  print('Stadium revenue raised: $stadiumRevenueRaised');
  print('Training player: ${candidate.id}');
  print('Player ability: ${baselinePlayer.ability.toStringAsFixed(4)} -> ${upgradedPlayer.ability.toStringAsFixed(4)}');
  print('Training development raised: $trainingDevelopmentRaised');
  print('Save version: ${envelope['saveVersion']}');
  print('Save bytes: ${utf8.encode(encoded).length}');
  print('V1 migration neutral: $migrationNeutral');
  print('Direct vs save-load resume: $continuationMatch');

  final pass = stadium.applied &&
      training.applied &&
      invested.stadiumFor(richest.clubId).level == 1 &&
      invested.trainingGroundFor(richest.clubId).level == 1 &&
      spendCorrect &&
      cashCorrect &&
      debtUnchanged &&
      stadiumRevenueRaised &&
      trainingDevelopmentRaised &&
      envelope['saveVersion'] == FacilityRuntimeSaveCodec.currentSaveVersion &&
      migrationNeutral &&
      continuationMatch;
  print('Facility portfolio persistence and runtime effects: ${pass ? 'PASS' : 'FAIL'}');

  if (!pass) {
    throw StateError('M38 facility portfolio validation failed.');
  }
}
