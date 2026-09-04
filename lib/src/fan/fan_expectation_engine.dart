import '../finance/financial_health.dart';
import 'fan_expectation.dart';
import 'fan_season_context.dart';

class FanExpectationEngine {
  const FanExpectationEngine();

  FanExpectation generate(FanSeasonContext context) {
    if (!context.hasTransferWindow) {
      return const FanExpectation(
        type: FanExpectationType.none,
        reasonCode: 'no_next_window',
      );
    }

    if (context.promoted) {
      if (context.financiallyStressed) {
        return const FanExpectation(
          type: FanExpectationType.smartLoanReinforcement,
          reasonCode: 'promoted_but_financially_stressed',
        );
      }
      return const FanExpectation(
        type: FanExpectationType.prepareForHigherTier,
        reasonCode: 'promotion_requires_reinforcement',
      );
    }

    if (context.relegated) {
      if (context.financiallyStressed) {
        return const FanExpectation(
          type: FanExpectationType.financialDiscipline,
          reasonCode: 'relegated_and_financially_stressed',
        );
      }
      return const FanExpectation(
        type: FanExpectationType.rebuildAfterRelegation,
        reasonCode: 'relegation_requires_rebuild',
      );
    }

    if (context.financiallyStressed) {
      if (context.bottomQuarter || context.clubStrength < 62.0) {
        return const FanExpectation(
          type: FanExpectationType.smartLoanReinforcement,
          reasonCode: 'weak_squad_without_star_budget',
        );
      }
      return const FanExpectation(
        type: FanExpectationType.financialDiscipline,
        reasonCode: 'protect_club_finances',
      );
    }

    if (context.bottomQuarter) {
      return const FanExpectation(
        type: FanExpectationType.strengthenSquad,
        reasonCode: 'poor_league_finish',
      );
    }

    if (context.topQuarter &&
        (context.financialHealth == FinancialHealth.veryStrong ||
            context.financialHealth == FinancialHealth.solid)) {
      return const FanExpectation(
        type: FanExpectationType.ambitiousReinforcement,
        reasonCode: 'strong_position_and_finances',
      );
    }

    return const FanExpectation(
      type: FanExpectationType.measuredImprovement,
      reasonCode: 'balanced_context',
    );
  }
}
