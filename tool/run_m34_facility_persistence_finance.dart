import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/facility_investment_orchestrator.dart';
import 'package:futbol_baskanlik_m0/src/save/facility_runtime_career_engine.dart';
import 'package:futbol_baskanlik_m0/src/save/facility_runtime_checkpoint.dart';
import 'package:futbol_baskanlik_m0/src/save/facility_runtime_save_codec.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const investment = FacilityInvestmentOrchestrator();
  const codec = FacilityRuntimeSaveCodec();
  const career = FacilityRuntimeCareerEngine();

  final first = FacilityRuntimeCheckpoint.initial(
    worldEngine
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: 8,
        )
        .checkpoint,
  );
  final richest = first.world.nextSeasonFinanceStates.reduce(
    (a, b) => a.cash >= b.cash ? a : b,
  );
  final invested = investment.upgradeTowardTarget(
    checkpoint: first,
    clubId: richest.clubId,
    targetLevel: 2,
  );
  final cashAfterInvestment = invested.world.nextSeasonFinanceStates
      .firstWhere((state) => state.clubId == richest.clubId)
      .cash;
  final encoded = codec.encode(invested);
  final loaded = codec.decode(encoded);
  final resumed = career.resume(checkpoint: loaded, seasonCount: 12);
  final direct = career.resume(checkpoint: invested, seasonCount: 12);
  final envelope = jsonDecode(encoded) as Map<String, dynamic>;

  final continuationMatch = resumed.signature == direct.signature;
  final spent = invested.totalInvestmentSpent;
  final cashDelta = richest.cash - cashAfterInvestment;

  print('M34 Facility Persistence / Finance Orchestration I');
  print('Seed: $seed');
  print('Investment season checkpoint: 8');
  print('Investment club: ${richest.clubId}');
  print('Academy level: ${invested.facilityFor(richest.clubId).level}');
  print('Investment spend: ${spent.millions.toStringAsFixed(2)}M');
  print('Immediate cash delta: ${cashDelta.millions.toStringAsFixed(2)}M');
  print('Save version: ${envelope['saveVersion']}');
  print('Save bytes: ${utf8.encode(encoded).length}');
  print('Loaded academy records: ${loaded.academyFacilities.length}');
  print('Completed seasons after resume: ${resumed.completedSeasons}');
  print('Facility state preserved: ${resumed.facilityFor(richest.clubId).level == 2}');
  print('Direct vs save-load resume: $continuationMatch');
  print('Finance-funded facility persistence: ${continuationMatch ? 'PASS' : 'FAIL'}');

  if (invested.facilityFor(richest.clubId).level != 2 ||
      spent != Money.fromUnits(9000000) ||
      cashDelta != spent ||
      loaded.academyFacilities.length != 48 ||
      resumed.completedSeasons != 20 ||
      resumed.facilityFor(richest.clubId).level != 2 ||
      !continuationMatch) {
    throw StateError('M34 facility persistence validation failed.');
  }
}
