import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/sponsor_crisis_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const sponsorOnly = SponsorRuntimeCareerEngine();
  const codec = SponsorPresidentRuntimeSaveCodec();
  const neutralComposition = SponsorCrisisRuntimeCareerEngine(
    crisisIntegration: CrisisRuntimeIntegrationEngine(
      decisionEngine: CrisisDecisionEngine(activationThreshold: 101),
    ),
  );
  const forcedComposition = SponsorCrisisRuntimeCareerEngine(
    crisisIntegration: CrisisRuntimeIntegrationEngine(
      decisionEngine: CrisisDecisionEngine(activationThreshold: 0),
    ),
  );

  test('M46 neutral crisis composition preserves M45 sponsor runtime exactly', () {
    final world = const FictionalWorldFactory().build();
    final legacy = sponsorOnly.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
    );
    final combined = neutralComposition.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
    );

    expect(combined.crisisCount, 0);
    expect(
      codec.encode(combined.checkpoint),
      codec.encode(legacy.checkpoint),
    );
    expect(
      combined.boundaries.map((item) => item.sponsor.signature).toList(),
      legacy.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M46 crisis applies after sponsor-aware economy and preserves sponsor state', () {
    final world = const FictionalWorldFactory().build();
    final result = forcedComposition.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final boundary = result.boundaries.single;
    final preFinance = {
      for (final state in boundary.sponsor.checkpoint.domain.presidentRuntime
          .runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final postFinance = {
      for (final state in boundary.checkpoint.domain.presidentRuntime.runtime
          .runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final worldSeason = boundary.sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single;

    expect(boundary.crisisCount, 48);
    expect(
      boundary.checkpoint.sponsor.signature,
      boundary.sponsor.checkpoint.sponsor.signature,
    );
    for (final snapshot in boundary.crisis.clubs) {
      final resolution = snapshot.resolution!;
      expect(snapshot.context.finance.signature, preFinance[snapshot.clubId]!.signature);
      expect(postFinance[snapshot.clubId]!.signature, resolution.finance.signature);
      expect(resolution.finance.debt, snapshot.context.finance.debt);
    }
    for (final finance in worldSeason.finances) {
      expect(
        finance.sponsorRevenue,
        boundary.sponsor.revenueByClub[finance.clubId],
      );
    }
  });

  test('M46 crisis-adjusted fan and media feed the next sponsor context', () {
    final recordingSponsor = _RecordingSponsorSystemEngine();
    final runtime = SponsorCrisisRuntimeCareerEngine(
      sponsorRuntime: SponsorRuntimeCareerEngine(
        sponsorSystem: recordingSponsor,
      ),
      crisisIntegration: const CrisisRuntimeIntegrationEngine(
        decisionEngine: CrisisDecisionEngine(activationThreshold: 0),
      ),
    );
    final world = const FictionalWorldFactory().build();
    final result = runtime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 4,
    );
    final first = result.boundaries.first;
    final beforeByClub = {
      for (final state in first.sponsor.checkpoint.domain.presidentRuntime.clubs)
        state.clubId: state,
    };
    final afterByClub = {
      for (final state in first.checkpoint.domain.presidentRuntime.clubs)
        state.clubId: state,
    };
    final nextFan = recordingSponsor.fanTrustBySeason[1]!;
    final nextMedia = recordingSponsor.mediaCredibilityBySeason[1]!;

    var changed = 0;
    for (final clubId in afterByClub.keys) {
      final before = beforeByClub[clubId]!;
      final after = afterByClub[clubId]!;
      if (before.fanReputation.signature != after.fanReputation.signature ||
          before.mediaReputation.signature != after.mediaReputation.signature) {
        changed++;
      }
      expect(nextFan[clubId], after.fanReputation.overallTrust);
      expect(nextMedia[clubId], after.mediaReputation.credibility);
    }

    expect(changed, greaterThan(0));
    expect(recordingSponsor.resolveCalls, 6);
  });

  test('M46 2 plus 2 save resume matches uninterrupted four seasons', () {
    final world = const FictionalWorldFactory().build();
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

    expect(
      codec.encode(resumed.checkpoint),
      codec.encode(direct.checkpoint),
    );
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}

class _RecordingSponsorSystemEngine extends SponsorSystemEngine {
  final Map<int, Map<String, int>> fanTrustBySeason = {};
  final Map<int, Map<String, int>> mediaCredibilityBySeason = {};
  int resolveCalls = 0;

  @override
  SponsorSeasonResolution resolveSeason({
    required int seasonIndex,
    required List<Club> clubs,
    required Map<String, int> leaguePositions,
    required Map<String, PresidentManagementProfile> presidentProfilesByClub,
    required int careerSeed,
    required int simulationVersion,
    Map<String, FanState> fanStatesByClub = const {},
    Map<String, MediaState> mediaStatesByClub = const {},
    Iterable<SponsorContract> existingContracts = const [],
    Money totalRevenuePaid = Money.zero,
  }) {
    resolveCalls++;
    final fans = fanTrustBySeason.putIfAbsent(seasonIndex, () => {});
    final media = mediaCredibilityBySeason.putIfAbsent(seasonIndex, () => {});
    for (final club in clubs) {
      fans[club.id] = fanStatesByClub[club.id]?.overallTrust ?? -1;
      media[club.id] = mediaStatesByClub[club.id]?.credibility ?? -1;
    }
    return super.resolveSeason(
      seasonIndex: seasonIndex,
      clubs: clubs,
      leaguePositions: leaguePositions,
      presidentProfilesByClub: presidentProfilesByClub,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
      fanStatesByClub: fanStatesByClub,
      mediaStatesByClub: mediaStatesByClub,
      existingContracts: existingContracts,
      totalRevenuePaid: totalRevenuePaid,
    );
  }
}
