import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M15 president identities are deterministic and election-specific', () {
    const generator = PresidentProfileGenerator();
    final initial = generator.generateInitial(
      clubId: 'club',
      careerSeed: 1501,
      simulationVersion: 1,
    );
    final repeat = generator.generateInitial(
      clubId: 'club',
      careerSeed: 1501,
      simulationVersion: 1,
    );
    final challenger = generator.generateChallenger(
      clubId: 'club',
      seasonIndex: 3,
      electionTermNumber: 1,
      careerSeed: 1501,
      simulationVersion: 1,
    );

    expect(initial.signature, repeat.signature);
    expect(initial.id, isNot(challenger.id));
    expect(initial.name, isNotEmpty);
    expect(challenger.name, isNotEmpty);
  });

  test('M15 turns every election loss into one real president handover', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentTenureCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const PresidentTenureCareerValidator().validate(report);

    print(
      'M15_BALANCE elections=${report.electionReport.totalElections} '
      'reelected=${report.electionReport.reelections} '
      'lost=${report.electionReport.losses} '
      'turnovers=${report.totalTurnovers} '
      'uniquePresidents=${report.uniquePresidents} '
      'clubsChanged=${report.clubsWithTurnover} '
      'repeatClubs=${report.repeatedTurnoverClubs} '
      'maxTurnovers=${report.maximumTurnoversPerClub} '
      'avgOutgoingTenure=${report.averageOutgoingTenureSeasons.toStringAsFixed(2)} '
      'tenureRange=${report.minimumOutgoingTenureSeasons}..${report.maximumOutgoingTenureSeasons}',
    );

    expect(issues, isEmpty);
    expect(report.seasonCount, 20);
    expect(report.electionReport.totalElections, 240);
    expect(report.electionReport.reelections, 158);
    expect(report.electionReport.losses, 82);
    expect(report.totalTurnovers, 82);
    expect(report.recordedReelections, 158);
    expect(report.initialStates, hasLength(48));
    expect(report.finalStates, hasLength(48));
    expect(report.uniquePresidents, 130);
    expect(report.clubsWithTurnover, inInclusiveRange(32, 39));
    expect(report.repeatedTurnoverClubs, inInclusiveRange(20, 29));
    expect(report.maximumTurnoversPerClub, inInclusiveRange(4, 5));
    expect(report.averageOutgoingTenureSeasons, inInclusiveRange(6, 8));
    expect(report.minimumOutgoingTenureSeasons, 4);
    expect(report.maximumOutgoingTenureSeasons, inInclusiveRange(16, 20));
  });

  test('M15 is deterministic and does not alter the M14 election world', () {
    final world = const FictionalWorldFactory().build();
    const engine = PresidentTenureCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 15101),
      seasonCount: 8,
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 15101),
      seasonCount: 8,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 15102),
      seasonCount: 8,
    );

    expect(first.signature, repeat.signature);
    expect(first.signature, isNot(equals(different.signature)));
    expect(
      const PresidentTenureCareerValidator().validate(first),
      isEmpty,
    );
    expect(first.totalTurnovers, first.electionReport.losses);
  });

  test('M15 respects custom career season indices during handover', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentTenureCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 15150, seasonIndex: 7),
      seasonCount: 5,
    );
    final issues = const PresidentTenureCareerValidator().validate(report);

    expect(issues, isEmpty);
    expect(report.initialStates.every((state) => state.startedSeasonIndex == 7), isTrue);
    expect(report.electionReport.totalElections, 48);
    expect(
      report.turnovers.every(
        (event) =>
            event.electionSeasonIndex == 10 &&
            event.effectiveSeasonIndex == 11 &&
            event.outgoingTenureSeasons == 4,
      ),
      isTrue,
    );
    expect(
      report.finalStates.every(
        (state) => state.startedSeasonIndex == 7 || state.startedSeasonIndex == 11,
      ),
      isTrue,
    );
  });
}
