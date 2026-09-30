import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_preseason_weekly_handoff.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_b3a_finance_equivalence.dart';
import 'package:test/test.dart';

// Shared real fixture stays in an allowed test file.
class B3AFixture {
  B3AFixture({bool future = true}) {
    final world = const FictionalWorldFactory().build();
    application = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      controlledClubId: 't1_01',
      seasonCount: 1,
      hasFutureSeasonAfterReport: future,
    );
    final boundary = application.startPreseasonPromise(
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    boundary.submit(
        pending: pending, choice: pending.context.allowedTypes.first);
    w0 = application.openPreseasonWeeklyHandoff();
    var state = w0;
    for (var round = 1; round <= 30; round++) {
      state = application.advancePreseasonWeek(
          expectedState: state, expectedRound: round);
    }
    w30 = state;
    b1 = application.projectCommittedSeason(expectedState: state);
    b2 = application.closeAcceptedPromises(expectedResultCandidate: b1);
  }
  late final PlayerPresidentInteractiveDecisionApplicationSession application;
  late final PlayerPresidentPreseasonWeeklyState w0, w30;
  late final PlayerPresidentCommittedSeasonResultCandidate b1;
  late final PlayerPresidentAcceptedPromiseClosingCandidate b2;
  List<String> get signatures => [
        ...b2.finances.map((item) => item.signature),
        ...b2.closingFinanceStates.map((item) => item.signature),
        ...b2.activePromises.map((item) => item.signature),
        ...b2.movements.map((item) => item.signature),
        ...w30.boundary.proof.initialContracts.activeContracts
            .map((item) => item.signature),
        ...w30.boundary.opening.players.map((item) => item.signature),
      ];
  void expectUnchanged(List<String> before) {
    expect(signatures, before);
    expect(application.acceptedPromiseClosingCandidate, same(b2));
    expect(application.committedSeasonResultCandidate, same(b1));
    expect(application.preseasonWeeklyState, same(w30));
    expect(application.appliedPreseasonPromises, same(w0.applied));
    expect(w30.activePromises, same(w0.activePromises));
    expect(b2.activePromises, same(w0.activePromises));
    for (var i = 0; i < 48; i++) {
      expect(b2.activePromises[i], same(w0.activePromises[i]));
    }
    expect(w30.completedMatchCount, 720);
    expect(w0.completedMatchCount, 0);
    expect(application.completed, isNull);
    expect(application.completedTenureControl, isNull);
    expect(application.pendingDecision, isNull);
    expect(application.answeredDecisionCount, 0);
    expect(() => application.checkpoint, throwsStateError);
    expect(() => application.persistenceBundle, throwsStateError);
  }
}

void main() {
  late B3AFixture fixture;
  setUpAll(() => fixture = B3AFixture());
  test('real accepted B2: 48 exact record references and independent X1 wages',
      () {
    final before = fixture.signatures;
    final records = fixture.b2.finances;
    final closing = fixture.b2.closingFinanceStates;
    final result =
        const PlayerPresidentB3AFinanceEquivalence().inspect(fixture.b2);
    final opening = fixture.w30.boundary.opening;
    final proof = fixture.w30.boundary.proof.initialContracts;
    final hook = AdvancedTransferController.restore(
      careerSeed: proof.careerSeed,
      simulationVersion: proof.simulationVersion,
      initialSeasonIndex: proof.seasonIndex,
      activeContracts: proof.activeContracts,
      contractEvents: proof.initialEvents,
      activeLoans: const [],
      loanHistory: const [],
      installmentObligations: const [],
    );
    final wages = hook.annualWagesByClub(
        seasonIndex: 0,
        players: opening.players,
        clubs: fixture.w30.effectiveClubs,
        leagues: opening.leagues,
        financeStates: opening.financeStates)!;
    final flows = hook.flowsForSeason(
        seasonIndex: 0,
        clubs: fixture.w30.effectiveClubs,
        leagues: opening.leagues,
        openingFinanceStates: opening.financeStates);
    expect(result.source, same(fixture.b2));
    expect(result.source.finances, same(records));
    expect(result.source.closingFinanceStates, same(closing));
    expect(result.basicX1Verified, isTrue);
    expect(result.x1ProvenanceVerified, isTrue);
    expect(result.annualWagesByClub, wages);
    expect(result.annualWagesByClub.length, 48);
    expect(flows.transferInstallmentIncomeByClub, isEmpty);
    expect(flows.transferInstallmentExpenseByClub, isEmpty);
    for (var i = 0; i < 48; i++) {
      final finance = records[i];
      expect(result.source.finances[i], same(finance));
      expect(finance.wageExpense, wages[finance.clubId]);
      final prior =
          opening.financeStates.singleWhere((s) => s.clubId == finance.clubId);
      expect(finance.openingCash, prior.cash);
      expect(finance.openingDebt, prior.debt);
      expect(finance.expectedClosingCash, finance.closingCash);
      expect(finance.expectedClosingDebt, finance.closingDebt);
      expect(finance.transferInstallmentIncome, Money.zero);
      expect(finance.transferInstallmentExpense, Money.zero);
      final next = closing.singleWhere((s) => s.clubId == finance.clubId);
      expect(next.cash, finance.closingCash);
      expect(next.debt, finance.closingDebt);
    }
    expect(() => records.clear(), throwsUnsupportedError);
    expect(() => result.annualWagesByClub.clear(), throwsUnsupportedError);
    fixture.expectUnchanged(before);
  });
  test('numerically equal detached B2 cannot impersonate application ownership',
      () {
    final before = fixture.signatures;
    final detached = const PlayerPresidentAcceptedPromiseClosingProjection()
        .project(source: fixture.b1);
    expect(detached.finances.map((f) => f.signature),
        fixture.b2.finances.map((f) => f.signature));
    final result =
        const PlayerPresidentB3AFinanceEquivalence().inspect(detached);
    expect(result.sourceOwned, isFalse);
    expect(result.status,
        PlayerPresidentB3AFinanceEquivalenceStatus.sourceMismatch);
    expect(result.basicX1Verified, isFalse);
    expect(result.annualWagesByClub, isEmpty);
    fixture.expectUnchanged(before);
  });
  test(
      'repeated Basic/X1 proof never invents missing full-M65 runtime authority',
      () {
    final before = fixture.signatures;
    for (var i = 0; i < 3; i++) {
      final result =
          const PlayerPresidentB3AFinanceEquivalence().inspect(fixture.b2);
      expect(result.basicX1Verified, isTrue);
      expect(result.fullM65Equivalent, isFalse);
      expect(
          result.status,
          PlayerPresidentB3AFinanceEquivalenceStatus
              .fullM65EquivalenceUnproven);
      expect(result.sponsorAuthorityAvailable, isFalse);
      expect(result.stadiumAttendanceAuthorityAvailable, isFalse);
      expect(result.ticketPricingAuthorityAvailable, isFalse);
      expect(result.managerAdjustedClubAuthorityAvailable, isFalse);
    }
    fixture.expectUnchanged(before);
  });
}
