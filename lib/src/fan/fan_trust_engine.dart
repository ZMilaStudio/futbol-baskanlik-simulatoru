import '../finance/financial_health.dart';
import 'fan_expectation.dart';
import 'fan_season_context.dart';
import 'fan_trust_reason.dart';

class FanTrustEngine {
  const FanTrustEngine();

  List<FanTrustReason> evaluate({
    required FanSeasonContext context,
    required FanExpectation expectation,
  }) {
    final reasons = <FanTrustReason>[];
    _addSportingReason(context, reasons);
    _addFinancialReasons(context, reasons);
    _addTransferReason(context, expectation, reasons);
    return reasons;
  }

  void _addSportingReason(
    FanSeasonContext context,
    List<FanTrustReason> reasons,
  ) {
    if (context.promoted) {
      reasons.add(const FanTrustReason(
        dimension: FanTrustDimension.sporting,
        code: 'promotion',
        delta: 5,
      ));
      return;
    }
    if (context.relegated) {
      reasons.add(const FanTrustReason(
        dimension: FanTrustDimension.sporting,
        code: 'relegation',
        delta: -6,
      ));
      return;
    }
    if (context.leaguePosition == 1) {
      reasons.add(const FanTrustReason(
        dimension: FanTrustDimension.sporting,
        code: 'league_champion',
        delta: 4,
      ));
    } else if (context.topQuarter) {
      reasons.add(const FanTrustReason(
        dimension: FanTrustDimension.sporting,
        code: 'top_quarter_finish',
        delta: 2,
      ));
    } else if (context.bottomQuarter) {
      reasons.add(const FanTrustReason(
        dimension: FanTrustDimension.sporting,
        code: 'bottom_quarter_finish',
        delta: -2,
      ));
    }
  }

  void _addFinancialReasons(
    FanSeasonContext context,
    List<FanTrustReason> reasons,
  ) {
    switch (context.financialHealth) {
      case FinancialHealth.veryStrong:
        reasons.add(const FanTrustReason(
          dimension: FanTrustDimension.financial,
          code: 'very_strong_finances',
          delta: 2,
        ));
      case FinancialHealth.solid:
        reasons.add(const FanTrustReason(
          dimension: FanTrustDimension.financial,
          code: 'solid_finances',
          delta: 1,
        ));
      case FinancialHealth.balanced:
        break;
      case FinancialHealth.tight:
        reasons.add(const FanTrustReason(
          dimension: FanTrustDimension.financial,
          code: 'tight_finances',
          delta: -2,
        ));
      case FinancialHealth.debtCrisis:
        reasons.add(const FanTrustReason(
          dimension: FanTrustDimension.financial,
          code: 'debt_crisis',
          delta: -4,
        ));
    }
    if (context.emergencyBorrowing.minorUnits > 0) {
      reasons.add(const FanTrustReason(
        dimension: FanTrustDimension.financial,
        code: 'emergency_borrowing',
        delta: -1,
      ));
    }
  }

  void _addTransferReason(
    FanSeasonContext context,
    FanExpectation expectation,
    List<FanTrustReason> reasons,
  ) {
    if (!context.hasTransferWindow || expectation.type == FanExpectationType.none) {
      return;
    }
    final aggressiveSpend =
        context.transferSpendBpsOfCash > 3500 || context.installmentBuys >= 2;
    final incoming = context.totalIncoming;

    switch (expectation.type) {
      case FanExpectationType.none:
        return;
      case FanExpectationType.financialDiscipline:
        reasons.add(FanTrustReason(
          dimension: FanTrustDimension.transfer,
          code: aggressiveSpend
              ? 'ignored_financial_discipline'
              : 'respected_financial_discipline',
          delta: aggressiveSpend ? -4 : 2,
        ));
      case FanExpectationType.smartLoanReinforcement:
        if (context.loanIns > 0) {
          reasons.add(const FanTrustReason(
            dimension: FanTrustDimension.transfer,
            code: 'used_smart_loan',
            delta: 4,
          ));
        } else if (context.permanentBuys > 0 &&
            context.transferSpendBpsOfCash <= 2500 &&
            context.installmentBuys == 0) {
          reasons.add(const FanTrustReason(
            dimension: FanTrustDimension.transfer,
            code: 'affordable_alternative_reinforcement',
            delta: 1,
          ));
        } else {
          reasons.add(FanTrustReason(
            dimension: FanTrustDimension.transfer,
            code: aggressiveSpend
                ? 'overspent_in_financial_stress'
                : 'failed_to_reinforce_cheaply',
            delta: aggressiveSpend ? -4 : -2,
          ));
        }
      case FanExpectationType.strengthenSquad:
        reasons.add(FanTrustReason(
          dimension: FanTrustDimension.transfer,
          code: incoming > 0 ? 'squad_strengthened' : 'squad_need_ignored',
          delta: incoming > 0 ? 3 : -3,
        ));
      case FanExpectationType.ambitiousReinforcement:
        final delta = context.permanentBuys > 0
            ? 3
            : context.loanIns > 0
                ? 1
                : -2;
        reasons.add(FanTrustReason(
          dimension: FanTrustDimension.transfer,
          code: context.permanentBuys > 0
              ? 'ambitious_permanent_signing'
              : context.loanIns > 0
                  ? 'limited_ambition_loan'
                  : 'ambition_not_backed',
          delta: delta,
        ));
      case FanExpectationType.rebuildAfterRelegation:
        reasons.add(FanTrustReason(
          dimension: FanTrustDimension.transfer,
          code: incoming > 0 ? 'relegation_rebuild_started' : 'rebuild_not_started',
          delta: incoming > 0 ? 3 : -3,
        ));
      case FanExpectationType.prepareForHigherTier:
        reasons.add(FanTrustReason(
          dimension: FanTrustDimension.transfer,
          code: incoming > 0 ? 'promotion_squad_prepared' : 'promotion_squad_unchanged',
          delta: incoming > 0 ? 3 : -3,
        ));
      case FanExpectationType.measuredImprovement:
        final delta = incoming == 0
            ? -1
            : incoming <= 2
                ? 2
                : aggressiveSpend
                    ? -1
                    : 1;
        reasons.add(FanTrustReason(
          dimension: FanTrustDimension.transfer,
          code: incoming == 0
              ? 'no_measured_improvement'
              : aggressiveSpend && incoming > 2
                  ? 'improvement_became_aggressive'
                  : 'measured_improvement_delivered',
          delta: delta,
        ));
    }
  }
}
