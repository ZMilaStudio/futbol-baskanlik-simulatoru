import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_media_composition.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const domainEngine = PresidentDomainCareerEngine();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const gatedCodec = PlayerPresidentTenureGatedPromiseMediaSaveCodec();

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
  final firstMediaByClub = {
    for (final item
        in baselineOne.report.sourceReport.baselineMediaReport.seasons.single.clubs)
      item.clubId: item,
  };
  final alternativeClubId = baselineOne.report.sourceReport.promiseReport.snapshots
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
  final turnoverClubId = initialIds.keys.firstWhere(
    (clubId) =>
        initialIds[clubId] != afterFourIds[clubId] &&
        fifthSeason.clubs
                .firstWhere((item) => item.clubId == clubId)
                .statement !=
            null,
  );
  final reelectedClubId = initialIds.keys.firstWhere(
    (clubId) =>
        initialIds[clubId] == afterFourIds[clubId] &&
        fifthSeason.clubs
                .firstWhere((item) => item.clubId == clubId)
                .statement !=
            null,
  );

  final activePromise = _AlternativePromiseProvider();
  final activeMedia = _AlternativeMediaStanceProvider();
  final active = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
    promiseProvider: activePromise,
    mediaProvider: activeMedia,
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
    for (final item in active.promiseSnapshots) item.promise.clubId: item,
  };
  final baselineMedia = {
    for (final item
        in baselineOne.report.sourceReport.baselineMediaReport.seasons.single.clubs)
      item.clubId: item,
  };
  final actualMedia = {
    for (final item in active.mediaSnapshots) item.clubId: item,
  };
  var promiseAiParity = 0;
  var mediaAiParity = 0;
  for (final club in world.clubs) {
    if (club.id == alternativeClubId) continue;
    if (actualPromises[club.id]!.signature != baselinePromises[club.id]!.signature) {
      throw StateError('M63 changed AI promise for ${club.id}.');
    }
    if (actualMedia[club.id]!.signature != baselineMedia[club.id]!.signature) {
      throw StateError('M63 changed AI media statement for ${club.id}.');
    }
    promiseAiParity++;
    mediaAiParity++;
  }
  final activeDelegation = activePromise.calls == 1 &&
      activeMedia.calls == 1 &&
      actualPromises[alternativeClubId]!.promise.type !=
          baselinePromises[alternativeClubId]!.promise.type &&
      actualMedia[alternativeClubId]!.statement!.stance !=
          baselineMedia[alternativeClubId]!.statement!.stance;

  final turnoverExpectedMediaCalls = baselineFive
      .report.sourceReport.baselineMediaReport.seasons
      .where((season) => season.seasonIndex < 4)
      .map(
        (season) =>
            season.clubs.firstWhere((item) => item.clubId == turnoverClubId),
      )
      .where((item) => item.statement != null)
      .length;
  final turnoverPromise = _EchoCountingPromiseProvider();
  final turnoverMedia = _EchoCountingMediaStanceProvider();
  final turnover = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
    promiseProvider: turnoverPromise,
    mediaProvider: turnoverMedia,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: turnoverClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final turnoverStopsControl = turnoverPromise.calls == 4 &&
      turnoverMedia.calls == turnoverExpectedMediaCalls &&
      turnover.checkpoint.tenureControl.lost &&
      domainCodec.encode(turnover.checkpoint.domain) ==
          domainCodec.encode(baselineFive.checkpoint);

  final reelectedExpectedMediaCalls = baselineFive
      .report.sourceReport.baselineMediaReport.seasons
      .map(
        (season) =>
            season.clubs.firstWhere((item) => item.clubId == reelectedClubId),
      )
      .where((item) => item.statement != null)
      .length;
  final reelectedPromise = _EchoCountingPromiseProvider();
  final reelectedMedia = _EchoCountingMediaStanceProvider();
  final reelected = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
    promiseProvider: reelectedPromise,
    mediaProvider: reelectedMedia,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final reelectionKeepsControl = reelectedPromise.calls == 5 &&
      reelectedMedia.calls == reelectedExpectedMediaCalls &&
      reelected.checkpoint.tenureControl.active &&
      domainCodec.encode(reelected.checkpoint.domain) ==
          domainCodec.encode(baselineFive.checkpoint);

  final restored = gatedCodec.decode(gatedCodec.encode(turnover.checkpoint));
  final stickyLoss = restored.tenureControl.lost &&
      restored.tenureControl.signature == turnover.checkpoint.tenureControl.signature;

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
  final resumed = PlayerPresidentTenureGatedPromiseMediaCareerEngine(
    promiseProvider: _AlternativePromiseProvider(),
    mediaProvider: _AlternativeMediaStanceProvider(),
  ).resume(
    checkpoint: gatedCodec.decode(gatedCodec.encode(first.checkpoint)),
    seasonCount: 2,
  );
  final deterministic = gatedCodec.encode(resumed.checkpoint) ==
      gatedCodec.encode(direct.checkpoint);

  if (!activeDelegation ||
      promiseAiParity != 47 ||
      mediaAiParity != 47 ||
      !turnoverStopsControl ||
      !reelectionKeepsControl ||
      !stickyLoss ||
      !deterministic ||
      world.clubs.length != 48) {
    throw StateError('M63 promise/media composition validation failed.');
  }

  print(
    'M63_PLAYER_PRESIDENT_TENURE_GATED_PROMISE_MEDIA_COMPOSITION_PASS '
    'controlled=$alternativeClubId promiseAiParity=$promiseAiParity '
    'mediaAiParity=$mediaAiParity activeDelegation=$activeDelegation '
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
