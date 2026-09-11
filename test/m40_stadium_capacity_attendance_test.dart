import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/stadium_facility.dart';
import 'package:test/test.dart';

void main() {
  const policy = StadiumInvestmentPolicy();
  const seed = 20260903;
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const worldEngine = WorldCareerEngine();
  const career = FacilityRuntimeCareerEngine();
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

  FacilityRuntimeCheckpoint withStadiumLevel(
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

  test('M40 capacity grows by level and level zero preserves legacy revenue', () {
    final capacities = <int>[
      for (var level = 0; level <= StadiumInvestmentPolicy.maxLevel; level++)
        policy.capacityForLevel(level),
    ];

    expect(capacities, orderedEquals(<int>[18000, 20500, 23500, 27000, 31000, 36000]));
    for (var i = 1; i < capacities.length; i++) {
      expect(capacities[i], greaterThan(capacities[i - 1]));
    }

    final neutral = policy.attendanceProfile(
      level: 0,
      clubStrength: 81.5,
      leaguePosition: 1,
    );
    expect(neutral.revenueMultiplierBps, 10000);
    expect(neutral.attendance, lessThanOrEqualTo(neutral.capacity));
  });

  test('M40 demand reacts to sporting strength and league position', () {
    final weakBottom = policy.demandSeats(
      clubStrength: 55,
      leaguePosition: 16,
    );
    final weakTop = policy.demandSeats(
      clubStrength: 55,
      leaguePosition: 1,
    );
    final strongTop = policy.demandSeats(
      clubStrength: 82,
      leaguePosition: 1,
    );

    expect(weakTop, greaterThan(weakBottom));
    expect(strongTop, greaterThan(weakTop));
  });

  test('M40 unused capacity limits stadium revenue upside', () {
    final weak = policy.attendanceProfile(
      level: 5,
      clubStrength: 55,
      leaguePosition: 16,
    );
    final ceiling = policy.matchdayRevenueMultiplierBps(5);

    expect(weak.attendance, lessThan(weak.capacity));
    expect(weak.occupancyBps, lessThan(10000));
    expect(weak.revenueMultiplierBps, greaterThan(10000));
    expect(weak.revenueMultiplierBps, lessThan(ceiling));
  });

  test('M40 strong demand can realize the existing stadium revenue ceiling', () {
    final strong = policy.attendanceProfile(
      level: 1,
      clubStrength: 82,
      leaguePosition: 1,
    );

    expect(strong.attendance, strong.capacity);
    expect(strong.occupancyBps, 10000);
    expect(
      strong.revenueMultiplierBps,
      policy.matchdayRevenueMultiplierBps(1),
    );
  });

  test('M40 attendance model drives real economy and remains save deterministic', () {
    final neutral = season8();
    const clubId = 't1_01';
    final upgraded = withStadiumLevel(neutral, clubId, 1);

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

    expect(
      upgradedFinance.matchdayRevenue,
      greaterThan(baselineFinance.matchdayRevenue),
    );

    final levelThree = withStadiumLevel(neutral, clubId, 3);
    final direct = career.resume(checkpoint: levelThree, seasonCount: 3);
    final loaded = codec.decode(codec.encode(levelThree));
    final resumed = career.resume(checkpoint: loaded, seasonCount: 3);

    expect(loaded.signature, levelThree.signature);
    expect(resumed.signature, direct.signature);
  });
}
