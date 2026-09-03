import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

import '../tool/m0_data.dart';

void main() {
  test('market value rewards youth and potential', () {
    const model = MarketValueModel();
    const young = Player(
      id: 'young',
      name: 'Young',
      clubId: 'a',
      position: PlayerPosition.forward,
      age: 20,
      ability: 70,
      potential: 88,
      retirementAge: 36,
      isAcademyGraduate: false,
    );
    const veteran = Player(
      id: 'veteran',
      name: 'Veteran',
      clubId: 'a',
      position: PlayerPosition.forward,
      age: 33,
      ability: 70,
      potential: 70,
      retirementAge: 36,
      isAcademyGraduate: false,
    );

    expect(model.value(young), greaterThan(model.value(veteran)));
    expect(model.value(young), greaterThan(const Money.fromUnits(250000)));
  });

  test('M4 simulates a deterministic valid 20-season transfer career', () {
    const engine = TransferCareerEngine();
    const validator = TransferCareerValidator();
    const config = SimulationConfig(careerSeed: 20260903);

    final first = engine.simulate(clubs: m0Clubs, config: config);
    final second = engine.simulate(clubs: m0Clubs, config: config);

    expect(first.seasonCount, 20);
    expect(first.signature, second.signature);
    expect(validator.validate(first), isEmpty);
    expect(first.finalPlayers.length, greaterThanOrEqualTo(88));

    for (final state in first.finalFinanceStates) {
      expect(state.cash, greaterThanOrEqualTo(Money.zero));
      expect(state.debt, greaterThanOrEqualTo(Money.zero));
    }
    for (final season in first.seasons) {
      final ids = season.transfersAfterSeason.map((deal) => deal.playerId).toList();
      expect(ids.toSet().length, ids.length);
      for (final deal in season.transfersAfterSeason) {
        expect(deal.fromClubId, isNot(deal.toClubId));
        expect(deal.fee, greaterThan(Money.zero));
        expect(deal.fee, greaterThanOrEqualTo(deal.marketValue.scaleBasisPoints(9000)));
        expect(deal.fee, lessThanOrEqualTo(deal.marketValue.scaleBasisPoints(13300)));
      }
    }
  });

  test('M4 baseline avoids a frozen or hyperactive transfer market', () {
    final report = const TransferCareerEngine().simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 20260903),
    );
    final totalCash = report.finalFinanceStates.fold<Money>(
      Money.zero,
      (sum, state) => sum + state.cash,
    );
    final totalDebt = report.finalFinanceStates.fold<Money>(
      Money.zero,
      (sum, state) => sum + state.debt,
    );
    final participants = <String>{};
    for (final season in report.seasons) {
      for (final deal in season.transfersAfterSeason) {
        participants
          ..add(deal.fromClubId)
          ..add(deal.toClubId);
      }
    }

    expect(report.totalTransfers, inInclusiveRange(15, 120));
    expect(
      report.totalTransferVolume,
      greaterThanOrEqualTo(const Money.fromUnits(40000000)),
    );
    expect(
      report.totalTransferVolume,
      lessThanOrEqualTo(const Money.fromUnits(500000000)),
    );
    expect(
      totalCash,
      greaterThanOrEqualTo(const Money.fromUnits(20000000)),
    );
    expect(
      totalCash,
      lessThanOrEqualTo(const Money.fromUnits(500000000)),
    );
    expect(totalDebt, greaterThan(Money.zero));
    expect(totalDebt, lessThan(const Money.fromUnits(400000000)));
    expect(participants.length, greaterThanOrEqualTo(4));
  });

  test('different seeds produce different transfer careers', () {
    const engine = TransferCareerEngine();
    final a = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 4101),
    );
    final b = engine.simulate(
      clubs: m0Clubs,
      config: const SimulationConfig(careerSeed: 4102),
    );

    expect(a.signature, isNot(equals(b.signature)));
  });
}
