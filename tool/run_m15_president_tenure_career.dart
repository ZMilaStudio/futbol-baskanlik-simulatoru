import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentTenureCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PresidentTenureCareerValidator().validate(report);

  print('M15 20-season president tenure + turnover career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Elections: ${report.electionReport.totalElections}');
  print('Reelected: ${report.electionReport.reelections}');
  print('Lost: ${report.electionReport.losses}');
  print('President turnovers: ${report.totalTurnovers}');
  print('Unique presidents: ${report.uniquePresidents}');
  print('Clubs with turnover: ${report.clubsWithTurnover}');
  print('Repeat-turnover clubs: ${report.repeatedTurnoverClubs}');
  print('Max turnovers in one club: ${report.maximumTurnoversPerClub}');
  print(
    'Average outgoing tenure: '
    '${report.averageOutgoingTenureSeasons.toStringAsFixed(2)} seasons',
  );
  print(
    'Outgoing tenure range: '
    '${report.minimumOutgoingTenureSeasons}..${report.maximumOutgoingTenureSeasons}',
  );
  print('Validation issues: ${issues.length}');
  if (issues.isNotEmpty) {
    for (final issue in issues) {
      print('  - $issue');
    }
    throw StateError('M15 validation failed.');
  }
}
