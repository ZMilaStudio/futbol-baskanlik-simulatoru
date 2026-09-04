import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M14 approval weights reputation dimensions without a single-metric veto', () {
    const engine = PresidentElectionEngine();
    final balanced = engine.evaluate(
      clubId: 'club',
      seasonIndex: 3,
      termNumber: 1,
      fanOverallTrust: 70,
      fanIdentityTrust: 80,
      mediaCredibility: 60,
      promiseScore: 50,
      careerSeed: 1401,
      simulationVersion: 1,
    );
    final weakPromises = engine.evaluate(
      clubId: 'club',
      seasonIndex: 3,
      termNumber: 1,
      fanOverallTrust: 70,
      fanIdentityTrust: 80,
      mediaCredibility: 60,
      promiseScore: 10,
      careerSeed: 1401,
      simulationVersion: 1,
    );

    expect(balanced.approval, 64);
    expect(weakPromises.approval, 54);
    expect(balanced.contributions, hasLength(4));
    expect(
      balanced.contributions.fold<int>(0, (sum, item) => sum + item.weightBps),
      10000,
    );
    expect(balanced.challengerStrength, inInclusiveRange(42, 78));
  });

  test('M14 simulates deterministic four-season presidential elections', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentElectionCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PresidentElectionCareerValidator().validate(report);

    print(
      'M14_BALANCE elections=${report.totalElections} '
      'reelected=${report.reelections} '
      'lost=${report.losses} '
      'rate=${report.reelectionRate.toStringAsFixed(3)} '
      'approval=${report.averageApproval.toStringAsFixed(2)} '
      'challenger=${report.averageChallengerStrength.toStringAsFixed(2)} '
      'range=${report.minimumApproval}..${report.maximumApproval} '
      'competitive=${report.competitiveElections} '
      'landslideWins=${report.landslideReelections} '
      'landslideLosses=${report.landslideLosses} '
      'boundary=${report.boundaryApprovals}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.electionInterval, 4);
    expect(report.totalElections, 240);
    expect(report.reelections, greaterThan(60));
    expect(report.losses, greaterThan(30));
    expect(report.averageApproval, inInclusiveRange(45, 80));
    expect(report.averageChallengerStrength, inInclusiveRange(45, 75));
    expect(report.minimumApproval, inInclusiveRange(10, 70));
    expect(report.maximumApproval, inInclusiveRange(55, 95));
    expect(report.competitiveElections, greaterThan(20));
    expect(report.boundaryApprovals, lessThanOrEqualTo(2));
  });

  test('M14 is deterministic and election reputation shares one advanced world', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentElectionCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 14101),
      seasonCount: 8,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 14101),
      seasonCount: 8,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 14102),
      seasonCount: 8,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(first.totalElections, 96);
    expect(
      first.fanReport.advancedTransferReport.signature,
      first.reputationReport.advancedTransferReport.signature,
    );
    expect(
      first.reputationReport.promiseReport.advancedTransferReport.signature,
      first.reputationReport.advancedTransferReport.signature,
    );
  });
}
