import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/president_facility_investment_runtime_integration.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const controlled = 't1_02';
  const m48 = PresidentFacilityInvestmentRuntimeCareerEngine();
  const codec = PlayerPresidentFacilityControlSaveCodec();

  final baseline = m48.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
  );
  final neutral = const PlayerPresidentFacilityControlCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final neutralParity =
      neutral.checkpoint.runtime.signature == baseline.checkpoint.signature &&
          neutral.boundaries[0].checkpoint.runtime.signature ==
              baseline.boundaries[0].checkpoint.signature &&
          neutral.boundaries[1].checkpoint.runtime.signature ==
              baseline.boundaries[1].checkpoint.signature;

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

  final holdDecision = hold.boundaries.first.decisions
      .firstWhere((item) => item.clubId == controlled);
  final stadiumDecision = stadium.boundaries.first.decisions
      .firstWhere((item) => item.clubId == controlled);
  final aiBaselineByClub = {
    for (final decision in baseline.boundaries.first.decisions)
      decision.clubId: decision.signature,
  };
  final aiParityCount = hold.boundaries.first.decisions
      .where((item) => item.clubId != controlled)
      .where((item) => item.decision.signature == aiBaselineByClub[item.clubId])
      .length;

  final holdFinance = hold.boundaries[1].source.sponsor.report.sourceReport
      .advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == controlled);
  final stadiumFinance = stadium.boundaries[1].source.sponsor.report.sourceReport
      .advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == controlled);
  final stadiumEffect =
      stadiumFinance.matchdayRevenue > holdFinance.matchdayRevenue;

  final openingFinance = stadium.boundaries.first.source.checkpoint.runtime.domain
      .presidentRuntime.runtime.runtime.world.nextSeasonFinanceStates
      .firstWhere((item) => item.clubId == controlled);
  final investedFinance = stadium.boundaries.first.checkpoint.runtime.runtime.domain
      .presidentRuntime.runtime.runtime.world.nextSeasonFinanceStates
      .firstWhere((item) => item.clubId == controlled);
  final debtPreserved = investedFinance.debt == openingFinance.debt;
  final cashSpendMatches =
      openingFinance.cash - investedFinance.cash == stadiumDecision.spend;

  const parityEngine = PlayerPresidentFacilityControlCareerEngine(
    control: PlayerPresidentFacilityControlRuntimeEngine(
      provider: _AlternatingProvider(),
    ),
  );
  final direct = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 4,
    electionInterval: 2,
  );
  final first = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
    electionInterval: 2,
    hasFutureSeasonAfterReport: true,
  );
  final encoded = codec.encode(first.checkpoint);
  final loaded = codec.decode(encoded);
  final second = parityEngine.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );
  final finalCheckpointMatch =
      codec.encode(second.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch =
      [...first.boundaries, ...second.boundaries]
              .map((item) => item.signature)
              .join('||') ==
          direct.boundaries.map((item) => item.signature).join('||');
  final controlledClubPersisted = loaded.controlledClubId == controlled &&
      second.checkpoint.controlledClubId == controlled;

  final playerWindows = direct.boundaries
      .where((item) => item.preparedNextSeason)
      .where((item) => item.decisions.any((decision) => decision.playerControlled))
      .length;
  final playerSpend = direct.boundaries.fold<Money>(
    Money.zero,
    (sum, boundary) =>
        sum +
        boundary.decisions
            .where((decision) => decision.playerControlled)
            .fold<Money>(Money.zero, (inner, item) => inner + item.spend),
  );

  if (!neutralParity) {
    throw StateError('M49 no-provider path must preserve M48 exactly.');
  }
  if (!holdDecision.playerControlled || holdDecision.spend != Money.zero) {
    throw StateError('M49 hold choice must control exactly one club and spend zero.');
  }
  if (aiParityCount != world.clubs.length - 1) {
    throw StateError('M49 must preserve M48 AI decisions for the other 47 clubs.');
  }
  if (!stadiumDecision.playerControlled ||
      stadiumDecision.decision.stadiumAppliedUpgrades <= 0 ||
      !stadiumEffect) {
    throw StateError('M49 stadium choice must affect the next real matchday economy.');
  }
  if (!debtPreserved || !cashSpendMatches) {
    throw StateError('M49 player facility spending must use real cash without hidden debt.');
  }
  if (!controlledClubPersisted || !finalCheckpointMatch || !boundaryMatch) {
    throw StateError('M49 save/resume parity failed.');
  }
  if (playerWindows != 3 || playerSpend <= Money.zero) {
    throw StateError('M49 canonical player decisions must stay active across future boundaries.');
  }

  print('M49_PLAYER_FACILITY_CONTROL_PASS');
  print('seed=$seed');
  print('controlledClub=$controlled');
  print('aiParityCount=$aiParityCount');
  print('playerWindows=$playerWindows');
  print('playerSpend=${playerSpend.minorUnits}');
  print('holdSpend=${holdDecision.spend.minorUnits}');
  print('stadiumUpgrades=${stadiumDecision.decision.stadiumAppliedUpgrades}');
  print('matchdayRevenue=${holdFinance.matchdayRevenue.minorUnits}->${stadiumFinance.matchdayRevenue.minorUnits}');
  print('neutralM48Parity=$neutralParity');
  print('debtPreserved=$debtPreserved');
  print('cashSpendMatches=$cashSpendMatches');
  print('controlledClubPersisted=$controlledClubPersisted');
  print('finalCheckpointMatch=$finalCheckpointMatch');
  print('boundaryMatch=$boundaryMatch');
  print('saveBytes=${encoded.length}');
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
