import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/facility_sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const codec = FacilitySponsorCrisisRuntimeSaveCodec();
  const runtimeCodec = SponsorPresidentRuntimeSaveCodec();
  const runtime = FacilitySponsorCrisisRuntimeCareerEngine();
  final target = world.clubs.reduce(
    (a, b) => a.strength >= b.strength ? a : b,
  );
  final academies = world.clubs
      .map(
        (club) => AcademyFacilityState(
          clubId: club.id,
          level: club.id == target.id ? 2 : 0,
        ),
      )
      .toList();
  final stadiums = world.clubs
      .map(
        (club) => StadiumFacilityState(
          clubId: club.id,
          level: club.id == target.id ? 2 : 0,
        ),
      )
      .toList();
  final training = world.clubs
      .map(
        (club) => TrainingGroundFacilityState(
          clubId: club.id,
          level: club.id == target.id ? 2 : 0,
        ),
      )
      .toList();

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
  final splitBoundaries = [...first.boundaries, ...resumed.boundaries];

  final saveResumeMatch =
      codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch = _listEquals(
    splitBoundaries.map((item) => item.signature).toList(),
    direct.boundaries.map((item) => item.signature).toList(),
  );
  final facilitySignature = direct.checkpoint.facilities.signature;
  final facilitiesPreserved = direct.boundaries.every(
    (item) => item.checkpoint.facilities.signature == facilitySignature,
  );
  final contractsComplete = direct.boundaries.every(
    (item) => item.sponsor.contracts.length == world.clubs.length,
  );
  final sponsorStatePreserved = direct.boundaries.every(
    (item) =>
        item.checkpoint.runtime.sponsor.signature ==
        item.sponsor.checkpoint.sponsor.signature,
  );
  final debtPreserved = direct.boundaries.every(
    (boundary) => boundary.crisis.clubs.every(
      (item) =>
          item.resolution == null ||
          item.resolution!.finance.debt == item.context.finance.debt,
    ),
  );
  final financeReplacementMatch = direct.boundaries.every((boundary) {
    final season = boundary.sponsor.report.sourceReport.advancedTransferReport
        .worldReport.seasons.single;
    return season.finances.every(
      (finance) =>
          finance.sponsorRevenue ==
          boundary.sponsor.revenueByClub[finance.clubId],
    );
  });

  const neutralCrisis = CrisisRuntimeIntegrationEngine(
    decisionEngine: CrisisDecisionEngine(activationThreshold: 101),
  );
  const neutralM47 = FacilitySponsorCrisisRuntimeCareerEngine(
    crisisIntegration: neutralCrisis,
  );
  const neutralM46 = SponsorCrisisRuntimeCareerEngine(
    crisisIntegration: neutralCrisis,
  );
  final neutral = neutralM47.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
  );
  final legacy = neutralM46.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
  );
  final neutralM46Parity = neutral.crisisCount == 0 &&
      runtimeCodec.encode(neutral.checkpoint.runtime) ==
          runtimeCodec.encode(legacy.checkpoint) &&
      _listEquals(
        neutral.boundaries.map((item) => item.sponsor.signature).toList(),
        legacy.boundaries.map((item) => item.sponsor.signature).toList(),
      );

  final neutralFinance = neutral.boundaries.first.sponsor.report.sourceReport
      .advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == target.id);
  final facilityFinance = direct.boundaries.first.sponsor.report.sourceReport
      .advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == target.id);
  final stadiumEffect =
      facilityFinance.matchdayRevenue > neutralFinance.matchdayRevenue;

  const forcedRuntime = FacilitySponsorCrisisRuntimeCareerEngine(
    crisisIntegration: CrisisRuntimeIntegrationEngine(
      decisionEngine: CrisisDecisionEngine(activationThreshold: 0),
    ),
  );
  final forced = forcedRuntime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 1,
  );
  final forcedWiring = forced.crisisCount == world.clubs.length;

  final saveBytes = codec.encode(direct.checkpoint).length;
  print('M47_FACILITY_SPONSOR_CRISIS seasons=${direct.boundaries.length}');
  print('M47_FACILITY_SPONSOR_CRISIS target=${target.id}');
  print(
    'M47_FACILITY_SPONSOR_CRISIS levels='
    '${direct.checkpoint.facilities.academyFor(target.id).level}/'
    '${direct.checkpoint.facilities.stadiumFor(target.id).level}/'
    '${direct.checkpoint.facilities.trainingGroundFor(target.id).level}',
  );
  print(
    'M47_FACILITY_SPONSOR_CRISIS matchday='
    '${neutralFinance.matchdayRevenue.units.toStringAsFixed(2)}>'
    '${facilityFinance.matchdayRevenue.units.toStringAsFixed(2)}',
  );
  print(
    'M47_FACILITY_SPONSOR_CRISIS crises=${direct.crisisCount}/'
    '${direct.boundaries.length * world.clubs.length}',
  );
  print('M47_FACILITY_SPONSOR_CRISIS forcedWiring=$forcedWiring');
  print('M47_FACILITY_SPONSOR_CRISIS debtPreserved=$debtPreserved');
  print('M47_FACILITY_SPONSOR_CRISIS sponsorStatePreserved=$sponsorStatePreserved');
  print('M47_FACILITY_SPONSOR_CRISIS financeReplacementMatch=$financeReplacementMatch');
  print('M47_FACILITY_SPONSOR_CRISIS facilitiesPreserved=$facilitiesPreserved');
  print('M47_FACILITY_SPONSOR_CRISIS stadiumEffect=$stadiumEffect');
  print('M47_FACILITY_SPONSOR_CRISIS neutralM46Parity=$neutralM46Parity');
  print('M47_FACILITY_SPONSOR_CRISIS saveResumeMatch=$saveResumeMatch');
  print('M47_FACILITY_SPONSOR_CRISIS boundaryMatch=$boundaryMatch');
  print('M47_FACILITY_SPONSOR_CRISIS saveBytes=$saveBytes');

  if (!contractsComplete ||
      !forcedWiring ||
      !debtPreserved ||
      !sponsorStatePreserved ||
      !financeReplacementMatch ||
      !facilitiesPreserved ||
      !stadiumEffect ||
      !neutralM46Parity ||
      !saveResumeMatch ||
      !boundaryMatch) {
    throw StateError('M47 facility + sponsor + crisis canonical gate failed.');
  }

  print('M47_FACILITY_SPONSOR_CRISIS PASS');
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
