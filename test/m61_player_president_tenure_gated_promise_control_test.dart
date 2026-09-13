import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_control.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const domainEngine = PresidentDomainCareerEngine();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const gatedCodec = PlayerPresidentTenureGatedPromiseSaveCodec();

  late FictionalWorldSetup world;
  late PresidentDomainResumeResult baselineOne;
  late PresidentDomainResumeResult baselineFour;
  late PresidentDomainResumeResult baselineFive;
  late String turnoverClubId;
  late String reelectedClubId;
  late String alternativeClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    baselineOne = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    baselineFour = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    baselineFive = domainEngine.simulateWithCheckpoint(
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
    turnoverClubId = initialIds.keys.firstWhere(
      (clubId) => initialIds[clubId] != afterFourIds[clubId],
    );
    reelectedClubId = initialIds.keys.firstWhere(
      (clubId) => initialIds[clubId] == afterFourIds[clubId],
    );
    alternativeClubId = baselineOne.report.sourceReport.promiseReport.snapshots
        .firstWhere(
          (snapshot) =>
              PlayerPresidentPromiseGenerator.allowedPromiseTypes(
                snapshot.context,
              ).any((type) => type != snapshot.promise.type),
        )
        .promise
        .clubId;
  });

  test('M61 active incumbent delegates promise choice and keeps 47 AI clubs exact', () {
    final provider = _AlternativePromiseProvider();
    final result = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: provider,
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
    final resultByClub = {
      for (final item in result.promiseSnapshots) item.promise.clubId: item,
    };
    var aiParity = 0;
    for (final club in world.clubs) {
      final baseline = baselineByClub[club.id]!;
      final actual = resultByClub[club.id]!;
      if (club.id == alternativeClubId) {
        expect(actual.promise.type, isNot(baseline.promise.type));
      } else {
        expect(actual.signature, baseline.signature);
        aiParity++;
      }
    }

    expect(provider.calls, 1);
    expect(aiParity, 47);
    expect(result.checkpoint.tenureControl.active, isTrue);
  });

  test('M61 real turnover blocks player promise provider on successor first season', () {
    final provider = _EchoCountingPromiseProvider();
    final result = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 5,
      electionInterval: 4,
    );

    expect(provider.calls, 4);
    expect(result.checkpoint.tenureControl.lost, isTrue);
    expect(result.checkpoint.tenureControl.lostAtCompletedSeason, 4);
    expect(
      domainCodec.encode(result.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M61 reelection keeps player promise control active into next term', () {
    final provider = _EchoCountingPromiseProvider();
    final result = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 5,
      electionInterval: 4,
    );

    expect(provider.calls, 5);
    expect(result.checkpoint.tenureControl.active, isTrue);
    expect(
      domainCodec.encode(result.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M61 persisted lost tenure never reactivates promise provider after load', () {
    final firstProvider = _EchoCountingPromiseProvider();
    final first = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: firstProvider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    expect(firstProvider.calls, 4);
    expect(first.checkpoint.tenureControl.lost, isTrue);

    final restored = gatedCodec.decode(gatedCodec.encode(first.checkpoint));
    final blocker = _FailIfCalledPromiseProvider();
    final resumed = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: blocker,
    ).resume(
      checkpoint: restored,
      seasonCount: 1,
    );

    expect(blocker.calls, 0);
    expect(resumed.checkpoint.tenureControl.lost, isTrue);
    expect(
      domainCodec.encode(resumed.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M61 save resume is deterministic with a recreated runtime-only provider', () {
    final direct = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: _AlternativePromiseProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: alternativeClubId,
      seasonCount: 5,
      electionInterval: 4,
    );
    final first = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: _AlternativePromiseProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: alternativeClubId,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final restored = gatedCodec.decode(gatedCodec.encode(first.checkpoint));
    final resumed = PlayerPresidentTenureGatedPromiseCareerEngine(
      decisionProvider: _AlternativePromiseProvider(),
    ).resume(
      checkpoint: restored,
      seasonCount: 2,
    );

    expect(
      gatedCodec.encode(resumed.checkpoint),
      gatedCodec.encode(direct.checkpoint),
    );
  });
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

class _FailIfCalledPromiseProvider extends PlayerPromiseDecisionProvider {
  int calls = 0;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    calls++;
    throw StateError('Promise provider must stay blocked after presidency loss.');
  }
}
