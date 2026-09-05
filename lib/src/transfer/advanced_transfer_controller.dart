import '../contract/contract_event.dart';
import '../contract/player_contract.dart';
import '../contract/player_contract_controller.dart';
import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../world/world_finance_hooks.dart';
import '../world/world_league.dart';
import '../world/world_roster_hooks.dart';
import '../world/world_transfer_hooks.dart';
import 'loan_agreement.dart';
import 'loan_market_engine.dart';
import 'transfer_deal.dart';
import 'transfer_installment.dart';

class AdvancedTransferController
    implements WorldRosterHooks, WorldFinanceHooks, WorldTransferHooks {
  AdvancedTransferController({
    required int careerSeed,
    required int simulationVersion,
    required int initialSeasonIndex,
    this.loanMarketEngine = const LoanMarketEngine(),
  })  : careerSeed = careerSeed,
        simulationVersion = simulationVersion,
        contractController = PlayerContractController(
          careerSeed: careerSeed,
          simulationVersion: simulationVersion,
          initialSeasonIndex: initialSeasonIndex,
        );

  AdvancedTransferController.restore({
    required int careerSeed,
    required int simulationVersion,
    required int initialSeasonIndex,
    required Iterable<PlayerContract> activeContracts,
    required Iterable<ContractEvent> contractEvents,
    required Iterable<LoanAgreement> activeLoans,
    required Iterable<LoanAgreement> loanHistory,
    required Iterable<TransferInstallmentObligation> installmentObligations,
    this.loanMarketEngine = const LoanMarketEngine(),
  })  : careerSeed = careerSeed,
        simulationVersion = simulationVersion,
        contractController = PlayerContractController.restore(
          careerSeed: careerSeed,
          simulationVersion: simulationVersion,
          initialSeasonIndex: initialSeasonIndex,
          activeContracts: activeContracts,
          events: contractEvents,
        ) {
    for (final loan in activeLoans) {
      if (_activeLoans.containsKey(loan.playerId)) {
        throw ArgumentError('Duplicate restored active loan ${loan.playerId}.');
      }
      _activeLoans[loan.playerId] = loan;
    }
    _loanHistory.addAll(loanHistory);
    _installmentObligations.addAll(installmentObligations);
  }

  final int careerSeed;
  final int simulationVersion;
  final PlayerContractController contractController;
  final LoanMarketEngine loanMarketEngine;

  final Map<String, LoanAgreement> _activeLoans = {};
  final List<LoanAgreement> _loanHistory = [];
  final List<TransferInstallmentObligation> _installmentObligations = [];

  List<PlayerContract> get activeContracts => contractController.activeContracts;
  List<ContractEvent> get contractEvents => contractController.events;
  List<LoanAgreement> get activeLoans {
    final values = _activeLoans.values.toList()
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    return List.unmodifiable(values);
  }

  List<LoanAgreement> get loanHistory => List.unmodifiable(_loanHistory);
  List<TransferInstallmentObligation> get installmentObligations =>
      List.unmodifiable(_installmentObligations);

  @override
  Map<String, Money>? annualWagesByClub({
    required int seasonIndex,
    required List<Player> players,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) {
    if (contractController.activeContracts.isEmpty) {
      return contractController.annualWagesByClub(
        seasonIndex: seasonIndex,
        players: players,
        clubs: clubs,
        leagues: leagues,
        financeStates: financeStates,
      );
    }

    final totals = {for (final club in clubs) club.id: Money.zero};
    final playersById = {for (final player in players) player.id: player};
    for (final contract in contractController.activeContracts) {
      if (!contract.isActiveDuring(seasonIndex)) continue;
      final player = playersById[contract.playerId];
      if (player == null) continue;
      final loan = _activeLoans[contract.playerId];
      if (loan != null && loan.isActiveDuring(seasonIndex)) {
        if (player.clubId != loan.loanClubId ||
            contract.clubId != loan.parentClubId) {
          throw StateError('Loan/contract mismatch for ${player.id}.');
        }
        final loanShare =
            contract.annualWage.scaleBasisPoints(loan.loanClubWageShareBps);
        final parentShare = contract.annualWage - loanShare;
        totals[loan.loanClubId] = totals[loan.loanClubId]! + loanShare;
        totals[loan.parentClubId] = totals[loan.parentClubId]! + parentShare;
        continue;
      }
      if (player.isFreeAgent) continue;
      if (player.clubId != contract.clubId) {
        throw StateError('Contract club mismatch for ${player.id}.');
      }
      totals[contract.clubId] = totals[contract.clubId]! + contract.annualWage;
    }
    return totals;
  }

  @override
  List<Player> prepareNextSeasonPlayers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> activePlayers,
    required List<Player> retiredPlayers,
    required List<Player> youthIntake,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  }) {
    final returned = List<Player>.of(activePlayers);
    final retiredIds = retiredPlayers.map((player) => player.id).toSet();
    final expiredLoanIds = <String>[];
    for (final loan in _activeLoans.values) {
      if (retiredIds.contains(loan.playerId) ||
          loan.endSeasonIndex <= nextSeasonIndex) {
        final index = returned.indexWhere((player) => player.id == loan.playerId);
        if (index >= 0) {
          returned[index] = returned[index].copyWith(clubId: loan.parentClubId);
        }
        expiredLoanIds.add(loan.playerId);
      }
    }
    for (final playerId in expiredLoanIds) {
      _activeLoans.remove(playerId);
    }

    return contractController.prepareNextSeasonPlayers(
      seasonIndex: seasonIndex,
      nextSeasonIndex: nextSeasonIndex,
      activePlayers: returned,
      retiredPlayers: retiredPlayers,
      youthIntake: youthIntake,
      clubs: clubs,
      leaguesForNextSeason: leaguesForNextSeason,
      financeStates: financeStates,
    );
  }

  @override
  Map<String, int>? contractYearsRemainingForTransfer({
    required int nextSeasonIndex,
    required List<Player> players,
  }) =>
      contractController.contractYearsRemainingForTransfer(
        nextSeasonIndex: nextSeasonIndex,
        players: players,
      );

  @override
  void onTransferWindowCompleted({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> playersBeforeWindow,
    required List<Player> playersAfterWindow,
    required List<TransferDeal> transfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  }) {
    contractController.onTransferWindowCompleted(
      seasonIndex: seasonIndex,
      nextSeasonIndex: nextSeasonIndex,
      playersBeforeWindow: playersBeforeWindow,
      playersAfterWindow: playersAfterWindow,
      transfers: transfers,
      clubs: clubs,
      leaguesForNextSeason: leaguesForNextSeason,
      financeStates: financeStates,
    );
  }

  @override
  WorldFinanceSeasonFlows flowsForSeason({
    required int seasonIndex,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> openingFinanceStates,
  }) {
    final income = <String, Money>{};
    final expense = <String, Money>{};
    for (final obligation in _installmentObligations) {
      for (final installment in obligation.installments) {
        if (installment.dueSeasonIndex != seasonIndex) continue;
        income[obligation.fromClubId] =
            (income[obligation.fromClubId] ?? Money.zero) + installment.amount;
        expense[obligation.toClubId] =
            (expense[obligation.toClubId] ?? Money.zero) + installment.amount;
      }
    }
    return WorldFinanceSeasonFlows(
      transferInstallmentIncomeByClub: income,
      transferInstallmentExpenseByClub: expense,
    );
  }

  @override
  WorldTransferPostProcessResult afterPermanentTransfers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required List<TransferDeal> permanentTransfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
  }) {
    for (final deal in permanentTransfers) {
      if (deal.installments.isEmpty) continue;
      _installmentObligations.add(
        TransferInstallmentObligation(
          playerId: deal.playerId,
          fromClubId: deal.fromClubId,
          toClubId: deal.toClubId,
          createdSeasonIndex: seasonIndex,
          installments: List.unmodifiable(deal.installments),
        ),
      );
    }

    final contractsByPlayer = {
      for (final contract in contractController.activeContracts)
        contract.playerId: contract,
    };
    final loanResult = loanMarketEngine.simulateWindow(
      clubs: clubs,
      players: players,
      financeStates: financeStates,
      contractsByPlayer: contractsByPlayer,
      permanentlyMovedPlayerIds:
          permanentTransfers.map((deal) => deal.playerId).toSet(),
      careerSeed: careerSeed,
      seasonIndex: seasonIndex,
      nextSeasonIndex: nextSeasonIndex,
      simulationVersion: simulationVersion,
    );
    for (final loan in loanResult.agreements) {
      _activeLoans[loan.playerId] = loan;
      _loanHistory.add(loan);
    }
    return WorldTransferPostProcessResult(
      players: loanResult.players,
      financeStates: loanResult.financeStates,
      cashMovements: loanResult.cashMovements,
    );
  }
}
