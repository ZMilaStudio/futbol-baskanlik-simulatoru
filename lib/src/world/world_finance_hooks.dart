import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import 'world_league.dart';

class WorldFinanceSeasonFlows {
  const WorldFinanceSeasonFlows({
    this.transferInstallmentIncomeByClub = const {},
    this.transferInstallmentExpenseByClub = const {},
  });

  final Map<String, Money> transferInstallmentIncomeByClub;
  final Map<String, Money> transferInstallmentExpenseByClub;
}

abstract interface class WorldFinanceHooks {
  WorldFinanceSeasonFlows flowsForSeason({
    required int seasonIndex,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> openingFinanceStates,
  });
}

class NoopWorldFinanceHooks implements WorldFinanceHooks {
  const NoopWorldFinanceHooks();

  @override
  WorldFinanceSeasonFlows flowsForSeason({
    required int seasonIndex,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> openingFinanceStates,
  }) =>
      const WorldFinanceSeasonFlows();
}
