import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const investment = FacilityInvestmentOrchestrator();
  const codec = FacilityRuntimeSaveCodec();
  const career = FacilityRuntimeCareerEngine();

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

  test('M34 academy upgrade charges real club cash and persists', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final upgraded = investment.upgradeTowardTarget(
      checkpoint: before,
      clubId: richest.clubId,
      targetLevel: 2,
    );
    final afterFinance = upgraded.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == richest.clubId);

    expect(upgraded.facilityFor(richest.clubId).level, 2);
    expect(upgraded.totalInvestmentSpent, Money.fromUnits(9000000));
    expect(richest.cash - afterFinance.cash, Money.fromUnits(9000000));
    expect(afterFinance.debt, richest.debt);

    final loaded = codec.decode(codec.encode(upgraded));
    expect(loaded.signature, upgraded.signature);
    expect(loaded.facilityFor(richest.clubId).level, 2);
  });

  test('M34 save load resume matches direct invested continuation', () {
    final before = season8();
    final richest = before.world.nextSeasonFinanceStates.reduce(
      (a, b) => a.cash >= b.cash ? a : b,
    );
    final invested = investment.upgradeTowardTarget(
      checkpoint: before,
      clubId: richest.clubId,
      targetLevel: 2,
    );
    final direct = career.resume(checkpoint: invested, seasonCount: 12);
    final loaded = codec.decode(codec.encode(invested));
    final resumed = career.resume(checkpoint: loaded, seasonCount: 12);

    expect(resumed.signature, direct.signature);
    expect(resumed.completedSeasons, 20);
    expect(resumed.facilityFor(richest.clubId).level, 2);
    expect(resumed.totalInvestmentSpent, Money.fromUnits(9000000));

    final baseline = worldEngine.resume(
      checkpoint: before.world,
      seasonCount: 12,
    );
    final baselineFinance = baseline.checkpoint.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == richest.clubId);
    final investedFinance = resumed.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == richest.clubId);
    expect(investedFinance.signature, isNot(baselineFinance.signature));
  });

  test('M34 refuses unaffordable upgrade without mutating state', () {
    final before = season8();
    final clubId = before.world.baseClubs.first.id;
    final finances = before.world.nextSeasonFinanceStates
        .map((state) => state.clubId == clubId
            ? ClubFinanceState(clubId: clubId, cash: Money.zero, debt: state.debt)
            : state)
        .toList(growable: false);
    final poorWorld = WorldCheckpoint(
      config: before.world.config,
      completedSeasons: before.world.completedSeasons,
      baseClubs: before.world.baseClubs,
      nextSeasonLeagues: before.world.nextSeasonLeagues,
      nextSeasonPlayers: before.world.nextSeasonPlayers,
      nextSeasonFinanceStates: finances,
    );
    final poor = FacilityRuntimeCheckpoint(
      world: poorWorld,
      academyFacilities: before.academyFacilities,
      totalInvestmentSpent: before.totalInvestmentSpent,
    );
    final result = investment.upgradeAcademy(checkpoint: poor, clubId: clubId);

    expect(result.applied, isFalse);
    expect(result.checkpoint.signature, poor.signature);
    expect(result.checkpoint.facilityFor(clubId).level, 0);
  });

  test('M34 rejects checksum corruption and future versions', () {
    final encoded = codec.encode(season8());
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    decoded['checksum'] = '00000000';
    expect(
      () => codec.decode(jsonEncode(decoded)),
      throwsA(isA<SaveLoadException>().having(
        (error) => error.failure,
        'failure',
        SaveLoadFailure.checksumMismatch,
      )),
    );

    final original = jsonDecode(encoded) as Map<String, dynamic>;
    original['saveVersion'] = FacilityRuntimeSaveCodec.currentSaveVersion + 1;
    original['checksum'] = SaveChecksum.forPayload(
      saveVersion: original['saveVersion'] as int,
      payload: original['payload'],
    );
    expect(
      () => codec.decode(SaveChecksum.canonicalJson(original)),
      throwsA(isA<SaveLoadException>().having(
        (error) => error.failure,
        'failure',
        SaveLoadFailure.unsupportedVersion,
      )),
    );
  });
}
