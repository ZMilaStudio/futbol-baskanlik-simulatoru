import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M16 handover preserves club trust but normalizes personal reputation', () {
    const policy = PresidentReputationHandoverPolicy();
    const fan = FanState(
      clubId: 'club',
      sportingTrust: 72,
      financialTrust: 41,
      transferTrust: 66,
      identityTrust: 28,
    );
    const media = MediaState(clubId: 'club', credibility: 33);
    final resetFan = policy.resetFan(fan);
    final resetMedia = policy.resetMedia(media);

    expect(resetFan.sportingTrust, 72);
    expect(resetFan.financialTrust, 41);
    expect(resetFan.transferTrust, 66);
    expect(resetFan.identityTrust, 52);
    expect(resetMedia.credibility, 57);
  });

  test('M16 sequential elections use post-handover incumbent reputation', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentReputationCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PresidentReputationCareerValidator().validate(report);

    print(
      'M16_BALANCE elections=${report.totalElections} '
      'reelected=${report.reelections} lost=${report.losses} '
      'turnovers=${report.totalTurnovers} unique=${report.uniquePresidents} '
      'rate=${report.reelectionRate.toStringAsFixed(3)} '
      'media=${report.averageFinalMediaCredibility.toStringAsFixed(2)} '
      'mediaRange=${report.minimumFinalMediaCredibility}..${report.maximumFinalMediaCredibility} '
      'identity=${report.averageFinalIdentityTrust.toStringAsFixed(2)} '
      'identityRange=${report.minimumFinalIdentityTrust}..${report.maximumFinalIdentityTrust} '
      'handoverMediaDelta=${report.averageHandoverMediaDelta.toStringAsFixed(2)} '
      'handoverIdentityDelta=${report.averageHandoverIdentityDelta.toStringAsFixed(2)}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.totalElections, 240);
    expect(report.reelections, inInclusiveRange(145, 175));
    expect(report.losses, inInclusiveRange(65, 95));
    expect(report.totalTurnovers, report.losses);
    expect(report.handovers.length, report.losses);
    expect(report.uniquePresidents, 48 + report.losses);
    expect(report.reelectionRate, inInclusiveRange(0.60, 0.75));
    expect(report.averageFinalMediaCredibility, inInclusiveRange(65, 80));
    expect(report.minimumFinalMediaCredibility, inInclusiveRange(45, 65));
    expect(report.maximumFinalMediaCredibility, inInclusiveRange(85, 95));
    expect(report.averageFinalIdentityTrust, inInclusiveRange(58, 72));
    expect(report.minimumFinalIdentityTrust, inInclusiveRange(48, 62));
    expect(report.maximumFinalIdentityTrust, inInclusiveRange(75, 90));
    expect(report.averageHandoverMediaDelta, inInclusiveRange(-3, 3));
    expect(report.averageHandoverIdentityDelta, inInclusiveRange(0.5, 5));
    expect(
      report.finalMediaStates.every(
        (item) => item.credibility >= 0 && item.credibility <= 100,
      ),
      isTrue,
    );
    expect(
      report.finalFanStates.every(
        (item) => item.identityTrust >= 0 && item.identityTrust <= 100,
      ),
      isTrue,
    );
  });

  test('M16 is deterministic and remains on the same advanced world', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentReputationCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 16101),
      seasonCount: 8,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 16101),
      seasonCount: 8,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 16102),
      seasonCount: 8,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(
      first.fanTemplateReport.advancedTransferReport.signature,
      first.sourceReport.advancedTransferReport.signature,
    );
  });

  test('M16 schedules election and reputation handover from a custom season index', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentReputationCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 16150, seasonIndex: 7),
      seasonCount: 5,
    );
    final issues = const PresidentReputationCareerValidator().validate(report);

    expect(issues, isEmpty);
    expect(report.totalElections, 48);
    expect(
      report.elections.every((election) => election.seasonIndex == 10),
      isTrue,
    );
    expect(
      report.handovers.every(
        (handover) =>
            handover.electionSeasonIndex == 10 &&
            handover.effectiveSeasonIndex == 11,
      ),
      isTrue,
    );
  });
}
