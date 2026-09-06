import '../core/money.dart';
import '../election/president_management_profile.dart';
import '../save/facility_runtime_checkpoint.dart';
import 'academy_facility.dart';
import 'facility_investment_orchestrator.dart';

class PresidentAcademyInvestmentPlan {
  const PresidentAcademyInvestmentPlan({
    required this.targetLevel,
    required this.maxUpgradesThisWindow,
    required this.cashReserveBasisPoints,
  });

  final int targetLevel;
  final int maxUpgradesThisWindow;
  final int cashReserveBasisPoints;
}

class PresidentAcademyInvestmentResult {
  const PresidentAcademyInvestmentResult({
    required this.checkpoint,
    required this.plan,
    required this.beforeLevel,
    required this.afterLevel,
    required this.appliedUpgrades,
    required this.spend,
  });

  final FacilityRuntimeCheckpoint checkpoint;
  final PresidentAcademyInvestmentPlan plan;
  final int beforeLevel;
  final int afterLevel;
  final int appliedUpgrades;
  final Money spend;

  bool get invested => appliedUpgrades > 0;
}

class PresidentAcademyInvestmentOrchestrator {
  const PresidentAcademyInvestmentOrchestrator({
    this.policy = const AcademyInvestmentPolicy(),
    this.investment = const FacilityInvestmentOrchestrator(),
  });

  final AcademyInvestmentPolicy policy;
  final FacilityInvestmentOrchestrator investment;

  PresidentAcademyInvestmentPlan planFor(
    PresidentManagementProfile profile,
  ) {
    final youth = profile.youthOrientation;
    final discipline = profile.financialDiscipline;
    if (youth < 0 || youth > 100) {
      throw ArgumentError.value(youth, 'youthOrientation');
    }
    if (discipline < 0 || discipline > 100) {
      throw ArgumentError.value(discipline, 'financialDiscipline');
    }

    final targetLevel = policy.targetLevelForYouthOrientation(youth);
    final maxUpgrades = youth >= 80
        ? 2
        : youth >= 30
            ? 1
            : 0;
    final reserveBps =
        (1500 + discipline * 12 - youth * 8).clamp(700, 2200).toInt();

    return PresidentAcademyInvestmentPlan(
      targetLevel: targetLevel,
      maxUpgradesThisWindow: maxUpgrades,
      cashReserveBasisPoints: reserveBps,
    );
  }

  PresidentAcademyInvestmentResult apply({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
    required PresidentManagementProfile profile,
  }) {
    checkpoint.validate();
    final plan = planFor(profile);
    final beforeLevel = checkpoint.facilityFor(clubId).level;
    var current = checkpoint;
    var applied = 0;

    while (current.facilityFor(clubId).level < plan.targetLevel &&
        applied < plan.maxUpgradesThisWindow) {
      final nextDecision = policy.upgrade(current.facilityFor(clubId));
      if (!nextDecision.upgraded) break;

      final finance = current.world.nextSeasonFinanceStates
          .firstWhere((state) => state.clubId == clubId);
      final reserve = finance.cash.scaleBasisPoints(plan.cashReserveBasisPoints);
      if (finance.cash - nextDecision.cost < reserve) break;

      final result = investment.upgradeAcademy(
        checkpoint: current,
        clubId: clubId,
      );
      if (!result.applied) break;
      current = result.checkpoint;
      applied++;
    }

    return PresidentAcademyInvestmentResult(
      checkpoint: current,
      plan: plan,
      beforeLevel: beforeLevel,
      afterLevel: current.facilityFor(clubId).level,
      appliedUpgrades: applied,
      spend: current.totalInvestmentSpent - checkpoint.totalInvestmentSpent,
    );
  }
}
