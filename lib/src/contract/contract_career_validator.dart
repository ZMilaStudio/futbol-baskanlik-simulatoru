import '../core/money.dart';
import '../player/player.dart';
import '../world/world_career_validator.dart';
import 'contract_career_report.dart';
import 'contract_event.dart';
import 'player_contract.dart';

class ContractCareerValidator {
  const ContractCareerValidator({
    this.worldValidator = const WorldCareerValidator(),
  });

  final WorldCareerValidator worldValidator;

  List<String> validate(ContractCareerReport report) {
    final issues = <String>[
      ...worldValidator.validate(report.worldReport),
    ];
    if (report.worldReport.seasons.isEmpty) return issues;

    final finalSeasonIndex = report.worldReport.seasons.last.seasonIndex;
    final finalPlayersById = {
      for (final player in report.worldReport.finalPlayers) player.id: player,
    };
    final contractsByPlayer = <String, PlayerContract>{};
    for (final contract in report.activeContracts) {
      if (contractsByPlayer.containsKey(contract.playerId)) {
        issues.add('Duplicate active contract for ${contract.playerId}.');
        continue;
      }
      contractsByPlayer[contract.playerId] = contract;
      final player = finalPlayersById[contract.playerId];
      if (player == null) {
        issues.add('Contract references missing final player ${contract.playerId}.');
        continue;
      }
      if (player.isFreeAgent) {
        issues.add('Free agent ${player.id} has an active club contract.');
      }
      if (player.clubId != contract.clubId) {
        issues.add('Final contract club mismatch for ${player.id}.');
      }
      if (!contract.isActiveDuring(finalSeasonIndex)) {
        issues.add('Final contract is not active for ${player.id}.');
      }
      if (contract.startSeasonIndex >= contract.endSeasonIndex) {
        issues.add('Invalid contract term for ${player.id}.');
      }
      if (contract.annualWage <= Money.zero) {
        issues.add('Non-positive contract wage for ${player.id}.');
      }
    }

    for (final player in report.worldReport.finalPlayers) {
      final hasContract = contractsByPlayer.containsKey(player.id);
      if (player.isFreeAgent && hasContract) {
        issues.add('Free agent ${player.id} must not have a contract.');
      }
      if (!player.isFreeAgent && !hasContract) {
        issues.add('Club player ${player.id} is missing a contract.');
      }
    }

    for (final event in report.events) {
      if (event.type == ContractEventType.released) {
        if (event.toClubId != null || event.annualWage != null) {
          issues.add('Release event has invalid payload for ${event.playerId}.');
        }
        continue;
      }
      if (event.toClubId == null ||
          event.annualWage == null ||
          event.annualWage! <= Money.zero ||
          event.endSeasonIndex == null ||
          event.endSeasonIndex! <= event.seasonIndex) {
        issues.add('Contract event has invalid payload for ${event.playerId}.');
      }
    }

    for (final season in report.worldReport.seasons) {
      for (final finance in season.finances) {
        if (finance.wageExpense <= Money.zero) {
          issues.add(
            'Season ${season.seasonIndex} ${finance.clubId} has no wage expense.',
          );
        }
      }
    }

    return issues;
  }
}
