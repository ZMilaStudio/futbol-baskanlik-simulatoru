import 'package:futbol_baskanlik_m0/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const runtime = CrisisRuntimeCareerEngine();
  const domain = PresidentDomainCareerEngine();
  const codec = PresidentDomainMemorySaveCodec();
  const neutralRuntime = CrisisRuntimeCareerEngine(
    integrationEngine: CrisisRuntimeIntegrationEngine(
      decisionEngine: CrisisDecisionEngine(activationThreshold: 101),
    ),
  );

  final direct = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 2,
  );
  if (direct.crisisCount <= 0) {
    throw StateError('M44 canonical runtime produced no crises.');
  }
  final clubSeasons = world.clubs.length * direct.boundaries.length;
  if (direct.crisisCount * 4 >= clubSeasons * 3) {
    throw StateError(
      'M44 runtime crises are too common: ${direct.crisisCount}/$clubSeasons.',
    );
  }

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
  final finalCheckpointMatch =
      codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch = [
        ...first.boundaries,
        ...resumed.boundaries,
      ].map((item) => item.signature).join('||') ==
      direct.boundaries.map((item) => item.signature).join('||');
  if (!finalCheckpointMatch || !boundaryMatch) {
    throw StateError('M44 crisis runtime save/resume parity failed.');
  }

  final legacy = domain.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
  );
  final neutral = neutralRuntime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
  );
  final legacyParity =
      codec.encode(legacy.checkpoint) == codec.encode(neutral.checkpoint);
  if (!legacyParity || neutral.crisisCount != 0) {
    throw StateError('M44 neutral runtime did not preserve legacy state.');
  }

  var turnovers = 0;
  var policyChanges = 0;
  const decision = CrisisDecisionEngine();
  for (var index = 1; index < direct.boundaries.length; index++) {
    final previous = {
      for (final item in direct.boundaries[index - 1].clubs) item.clubId: item,
    };
    for (final current in direct.boundaries[index].clubs) {
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
  if (turnovers <= 0 || policyChanges <= 0) {
    throw StateError('M44 turnover did not produce a crisis-policy change.');
  }

  final crisisTypes = <CrisisType, int>{};
  final actions = <CrisisAction, int>{};
  for (final boundary in direct.boundaries) {
    for (final item in boundary.clubs) {
      final resolution = item.resolution;
      if (resolution == null) continue;
      crisisTypes[resolution.scenario.type] =
          (crisisTypes[resolution.scenario.type] ?? 0) + 1;
      actions[resolution.decision.action] =
          (actions[resolution.decision.action] ?? 0) + 1;
    }
  }

  print('M44_CRISIS_RUNTIME seasons=${direct.boundaries.length}');
  print(
    'M44_CRISIS_RUNTIME crises=${direct.crisisCount}/$clubSeasons '
    'types=$crisisTypes',
  );
  print('M44_CRISIS_RUNTIME actions=$actions');
  print('M44_CRISIS_RUNTIME turnovers=$turnovers policyChanges=$policyChanges');
  print('M44_CRISIS_RUNTIME legacyParity=$legacyParity');
  print('M44_CRISIS_RUNTIME finalCheckpointMatch=$finalCheckpointMatch');
  print('M44_CRISIS_RUNTIME boundaryMatch=$boundaryMatch');
  print('M44_CRISIS_RUNTIME PASS');
}
