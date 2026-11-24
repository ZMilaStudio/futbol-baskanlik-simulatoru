import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;

class _MarketRecorder extends TransferMarketEngine {
  TransferMarketResult? result;
  int calls = 0;
  @override
  TransferMarketResult simulateWindow({
    required List<Club> clubs,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required int careerSeed,
    required int seasonIndex,
    required int simulationVersion,
    Map<String, int>? contractYearsRemainingByPlayer,
    bool enableInstallments = false,
    Map<String, TransferBudgetPolicy>? budgetPoliciesByClub,
    Map<String, TransferActivityPolicy>? activityPoliciesByClub,
    Map<String, TransferNegotiationPolicy>? negotiationPoliciesByClub,
    Map<String, TransferYouthPreferencePolicy>? youthPreferencePoliciesByClub,
  }) {
    calls++;
    return result = super.simulateWindow(
        clubs: clubs,
        players: players,
        financeStates: financeStates,
        careerSeed: careerSeed,
        seasonIndex: seasonIndex,
        simulationVersion: simulationVersion,
        contractYearsRemainingByPlayer: contractYearsRemainingByPlayer,
        enableInstallments: enableInstallments,
        budgetPoliciesByClub: budgetPoliciesByClub,
        activityPoliciesByClub: activityPoliciesByClub,
        negotiationPoliciesByClub: negotiationPoliciesByClub,
        youthPreferencePoliciesByClub: youthPreferencePoliciesByClub);
  }
}

void main() {
  test('only published transfers expose detached exact producer values', () {
    final market = _MarketRecorder();
    final fixture = B3B1LegacyClosing(
        config: const SimulationConfig(careerSeed: 42002),
        worldEngine: WorldCareerEngine(transferMarketEngine: market));
    final transition = fixture.claim();
    expect(transition.completedTransferWindow, isNull);
    final pending = transition.prepareTransfer()!;
    expect(transition.completedTransferWindow, isNull);
    transition.submitTransfer(
        expectedPending: pending,
        choice: PlayerTransferStrategyChoice.fromProfile(
            pending.context.aiProfile));
    expect(transition.completedTransferWindow, isNull);
    transition.prepareDomain();
    transition.prepareOuterSuccessor();
    final manager = transition.managerPending!;
    if (manager.review.canRetain) {
      transition.submitManagerReview(
          expectedPending: manager, choice: PlayerManagerReviewChoice.retain);
    } else {
      final replacement = transition.submitManagerReview(
          expectedPending: manager, choice: PlayerManagerReviewChoice.replace)!;
      transition.submitManagerReplacement(
          expectedPending: replacement,
          selected: replacement.replacement!.candidates.first.manager);
    }
    expect(transition.completedTransferWindow, isNull);
    final graph = transition.moveOwnedAnnualContinuation();
    final snapshot = transition.completedTransferWindow!;
    final deals = market.result!.deals
        .where((row) =>
            row.fromClubId == snapshot.controlledClubId ||
            row.toClubId == snapshot.controlledClubId)
        .toList();
    expect(deals, isNotEmpty);
    expect(deals.where((row) => row.installments.isNotEmpty), isNotEmpty);
    expect(snapshot.transfers, hasLength(deals.length));
    for (var i = 0; i < deals.length; i++) {
      final actual = snapshot.transfers[i], source = deals[i];
      expect(actual.playerId, source.playerId);
      expect(actual.playerName, source.playerName);
      expect(actual.position, source.position);
      expect(actual.fromClubId, source.fromClubId);
      expect(actual.toClubId, source.toClubId);
      expect(actual.marketValue, source.marketValue);
      expect(actual.fee, source.fee);
      expect(actual.upfrontFee, source.upfrontFee);
      expect(actual.installments.map((row) => row.signature),
          source.installments.map((row) => row.signature));
      expect(() => actual.installments.clear(), throwsUnsupportedError);
    }
    final loans = graph.transferEvidence.loanHistory.where((row) =>
        row.startSeasonIndex == graph.targetSeasonIndex &&
        (row.parentClubId == snapshot.controlledClubId ||
            row.loanClubId == snapshot.controlledClubId));
    expect(snapshot.loans.map((row) => row.signature),
        loans.map((row) => row.signature));
    expect(snapshot.targetSeasonIndex, graph.targetSeasonIndex);
    expect(snapshot.completedSeasonIndex, graph.targetSeasonIndex - 1);
    final signature = snapshot.signature;
    expect(transition.moveOwnedAnnualContinuation(), same(graph));
    expect(transition.completedTransferWindow, same(snapshot));
    expect(market.calls, 1);
    // Real mutable producer list, after all ownership checks; never continued.
    deals.firstWhere((row) => row.installments.isNotEmpty).installments.clear();
    expect(snapshot.signature, signature);
    expect(
        snapshot.transfers.any((row) => row.installments.isNotEmpty), isTrue);
  });
}
