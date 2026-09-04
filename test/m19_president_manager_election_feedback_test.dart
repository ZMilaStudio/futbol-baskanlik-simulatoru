import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/election/president_manager_election_feedback_engine.dart';
import 'package:futbol_baskanlik_m0/src/election/president_manager_election_feedback_validator.dart';
import 'package:test/test.dart';

void main() {
  test('M19 closes manager patience back into presidential elections', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentManagerElectionFeedbackEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      maxIterations: 8,
    );
    final issues = const PresidentManagerElectionFeedbackValidator().validate(report);

    print(
      'M19_BALANCE iterations=${report.iterationCount} '
      'converged=${report.converged} cycle=${report.cycleDetected} '
      'elections=${report.finalReport.totalElections} '
      'baselineReelected=${report.baselineReelections} '
      'finalReelected=${report.finalReelections} '
      'baselineLost=${report.baselineLosses} finalLost=${report.finalLosses} '
      'electionDiff=${report.electionOutcomeDifferences} '
      'turnoverDiff=${report.turnoverDifferenceCount} '
      'baselineManagers=${report.baselineManagerChanges} '
      'finalManagers=${report.finalManagerChanges} '
      'managerDelta=${report.managerChangeDelta} '
      'baselineTransfers=${report.baselineTransfers} '
      'finalTransfers=${report.finalTransfers} '
      'transferDelta=${report.transferDelta} '
      'uniquePresidents=${report.uniqueFinalPresidents} '
      'worldChanged=${report.worldChanged}',
    );
    final iterationSummary = report.iterations
        .map(
          (item) => 'i${item.iteration}['
              'changed=${item.timelineChanged},manager=${item.managerChanges},'
              'transfers=${item.transfers},reelected=${item.reelections},'
              'lost=${item.losses},electionDiff=${item.electionOutcomeDifferences}]',
        )
        .join(' ');
    print('M19_ITERATIONS $iterationSummary');

    expect(issues, isEmpty);
    expect(report.converged, isTrue);
    expect(report.cycleDetected, isFalse);
    expect(report.iterationCount, inInclusiveRange(2, 6));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 161);
    expect(report.baselineLosses, 79);
    expect(report.baselineManagerChanges, 81);
    expect(report.baselineTransfers, 173);
    expect(report.iterations.first.managerChanges, 88);
    expect(report.iterations.first.transfers, 153);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);
    expect(report.electionOutcomeDifferences, inInclusiveRange(25, 90));
    expect(report.finalReelections, inInclusiveRange(140, 175));
    expect(report.finalLosses, inInclusiveRange(65, 100));
    expect(report.finalManagerChanges, inInclusiveRange(75, 100));
    expect(report.managerChangeDelta.abs(), lessThanOrEqualTo(25));
    expect(report.finalTransfers, inInclusiveRange(130, 210));
    expect(report.transferDelta.abs(), lessThanOrEqualTo(60));
    expect(report.uniqueFinalPresidents, inInclusiveRange(110, 145));
    expect(report.worldChanged, isTrue);
  });

  test('M19 feedback converges across representative career seeds', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentManagerElectionFeedbackEngine();
    for (final seed in const [19011, 19012, 19013]) {
      final report = engine.simulate(
        clubs: world.clubs,
        leagues: world.leagues,
        config: SimulationConfig(careerSeed: seed),
        seasonCount: 8,
        maxIterations: 8,
      );
      expect(report.converged, isTrue, reason: 'seed=$seed');
      expect(report.cycleDetected, isFalse, reason: 'seed=$seed');
      expect(report.iterationCount, inInclusiveRange(1, 8), reason: 'seed=$seed');
    }
  });

  test('M19 feedback is deterministic and seed-sensitive', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentManagerElectionFeedbackEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 19001),
      seasonCount: 4,
      maxIterations: 6,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 19001),
      seasonCount: 4,
      maxIterations: 6,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 19002),
      seasonCount: 4,
      maxIterations: 6,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
  });
}
