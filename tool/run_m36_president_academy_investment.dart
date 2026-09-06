import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/president_academy_investment_orchestrator.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const orchestrator = PresidentAcademyInvestmentOrchestrator();
  const career = FacilityRuntimeCareerEngine();
  const codec = FacilityRuntimeSaveCodec();

  final season8 = FacilityRuntimeCheckpoint.initial(
    worldEngine
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: 8,
        )
        .checkpoint,
  );
  final richest = season8.world.nextSeasonFinanceStates.reduce(
    (a, b) => a.cash >= b.cash ? a : b,
  );
  const profile = PresidentManagementProfile(
    presidentId: 'm36-canonical-president',
    archetype: PresidentManagementArchetype.youthArchitect,
    financialDiscipline: 60,
    riskAppetite: 45,
    transferAmbition: 40,
    youthOrientation: 90,
    managerPatience: 75,
  );
  final invested = orchestrator.apply(
    checkpoint: season8,
    clubId: richest.clubId,
    profile: profile,
  );
  final direct = career.resumeWithReport(
    checkpoint: invested.checkpoint,
    seasonCount: 12,
  );
  final loaded = codec.decode(codec.encode(invested.checkpoint));
  final resumed = career.resumeWithReport(
    checkpoint: loaded,
    seasonCount: 12,
  );
  final youthMatch = resumed.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .join('|') ==
      direct.report.seasons
          .expand((season) => season.youthIntakeAfterSeason)
          .map((player) => player.signature)
          .join('|');
  final checkpointMatch =
      resumed.checkpoint.signature == direct.checkpoint.signature;

  print('M36 President Youth Orientation -> Academy Investment Orchestration I');
  print('Seed: $seed');
  print('Investment checkpoint: season 8');
  print('Investment club: ${richest.clubId}');
  print('Youth orientation: ${profile.youthOrientation}');
  print('Financial discipline: ${profile.financialDiscipline}');
  print('Target academy level: ${invested.plan.targetLevel}');
  print('Window upgrade cap: ${invested.plan.maxUpgradesThisWindow}');
  print('Cash reserve: ${invested.plan.cashReserveBasisPoints} bps');
  print('Applied upgrades: ${invested.appliedUpgrades}');
  print('Academy level: ${invested.beforeLevel} -> ${invested.afterLevel}');
  print('Investment spend: ${invested.spend.millions.toStringAsFixed(2)}M');
  print('Completed seasons after resume: ${resumed.checkpoint.completedSeasons}');
  print('Youth history match: $youthMatch');
  print('Final checkpoint match: $checkpointMatch');
  print(
    'President-driven academy investment: '
    '${youthMatch && checkpointMatch ? 'PASS' : 'FAIL'}',
  );

  if (!youthMatch || !checkpointMatch || invested.appliedUpgrades != 2) {
    throw StateError('M36 canonical acceptance failed.');
  }
}
