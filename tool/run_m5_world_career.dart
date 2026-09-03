import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const WorldCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const WorldCareerValidator().validate(report);
  final averageFee = report.totalTransfers == 0
      ? Money.zero
      : Money.fromMinorUnits(
          report.totalTransferVolume.minorUnits ~/ report.totalTransfers,
        );
  final clubById = {for (final club in report.finalClubs) club.id: club};
  final finalFinanceById = {
    for (final state in report.finalFinanceStates) state.clubId: state,
  };

  print('M5 20-season / 48-club / 3-league world career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Matches: ${report.totalMatches}');
  print('Initial players: ${report.initialPlayerCount}');
  print('Final players: ${report.finalPlayers.length}');
  print('League movements: ${report.totalMovements}');
  print('Transfers: ${report.totalTransfers}');
  print('Transfer volume: ${report.totalTransferVolume}');
  print('Average fee: $averageFee');
  print('Final total cash: ${report.finalTotalCash}');
  print('Final total debt: ${report.finalTotalDebt}');
  print('Emergency borrowing: ${report.totalEmergencyBorrowing}');
  print('Final health: ${report.finalHealthCounts}');
  print('First-tier championships:');
  final champions = report.firstTierChampions.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in champions) {
    print('  ${clubById[entry.key]?.name ?? entry.key}: ${entry.value}');
  }
  print('Final leagues:');
  for (final league in report.finalLeagues) {
    final leagueClubs = league.clubIds.map((id) => clubById[id]!).toList()
      ..sort((a, b) => b.strength.compareTo(a.strength));
    final averageStrength = leagueClubs.fold<double>(
          0,
          (sum, club) => sum + club.strength,
        ) /
        leagueClubs.length;
    var tierCash = Money.zero;
    var tierDebt = Money.zero;
    for (final clubId in league.clubIds) {
      final finance = finalFinanceById[clubId]!;
      tierCash += finance.cash;
      tierDebt += finance.debt;
    }
    print(
      '  ${league.name}: clubs=${league.clubIds.length}, '
      'avgStrength=${averageStrength.toStringAsFixed(2)}, '
      'cash=$tierCash, debt=$tierDebt',
    );
  }
  print('Validation issues: ${issues.length}');

  if (issues.isNotEmpty) {
    throw StateError('M5 validation failed: $issues');
  }
}
