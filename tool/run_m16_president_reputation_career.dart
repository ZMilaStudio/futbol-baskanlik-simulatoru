import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final report = const PresidentReputationCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: SimulationConfig(careerSeed: seed),
  );
  final issues = const PresidentReputationCareerValidator().validate(report);

  print('M16 20-season president reputation handover career');
  print('Seed: $seed');
  print('Seasons: ${report.seasonCount}');
  print('Elections: ${report.totalElections}');
  print('Reelected: ${report.reelections}');
  print('Lost / turnovers: ${report.losses} / ${report.totalTurnovers}');
  print('Unique presidents: ${report.uniquePresidents}');
  print('Reelection rate: ${(report.reelectionRate * 100).toStringAsFixed(1)}%');
  print('Final media credibility: ${report.averageFinalMediaCredibility.toStringAsFixed(2)}');
  print('Media range: ${report.minimumFinalMediaCredibility}..${report.maximumFinalMediaCredibility}');
  print('Final identity trust: ${report.averageFinalIdentityTrust.toStringAsFixed(2)}');
  print('Identity range: ${report.minimumFinalIdentityTrust}..${report.maximumFinalIdentityTrust}');
  print('Avg handover media delta: ${report.averageHandoverMediaDelta.toStringAsFixed(2)}');
  print('Avg handover identity delta: ${report.averageHandoverIdentityDelta.toStringAsFixed(2)}');
  print('Validation issues: ${issues.length}');
  if (issues.isNotEmpty) {
    for (final issue in issues) {
      print('  - $issue');
    }
    throw StateError('M16 validation failed.');
  }
}
