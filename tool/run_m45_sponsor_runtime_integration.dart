import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const runtime = SponsorRuntimeCareerEngine();
  const codec = SponsorPresidentRuntimeSaveCodec();

  final direct = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 1,
  );
  if (direct.boundaries.length != 4 ||
      direct.boundaries.any((item) => item.contracts.length != 48)) {
    throw StateError('M45 did not resolve one sponsor contract per club-season.');
  }

  var financeReplacementMatch = true;
  for (final boundary in direct.boundaries) {
    final worldSeason = boundary.report.sourceReport.advancedTransferReport
        .worldReport.seasons.single;
    for (final finance in worldSeason.finances) {
      if (finance.sponsorRevenue != boundary.revenueByClub[finance.clubId]) {
        financeReplacementMatch = false;
        break;
      }
    }
  }
  if (!financeReplacementMatch) {
    throw StateError('M45 sponsor revenue was not the real economy replacement.');
  }

  var preservedAcrossTurnover = 0;
  var renewedByNewPresident = 0;
  for (var index = 1; index < direct.boundaries.length; index++) {
    final prior = direct.boundaries[index - 1];
    final current = direct.boundaries[index];
    final currentPresidentByClub = {
      for (final state in prior.checkpoint.domain.presidentRuntime.clubs)
        state.clubId: state.managementProfile.presidentId,
    };
    final priorContractByClub = {
      for (final contract in prior.contracts) contract.offer.clubId: contract,
    };
    for (final contract in current.contracts) {
      final previous = priorContractByClub[contract.offer.clubId];
      final president = currentPresidentByClub[contract.offer.clubId];
      if (previous == null || president == null) continue;
      if (previous.isActiveAt(current.seasonIndex) &&
          previous.signature == contract.signature &&
          contract.acceptedByPresidentId != president) {
        preservedAcrossTurnover++;
      }
      if (contract.startSeasonIndex == current.seasonIndex &&
          contract.acceptedByPresidentId == president &&
          previous.acceptedByPresidentId != contract.acceptedByPresidentId) {
        renewedByNewPresident++;
      }
    }
  }
  if (preservedAcrossTurnover <= 0 || renewedByNewPresident <= 0) {
    throw StateError(
      'M45 canonical did not observe both contract continuity and renewal after turnover.',
    );
  }

  final first = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 1,
    hasFutureSeasonAfterReport: true,
  );
  final encoded = codec.encode(first.checkpoint);
  final loaded = codec.decode(encoded);
  if (codec.encode(loaded) != encoded) {
    throw StateError('M45 composite save round-trip is not canonical.');
  }
  final resumed = runtime.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );
  final finalCheckpointMatch =
      codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch = [
        ...first.boundaries,
        ...resumed.boundaries,
      ].map((item) => item.signature).join('||') ==
      direct.boundaries.map((item) => item.signature).join('||');
  if (!finalCheckpointMatch || !boundaryMatch) {
    throw StateError('M45 2+2 save/resume parity failed.');
  }

  final revenueBySeason = direct.boundaries
      .map((item) => item.totalRevenue.units.toStringAsFixed(2))
      .join(',');
  print('M45_SPONSOR_RUNTIME seasons=${direct.boundaries.length}');
  print('M45_SPONSOR_RUNTIME contractsPerSeason=48');
  print('M45_SPONSOR_RUNTIME revenueBySeason=$revenueBySeason');
  print(
    'M45_SPONSOR_RUNTIME cumulativeRevenue='
    '${direct.checkpoint.sponsor.totalRevenuePaid.units.toStringAsFixed(2)}',
  );
  print(
    'M45_SPONSOR_RUNTIME preservedAcrossTurnover=$preservedAcrossTurnover '
    'renewedByNewPresident=$renewedByNewPresident',
  );
  print('M45_SPONSOR_RUNTIME saveBytes=${encoded.length}');
  print('M45_SPONSOR_RUNTIME financeReplacementMatch=$financeReplacementMatch');
  print('M45_SPONSOR_RUNTIME finalCheckpointMatch=$finalCheckpointMatch');
  print('M45_SPONSOR_RUNTIME boundaryMatch=$boundaryMatch');
  print('M45_SPONSOR_RUNTIME PASS');
}
