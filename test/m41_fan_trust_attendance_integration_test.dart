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

  test('M41 neutral fan trust preserves M40 demand and attendance exactly', () {
    final legacyDemand = policy.demandSeats(
      clubStrength: 70,
      leaguePosition: 5,
    );
    final explicitNeutralDemand = policy.demandSeats(
      clubStrength: 70,
      leaguePosition: 5,
      fanTrust: StadiumInvestmentPolicy.neutralFanTrust,
    );
    final legacyProfile = policy.attendanceProfile(
      level: 3,
      clubStrength: 70,
      leaguePosition: 5,
    );
    final explicitNeutralProfile = policy.attendanceProfile(
      level: 3,
      clubStrength: 70,
      leaguePosition: 5,
      fanTrust: StadiumInvestmentPolicy.neutralFanTrust,
    );

    expect(explicitNeutralDemand, legacyDemand);
    expect(explicitNeutralProfile.demand, legacyProfile.demand);
    expect(explicitNeutralProfile.attendance, legacyProfile.attendance);
    expect(
      explicitNeutralProfile.revenueMultiplierBps,
      legacyProfile.revenueMultiplierBps,
    );
  });

  test('M41 fan trust demand multiplier is bounded and monotonic', () {
    expect(policy.fanTrustDemandMultiplierBps(0), 7000);
    expect(policy.fanTrustDemandMultiplierBps(60), 10000);
    expect(policy.fanTrustDemandMultiplierBps(100), 12000);
    expect(
      () => policy.fanTrustDemandMultiplierBps(-1),
      throwsArgumentError,
    );
    expect(
      () => policy.fanTrustDemandMultiplierBps(101),
      throwsArgumentError,
    );
  });

  test('M41 low neutral and high trust create ordered stadium demand', () {
    final low = policy.attendanceProfile(
      level: 3,
      clubStrength: 70,
      leaguePosition: 5,
      fanTrust: 20,
    );
    final neutral = policy.attendanceProfile(
      level: 3,
      clubStrength: 70,
      leaguePosition: 5,
      fanTrust: 60,
    );
    final high = policy.attendanceProfile(
      level: 3,
      clubStrength: 70,
      leaguePosition: 5,
      fanTrust: 90,
    );

    expect(low.demand, lessThan(neutral.demand));
    expect(neutral.demand, lessThan(high.demand));
    expect(low.attendance, lessThan(neutral.attendance));
    expect(neutral.attendance, lessThanOrEqualTo(high.attendance));
  });

  test('M41 real FanState changes real facility matchday revenue', () {
    const clubId = 't1_01';
    final checkpoint = withStadiumLevel(season8(), clubId, 3);
    final lowFan = FanState.initial(clubId, trust: 20);
    final highFan = FanState.initial(clubId, trust: 90);

    final lowRun = career.resumeWithReport(
      checkpoint: checkpoint,
      seasonCount: 1,
      fanStatesByClub: <String, FanState>{clubId: lowFan},
    );
    final highRun = career.resumeWithReport(
      checkpoint: checkpoint,
      seasonCount: 1,
      fanStatesByClub: <String, FanState>{clubId: highFan},
    );
    final lowFinance = lowRun.report.seasons.single.finances
        .firstWhere((finance) => finance.clubId == clubId);
    final highFinance = highRun.report.seasons.single.finances
        .firstWhere((finance) => finance.clubId == clubId);

    expect(lowFan.overallTrust, 20);
    expect(highFan.overallTrust, 90);
    expect(highFinance.matchdayRevenue, greaterThan(lowFinance.matchdayRevenue));
  });

  test('M41 fan-aware continuation remains save deterministic and neutral-safe', () {
    const clubId = 't1_01';
    final checkpoint = withStadiumLevel(season8(), clubId, 3);
    final neutralFan = FanState.initial(
      clubId,
      trust: StadiumInvestmentPolicy.neutralFanTrust,
    );
    final highFan = FanState.initial(clubId, trust: 90);

    final implicitNeutral = career.resume(
      checkpoint: checkpoint,
      seasonCount: 1,
    );
    final explicitNeutral = career.resume(
      checkpoint: checkpoint,
      seasonCount: 1,
      fanStatesByClub: <String, FanState>{clubId: neutralFan},
    );
    expect(explicitNeutral.signature, implicitNeutral.signature);

    final direct = career.resume(
      checkpoint: checkpoint,
      seasonCount: 3,
      fanStatesByClub: <String, FanState>{clubId: highFan},
    );
    final loaded = codec.decode(codec.encode(checkpoint));
    final resumed = career.resume(
      checkpoint: loaded,
      seasonCount: 3,
      fanStatesByClub: <String, FanState>{clubId: highFan},
    );

    expect(loaded.signature, checkpoint.signature);
    expect(resumed.signature, direct.signature);
  });
}
