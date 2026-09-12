import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/president_facility_investment_runtime_integration.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const m48 = PresidentFacilityInvestmentRuntimeCareerEngine();
  const codec = PlayerPresidentFacilityControlSaveCodec();

  test('M49 without a player provider preserves M48 exactly', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m48.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
    );
    final player = const PlayerPresidentFacilityControlCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: 't1_02',
      seasonCount: 3,
    );

    expect(player.checkpoint.runtime.signature, baseline.checkpoint.signature);
    expect(
      player.boundaries.map((item) => item.checkpoint.runtime.signature).toList(),
      baseline.boundaries.map((item) => item.checkpoint.signature).toList(),
    );
  });

  test('M49 player hold overrides only the controlled club', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m48.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );
    final controlled = baseline.boundaries.first.decisions
        .firstWhere((decision) => decision.invested)
        .clubId;
    final player = const PlayerPresidentFacilityControlCareerEngine(
      control: PlayerPresidentFacilityControlRuntimeEngine(
        provider: _HoldProvider(),
      ),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
    );

    final playerBoundary = player.boundaries.first;
    final playerDecision = playerBoundary.decisions
        .firstWhere((decision) => decision.clubId == controlled);
    expect(playerDecision.playerControlled, isTrue);
    expect(playerDecision.requestedChoice?.signature,
        PlayerFacilityInvestmentChoice.hold.signature);
    expect(playerDecision.spend, Money.zero);
    expect(playerDecision.decision.academyAppliedUpgrades, 0);
    expect(playerDecision.decision.trainingGroundAppliedUpgrades, 0);
    expect(playerDecision.decision.stadiumAppliedUpgrades, 0);
    expect(
      playerBoundary.decisions.where((decision) => decision.playerControlled),
      hasLength(1),
    );

    final baselineByClub = {
      for (final decision in baseline.boundaries.first.decisions)
        decision.clubId: decision.signature,
    };
    for (final decision
        in playerBoundary.decisions.where((item) => item.clubId != controlled)) {
      expect(decision.decision.signature, baselineByClub[decision.clubId]);
    }
  });

  test('M49 player stadium choice affects the next real matchday economy', () {
    final world = const FictionalWorldFactory().build();
    const controlled = 't1_02';
    final hold = const PlayerPresidentFacilityControlCareerEngine(
      control: PlayerPresidentFacilityControlRuntimeEngine(
        provider: _HoldProvider(),
      ),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
    );
    final stadium = const PlayerPresidentFacilityControlCareerEngine(
      control: PlayerPresidentFacilityControlRuntimeEngine(
        provider: _StadiumProvider(),
      ),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
    );

    final decision = stadium.boundaries.first.decisions
        .firstWhere((item) => item.clubId == controlled);
    expect(decision.playerControlled, isTrue);
    expect(decision.decision.stadiumAppliedUpgrades, greaterThan(0));
    expect(
      stadium.boundaries.first.checkpoint.runtime.facilities
          .stadiumFor(controlled)
          .level,
      greaterThan(
        hold.boundaries.first.checkpoint.runtime.facilities
            .stadiumFor(controlled)
            .level,
      ),
    );

    final holdFinance = hold.boundaries[1].source.sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == controlled);
    final stadiumFinance = stadium.boundaries[1].source.sponsor.report.sourceReport
        .advancedTransferReport.worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == controlled);
    expect(stadiumFinance.matchdayRevenue, greaterThan(holdFinance.matchdayRevenue));
  });

  test('M49 save round trip persists the player controlled club', () {
    final world = const FictionalWorldFactory().build();
    final result = const PlayerPresidentFacilityControlCareerEngine(
      control: PlayerPresidentFacilityControlRuntimeEngine(
        provider: _AlternatingProvider(),
      ),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: 't1_02',
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final encoded = codec.encode(result.checkpoint);
    final loaded = codec.decode(encoded);

    expect(loaded.controlledClubId, 't1_02');
    expect(codec.encode(loaded), encoded);
    expect(loaded.signature, result.checkpoint.signature);
  });

  test('M49 2 plus 2 save resume matches uninterrupted four seasons', () {
    final world = const FictionalWorldFactory().build();
    const engine = PlayerPresidentFacilityControlCareerEngine(
      control: PlayerPresidentFacilityControlRuntimeEngine(
        provider: _AlternatingProvider(),
      ),
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: 't1_02',
      seasonCount: 4,
      electionInterval: 2,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: 't1_02',
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final second = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(second.checkpoint.controlledClubId, 't1_02');
  });
}

class _HoldProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _HoldProvider();

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) =>
      PlayerFacilityInvestmentChoice.hold;
}

class _StadiumProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _StadiumProvider();

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) =>
      const PlayerFacilityInvestmentChoice(stadiumUpgrades: 1);
}

class _AlternatingProvider extends PlayerFacilityInvestmentDecisionProvider {
  const _AlternatingProvider();

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    if (context.seasonIndex.isEven) {
      return const PlayerFacilityInvestmentChoice(
        academyUpgrades: 1,
        stadiumUpgrades: 1,
      );
    }
    return const PlayerFacilityInvestmentChoice(trainingGroundUpgrades: 1);
  }
}
