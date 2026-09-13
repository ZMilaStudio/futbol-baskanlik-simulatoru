import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_media_composition.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const domainEngine = PresidentDomainCareerEngine();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const gatedCodec = PlayerPresidentTenureGatedPromiseMediaSaveCodec();

  late FictionalWorldSetup world;
  late PresidentDomainResumeResult baselineOne;
  late PresidentDomainResumeResult baselineFour;
  late PresidentDomainResumeResult baselineFive;
  late String turnoverClubId;
  late String reelectedClubId;
  late String alternativeClubId;
  late int turnoverExpectedMediaCalls;
  late int reelectedExpectedMediaCalls;

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
    final firstMediaByClub = {
      for (final item
          in baselineOne.report.sourceReport.baselineMediaReport.seasons.single.clubs)
        item.clubId: item,
    };
    alternativeClubId = baselineOne.report.sourceReport.promiseReport.snapshots
        .firstWhere(
          (snapshot) =>
              firstMediaByClub[snapshot.promise.clubId]!.statement != null &&
              PlayerPresidentPromiseGenerator.allowedPromiseTypes(
                snapshot.context,
              ).any((type) => type != snapshot.promise.type),
        )
        .promise
        .clubId;

    final fifthSeason = baselineFive
        .report.sourceReport.baselineMediaReport.seasons
        .firstWhere((season) => season.seasonIndex == 4);
    turnoverClubId = initialIds.keys.firstWhere(
      (clubId) =>
          initialIds[clubId] != afterFourIds[clubId] &&
          fifthSeason.clubs
                  .firstWhere((item) => item.clubId == clubId)
                  .statement !=
              null,
    );
    reelectedClubId = initialIds.keys.firstWhere(
      (clubId) =>
          initialIds[clubId] == afterFourIds[clubId] &&
          fifthSeason.clubs
                  .firstWhere((item) => item.clubId == clubId)
                  .statement !=
              null,
    );

    turnoverExpectedMediaCalls = baselineFive
        .report.sourceReport.baselineMediaReport.seasons
        .where((season) => season.seasonIndex < 4)
        .map(
          (season) =>
              season.clubs.firstWhere((item) => item.clubId == turnoverClubId),
        )
        .where((item) => item.statement != null)
        .length;
    reelectedExpectedMediaCalls = baselineFive
        .report.sourceReport.baselineMediaReport.seasons
        .map(
          (season) =>
              season.clubs.firstWhere((item) => item.clubId == reelectedClubId),
        )
        .where((item) => item.statement != null)
        .length;
  });

  test('M63 composes active promise and media choices on one domain stream', () {
    final promiseProvider = _AlternativePromiseProvider();
    final mediaProvider = _AlternativeMediaStanceProvider();
    final result = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: promiseProvider,
      mediaProvider: mediaProvider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: alternativeClubId,
      seasonCount: 1,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );

    final baselinePromises = {
      for (final item in baselineOne.report.sourceReport.promiseReport.snapshots)
        item.promise.clubId: item,
    };
    final actualPromises = {
      for (final item in result.promiseSnapshots) item.promise.clubId: item,
    };
    final baselineMedia = {
      for (final item
          in baselineOne.report.sourceReport.baselineMediaReport.seasons.single.clubs)
        item.clubId: item,
    };
    final actualMedia = {
      for (final item in result.mediaSnapshots) item.clubId: item,
    };

    var promiseAiParity = 0;
    var mediaAiParity = 0;
    for (final club in world.clubs) {
      if (club.id == alternativeClubId) {
        expect(
          actualPromises[club.id]!.promise.type,
          isNot(baselinePromises[club.id]!.promise.type),
        );
        expect(
          actualMedia[club.id]!.statement!.stance,
          isNot(baselineMedia[club.id]!.statement!.stance),
        );
        expect(
          actualMedia[club.id]!.statement!.id,
          baselineMedia[club.id]!.statement!.id,
        );
        expect(
          actualMedia[club.id]!.statement!.topic,
          baselineMedia[club.id]!.statement!.topic,
        );
      } else {
        expect(actualPromises[club.id]!.signature, baselinePromises[club.id]!.signature);
        expect(actualMedia[club.id]!.signature, baselineMedia[club.id]!.signature);
        promiseAiParity++;
        mediaAiParity++;
      }
    }

    expect(promiseProvider.calls, 1);
    expect(mediaProvider.calls, 1);
    expect(promiseAiParity, 47);
    expect(mediaAiParity, 47);
    expect(result.checkpoint.tenureControl.active, isTrue);
  });

  test('M63 real turnover blocks both providers on successor first season', () {
    final promiseProvider = _EchoCountingPromiseProvider();
    final mediaProvider = _EchoCountingMediaStanceProvider();
    final result = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: promiseProvider,
      mediaProvider: mediaProvider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 5,
      electionInterval: 4,
    );

    expect(promiseProvider.calls, 4);
    expect(mediaProvider.calls, turnoverExpectedMediaCalls);
    expect(result.checkpoint.tenureControl.lost, isTrue);
    expect(result.checkpoint.tenureControl.lostAtCompletedSeason, 4);
    expect(
      domainCodec.encode(result.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M63 reelection keeps both providers active into next term', () {
    final promiseProvider = _EchoCountingPromiseProvider();
    final mediaProvider = _EchoCountingMediaStanceProvider();
    final result = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: promiseProvider,
      mediaProvider: mediaProvider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 5,
      electionInterval: 4,
    );

    expect(promiseProvider.calls, 5);
    expect(mediaProvider.calls, reelectedExpectedMediaCalls);
    expect(result.checkpoint.tenureControl.active, isTrue);
    expect(
      domainCodec.encode(result.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M63 persisted lost tenure blocks both providers after load', () {
    final firstPromise = _EchoCountingPromiseProvider();
    final firstMedia = _EchoCountingMediaStanceProvider();
    final first = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: firstPromise,
      mediaProvider: firstMedia,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 4,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    expect(firstPromise.calls, 4);
    expect(firstMedia.calls, turnoverExpectedMediaCalls);
    expect(first.checkpoint.tenureControl.lost, isTrue);

    final restored = gatedCodec.decode(gatedCodec.encode(first.checkpoint));
    final blockedPromise = _FailIfCalledPromiseProvider();
    final blockedMedia = _FailIfCalledMediaStanceProvider();
    final resumed = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: blockedPromise,
      mediaProvider: blockedMedia,
    ).resume(
      checkpoint: restored,
      seasonCount: 1,
    );

    expect(blockedPromise.calls, 0);
    expect(blockedMedia.calls, 0);
    expect(resumed.checkpoint.tenureControl.lost, isTrue);
    expect(
      domainCodec.encode(resumed.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M63 split save resume matches direct combined-control run', () {
    final direct = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaStanceProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 5,
      electionInterval: 4,
    );
    final first = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaStanceProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final restored = gatedCodec.decode(gatedCodec.encode(first.checkpoint));
    final resumed = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaStanceProvider(),
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

class _EchoCountingMediaStanceProvider
    extends PlayerMediaStatementDecisionProvider {
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    return context.aiStatement.stance;
  }
}

class _AlternativeMediaStanceProvider
    extends PlayerMediaStatementDecisionProvider {
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    return context.allowedStances.firstWhere(
      (stance) => stance != context.aiStatement.stance,
    );
  }
}

class _FailIfCalledMediaStanceProvider
    extends PlayerMediaStatementDecisionProvider {
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    throw StateError('Media provider must stay blocked after presidency loss.');
  }
}
