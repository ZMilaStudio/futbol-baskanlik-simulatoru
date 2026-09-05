import '../contract/contract_event.dart';
import '../contract/player_contract.dart';
import '../manager/manager.dart';
import '../manager/manager_assignment.dart';
import '../manager/manager_career_season.dart';
import '../transfer/loan_agreement.dart';
import '../transfer/transfer_installment.dart';
import '../world/world_career_report.dart';
import '../world/world_checkpoint.dart';

class AdvancedTransferRuntimeState {
  AdvancedTransferRuntimeState({
    required Iterable<PlayerContract> activeContracts,
    required Iterable<ContractEvent> contractEvents,
    required Iterable<LoanAgreement> activeLoans,
    required Iterable<LoanAgreement> loanHistory,
    required Iterable<TransferInstallmentObligation> installmentObligations,
  })  : activeContracts = List.unmodifiable(activeContracts),
        contractEvents = List.unmodifiable(contractEvents),
        activeLoans = List.unmodifiable(activeLoans),
        loanHistory = List.unmodifiable(loanHistory),
        installmentObligations = List.unmodifiable(installmentObligations);

  final List<PlayerContract> activeContracts;
  final List<ContractEvent> contractEvents;
  final List<LoanAgreement> activeLoans;
  final List<LoanAgreement> loanHistory;
  final List<TransferInstallmentObligation> installmentObligations;

  void validate(WorldCheckpoint world) {
    final clubIds = world.baseClubs.map((club) => club.id).toSet();
    final playersById = {
      for (final player in world.nextSeasonPlayers) player.id: player,
    };
    final contractByPlayer = <String, PlayerContract>{};
    for (final contract in activeContracts) {
      if (!playersById.containsKey(contract.playerId) ||
          !clubIds.contains(contract.clubId) ||
          contract.startSeasonIndex >= contract.endSeasonIndex ||
          contract.annualWage.minorUnits < 0 ||
          contractByPlayer.containsKey(contract.playerId)) {
        throw ArgumentError(
          'Invalid or duplicate active contract ${contract.playerId}.',
        );
      }
      contractByPlayer[contract.playerId] = contract;
    }

    final activeLoanIds = <String>{};
    for (final loan in activeLoans) {
      final player = playersById[loan.playerId];
      final contract = contractByPlayer[loan.playerId];
      if (player == null ||
          contract == null ||
          !activeLoanIds.add(loan.playerId) ||
          !clubIds.contains(loan.parentClubId) ||
          !clubIds.contains(loan.loanClubId) ||
          loan.parentClubId == loan.loanClubId ||
          player.clubId != loan.loanClubId ||
          contract.clubId != loan.parentClubId ||
          !loan.isActiveDuring(world.nextSeasonIndex) ||
          loan.loanFee.minorUnits < 0 ||
          loan.loanClubWageShareBps < 0 ||
          loan.loanClubWageShareBps > 10000) {
        throw ArgumentError('Invalid active loan ${loan.playerId}.');
      }
    }

    final historySignatures = <String>{};
    for (final loan in loanHistory) {
      if (!clubIds.contains(loan.parentClubId) ||
          !clubIds.contains(loan.loanClubId) ||
          loan.startSeasonIndex >= loan.endSeasonIndex ||
          loan.loanFee.minorUnits < 0 ||
          loan.loanClubWageShareBps < 0 ||
          loan.loanClubWageShareBps > 10000 ||
          !historySignatures.add(loan.signature)) {
        throw ArgumentError('Invalid or duplicate loan history entry.');
      }
    }
    for (final loan in activeLoans) {
      if (!historySignatures.contains(loan.signature)) {
        throw ArgumentError('Active loan must also exist in loan history.');
      }
    }

    for (final obligation in installmentObligations) {
      if (!clubIds.contains(obligation.fromClubId) ||
          !clubIds.contains(obligation.toClubId) ||
          obligation.fromClubId == obligation.toClubId ||
          obligation.installments.isEmpty) {
        throw ArgumentError(
          'Invalid installment obligation ${obligation.playerId}.',
        );
      }
      for (final installment in obligation.installments) {
        if (installment.amount.minorUnits <= 0 ||
            installment.dueSeasonIndex <= obligation.createdSeasonIndex) {
          throw ArgumentError(
            'Invalid installment for ${obligation.playerId}.',
          );
        }
      }
    }

    for (final event in contractEvents) {
      if (event.playerId.isEmpty ||
          (event.fromClubId != null && !clubIds.contains(event.fromClubId)) ||
          (event.toClubId != null && !clubIds.contains(event.toClubId)) ||
          (event.annualWage != null && event.annualWage!.minorUnits < 0)) {
        throw ArgumentError('Invalid contract event ${event.playerId}.');
      }
    }
  }
}

class ManagerRuntimeState {
  ManagerRuntimeState({
    required Iterable<Manager> managers,
    required Iterable<ManagerAssignment> assignments,
    required Iterable<ManagerCareerSeason> seasons,
  })  : managers = List.unmodifiable(managers),
        assignments = List.unmodifiable(assignments),
        seasons = List.unmodifiable(seasons);

  final List<Manager> managers;
  final List<ManagerAssignment> assignments;
  final List<ManagerCareerSeason> seasons;

  void validate(WorldCheckpoint world) {
    final clubIds = world.baseClubs.map((club) => club.id).toSet();
    final managerIds = <String>{};
    for (final manager in managers) {
      if (manager.id.isEmpty ||
          manager.name.isEmpty ||
          manager.startAge < 20 ||
          manager.retirementAge <= manager.startAge ||
          !managerIds.add(manager.id)) {
        throw ArgumentError('Invalid or duplicate manager ${manager.id}.');
      }
    }

    final assignmentClubs = <String>{};
    final assignedManagers = <String>{};
    for (final assignment in assignments) {
      if (!clubIds.contains(assignment.clubId) ||
          !managerIds.contains(assignment.managerId) ||
          !assignmentClubs.add(assignment.clubId) ||
          !assignedManagers.add(assignment.managerId) ||
          assignment.completedSeasons < 0 ||
          !assignment.boardRelationship.isFinite ||
          assignment.boardRelationship < 0 ||
          assignment.boardRelationship > 100) {
        throw ArgumentError(
          'Invalid manager assignment ${assignment.clubId}.',
        );
      }
    }
    if (assignmentClubs.length != clubIds.length ||
        assignmentClubs.difference(clubIds).isNotEmpty ||
        clubIds.difference(assignmentClubs).isNotEmpty) {
      throw ArgumentError('Manager state must assign every club exactly once.');
    }

    if (seasons.length > world.completedSeasons) {
      throw ArgumentError(
        'Manager history cannot exceed completed season count.',
      );
    }
    final firstRetainedSeasonIndex = world.nextSeasonIndex - seasons.length;
    for (var index = 0; index < seasons.length; index++) {
      final season = seasons[index];
      final expectedIndex = firstRetainedSeasonIndex + index;
      if (season.seasonIndex != expectedIndex || season.clubs.length != 48) {
        throw ArgumentError('Invalid manager season ${season.seasonIndex}.');
      }
      final seasonClubIds = season.clubs.map((item) => item.clubId).toSet();
      if (seasonClubIds.length != 48 ||
          seasonClubIds.difference(clubIds).isNotEmpty ||
          clubIds.difference(seasonClubIds).isNotEmpty) {
        throw ArgumentError(
          'Manager season ${season.seasonIndex} must cover every club.',
        );
      }
      for (final clubSeason in season.clubs) {
        if (!managerIds.contains(clubSeason.managerId) ||
            !clubSeason.fitScore.isFinite ||
            !clubSeason.strengthImpact.isFinite ||
            !clubSeason.relationshipBefore.isFinite ||
            !clubSeason.relationshipAfter.isFinite) {
          throw ArgumentError('Invalid manager club-season state.');
        }
      }
      for (final change in season.changesAfterSeason) {
        if (!clubIds.contains(change.clubId) ||
            !managerIds.contains(change.fromManagerId) ||
            !managerIds.contains(change.toManagerId)) {
          throw ArgumentError('Invalid manager change history.');
        }
      }
    }
  }
}

class AdvancedRuntimeCheckpoint {
  AdvancedRuntimeCheckpoint({
    required this.world,
    required this.transfer,
    required this.manager,
  }) {
    validate();
  }

  final WorldCheckpoint world;
  final AdvancedTransferRuntimeState transfer;
  final ManagerRuntimeState manager;

  int get completedSeasons => world.completedSeasons;
  int get nextSeasonIndex => world.nextSeasonIndex;

  void validate() {
    world.validate();
    transfer.validate(world);
    manager.validate(world);
  }
}

class AdvancedRuntimeSimulationResult {
  const AdvancedRuntimeSimulationResult({
    required this.report,
    required this.checkpoint,
  });

  final WorldCareerReport report;
  final AdvancedRuntimeCheckpoint checkpoint;
}
