import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/finance/season_finance_authority_receipt.dart';
import 'package:test/test.dart';

class ReceiptProvider extends PlayerMatchdayTicketPricingDecisionProvider {
  ReceiptProvider({this.fail = false, this.observer});
  final bool fail;
  final FullM65SeasonFinancePipeline? observer;
  final List<String> events = [];
  int choices = 0;
  @override
  MatchdayTicketPricingChoice choose(
      PlayerPresidentTicketPricingDecisionContext context) {
    choices++;
    expect(observer?.receipt, isNull);
    events.add('choose:${context.clubId}');
    if (fail) throw StateError('provider failure');
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
  }

  @override
  void onApplied(PlayerPresidentTicketPricingDecision decision) {
    events.add('applied:${decision.context.clubId}');
  }
}

class FinanceCall {
  FinanceCall(this.clubs, this.openings, this.wages, this.income, this.expense,
      this.sponsor, this.multipliers, this.results);
  final List<Club> clubs;
  final List<ClubFinanceState> openings;
  final Map<String, Money>? wages, income, expense, sponsor;
  final Map<String, int> multipliers;
  final List<ClubFinanceSeason> results;
}

class ObservedEconomy extends BasicEconomyEngine {
  ObservedEconomy({this.failure, this.provider});
  final String? failure;
  final ReceiptProvider? provider;
  final List<FinanceCall> calls = [];
  @override
  List<ClubFinanceSeason> simulateSeason(
      {required List<Club> clubs,
      required List<Player> players,
      required SeasonReport seasonReport,
      required List<ClubFinanceState> openingStates,
      int economicScaleBps = 10000,
      int costScaleBps = 10000,
      Map<String, Money>? annualWagesByClub,
      Map<String, Money>? transferInstallmentIncomeByClub,
      Map<String, Money>? transferInstallmentExpenseByClub,
      Map<String, int> matchdayRevenueMultiplierBpsByClub = const {},
      Map<String, Money>? sponsorRevenueByClub}) {
    provider?.events.add('delegate:${clubs.first.id}');
    if (failure == 'delegate') throw StateError('delegate failure');
    final rows = super.simulateSeason(
        clubs: clubs,
        players: players,
        seasonReport: seasonReport,
        openingStates: openingStates,
        economicScaleBps: economicScaleBps,
        costScaleBps: costScaleBps,
        annualWagesByClub: annualWagesByClub,
        transferInstallmentIncomeByClub: transferInstallmentIncomeByClub,
        transferInstallmentExpenseByClub: transferInstallmentExpenseByClub,
        matchdayRevenueMultiplierBpsByClub: matchdayRevenueMultiplierBpsByClub,
        sponsorRevenueByClub: sponsorRevenueByClub);
    final output = failure == 'coverage' ? rows.take(15).toList() : rows;
    calls.add(FinanceCall(
        clubs,
        openingStates,
        annualWagesByClub,
        transferInstallmentIncomeByClub,
        transferInstallmentExpenseByClub,
        sponsorRevenueByClub,
        matchdayRevenueMultiplierBpsByClub,
        output));
    return output;
  }
}

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 20261001);
  test(
      'AR-B records actual delegate inputs and exact 48 outputs; read has zero effects',
      () {
    final owner = Object(), revision = Object(), provenance = Object();
    final observer = FullM65SeasonFinancePipeline(
        owner: owner,
        sourceRevision: revision,
        provenance: provenance,
        seasonIndex: 0);
    final provider = ReceiptProvider(observer: observer);
    final economy = ObservedEconomy(provider: provider);
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        financeRecording: observer,
        playerProvider: provider,
        baseWorldEngine: WorldCareerEngine(economyEngine: economy));
    final result = observer.record(() => engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1));
    final receipt = observer.receipt!;
    expect(receipt.successful, isTrue);
    expect(receipt.inputs.length, 48);
    expect(economy.calls.length, 3);
    for (final call in economy.calls) {
      for (final row in call.results) {
        final input = receipt.inputs[row.clubId]!;
        expect(
            identical(
                input.club, call.clubs.singleWhere((c) => c.id == row.clubId)),
            isTrue);
        expect(
            identical(input.opening,
                call.openings.singleWhere((s) => s.clubId == row.clubId)),
            isTrue);
        expect(input.wages, call.wages![row.clubId]);
        expect(input.installmentIncome, call.income?[row.clubId] ?? Money.zero);
        expect(
            input.installmentExpense, call.expense?[row.clubId] ?? Money.zero);
        expect(input.sponsorRevenue, call.sponsor![row.clubId]);
        expect(input.finalMultiplierBps, call.multipliers[row.clubId]);
        expect(input.incomingMultiplierBps, input.attendance.multiplierBps);
        expect(input.ticket.context.baseAttendance.revenueMultiplierBps,
            input.attendance.multiplierBps);
        expect(
            identical(
                input.ticket, result.boundaries.single.decisionFor(row.clubId)),
            isTrue);
        expect(identical(row, result.boundaries.single.financeFor(row.clubId)),
            isTrue);
      }
    }
    final calls = provider.choices;
    for (var i = 0; i < 3; i++) {
      receipt.verify(
          expectedOwner: owner,
          expectedRevision: revision,
          expectedProvenance: provenance,
          expectedSeason: 0,
          expectedResults: economy.calls.expand((call) => call.results));
    }
    expect(economy.calls.length, 3);
    expect(provider.choices, calls);
    expect(() => receipt.inputs.clear(), throwsUnsupportedError);
    expect(() => receipt.results.clear(), throwsUnsupportedError);
    expect(
        () => receipt.verify(
            expectedOwner: Object(),
            expectedRevision: revision,
            expectedProvenance: provenance,
            expectedSeason: 0,
            expectedResults: receipt.results),
        throwsStateError);
    expect(
        () => receipt.verify(
            expectedOwner: owner,
            expectedRevision: Object(),
            expectedProvenance: provenance,
            expectedSeason: 0,
            expectedResults: receipt.results),
        throwsStateError);
    expect(
        () => receipt.verify(
            expectedOwner: owner,
            expectedRevision: revision,
            expectedProvenance: Object(),
            expectedSeason: 0,
            expectedResults: receipt.results),
        throwsStateError);
    expect(
        () => receipt.verify(
            expectedOwner: owner,
            expectedRevision: revision,
            expectedProvenance: provenance,
            expectedSeason: 1,
            expectedResults: receipt.results),
        throwsStateError);
    expect(
        () => receipt.verify(
            expectedOwner: owner,
            expectedRevision: revision,
            expectedProvenance: provenance,
            expectedSeason: 0,
            expectedResults: receipt.results.take(47)),
        throwsStateError);
    // Equal values from a separate actual settlement do not establish identity.
    final other = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
            playerProvider: ReceiptProvider())
        .simulateWithCheckpoint(
            clubs: world.clubs,
            leagues: world.leagues,
            config: config,
            controlledClubId: world.clubs.first.id,
            seasonCount: 1);
    expect(other.boundaries.single.financeFor(world.clubs.first.id).signature,
        result.boundaries.single.financeFor(world.clubs.first.id).signature);
    expect(
        () => receipt.verify(
            expectedOwner: owner,
            expectedRevision: revision,
            expectedProvenance: provenance,
            expectedSeason: 0,
            expectedResults: world.clubs
                .map((c) => other.boundaries.single.financeFor(c.id))),
        throwsStateError);
    var retryCalled = false;
    expect(
        () => observer.record(() {
              retryCalled = true;
            }),
        throwsStateError);
    expect(retryCalled, isFalse);
    final duplicateObserver = FullM65SeasonFinancePipeline(
        owner: owner,
        sourceRevision: revision,
        provenance: provenance,
        seasonIndex: 0);
    expect(
        () => duplicateObserver.record(() {
              retryCalled = true;
            }),
        throwsStateError);
    expect(retryCalled, isFalse);
  });

  for (final failure in ['provider', 'delegate', 'coverage']) {
    test('AR-B $failure failure publishes no receipt and cannot replay attempt',
        () {
      final observer = FullM65SeasonFinancePipeline(
          owner: Object(),
          sourceRevision: Object(),
          provenance: Object(),
          seasonIndex: 0);
      final provider =
          ReceiptProvider(fail: failure == 'provider', observer: observer);
      final economy = ObservedEconomy(failure: failure, provider: provider);
      final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
          financeRecording: observer,
          playerProvider: provider,
          baseWorldEngine: WorldCareerEngine(economyEngine: economy));
      expect(
          () => observer.record(() => engine.simulateWithCheckpoint(
              clubs: world.clubs,
              leagues: world.leagues,
              config: config,
              controlledClubId: world.clubs.first.id,
              seasonCount: 1)),
          throwsStateError);
      expect(observer.receipt, isNull);
      final duplicate = FullM65SeasonFinancePipeline(
          owner: observer.owner,
          sourceRevision: observer.sourceRevision,
          provenance: observer.provenance,
          seasonIndex: observer.seasonIndex);
      expect(() => duplicate.record(() => fail('must not repeat producer')),
          throwsStateError);
      expect(duplicate.receipt, isNull);
      final choices = provider.choices, calls = economy.calls.length;
      expect(
          () => observer.record(() => engine.simulateWithCheckpoint(
              clubs: world.clubs,
              leagues: world.leagues,
              config: config,
              controlledClubId: world.clubs.first.id,
              seasonCount: 1)),
          throwsStateError);
      expect(provider.choices, choices);
      expect(economy.calls.length, calls);
      expect(observer.receipt, isNull);
    });
  }
  test('AR-B empty/component-free observation is not a successful receipt', () {
    final observer = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    expect(() => observer.record(() {}), throwsStateError);
    expect(observer.receipt, isNull);
  });

  test(
      'AR-B complete delegate success followed by boundary exception does not commit receipt',
      () {
    final observer = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    final economy = ObservedEconomy();
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        financeRecording: observer,
        baseWorldEngine: WorldCareerEngine(economyEngine: economy));
    expect(
        () => observer.record(() {
              engine.simulateWithCheckpoint(
                  clubs: world.clubs,
                  leagues: world.leagues,
                  config: config,
                  controlledClubId: world.clubs.first.id,
                  seasonCount: 1);
              expect(economy.calls.length, 3);
              expect(observer.receipt, isNull);
              throw StateError('boundary validation failure');
            }),
        throwsStateError);
    expect(observer.receipt, isNull);
    expect(
        () => observer.record(() => fail('must not replay')), throwsStateError);
    expect(economy.calls.length, 3);
  });

  test('AR-B missing real pricing component and wrong season fail closed', () {
    final missing = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    expect(
        () => missing.record(() =>
            FacilitySponsorCrisisRuntimeCareerEngine(financeRecording: missing)
                .simulateWithCheckpoint(
                    clubs: world.clubs,
                    leagues: world.leagues,
                    config: config,
                    seasonCount: 1)),
        throwsStateError);
    expect(missing.receipt, isNull);
    final wrongSeason = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 1);
    expect(
        () => wrongSeason.record(() =>
            PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                    financeRecording: wrongSeason)
                .simulateWithCheckpoint(
                    clubs: world.clubs,
                    leagues: world.leagues,
                    config: config,
                    controlledClubId: world.clubs.first.id,
                    seasonCount: 1)),
        throwsStateError);
    expect(wrongSeason.receipt, isNull);
  });
}
