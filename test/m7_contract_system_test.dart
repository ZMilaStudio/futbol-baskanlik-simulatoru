import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('contract term materially affects player market value', () {
    const player = Player(
      id: 'contract_value_player',
      name: 'Test Oyuncu',
      clubId: 'club_a',
      position: PlayerPosition.midfielder,
      age: 24,
      ability: 74,
      potential: 82,
      retirementAge: 36,
      isAcademyGraduate: false,
    );
    const model = MarketValueModel();

    final legacy = model.value(player);
    final oneYear = model.value(player, contractYearsRemaining: 1);
    final fourYears = model.value(player, contractYearsRemaining: 4);

    expect(oneYear, lessThan(legacy));
    expect(fourYears, greaterThan(legacy));
    expect(fourYears, greaterThan(oneYear));
  });

  test('M7 simulates a valid deterministic 20-season contract career', () {
    final world = const FictionalWorldFactory().build();
    const engine = ContractWorldCareerEngine();
    final report = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final repeat = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final issues = const ContractCareerValidator().validate(report);

    print(
      'M7_BALANCE contracts=${report.activeContracts.length} '
      'renewals=${report.renewals} releases=${report.releases} '
      'freeSignings=${report.freeAgentSignings} '
      'freeAgents=${report.finalFreeAgents} '
      'youthContracts=${report.youthContracts} '
      'transferContracts=${report.transferContracts} '
      'wageBill=${report.finalAnnualWageBill} '
      'avgWage=${report.averageFinalAnnualWage.toStringAsFixed(0)} '
      'transfers=${report.worldReport.totalTransfers} '
      'cash=${report.worldReport.finalTotalCash} '
      'debt=${report.worldReport.finalTotalDebt}',
    );

    expect(issues, isEmpty);
    expect(report.signature, repeat.signature);
    expect(report.worldReport.seasonCount, 20);
    expect(report.worldReport.totalMatches, 14400);
    expect(report.initialContracts, 864);
    expect(report.youthContracts, 19 * 48);
    expect(report.transferContracts, report.worldReport.totalTransfers);
    expect(
      report.activeContracts.length,
      report.worldReport.finalPlayers.length - report.finalFreeAgents,
    );

    // Broad regression guards: these deliberately allow later balancing work
    // while preventing a frozen or exploding contract/free-agent economy.
    expect(report.renewals, inInclusiveRange(1500, 7000));
    expect(report.releases, inInclusiveRange(300, 2500));
    expect(report.freeAgentSignings, inInclusiveRange(200, 2000));
    expect(report.finalFreeAgents, inInclusiveRange(5, 100));
    expect(report.worldReport.totalTransfers, inInclusiveRange(40, 300));
    expect(
      report.finalAnnualWageBill,
      greaterThanOrEqualTo(const Money.fromUnits(200000000)),
    );
    expect(
      report.finalAnnualWageBill,
      lessThanOrEqualTo(const Money.fromUnits(900000000)),
    );
    expect(
      report.worldReport.finalTotalCash,
      inInclusiveRange(
        const Money.fromUnits(100000000),
        const Money.fromUnits(2000000000),
      ),
    );
    expect(
      report.worldReport.finalTotalDebt,
      inInclusiveRange(
        const Money.fromUnits(100000000),
        const Money.fromUnits(2000000000),
      ),
    );
  });

  test('M7 different seeds diverge', () {
    final world = const FictionalWorldFactory().build();
    const engine = ContractWorldCareerEngine();
    final first = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 7101),
      seasonCount: 3,
    );
    final different = engine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 7102),
      seasonCount: 3,
    );

    expect(first.signature, isNot(equals(different.signature)));
  });

  test('manager and contract hooks coexist on the same world engine', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 7611);
    final managerController = ManagerCareerController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: config.seasonIndex,
    );
    const contractEngine = ContractWorldCareerEngine();
    final report = contractEngine.simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
      hooks: managerController,
    );

    expect(managerController.seasons.length, 3);
    expect(const ContractCareerValidator().validate(report), isEmpty);
  });
}
