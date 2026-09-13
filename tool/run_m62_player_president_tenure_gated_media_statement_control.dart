import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_media_statement_control.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const domainEngine = PresidentDomainCareerEngine();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const gatedCodec = PlayerPresidentTenureGatedMediaStatementSaveCodec();

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
  final alternativeClubId = baselineOne
      .report.sourceReport.baselineMediaReport.seasons.single.clubs
      .firstWhere((item) => item.statement != null)
      .clubId;

  final activeProvider = _AlternativeMediaStanceProvider();
  final active = PlayerPresidentTenureGatedMediaStatementCareerEngine(
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
    for (final item
        in baselineOne.report.sourceReport.baselineMediaReport.seasons.single.clubs)
      item.clubId: item,
  };
  final activeByClub = {
    for (final item in active.mediaSnapshots) item.clubId: item,
  };
  var aiParity = 0;
  for (final club in world.clubs) {
    if (club.id == alternativeClubId) continue;
    if (activeByClub[club.id]!.signature != baselineByClub[club.id]!.signature) {
      throw StateError('M62 changed AI media statement for ${club.id}.');
    }
    aiParity++;
  }
  final activeDelegation = activeProvider.calls == 1 &&
      activeByClub[alternativeClubId]!.statement!.stance !=
          baselineByClub[alternativeClubId]!.statement!.stance;

  final turnoverExpectedCalls = baselineFive
      .report.sourceReport.baselineMediaReport.seasons
      .where((season) => season.seasonIndex < 4)
      .map(
        (season) =>
            season.clubs.firstWhere((item) => item.clubId == turnoverClubId),
      )
      .where((item) => item.statement != null)
      .length;
  final turnoverProvider = _EchoCountingMediaStanceProvider();
  final turnover = PlayerPresidentTenureGatedMediaStatementCareerEngine(
    decisionProvider: turnoverProvider,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: turnoverClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final turnoverStopsControl = turnoverProvider.calls == turnoverExpectedCalls &&
      turnover.checkpoint.tenureControl.lost &&
      domainCodec.encode(turnover.checkpoint.domain) ==
          domainCodec.encode(baselineFive.checkpoint);

  final reelectedExpectedCalls = baselineFive
      .report.sourceReport.baselineMediaReport.seasons
      .map(
        (season) =>
            season.clubs.firstWhere((item) => item.clubId == reelectedClubId),
      )
      .where((item) => item.statement != null)
      .length;
  final reelectedProvider = _EchoCountingMediaStanceProvider();
  final reelected = PlayerPresidentTenureGatedMediaStatementCareerEngine(
    decisionProvider: reelectedProvider,
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final reelectionKeepsControl =
      reelectedProvider.calls == reelectedExpectedCalls &&
          reelected.checkpoint.tenureControl.active &&
          domainCodec.encode(reelected.checkpoint.domain) ==
              domainCodec.encode(baselineFive.checkpoint);

  final restored = gatedCodec.decode(gatedCodec.encode(turnover.checkpoint));
  final stickyLoss = restored.tenureControl.lost &&
      restored.tenureControl.signature == turnover.checkpoint.tenureControl.signature;

  final direct = PlayerPresidentTenureGatedMediaStatementCareerEngine(
    decisionProvider: _AlternativeMediaStanceProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClubId,
    seasonCount: 5,
    electionInterval: 4,
  );
  final first = PlayerPresidentTenureGatedMediaStatementCareerEngine(
    decisionProvider: _AlternativeMediaStanceProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: reelectedClubId,
    seasonCount: 3,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final resumed = PlayerPresidentTenureGatedMediaStatementCareerEngine(
    decisionProvider: _AlternativeMediaStanceProvider(),
  ).resume(
    checkpoint: gatedCodec.decode(gatedCodec.encode(first.checkpoint)),
    seasonCount: 2,
  );
  final deterministic = gatedCodec.encode(resumed.checkpoint) ==
      gatedCodec.encode(direct.checkpoint);

  if (!activeDelegation ||
      aiParity != 47 ||
      !turnoverStopsControl ||
      !reelectionKeepsControl ||
      !stickyLoss ||
      !deterministic ||
      world.clubs.length != 48) {
    throw StateError(
      'M62 tenure-gated media statement control validation failed.',
    );
  }

  print(
    'M62_PLAYER_PRESIDENT_TENURE_GATED_MEDIA_STATEMENT_CONTROL_PASS '
    'controlled=$alternativeClubId aiParity=$aiParity '
    'activeDelegation=$activeDelegation '
    'turnoverStopsControl=$turnoverStopsControl '
    'reelectionKeepsControl=$reelectionKeepsControl '
    'stickyLoss=$stickyLoss deterministic=$deterministic '
    'worldClubs=${world.clubs.length}',
  );
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
