import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const domainEngine = PresidentDomainCareerEngine();
  const codec = PresidentDomainMemorySaveCodec();
  const defaultRuntime = CrisisRuntimeCareerEngine();
  const forcedIntegration = CrisisRuntimeIntegrationEngine(
    decisionEngine: CrisisDecisionEngine(activationThreshold: 0),
  );
  const forcedRuntime = CrisisRuntimeCareerEngine(
    integrationEngine: forcedIntegration,
  );
  const neutralRuntime = CrisisRuntimeCareerEngine(
    integrationEngine: CrisisRuntimeIntegrationEngine(
      decisionEngine: CrisisDecisionEngine(activationThreshold: 101),
    ),
  );

  late FictionalWorldSetup world;
  late PresidentDomainResumeResult oneSeason;
  late CrisisRuntimeBoundaryResult forcedBoundary;
  late CrisisRuntimeCareerResult defaultFour;
  late PresidentDomainResumeResult legacyFour;
  late CrisisRuntimeCareerResult neutralFour;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    oneSeason = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    forcedBoundary = forcedIntegration.apply(oneSeason.checkpoint);
    defaultFour = defaultRuntime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
    );
    legacyFour = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
    );
    neutralFour = neutralRuntime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 2,
    );
  });

  test('M44 boundary writes crisis effects into real continuation state', () {
    expect(forcedBoundary.clubs, hasLength(48));
    expect(forcedBoundary.crisisCount, 48);

    final item = forcedBoundary.clubs.first;
    final resolution = item.resolution!;
    final financeByClub = {
      for (final state in forcedBoundary.checkpoint.presidentRuntime.runtime
          .runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final presidentByClub = {
      for (final state in forcedBoundary.checkpoint.presidentRuntime.clubs)
        state.clubId: state,
    };

    expect(financeByClub[item.clubId]!.signature, resolution.finance.signature);
    expect(
      presidentByClub[item.clubId]!.fanReputation.signature,
      resolution.fan.signature,
    );
    expect(
      presidentByClub[item.clubId]!.mediaReputation.signature,
      resolution.media.signature,
    );
    expect(resolution.finance.debt, item.context.finance.debt);
  });

  test('M44 neutral wrapper preserves legacy president-domain checkpoint', () {
    expect(neutralFour.crisisCount, 0);
    expect(
      codec.encode(neutralFour.checkpoint),
      codec.encode(legacyFour.checkpoint),
    );
  });

  test('M44 existing president save codec persists crisis-adjusted state', () {
    final encoded = codec.encode(forcedBoundary.checkpoint);
    final loaded = codec.decode(encoded);
    expect(codec.encode(loaded), encoded);

    final direct = forcedRuntime.resume(
      checkpoint: forcedBoundary.checkpoint,
      seasonCount: 1,
    );
    final resumed = forcedRuntime.resume(
      checkpoint: loaded,
      seasonCount: 1,
    );
    expect(resumed.signature, direct.signature);
    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
  });

  test('M44 2 plus 2 save resume matches uninterrupted four seasons', () {
    final first = defaultRuntime.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final resumed = defaultRuntime.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(
      codec.encode(resumed.checkpoint),
      codec.encode(defaultFour.checkpoint),
    );
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      defaultFour.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M44 real president turnover can change crisis policy', () {
    var turnovers = 0;
    var policyChanges = 0;
    const decision = CrisisDecisionEngine();

    for (var index = 1; index < defaultFour.boundaries.length; index++) {
      final previous = {
        for (final item in defaultFour.boundaries[index - 1].clubs)
          item.clubId: item,
      };
      for (final current in defaultFour.boundaries[index].clubs) {
        final before = previous[current.clubId]!;
        if (before.presidentId == current.presidentId) continue;
        turnovers++;

        for (final type in CrisisType.values) {
          final scenario = CrisisScenario(type: type, severity: 80);
          final oldAction = decision
              .choose(scenario: scenario, president: before.context.president)
              .action;
          final newAction = decision
              .choose(scenario: scenario, president: current.context.president)
              .action;
          if (oldAction != newAction) {
            policyChanges++;
            break;
          }
        }
      }
    }

    expect(turnovers, greaterThan(0));
    expect(policyChanges, greaterThan(0));
  });
}
