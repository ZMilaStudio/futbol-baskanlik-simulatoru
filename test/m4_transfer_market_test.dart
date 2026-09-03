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
    expect(first.totalTransfers, greaterThan(0));
    expect(first.totalTransfers, lessThan(250));
    expect(first.totalTransferVolume, greaterThan(Money.zero));
    expect(first.totalTransferVolume, lessThan(const Money.fromUnits(2000000000)));
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
        expect(deal.fee, greaterThanOrEqualTo(deal.marketValue.scaleBasisPoints(9800)));
        expect(deal.fee, lessThanOrEqualTo(deal.marketValue.scaleBasisPoints(13300)));
      }
    }
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
