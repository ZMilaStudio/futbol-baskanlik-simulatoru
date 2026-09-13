import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_control.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const domainEngine = PresidentDomainCareerEngine();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const gatedCodec = PlayerPresidentTenureGatedPromiseSaveCodec();

  final baselineOne = domainEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 1,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final baselineFour = domainEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final baselineFive = domainEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 5,
    electionInterval: 4,
  );

  final initialIds = {
    for (final club in world.clubs)
      club.id: const PresidentProfileGenerator()
          .generateInitial(
            clubId: club.id,
            careerSeed: seed,
            simulationVersion: config.simulationVersion,
          )
          .id,
  };
  final afterFourIds = {
    for (final state in baselineFour.checkpoint.presidentRuntime.clubs)
      state.clubId: state.tenure.president.id,
  };
  final turnoverClubId = initialIds.keys.firstWhere(
    (clubId) => initialIds[clubId] != afterFourIds[clubId],
  );
  final reelectedClubId = initialIds.keys.firstWhere(
    (clubId) => initialIds[clubId] == afterFourIds[clubId],
  );
  final alternativeClubId =
      baselineOne.report.sourceReport.promiseReport.snapshots
          .firstWhere(
            (snapshot) =>
                PlayerPresidentPromiseGenerator.allowedPromiseTypes(
                  snapshot.context,
                ).any((type) => type != snapshot.promise.type),
          )
          .promise
          .clubId;

  final activeProvider = _AlternativePromiseProvider();
  final active = PlayerPresidentTenureGatedPromiseCareerEngine(
    decisionProvider: activeProvider,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: alternativeClubId,
    seasonCount: 1,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final baselineByClub = {
    for (final item in baselineOne.report.sourceReport.promiseReport.snapshots)
      item.promise.clubId: item,
  };
  final activeByClub = {
    for (final item in active.promiseSnapshots) item.promise.clubId: item,
  };
  var aiParity = 0;
  for (final club in world.clubs) {
    if (club.id == alternativeClubId) continue;
    if (activeByClub[club.id]!.signature != baselineByClub[club.id]!.signature) {
      throw StateError('M61 changed AI promise for ${club.id}.');
    }
    aiParity++;
  }
  final activeDelegation = activeProvider.calls == 1 &&
      activeByClub[alternativeClubId]!.promise.type !=
          baselineByClub[alternativeClubId]!.promise.type;

  final turnoverProvider = _EchoCountingPromiseProvider();
  final turnover = PlayerPresidentTenureGatedPromiseCareerEngine(
    decisionProvider: turnoverProvider,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: turnoverClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final turnoverStopsControl = turnoverProvider.calls == 4 &&
      turnover.checkpoint.tenureControl.lost &&
      domainCodec.encode(turnover.checkpoint.domain) ==
          domainCodec.encode(baselineFive.checkpoint);

  final reelectedProvider = _EchoCountingPromiseProvider();
  final reelected = PlayerPresidentTenureGatedPromiseCareerEngine(
    decisionProvider: reelectedProvider,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final reelectionKeepsControl = reelectedProvider.calls == 5 &&
      reelected.checkpoint.tenureControl.active &&
      domainCodec.encode(reelected.checkpoint.domain) ==
          domainCodec.encode(baselineFive.checkpoint);

  final restored = gatedCodec.decode(gatedCodec.encode(turnover.checkpoint));
  final stickyLoss = restored.tenureControl.lost &&
      restored.tenureControl.signature == turnover.checkpoint.tenureControl.signature;
  final deterministic = gatedCodec.encode(restored) ==
      gatedCodec.encode(turnover.checkpoint);

  if (!activeDelegation ||
      aiParity != 47 ||
      !turnoverStopsControl ||
      !reelectionKeepsControl ||
      !stickyLoss ||
      !deterministic ||
      world.clubs.length != 48) {
    throw StateError('M61 tenure-gated promise control validation failed.');
  }

  print(
    'M61_PLAYER_PRESIDENT_TENURE_GATED_PROMISE_CONTROL_PASS '
    'controlled=$alternativeClubId aiParity=$aiParity '
    'activeDelegation=$activeDelegation '
    'turnoverStopsControl=$turnoverStopsControl '
    'reelectionKeepsControl=$reelectionKeepsControl '
    'stickyLoss=$stickyLoss deterministic=$deterministic '
    'worldClubs=${world.clubs.length}',
  );
}

class _EchoCountingPromiseProvider extends PlayerPromiseDecisionProvider {
  int calls = 0;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    calls++;
    return context.aiPromise.type;
  }
}

class _AlternativePromiseProvider extends PlayerPromiseDecisionProvider {
  int calls = 0;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    calls++;
    return context.allowedTypes.firstWhere(
      (type) => type != context.aiPromise.type,
      orElse: () => context.aiPromise.type,
    );
  }
}
