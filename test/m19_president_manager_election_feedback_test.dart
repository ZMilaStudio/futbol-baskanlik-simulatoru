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
    expect(report.iterationCount, inInclusiveRange(1, 8));
    expect(report.finalReport.totalElections, 240);
    expect(report.worldChanged, isTrue);
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
