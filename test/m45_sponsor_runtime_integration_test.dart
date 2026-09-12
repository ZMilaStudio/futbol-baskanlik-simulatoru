import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const runtime = SponsorRuntimeCareerEngine();
  const codec = SponsorPresidentRuntimeSaveCodec();

  test('M45 sponsor revenue replaces legacy revenue in real economy rows', () {
    final world = const FictionalWorldFactory().build();
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
      seasonCount: 1,
    );
    final boundary = result.boundaries.single;
    final worldSeason = boundary.report.sourceReport.advancedTransferReport
        .worldReport.seasons.single;

    expect(boundary.contracts, hasLength(48));
    expect(boundary.revenueByClub, hasLength(48));
    expect(worldSeason.finances, hasLength(48));
    for (final finance in worldSeason.finances) {
      expect(
        finance.sponsorRevenue,
        boundary.revenueByClub[finance.clubId],
        reason: 'Sponsor runtime revenue must be the economy replacement for '
            '${finance.clubId}.',
      );
    }
    expect(
      result.checkpoint.sponsor.totalRevenuePaid,
      boundary.totalRevenue,
    );
  });

  test('M45 multi-year sponsor survives a real president turnover', () {
    final world = const FictionalWorldFactory().build();
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
      seasonCount: 3,
      electionInterval: 1,
    );

    var preservedAcrossTurnover = false;
    for (var index = 1; index < result.boundaries.length; index++) {
      final prior = result.boundaries[index - 1];
      final current = result.boundaries[index];
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
          preservedAcrossTurnover = true;
          break;
        }
      }
    }
    expect(preservedAcrossTurnover, isTrue);
  });

  test('M45 expired contract renewal uses the current president profile', () {
    final world = const FictionalWorldFactory().build();
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
      seasonCount: 4,
      electionInterval: 1,
    );

    var renewedAfterPresidentChange = false;
    for (var index = 1; index < result.boundaries.length; index++) {
      final prior = result.boundaries[index - 1];
      final current = result.boundaries[index];
      final currentPresidentByClub = {
        for (final state in prior.checkpoint.domain.presidentRuntime.clubs)
          state.clubId: state.managementProfile.presidentId,
      };
      final priorContractByClub = {
        for (final contract in prior.contracts) contract.offer.clubId: contract,
      };
      for (final contract in current.contracts) {
        if (contract.startSeasonIndex != current.seasonIndex) continue;
        final president = currentPresidentByClub[contract.offer.clubId];
        final previous = priorContractByClub[contract.offer.clubId];
        expect(contract.acceptedByPresidentId, president);
        if (previous != null &&
            previous.acceptedByPresidentId != contract.acceptedByPresidentId) {
          renewedAfterPresidentChange = true;
        }
      }
    }
    expect(renewedAfterPresidentChange, isTrue);
  });

  test('M45 composite sponsor president save is deterministic and round-trips', () {
    final world = const FictionalWorldFactory().build();
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: seed),
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final encoded = codec.encode(result.checkpoint);
    final loaded = codec.decode(encoded);

    expect(codec.encode(loaded), encoded);
    expect(loaded.signature, result.checkpoint.signature);
    expect(loaded.nextSeasonIndex, result.checkpoint.nextSeasonIndex);
  });

  test('M45 2 plus 2 save resume matches uninterrupted four seasons', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: seed);
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

    expect(
      codec.encode(resumed.checkpoint),
      codec.encode(direct.checkpoint),
    );
    expect(
      [
        ...first.boundaries,
        ...resumed.boundaries,
      ].map((item) => item.signature).toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
