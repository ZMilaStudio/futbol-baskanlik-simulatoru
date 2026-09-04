import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentElectionCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PresidentElectionCareerValidator().validate(report);

  print('M14 20-season presidential election career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Election interval: ${report.electionInterval}');
  print('Elections: ${report.totalElections}');
  print('Reelected: ${report.reelections}');
  print('Lost: ${report.losses}');
  print('Reelection rate: ${(report.reelectionRate * 100).toStringAsFixed(1)}%');
  print('Average approval: ${report.averageApproval.toStringAsFixed(2)}');
  print(
    'Average challenger strength: '
    '${report.averageChallengerStrength.toStringAsFixed(2)}',
  );
  print('Approval range: ${report.minimumApproval}..${report.maximumApproval}');
  print('Competitive elections: ${report.competitiveElections}');
  print('Landslide reelections: ${report.landslideReelections}');
  print('Landslide losses: ${report.landslideLosses}');
  print('Boundary approvals: ${report.boundaryApprovals}');
  print('Validation issues: ${issues.length}');
  for (final issue in issues) {
    print('  - $issue');
  }
}
