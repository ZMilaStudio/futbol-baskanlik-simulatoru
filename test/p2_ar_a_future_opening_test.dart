import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_future_season_authority.dart';
import 'package:futbol_baskanlik_m0/src/world/world_opening_state_initializer.dart';
import 'package:futbol_baskanlik_m0/src/promise/promise_opening_context_builder.dart';
import 'package:test/test.dart';

/// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER. These deterministic inputs do NOT
/// represent B2's real post-offseason state and are never accepted by an app.
FutureOpeningSourceRequirements futureContractFixture(
    {Object? owner,
    Object? revision,
    Object? provenance,
    Object? receiptOwner,
    Object? receiptRevision,
    Object? receiptProvenance,
    int? receiptSeason,
    bool includeLoan = false,
    bool includeFreeAgent = false,
    bool omitContract = false}) {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 20260903, seasonIndex: 1);
  final opening = const WorldOpeningStateInitializer()
      .prepare(clubs: world.clubs, leagues: world.leagues, config: config);
  final transfer = AdvancedTransferController(
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
      initialSeasonIndex: 1);
  transfer.annualWagesByClub(
      seasonIndex: 1,
      clubs: opening.baseClubs,
      players: opening.players,
      leagues: opening.leagues,
      financeStates: opening.financeStates);
  final identity = owner ?? Object(), rev = revision ?? Object();
  final origin = provenance ?? Object();
  return FutureOpeningSourceRequirements(
      owner: identity,
      sourceRevision: rev,
      provenance: origin,
      config: config,
      baseClubs: opening.baseClubs,
      postOffseasonPlayers: [
        for (var i = 0; i < opening.players.length; i++)
          includeLoan && i == 0
              ? opening.players[i].copyWith(clubId: 't1_02')
              : opening.players[i],
        if (includeFreeAgent)
          const Player(
              id: 'fixture-free-agent',
              name: 'Fixture FA',
              clubId: Player.freeAgentClubId,
              position: PlayerPosition.midfielder,
              age: 22,
              ability: 60,
              potential: 70,
              retirementAge: 35,
              isAcademyGraduate: false),
      ],
      openingFinance: opening.financeStates,
      nextLeagues: opening.leagues,
      contractTransferOpening: FutureContractTransferOpeningRequirements(
          owner: receiptOwner ?? identity,
          sourceRevision: receiptRevision ?? rev,
          provenance: receiptProvenance ?? origin,
          targetSeason: receiptSeason ?? 1,
          contracts: omitContract
              ? transfer.activeContracts.skip(1)
              : transfer.activeContracts,
          activeLoans: [
            ...transfer.activeLoans,
            if (includeLoan)
              LoanAgreement(
                  playerId: opening.players.first.id,
                  parentClubId: opening.players.first.clubId,
                  loanClubId: 't1_02',
                  startSeasonIndex: 1,
                  endSeasonIndex: 2,
                  loanFee: Money.zero,
                  loanClubWageShareBps: 5000),
          ],
          installments: transfer.installmentObligations));
}

FutureSeasonOpeningCandidate prepareFixture(FuturePreseasonBoundary consumer,
        FutureOpeningSourceRequirements source) =>
    consumer.prepare(
        expectedSource: source,
        expectedOwner: source.owner,
        expectedRevision: source.sourceRevision,
        expectedSeason: source.targetSeason);

void main() {
  test('loan player and parent contract remain distinct opening inputs', () {
    final source = futureContractFixture(includeLoan: true);
    final candidate = prepareFixture(
        FuturePreseasonBoundary.forContractFixture(source), source);
    final loan = source.contractTransferOpening.activeLoans.single;
    final player =
        source.postOffseasonPlayers.singleWhere((p) => p.id == loan.playerId);
    final contract = source.contractTransferOpening.contracts
        .singleWhere((c) => c.playerId == loan.playerId);
    expect(player.clubId, loan.loanClubId);
    expect(contract.clubId, loan.parentClubId);
    expect(candidate.isAuthoritative, isFalse);
    expect(candidate.source.contractTransferOpening.activeLoans.single,
        same(loan));
    expect(candidate.promiseContexts.length, 48);
    expect(candidate.w0.completedMatchCount, 0);
  });
  test('free agents remain in source without fabricated active contracts', () {
    final source = futureContractFixture(includeFreeAgent: true);
    final candidate = prepareFixture(
        FuturePreseasonBoundary.forContractFixture(source), source);
    expect(candidate.source.postOffseasonPlayers.last.isFreeAgent, isTrue);
    expect(candidate.source.contractTransferOpening.contracts.length,
        candidate.source.postOffseasonPlayers.length - 1);
    final plain = futureContractFixture();
    final expected = prepareFixture(
        FuturePreseasonBoundary.forContractFixture(plain), plain);
    expect(candidate.effectiveClubs.map((c) => c.strength),
        expected.effectiveClubs.map((c) => c.strength));
    expect(candidate.isAuthoritative, isFalse);
    expect(candidate.promiseContexts.length, 48);
    expect(candidate.w0.completedMatchCount, 0);
  });
  test(
      'fixture consumer uses real initial appointment and one manager-adjusted source',
      () {
    final source = futureContractFixture();
    final candidate = prepareFixture(
        FuturePreseasonBoundary.forContractFixture(source), source);
    expect(candidate.isAuthoritative, isFalse);
    expect(candidate.isInitialManagerAppointment, isTrue);
    expect(candidate.source, same(source));
    expect(candidate.managerAuthority.owner, same(source.owner));
    expect(
        candidate.managerAuthority.sourceRevision, same(source.sourceRevision));
    expect(candidate.managerAuthority.seasons, isEmpty);
    expect(candidate.managerAuthority.assignments.length, 48);
    expect(
        candidate.managerAuthority.assignments.values.every(
            (a) => a.appointedSeasonIndex == 1 && a.completedSeasons == 0),
        isTrue);
    expect(candidate.effectiveClubs,
        same(candidate.managerAuthority.effectiveClubs));
    final expected = const PromiseOpeningContextBuilder().build(
        seasonIndex: 1,
        effectiveClubs: candidate.effectiveClubs,
        leagues: source.nextLeagues,
        openingFinanceStates: source.openingFinance);
    expect(candidate.promiseContexts.length, 48);
    for (var i = 0; i < expected.length; i++) {
      final actual = candidate.promiseContexts[i], context = expected[i];
      expect(actual.clubId, context.clubId);
      expect(actual.seasonIndex, 1);
      expect(actual.expectedPosition, context.expectedPosition);
      expect(actual.tier, context.tier);
      expect(actual.openingCash, context.openingCash);
      expect(actual.openingDebt, context.openingDebt);
    }
    expect(candidate.w0.seasonIndex, 1);
    expect(candidate.w0.nextRound, 1);
    expect(candidate.w0.completedMatchCount, 0);
    expect(candidate.w0.fixtures.length, 720);
    final expectedW0 = const WeeklyWorldFixtureResultCore().prepare(
        clubs: candidate.effectiveClubs,
        leagues: source.nextLeagues,
        config: source.config);
    // Future weekly source uses exactly the captured clubs (not squad-only).
    final round = const WeeklyWorldFixtureResultCore().advanceRound(
        snapshot: candidate.w0,
        expectedRound: 1,
        effectiveClubs: candidate.effectiveClubs);
    final oracle = const WeeklyWorldFixtureResultCore().advanceRound(
        snapshot: expectedW0,
        expectedRound: 1,
        effectiveClubs: candidate.effectiveClubs);
    expect(
        round.fixtures
            .map((f) => [
                  f.globalKey,
                  f.fixture.result?.homeGoals,
                  f.fixture.result?.awayGoals,
                  f.fixture.result?.matchSeed,
                  f.fixture.result?.homeExpectedGoals,
                  f.fixture.result?.awayExpectedGoals
                ])
            .toList(),
        oracle.fixtures
            .map((f) => [
                  f.globalKey,
                  f.fixture.result?.homeGoals,
                  f.fixture.result?.awayGoals,
                  f.fixture.result?.matchSeed,
                  f.fixture.result?.homeExpectedGoals,
                  f.fixture.result?.awayExpectedGoals
                ])
            .toList());
    expect(candidate.w0.completedMatchCount, 0);
    final fork = candidate.managerAuthority.forkDetached(
        expectedOwner: source.owner,
        expectedRevision: source.sourceRevision,
        expectedSeason: 1);
    expect(fork.seasons, isEmpty);
    expect(
        () => fork.adjustClubsForSeason(
            seasonIndex: 1,
            squadClubs: candidate.effectiveClubs,
            players: source.postOffseasonPlayers,
            leagues: source.nextLeagues,
            financeStates: source.openingFinance),
        throwsStateError);
  });

  test(
      'owner/revision/season/value-equal source and duplicate consumption fail closed',
      () {
    final source = futureContractFixture();
    final equal = futureContractFixture(
        owner: source.owner,
        revision: source.sourceRevision,
        provenance: source.provenance);
    final consumer = FuturePreseasonBoundary.forContractFixture(source);
    expect(() => prepareFixture(consumer, equal), throwsStateError);
    expect(
        () => consumer.prepare(
            expectedSource: source,
            expectedOwner: Object(),
            expectedRevision: source.sourceRevision,
            expectedSeason: 1),
        throwsStateError);
    expect(
        () => consumer.prepare(
            expectedSource: source,
            expectedOwner: source.owner,
            expectedRevision: Object(),
            expectedSeason: 1),
        throwsStateError);
    expect(
        () => consumer.prepare(
            expectedSource: source,
            expectedOwner: source.owner,
            expectedRevision: source.sourceRevision,
            expectedSeason: 2),
        throwsStateError);
    final candidate = prepareFixture(consumer, source);
    expect(() => prepareFixture(consumer, source), throwsStateError);
    final repeat = prepareFixture(
        FuturePreseasonBoundary.forContractFixture(equal), equal);
    expect(candidate.effectiveClubs.map((c) => c.strength),
        repeat.effectiveClubs.map((c) => c.strength));
    expect(candidate.managerAuthority.managers.map((m) => m.signature),
        repeat.managerAuthority.managers.map((m) => m.signature));
    expect(
        candidate.managerAuthority.assignments.values.map((a) => a.signature),
        repeat.managerAuthority.assignments.values.map((a) => a.signature));
    expect(candidate.w0.fixtures.map((f) => f.globalKey),
        repeat.w0.fixtures.map((f) => f.globalKey));
  });

  test(
      'fixture cannot impersonate production capability; incomplete receipts are rejected',
      () {
    final source = futureContractFixture();
    expect(source is FutureOpeningSourceCapability, isFalse);
    expect(() => FuturePreseasonBoundary.fromCapability(source as dynamic),
        throwsA(isA<TypeError>()));
    for (final invalid in [
      futureContractFixture(receiptOwner: Object()),
      futureContractFixture(receiptRevision: Object()),
      futureContractFixture(receiptProvenance: Object()),
      futureContractFixture(receiptSeason: 2),
      futureContractFixture(omitContract: true)
    ]) {
      final before =
          invalid.postOffseasonPlayers.map((p) => p.signature).toList();
      final consumer = FuturePreseasonBoundary.forContractFixture(invalid);
      expect(() => prepareFixture(consumer, invalid), throwsStateError);
      expect(() => prepareFixture(consumer, invalid), throwsStateError);
      expect(invalid.postOffseasonPlayers.map((p) => p.signature), before);
    }
    expect(() => source.postOffseasonPlayers.clear(), throwsUnsupportedError);
    expect(() => source.openingFinance.clear(), throwsUnsupportedError);
    expect(() => source.contractTransferOpening.contracts.clear(),
        throwsUnsupportedError);
  });
}
