import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/president_facility_investment_runtime_integration.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const codec = FacilitySponsorCrisisRuntimeSaveCodec();
  const m47 = FacilitySponsorCrisisRuntimeCareerEngine();
  const runtime = PresidentFacilityInvestmentRuntimeCareerEngine();

  final direct = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 4,
    electionInterval: 2,
  );
  final first = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
    hasFutureSeasonAfterReport: true,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final resumed = runtime.resume(checkpoint: loaded, seasonCount: 2);
  final splitBoundaries = [...first.boundaries, ...resumed.boundaries];

  final saveResumeMatch =
      codec.encode(resumed.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch = _listEquals(
    splitBoundaries.map((item) => item.signature).toList(),
    direct.boundaries.map((item) => item.signature).toList(),
  );
  final preparedBoundaries =
      direct.boundaries.where((item) => item.preparedNextSeason).toList();
  final decisionCount = preparedBoundaries.fold<int>(
    0,
    (sum, item) => sum + item.decisions.length,
  );
  final academyUpgrades = preparedBoundaries
      .expand((item) => item.decisions)
      .fold<int>(0, (sum, item) => sum + item.academyAppliedUpgrades);
  final trainingUpgrades = preparedBoundaries
      .expand((item) => item.decisions)
      .fold<int>(0, (sum, item) => sum + item.trainingGroundAppliedUpgrades);
  final stadiumUpgrades = preparedBoundaries
      .expand((item) => item.decisions)
      .fold<int>(0, (sum, item) => sum + item.stadiumAppliedUpgrades);
  final investmentActive = direct.totalFacilityInvestmentSpend > Money.zero &&
      direct.investedClubWindows > 0 &&
      academyUpgrades + trainingUpgrades + stadiumUpgrades > 0;

  final currentPresidentMatch = preparedBoundaries.every((boundary) {
    final currentByClub = {
      for (final state
          in boundary.source.checkpoint.runtime.domain.presidentRuntime.clubs)
        state.clubId: state.managementProfile.presidentId,
    };
    return boundary.decisions.every(
      (decision) => decision.presidentId == currentByClub[decision.clubId],
    );
  });

  final sponsorStatePreserved = preparedBoundaries.every(
    (boundary) =>
        boundary.source.checkpoint.runtime.sponsor.signature ==
        boundary.checkpoint.runtime.sponsor.signature,
  );
  final debtPreserved = preparedBoundaries.every((boundary) {
    final before = {
      for (final state in boundary.source.checkpoint.runtime.domain
          .presidentRuntime.runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final after = {
      for (final state in boundary.checkpoint.runtime.domain.presidentRuntime
          .runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    return before.keys.every((clubId) => before[clubId]!.debt == after[clubId]!.debt);
  });
  final cashSpendMatches = preparedBoundaries.every((boundary) {
    final before = {
      for (final state in boundary.source.checkpoint.runtime.domain
          .presidentRuntime.runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    final after = {
      for (final state in boundary.checkpoint.runtime.domain.presidentRuntime
          .runtime.runtime.world.nextSeasonFinanceStates)
        state.clubId: state,
    };
    return boundary.decisions.every(
      (decision) =>
          before[decision.clubId]!.cash - after[decision.clubId]!.cash ==
          decision.spend,
    );
  });

  final finalSeasonNoInvestment = !direct.boundaries.last.preparedNextSeason &&
      direct.boundaries.last.decisions.isEmpty;
  final oneSeasonM47 = m47.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 1,
  );
  final oneSeasonM48 = runtime.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 1,
  );
  final finalSeasonM47Parity =
      codec.encode(oneSeasonM47.checkpoint) == codec.encode(oneSeasonM48.checkpoint);

  final firstStadiumDecision = direct.boundaries.first.decisions.firstWhere(
    (decision) => decision.stadiumAppliedUpgrades > 0,
  );
  final target = firstStadiumDecision.clubId;
  final baseline = m47.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
    electionInterval: 2,
  );
  final baselineFinance = baseline.boundaries[1].sponsor.report.sourceReport
      .advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == target);
  final integratedFinance = direct.boundaries[1].source.sponsor.report.sourceReport
      .advancedTransferReport.worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == target);
  final stadiumEffect =
      integratedFinance.matchdayRevenue > baselineFinance.matchdayRevenue;

  final saveBytes = codec.encode(direct.checkpoint).length;
  print('M48_PRESIDENT_FACILITY_RUNTIME seasons=${direct.boundaries.length}');
  print('M48_PRESIDENT_FACILITY_RUNTIME prepared=${preparedBoundaries.length}');
  print('M48_PRESIDENT_FACILITY_RUNTIME decisions=$decisionCount');
  print(
    'M48_PRESIDENT_FACILITY_RUNTIME upgrades='
    '$academyUpgrades/$trainingUpgrades/$stadiumUpgrades',
  );
  print(
    'M48_PRESIDENT_FACILITY_RUNTIME spend='
    '${direct.totalFacilityInvestmentSpend.units.toStringAsFixed(2)}',
  );
  print('M48_PRESIDENT_FACILITY_RUNTIME investedWindows=${direct.investedClubWindows}');
  print('M48_PRESIDENT_FACILITY_RUNTIME stadiumTarget=$target');
  print(
    'M48_PRESIDENT_FACILITY_RUNTIME matchday='
    '${baselineFinance.matchdayRevenue.units.toStringAsFixed(2)}>'
    '${integratedFinance.matchdayRevenue.units.toStringAsFixed(2)}',
  );
  print('M48_PRESIDENT_FACILITY_RUNTIME currentPresidentMatch=$currentPresidentMatch');
  print('M48_PRESIDENT_FACILITY_RUNTIME sponsorStatePreserved=$sponsorStatePreserved');
  print('M48_PRESIDENT_FACILITY_RUNTIME debtPreserved=$debtPreserved');
  print('M48_PRESIDENT_FACILITY_RUNTIME cashSpendMatches=$cashSpendMatches');
  print('M48_PRESIDENT_FACILITY_RUNTIME investmentActive=$investmentActive');
  print('M48_PRESIDENT_FACILITY_RUNTIME stadiumEffect=$stadiumEffect');
  print('M48_PRESIDENT_FACILITY_RUNTIME finalSeasonNoInvestment=$finalSeasonNoInvestment');
  print('M48_PRESIDENT_FACILITY_RUNTIME finalSeasonM47Parity=$finalSeasonM47Parity');
  print('M48_PRESIDENT_FACILITY_RUNTIME saveResumeMatch=$saveResumeMatch');
  print('M48_PRESIDENT_FACILITY_RUNTIME boundaryMatch=$boundaryMatch');
  print('M48_PRESIDENT_FACILITY_RUNTIME saveBytes=$saveBytes');

  if (preparedBoundaries.length != 3 ||
      decisionCount != 3 * world.clubs.length ||
      !currentPresidentMatch ||
      !sponsorStatePreserved ||
      !debtPreserved ||
      !cashSpendMatches ||
      !investmentActive ||
      !stadiumEffect ||
      !finalSeasonNoInvestment ||
      !finalSeasonM47Parity ||
      !saveResumeMatch ||
      !boundaryMatch) {
    throw StateError('M48 president facility investment runtime gate failed.');
  }

  print('M48_PRESIDENT_FACILITY_RUNTIME PASS');
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
