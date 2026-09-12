import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const codec = SponsorPresidentRuntimeSaveCodec();
  const runtime = SponsorCrisisRuntimeCareerEngine();

  final direct = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 2,
  );
  final first = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
    hasFutureSeasonAfterReport: true,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final resumed = runtime.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );

  final splitBoundaries = [...first.boundaries, ...resumed.boundaries];
  final saveResumeMatch =
      codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch = _listEquals(
    splitBoundaries.map((item) => item.signature).toList(),
    direct.boundaries.map((item) => item.signature).toList(),
  );
  final contractsComplete = direct.boundaries.every(
    (item) => item.sponsor.contracts.length == world.clubs.length,
  );
  final sponsorStatePreserved = direct.boundaries.every(
    (item) =>
        item.checkpoint.sponsor.signature ==
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

  const neutralRuntime = SponsorCrisisRuntimeCareerEngine(
    crisisIntegration: CrisisRuntimeIntegrationEngine(
      decisionEngine: CrisisDecisionEngine(activationThreshold: 101),
    ),
  );
  const sponsorOnly = SponsorRuntimeCareerEngine();
  final neutral = neutralRuntime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 2,
  );
  final sponsorBaseline = sponsorOnly.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 2,
  );
  final neutralM45Parity = neutral.crisisCount == 0 &&
      codec.encode(neutral.checkpoint) == codec.encode(sponsorBaseline.checkpoint) &&
      _listEquals(
        neutral.boundaries.map((item) => item.sponsor.signature).toList(),
        sponsorBaseline.boundaries.map((item) => item.signature).toList(),
      );

  const forcedRuntime = SponsorCrisisRuntimeCareerEngine(
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

  final revenueBySeason = direct.boundaries
      .map((item) => item.sponsorRevenue.units.toStringAsFixed(2))
      .join(',');
  final saveBytes = codec.encode(direct.checkpoint).length;

  print('M46_SPONSOR_CRISIS seasons=${direct.boundaries.length}');
  print('M46_SPONSOR_CRISIS contractsPerSeason=${world.clubs.length}');
  print('M46_SPONSOR_CRISIS sponsorRevenueBySeason=$revenueBySeason');
  print(
    'M46_SPONSOR_CRISIS cumulativeSponsorRevenue='
    '${direct.checkpoint.sponsor.totalRevenuePaid.units.toStringAsFixed(2)}',
  );
  print(
    'M46_SPONSOR_CRISIS crises=${direct.crisisCount}/'
    '${direct.boundaries.length * world.clubs.length}',
  );
  print('M46_SPONSOR_CRISIS forcedWiring=$forcedWiring');
  print('M46_SPONSOR_CRISIS debtPreserved=$debtPreserved');
  print('M46_SPONSOR_CRISIS sponsorStatePreserved=$sponsorStatePreserved');
  print('M46_SPONSOR_CRISIS financeReplacementMatch=$financeReplacementMatch');
  print('M46_SPONSOR_CRISIS neutralM45Parity=$neutralM45Parity');
  print('M46_SPONSOR_CRISIS saveResumeMatch=$saveResumeMatch');
  print('M46_SPONSOR_CRISIS boundaryMatch=$boundaryMatch');
  print('M46_SPONSOR_CRISIS saveBytes=$saveBytes');

  if (!contractsComplete ||
      !forcedWiring ||
      !debtPreserved ||
      !sponsorStatePreserved ||
      !financeReplacementMatch ||
      !neutralM45Parity ||
      !saveResumeMatch ||
      !boundaryMatch) {
    throw StateError('M46 sponsor + crisis runtime canonical gate failed.');
  }

  print('M46_SPONSOR_CRISIS PASS');
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
