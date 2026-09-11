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
  final implicitNeutral = policy.attendanceProfile(
    level: 3,
    clubStrength: 70,
    leaguePosition: 5,
  );
  final high = policy.attendanceProfile(
    level: 3,
    clubStrength: 70,
    leaguePosition: 5,
    fanTrust: 90,
  );

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
  const clubId = 't1_01';
  final checkpoint = _withStadiumLevel(season8, clubId, 3);
  final lowFan = FanState.initial(clubId, trust: 20);
  final neutralFan = FanState.initial(
    clubId,
    trust: StadiumInvestmentPolicy.neutralFanTrust,
  );
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

  final implicitNeutralRuntime = career.resume(
    checkpoint: checkpoint,
    seasonCount: 1,
  );
  final explicitNeutralRuntime = career.resume(
    checkpoint: checkpoint,
    seasonCount: 1,
    fanStatesByClub: <String, FanState>{clubId: neutralFan},
  );
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

  final neutralLegacyMatch = neutral.demand == implicitNeutral.demand &&
      neutral.attendance == implicitNeutral.attendance &&
      neutral.revenueMultiplierBps == implicitNeutral.revenueMultiplierBps &&
      implicitNeutralRuntime.signature == explicitNeutralRuntime.signature;
  final trustDemandOrdered =
      low.demand < neutral.demand && neutral.demand < high.demand;
  final realRevenueOrdered =
      highFinance.matchdayRevenue > lowFinance.matchdayRevenue;
  final saveContinuationMatch = loaded.signature == checkpoint.signature &&
      resumed.signature == direct.signature;

  print('M41 Attendance Demand & Fan Trust Integration II');
  print('Seed: $seed');
  print('Target club: $clubId');
  print(
    'Trust demand: low=${low.demand} neutral=${neutral.demand} high=${high.demand}',
  );
  print(
    'Trust multipliers: '
    '${policy.fanTrustDemandMultiplierBps(20)}, '
    '${policy.fanTrustDemandMultiplierBps(60)}, '
    '${policy.fanTrustDemandMultiplierBps(90)} bps',
  );
  print('Neutral M40 parity: $neutralLegacyMatch');
  print('Trust demand ordered: $trustDemandOrdered');
  print(
    'Real matchday revenue low -> high: '
    '${lowFinance.matchdayRevenue.millions.toStringAsFixed(2)}M -> '
    '${highFinance.matchdayRevenue.millions.toStringAsFixed(2)}M',
  );
  print('Real fan revenue effect: $realRevenueOrdered');
  print('Save/load continuation match: $saveContinuationMatch');

  final pass = neutralLegacyMatch &&
      trustDemandOrdered &&
      realRevenueOrdered &&
      saveContinuationMatch;
  print('Fan trust attendance integration: ${pass ? 'PASS' : 'FAIL'}');

  if (!pass) {
    throw StateError('M41 fan trust attendance validation failed.');
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
