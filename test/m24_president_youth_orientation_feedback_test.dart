import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  test('M24 youth orientation scales youth preference monotonically', () {
    const policy = PresidentYouthOrientationTransferPolicy();
    final low = policy.forYouthOrientation(20);
    final neutral = policy.forYouthOrientation(60);
    final high = policy.forYouthOrientation(90);

    expect(low.youthSignalScaleBps, 6000);
    expect(neutral.youthSignalScaleBps, 10000);
    expect(high.youthSignalScaleBps, 13000);
    expect(
      neutral.youthSignalScaleBps,
      TransferYouthPreferencePolicy.neutral.youthSignalScaleBps,
    );
    expect(low.applyYouthSignal(10), lessThan(neutral.applyYouthSignal(10)));
    expect(high.applyYouthSignal(10), greaterThan(neutral.applyYouthSignal(10)));
  });

  test('M24 youth orientation changes the first real transfer candidate', () {
    const buyer = Club(id: 'a_buyer', name: 'Buyer', strength: 65);
    const seller = Club(id: 'z_seller', name: 'Seller', strength: 70);
    final players = <Player>[
      for (var i = 0; i < 2; i++)
        _player('buyer_gk_$i', buyer.id, PlayerPosition.goalkeeper, 65),
      for (var i = 0; i < 6; i++)
        _player('buyer_def_$i', buyer.id, PlayerPosition.defender, 65),
      for (var i = 0; i < 6; i++)
        _player('buyer_mid_$i', buyer.id, PlayerPosition.midfielder, 65),
      const Player(
        id: 'ready_forward',
        name: 'Ready Forward',
        clubId: 'z_seller',
        position: PlayerPosition.forward,
        age: 27,
        ability: 79,
        potential: 79,
        retirementAge: 36,
        isAcademyGraduate: false,
      ),
      const Player(
        id: 'young_forward',
        name: 'Young Forward',
        clubId: 'z_seller',
        position: PlayerPosition.forward,
        age: 20,
        ability: 72,
        potential: 92,
        retirementAge: 36,
        isAcademyGraduate: false,
      ),
      for (var i = 0; i < 3; i++)
        _player('seller_fwd_$i', seller.id, PlayerPosition.forward, 50),
      for (var i = 0; i < 2; i++)
        _player('seller_gk_$i', seller.id, PlayerPosition.goalkeeper, 65),
      for (var i = 0; i < 5; i++)
        _player('seller_def_$i', seller.id, PlayerPosition.defender, 65),
      for (var i = 0; i < 4; i++)
        _player('seller_mid_$i', seller.id, PlayerPosition.midfielder, 65),
    ];
    const finances = [
      ClubFinanceState(
        clubId: 'a_buyer',
        cash: Money.fromUnits(500000000),
        debt: Money.zero,
      ),
      ClubFinanceState(
        clubId: 'z_seller',
        cash: Money.fromUnits(100000000),
        debt: Money.zero,
      ),
    ];
    const orientationPolicy = PresidentYouthOrientationTransferPolicy();

    final low = const TransferMarketEngine().simulateWindow(
      clubs: const [buyer, seller],
      players: players,
      financeStates: finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
      youthPreferencePoliciesByClub: {
        buyer.id: orientationPolicy.forYouthOrientation(20),
      },
    );
    final high = const TransferMarketEngine().simulateWindow(
      clubs: const [buyer, seller],
      players: players,
      financeStates: finances,
      careerSeed: 24001,
      seasonIndex: 0,
      simulationVersion: 1,
      youthPreferencePoliciesByClub: {
        buyer.id: orientationPolicy.forYouthOrientation(90),
      },
    );

    expect(low.deals, isNotEmpty);
    expect(high.deals, isNotEmpty);
    expect(low.deals.first.toClubId, buyer.id);
    expect(high.deals.first.toClubId, buyer.id);
    expect(low.deals.first.playerId, 'ready_forward');
    expect(high.deals.first.playerId, 'young_forward');
  });

  test('M24 neutral youth preference preserves the old advanced world', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20260903);
    final baseline = const AdvancedTransferWorldCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
    );
    final neutral = AdvancedTransferWorldCareerEngine(
      worldEngine: WorldCareerEngine(
        transferMarketEngine: TransferMarketEngine(
          youthPreferencePolicyProvider: (_, __) =>
              TransferYouthPreferencePolicy.neutral,
        ),
      ),
    ).simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
    );

    expect(neutral.signature, baseline.signature);
  });

  test('M24 closes youth orientation into the M23 feedback world', () {
    final world = const FictionalWorldFactory().build();
    final report = const PresidentYouthOrientationFeedbackEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      maxIterations: 8,
    );
    final issues =
        const PresidentYouthOrientationFeedbackValidator().validate(report);

    print(
      'M24_BALANCE iterations=${report.iterationCount} '
      'converged=${report.converged} cycle=${report.cycleDetected} '
      'elections=${report.finalReport.totalElections} '
      'reelected=${report.baselineReelections}->${report.finalReelections} '
      'lost=${report.baselineLosses}->${report.finalLosses} '
      'electionDiff=${report.electionOutcomeDifferences} '
      'managers=${report.baselineManagerChanges}->${report.finalManagerChanges} '
      'transfers=${report.baselineTransfers}->${report.finalTransfers} '
      'volume=${report.baselineTransferVolume}->${report.finalTransferVolume} '
      'installmentDeals=${report.baselineInstallmentDeals}->${report.finalInstallmentDeals} '
      'commitment=${report.baselineInstallmentCommitment}->${report.finalInstallmentCommitment} '
      'cash=${report.baselineFinalCash}->${report.finalCash} '
      'debt=${report.baselineFinalDebt}->${report.finalDebt} '
      'emergency=${report.baselineEmergencyBorrowing}->${report.finalEmergencyBorrowing} '
      'uniquePresidents=${report.uniqueFinalPresidents} '
      'worldChanged=${report.worldChanged}',
    );
    print(
      'M24_ITERATIONS ${report.iterations.map((item) => 'i${item.iteration}['
          'changed=${item.timelineChanged},manager=${item.managerChanges},'
          'transfers=${item.transfers},volume=${item.transferVolume},'
          'reelected=${item.reelections},lost=${item.losses},'
          'electionDiff=${item.electionOutcomeDifferences}]').join(' ')}',
    );

    expect(issues, isEmpty);
    expect(report.converged, isTrue);
    expect(report.cycleDetected, isFalse);
    expect(report.iterationCount, inInclusiveRange(3, 6));
    expect(report.finalReport.totalElections, 240);
    expect(report.baselineReelections, 156);
    expect(report.baselineLosses, 84);
    expect(report.baselineManagerChanges, 85);
    expect(report.baselineTransfers, 133);
    expect(report.iterations.last.timelineChanged, isFalse);
    expect(report.iterations.last.electionOutcomeDifferences, 0);
    expect(report.electionOutcomeDifferences, inInclusiveRange(25, 75));
    expect(report.finalReelections, inInclusiveRange(145, 170));
    expect(report.finalLosses, inInclusiveRange(70, 95));
    expect(report.finalTransfers, inInclusiveRange(135, 175));
    expect(report.finalManagerChanges, inInclusiveRange(75, 100));
    expect(report.finalTransferVolume.minorUnits, greaterThan(0));
    expect(report.finalInstallmentDeals, inInclusiveRange(60, 95));
    expect(report.finalCash.minorUnits, greaterThanOrEqualTo(0));
    expect(report.finalDebt.minorUnits, greaterThanOrEqualTo(0));
    expect(report.uniqueFinalPresidents, inInclusiveRange(115, 145));
    expect(report.worldChanged, isTrue);
  }, tags: 'canonical-feedback');
}

Player _player(
  String id,
  String clubId,
  PlayerPosition position,
  double ability,
) =>
    Player(
      id: id,
      name: id,
      clubId: clubId,
      position: position,
      age: 27,
      ability: ability,
      potential: ability,
      retirementAge: 36,
      isAcademyGraduate: false,
    );
