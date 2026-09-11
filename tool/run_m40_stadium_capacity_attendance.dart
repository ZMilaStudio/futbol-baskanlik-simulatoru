import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/stadium_facility.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  const policy = StadiumInvestmentPolicy();
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const career = FacilityRuntimeCareerEngine();
  const codec = FacilityRuntimeSaveCodec();

  final neutral = FacilityRuntimeCheckpoint.initial(
    worldEngine
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: 8,
        )
        .checkpoint,
  );
  const clubId = 't1_01';
  final upgraded = _withStadiumLevel(neutral, clubId, 1);

  final baselineRun = career.resumeWithReport(
    checkpoint: neutral,
    seasonCount: 1,
  );
  final upgradedRun = career.resumeWithReport(
    checkpoint: upgraded,
    seasonCount: 1,
  );
  final baselineFinance = baselineRun.report.seasons.single.finances
      .firstWhere((finance) => finance.clubId == clubId);
  final upgradedFinance = upgradedRun.report.seasons.single.finances
      .firstWhere((finance) => finance.clubId == clubId);

  final weak = policy.attendanceProfile(
    level: 5,
    clubStrength: 55,
    leaguePosition: 16,
  );
  final strong = policy.attendanceProfile(
    level: 1,
    clubStrength: 82,
    leaguePosition: 1,
  );
  final levelThree = _withStadiumLevel(neutral, clubId, 3);
  final direct = career.resume(checkpoint: levelThree, seasonCount: 3);
  final loaded = codec.decode(codec.encode(levelThree));
  final resumed = career.resume(checkpoint: loaded, seasonCount: 3);

  final capacityMonotonic = _capacityMonotonic(policy);
  final levelZeroLegacy = policy
          .attendanceProfile(
            level: 0,
            clubStrength: 82,
            leaguePosition: 1,
          )
          .revenueMultiplierBps ==
      10000;
  final weakUnderused = weak.attendance < weak.capacity &&
      weak.revenueMultiplierBps < policy.matchdayRevenueMultiplierBps(5);
  final strongAtCeiling = strong.attendance == strong.capacity &&
      strong.revenueMultiplierBps == policy.matchdayRevenueMultiplierBps(1);
  final realRevenueRaised =
      upgradedFinance.matchdayRevenue > baselineFinance.matchdayRevenue;
  final continuationMatch = direct.signature == resumed.signature &&
      loaded.signature == levelThree.signature;

  print('M40 Stadium Capacity & Attendance Core I');
  print('Seed: $seed');
  print('Target club: $clubId');
  print('Capacity levels: ${[
    for (var level = 0; level <= StadiumInvestmentPolicy.maxLevel; level++)
      policy.capacityForLevel(level),
  ].join(', ')}');
  print('Capacity monotonic: $capacityMonotonic');
  print('Level zero legacy: $levelZeroLegacy');
  print(
    'Weak demand: attendance=${weak.attendance}/${weak.capacity} '
    'occupancyBps=${weak.occupancyBps} revenueBps=${weak.revenueMultiplierBps}',
  );
  print('Weak underused: $weakUnderused');
  print(
    'Strong demand: attendance=${strong.attendance}/${strong.capacity} '
    'occupancyBps=${strong.occupancyBps} revenueBps=${strong.revenueMultiplierBps}',
  );
  print('Strong at legacy ceiling: $strongAtCeiling');
  print(
    'Matchday revenue: '
    '${baselineFinance.matchdayRevenue.millions.toStringAsFixed(2)}M -> '
    '${upgradedFinance.matchdayRevenue.millions.toStringAsFixed(2)}M',
  );
  print('Real matchday revenue raised: $realRevenueRaised');
  print('Save/load continuation match: $continuationMatch');

  final pass = capacityMonotonic &&
      levelZeroLegacy &&
      weakUnderused &&
      strongAtCeiling &&
      realRevenueRaised &&
      continuationMatch;
  print('Stadium capacity and attendance integration: ${pass ? 'PASS' : 'FAIL'}');

  if (!pass) {
    throw StateError('M40 stadium capacity and attendance validation failed.');
  }
}

FacilityRuntimeCheckpoint _withStadiumLevel(
  FacilityRuntimeCheckpoint checkpoint,
  String clubId,
  int level,
) =>
    FacilityRuntimeCheckpoint(
      world: checkpoint.world,
      academyFacilities: checkpoint.academyFacilities,
      stadiumFacilities: checkpoint.stadiumFacilities
          .map(
            (state) => state.clubId == clubId
                ? state.copyWith(level: level)
                : state,
          )
          .toList(growable: false),
      trainingGroundFacilities: checkpoint.trainingGroundFacilities,
      totalInvestmentSpent: checkpoint.totalInvestmentSpent,
    );

bool _capacityMonotonic(StadiumInvestmentPolicy policy) {
  var previous = policy.capacityForLevel(0);
  for (var level = 1; level <= StadiumInvestmentPolicy.maxLevel; level++) {
    final current = policy.capacityForLevel(level);
    if (current <= previous) {
      return false;
    }
    previous = current;
  }
  return true;
}
