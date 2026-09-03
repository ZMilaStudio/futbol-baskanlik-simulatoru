import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../world/league_tier.dart';
import 'manager.dart';
import 'manager_profile.dart';

class ManagerFitModel {
  const ManagerFitModel();

  double score({
    required Manager manager,
    required Club club,
    required List<Player> players,
    required LeagueTier leagueTier,
    required ClubFinanceState financeState,
  }) {
    if (players.isEmpty) {
      throw ArgumentError('Manager fit requires a non-empty squad.');
    }

    final averageAge =
        players.fold<double>(0, (sum, player) => sum + player.age) /
            players.length;
    final averagePotentialGap = players.fold<double>(
          0,
          (sum, player) => sum + (player.potential - player.ability).clamp(0, 30),
        ) /
        players.length;
    final debtPressure = financeState.debt > financeState.cash;
    final strongLiquidity = financeState.cash.minorUnits >
        financeState.debt.minorUnits * 2;

    var value = 50.0;
    value += (manager.boardCooperation - 60) * 0.06;

    if (debtPressure && manager.budgetDemand > 50) {
      value -= (manager.budgetDemand - 50) * 0.18;
    }

    switch (manager.profile) {
      case ManagerProfile.balanced:
        value += 5;
        value += (manager.manManagement - 60) * 0.08;
      case ManagerProfile.youthDeveloper:
        value += (26.0 - averageAge) * 1.8;
        value += averagePotentialGap * 1.1;
        value += (manager.youthDevelopment - 60) * 0.12;
        if (leagueTier != LeagueTier.first) value += 3;
      case ManagerProfile.budgetBuilder:
        if (debtPressure) value += 12;
        if (leagueTier == LeagueTier.second) value += 4;
        if (leagueTier == LeagueTier.third) value += 8;
        value += (55 - manager.budgetDemand) * 0.22;
      case ManagerProfile.starManager:
        if (leagueTier == LeagueTier.first) value += 14;
        if (leagueTier == LeagueTier.second) value -= 4;
        if (leagueTier == LeagueTier.third) value -= 12;
        value += (club.strength - 68) * 0.65;
        if (strongLiquidity) value += 5;
      case ManagerProfile.resultsFirst:
        value += (club.strength - 62) * 0.35;
        value += (manager.coaching - 65) * 0.18;
        if (leagueTier == LeagueTier.first) value += 4;
    }

    return value.clamp(15.0, 95.0).toDouble();
  }
}
