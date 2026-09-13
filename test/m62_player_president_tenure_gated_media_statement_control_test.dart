import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_media_statement_control.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const domainEngine = PresidentDomainCareerEngine();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const gatedCodec = PlayerPresidentTenureGatedMediaStatementSaveCodec();

  late FictionalWorldSetup world;
  late PresidentDomainResumeResult baselineOne;
  late PresidentDomainResumeResult baselineFour;
  late PresidentDomainResumeResult baselineFive;
  late String turnoverClubId;
  late String reelectedClubId;
  late String alternativeClubId;
  late int turnoverExpectedCalls;
  late int reelectedExpectedCalls;
  late int reelectedFirstTermCalls;

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
    alternativeClubId = baselineOne
        .report.sourceReport.baselineMediaReport.seasons.single.clubs
        .firstWhere((item) => item.statement != null)
        .clubId;

    turnoverExpectedCalls = baselineFive
        .report.sourceReport.baselineMediaReport.seasons
        .where((season) => season.seasonIndex < 4)
        .map(
          (season) =>
              season.clubs.firstWhere((item) => item.clubId == turnoverClubId),
        )
        .where((item) => item.statement != null)
        .length;
    reelectedFirstTermCalls = baselineFive
        .report.sourceReport.baselineMediaReport.seasons
        .where((season) => season.seasonIndex < 4)
        .map(
          (season) =>
              season.clubs.firstWhere((item) => item.clubId == reelectedClubId),
        )
        .where((item) => item.statement != null)
        .length;
    reelectedExpectedCalls = baselineFive
        .report.sourceReport.baselineMediaReport.seasons
        .map(
          (season) =>
              season.clubs.firstWhere((item) => item.clubId == reelectedClubId),
        )
        .where((item) => item.statement != null)
        .length;
  });

  test('M62 active incumbent delegates media stance and keeps 47 AI clubs exact', () {
    final provider = _AlternativeMediaStanceProvider();
    final result = PlayerPresidentTenureGatedMediaStatementCareerEngine(
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
      for (final item
          in baselineOne.report.sourceReport.baselineMediaReport.seasons.single.clubs)
        item.clubId: item,
    };
    final resultByClub = {
      for (final item in result.mediaSnapshots) item.clubId: item,
    };
    var aiParity = 0;
    for (final club in world.clubs) {
      final baseline = baselineByClub[club.id]!;
      final actual = resultByClub[club.id]!;
      if (club.id == alternativeClubId) {
        expect(actual.statement, isNotNull);
        expect(actual.statement!.stance, isNot(baseline.statement!.stance));
        expect(actual.statement!.id, baseline.statement!.id);
        expect(actual.statement!.targetManagerId, baseline.statement!.targetManagerId);
        expect(actual.statement!.topic, baseline.statement!.topic);
      } else {
        expect(actual.signature, baseline.signature);
        aiParity++;
      }
    }

    expect(provider.calls, 1);
    expect(aiParity, 47);
    expect(result.checkpoint.tenureControl.active, isTrue);
  });

  test('M62 real turnover blocks media provider on successor first season', () {
    final provider = _EchoCountingMediaStanceProvider();
    final result = PlayerPresidentTenureGatedMediaStatementCareerEngine(
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: turnoverClubId,
      seasonCount: 5,
      electionInterval: 4,
    );

    expect(provider.calls, turnoverExpectedCalls);
    expect(result.checkpoint.tenureControl.lost, isTrue);
    expect(result.checkpoint.tenureControl.lostAtCompletedSeason, 4);
    expect(
      domainCodec.encode(result.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M62 reelection keeps media control active into next term', () {
    final provider = _EchoCountingMediaStanceProvider();
    final result = PlayerPresidentTenureGatedMediaStatementCareerEngine(
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: reelectedClubId,
      seasonCount: 5,
      electionInterval: 4,
    );

    expect(reelectedExpectedCalls, reelectedFirstTermCalls + 1);
    expect(provider.calls, reelectedExpectedCalls);
    expect(result.checkpoint.tenureControl.active, isTrue);
    expect(
      domainCodec.encode(result.checkpoint.domain),
      domainCodec.encode(baselineFive.checkpoint),
    );
  });

  test('M62 persisted lost tenure never reactivates media provider after load', () {
    final firstProvider = _EchoCountingMediaStanceProvider();
    final first = PlayerPresidentTenureGatedMediaStatementCareerEngine(
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
    expect(firstProvider.calls, turnoverExpectedCalls);
    expect(first.checkpoint.tenureControl.lost, isTrue);

    final restored = gatedCodec.decode(gatedCodec.encode(first.checkpoint));
    final blocker = _FailIfCalledMediaStanceProvider();
    final resumed = PlayerPresidentTenureGatedMediaStatementCareerEngine(
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

  test('M62 save resume is deterministic with recreated runtime-only provider', () {
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
    final restored = gatedCodec.decode(gatedCodec.encode(first.checkpoint));
    final resumed = PlayerPresidentTenureGatedMediaStatementCareerEngine(
      decisionProvider: _AlternativeMediaStanceProvider(),
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
