import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:test/test.dart';

void main() {
  test('M57 without a player provider preserves M10 media generation', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 57001);
    final baseline = const MediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );
    final controlled = MediaCareerEngine(
      statementEngine: PlayerPresidentMediaStatementEngine(
        controlledClubId: world.clubs.first.id,
      ),
    ).fromManagerReport(
      managerReport: baseline.managerReport,
      config: config,
    );

    expect(controlled.signature, baseline.signature);
  });

  test('M57 overrides only controlled club stance and keeps 47 AI clubs exact', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 57002);
    final baseline = const MediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final baselineSeason = baseline.seasons.single;
    final controlledBaseline = baselineSeason.clubs.firstWhere(
      (item) =>
          item.statement != null && item.statement!.stance != MediaStance.noComment,
    );
    final player = MediaCareerEngine(
      statementEngine: PlayerPresidentMediaStatementEngine(
        controlledClubId: controlledBaseline.clubId,
        decisionProvider: const _FixedMediaStanceProvider(MediaStance.noComment),
      ),
    ).fromManagerReport(
      managerReport: baseline.managerReport,
      config: config,
    );
    final playerSeason = player.seasons.single;
    final controlledPlayer = playerSeason.clubs.firstWhere(
      (item) => item.clubId == controlledBaseline.clubId,
    );

    expect(controlledPlayer.statement, isNotNull);
    expect(controlledPlayer.statement!.stance, MediaStance.noComment);
    expect(controlledPlayer.statement!.id, controlledBaseline.statement!.id);
    expect(
      controlledPlayer.statement!.targetManagerId,
      controlledBaseline.statement!.targetManagerId,
    );
    expect(controlledPlayer.statement!.topic, controlledBaseline.statement!.topic);

    var aiParity = 0;
    for (final baselineClub in baselineSeason.clubs) {
      if (baselineClub.clubId == controlledBaseline.clubId) continue;
      final playerClub = playerSeason.clubs.firstWhere(
        (item) => item.clubId == baselineClub.clubId,
      );
      expect(playerClub.signature, baselineClub.signature);
      aiParity++;
    }
    expect(aiParity, 47);
  });

  test('M57 cannot force a statement event and skips provider when AI has none', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 57003);
    final baseline = const MediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final noEvent = baseline.seasons.single.clubs.firstWhere(
      (item) => item.statement == null,
    );
    final provider = _CountingMediaStanceProvider(MediaStance.strongSupport);
    final player = MediaCareerEngine(
      statementEngine: PlayerPresidentMediaStatementEngine(
        controlledClubId: noEvent.clubId,
        decisionProvider: provider,
      ),
    ).fromManagerReport(
      managerReport: baseline.managerReport,
      config: config,
    );
    final playerClub = player.seasons.single.clubs.firstWhere(
      (item) => item.clubId == noEvent.clubId,
    );

    expect(playerClub.statement, isNull);
    expect(provider.calls, 0);
  });

  test('M57 selected stance flows through real M10 credibility resolution', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 57004);
    final baseline = const MediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );
    final baselineClub = baseline.seasons.single.clubs.firstWhere(
      (item) => item.statement != null,
    );
    final alternative = baselineClub.statement!.stance == MediaStance.strongSupport
        ? MediaStance.pressure
        : MediaStance.strongSupport;
    final player = MediaCareerEngine(
      statementEngine: PlayerPresidentMediaStatementEngine(
        controlledClubId: baselineClub.clubId,
        decisionProvider: _FixedMediaStanceProvider(alternative),
      ),
    ).fromManagerReport(
      managerReport: baseline.managerReport,
      config: config,
    );
    final playerClub = player.seasons.single.clubs.firstWhere(
      (item) => item.clubId == baselineClub.clubId,
    );

    expect(playerClub.statement!.stance, alternative);
    expect(playerClub.credibilityBefore, baselineClub.credibilityBefore);
    expect(playerClub.credibilityAfter, isNot(baselineClub.credibilityAfter));
    expect(playerClub.change!.signature, isNot(baselineClub.change!.signature));
  });

  test('M57 media provider stays runtime-only across save and resume', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 57005);
    final controlledClubId = world.clubs.first.id;
    const provider = _FixedMediaStanceProvider(MediaStance.measuredSupport);
    const codec = PresidentDomainMemorySaveCodec();

    final direct = PlayerPresidentMediaStatementDomainCareerEngine(
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
    );
    final firstHalf = PlayerPresidentMediaStatementDomainCareerEngine(
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
      hasFutureSeasonAfterReport: true,
    );
    final restored = codec.decode(codec.encode(firstHalf.checkpoint));
    final resumed = PlayerPresidentMediaStatementDomainCareerEngine(
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).resume(
      checkpoint: restored,
      seasonCount: 2,
    );

    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
  });
}

class _FixedMediaStanceProvider extends PlayerMediaStatementDecisionProvider {
  const _FixedMediaStanceProvider(this.stance);

  final MediaStance stance;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) => stance;
}

class _CountingMediaStanceProvider extends PlayerMediaStatementDecisionProvider {
  _CountingMediaStanceProvider(this.stance);

  final MediaStance stance;
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    return stance;
  }
}
