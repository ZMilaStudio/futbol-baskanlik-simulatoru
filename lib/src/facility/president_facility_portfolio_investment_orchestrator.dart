import '../core/money.dart';
import '../election/president_management_profile.dart';
import '../save/facility_runtime_checkpoint.dart';
import 'facility_portfolio_investment_orchestrator.dart';

class PresidentFacilityPortfolioInvestmentPlan {
  const PresidentFacilityPortfolioInvestmentPlan({
    required this.stadiumPriorityScore,
    required this.trainingGroundPriorityScore,
    required this.stadiumTargetLevel,
    required this.trainingGroundTargetLevel,
    required this.maxStadiumUpgradesThisWindow,
    required this.maxTrainingGroundUpgradesThisWindow,
    required this.cashReserveBasisPoints,
  });

  final int stadiumPriorityScore;
  final int trainingGroundPriorityScore;
  final int stadiumTargetLevel;
  final int trainingGroundTargetLevel;
  final int maxStadiumUpgradesThisWindow;
  final int maxTrainingGroundUpgradesThisWindow;
  final int cashReserveBasisPoints;
}

class PresidentFacilityPortfolioInvestmentResult {
  const PresidentFacilityPortfolioInvestmentResult({
    required this.checkpoint,
    required this.plan,
    required this.beforeStadiumLevel,
    required this.afterStadiumLevel,
    required this.beforeTrainingGroundLevel,
    required this.afterTrainingGroundLevel,
    required this.appliedStadiumUpgrades,
    required this.appliedTrainingGroundUpgrades,
    required this.spend,
  });

  final FacilityRuntimeCheckpoint checkpoint;
  final PresidentFacilityPortfolioInvestmentPlan plan;
  final int beforeStadiumLevel;
  final int afterStadiumLevel;
  final int beforeTrainingGroundLevel;
  final int afterTrainingGroundLevel;
  final int appliedStadiumUpgrades;
  final int appliedTrainingGroundUpgrades;
  final Money spend;

  bool get invested =>
      appliedStadiumUpgrades > 0 || appliedTrainingGroundUpgrades > 0;
}

class PresidentFacilityPortfolioInvestmentOrchestrator {
  const PresidentFacilityPortfolioInvestmentOrchestrator({
    this.investment = const FacilityPortfolioInvestmentOrchestrator(),
  });

  final FacilityPortfolioInvestmentOrchestrator investment;

  PresidentFacilityPortfolioInvestmentPlan planFor(
    PresidentManagementProfile profile,
  ) {
    _validateTrait(profile.financialDiscipline, 'financialDiscipline');
    _validateTrait(profile.riskAppetite, 'riskAppetite');
    _validateTrait(profile.transferAmbition, 'transferAmbition');
    _validateTrait(profile.youthOrientation, 'youthOrientation');
    _validateTrait(profile.managerPatience, 'managerPatience');

    final stadiumScore =
        (profile.transferAmbition * 2 + profile.riskAppetite) ~/ 3;
    final trainingScore =
        (profile.youthOrientation * 2 + profile.managerPatience) ~/ 3;
    final strongestPriority =
        stadiumScore >= trainingScore ? stadiumScore : trainingScore;
    final reserveBps = (1700 +
            profile.financialDiscipline * 10 -
            strongestPriority * 5)
        .clamp(800, 2600)
        .toInt();

    return PresidentFacilityPortfolioInvestmentPlan(
      stadiumPriorityScore: stadiumScore,
      trainingGroundPriorityScore: trainingScore,
      stadiumTargetLevel: _targetLevel(stadiumScore),
      trainingGroundTargetLevel: _targetLevel(trainingScore),
      maxStadiumUpgradesThisWindow: _maxUpgrades(stadiumScore),
      maxTrainingGroundUpgradesThisWindow: _maxUpgrades(trainingScore),
      cashReserveBasisPoints: reserveBps,
    );
  }

  PresidentFacilityPortfolioInvestmentResult apply({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
    required PresidentManagementProfile profile,
  }) {
    checkpoint.validate();
    final plan = planFor(profile);
    final beforeStadium = checkpoint.stadiumFor(clubId).level;
    final beforeTraining = checkpoint.trainingGroundFor(clubId).level;
    var current = checkpoint;
    var trainingUpgrades = 0;
    var stadiumUpgrades = 0;

    // Fixed order is intentional: academy is applied by the outer M39 loop first,
    // then training ground, then stadium. This protects the legacy academy path
    // and makes cash competition deterministic.
    while (current.trainingGroundFor(clubId).level <
            plan.trainingGroundTargetLevel &&
        trainingUpgrades < plan.maxTrainingGroundUpgradesThisWindow) {
      final decision = investment.trainingGroundPolicy
          .upgrade(current.trainingGroundFor(clubId));
      if (!decision.upgraded ||
          !_preservesReserve(
            current,
            clubId,
            decision.cost,
            plan.cashReserveBasisPoints,
          )) {
        break;
      }
      final applied = investment.upgradeTrainingGround(
        checkpoint: current,
        clubId: clubId,
      );
      if (!applied.applied) break;
      current = applied.checkpoint;
      trainingUpgrades++;
    }

    while (current.stadiumFor(clubId).level < plan.stadiumTargetLevel &&
        stadiumUpgrades < plan.maxStadiumUpgradesThisWindow) {
      final decision =
          investment.stadiumPolicy.upgrade(current.stadiumFor(clubId));
      if (!decision.upgraded ||
          !_preservesReserve(
            current,
            clubId,
            decision.cost,
            plan.cashReserveBasisPoints,
          )) {
        break;
      }
      final applied = investment.upgradeStadium(
        checkpoint: current,
        clubId: clubId,
      );
      if (!applied.applied) break;
      current = applied.checkpoint;
      stadiumUpgrades++;
    }

    return PresidentFacilityPortfolioInvestmentResult(
      checkpoint: current,
      plan: plan,
      beforeStadiumLevel: beforeStadium,
      afterStadiumLevel: current.stadiumFor(clubId).level,
      beforeTrainingGroundLevel: beforeTraining,
      afterTrainingGroundLevel: current.trainingGroundFor(clubId).level,
      appliedStadiumUpgrades: stadiumUpgrades,
      appliedTrainingGroundUpgrades: trainingUpgrades,
      spend: current.totalInvestmentSpent - checkpoint.totalInvestmentSpent,
    );
  }

  bool _preservesReserve(
    FacilityRuntimeCheckpoint checkpoint,
    String clubId,
    Money cost,
    int reserveBasisPoints,
  ) {
    final finance = checkpoint.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == clubId);
    final reserve = finance.cash.scaleBasisPoints(reserveBasisPoints);
    return finance.cash - cost >= reserve;
  }

  int _targetLevel(int score) {
    if (score >= 85) return 5;
    if (score >= 70) return 4;
    if (score >= 55) return 3;
    if (score >= 40) return 2;
    if (score >= 25) return 1;
    return 0;
  }

  int _maxUpgrades(int score) {
    if (score >= 80) return 2;
    if (score >= 35) return 1;
    return 0;
  }

  void _validateTrait(int value, String name) {
    if (value < 0 || value > 100) {
      throw ArgumentError.value(value, name, 'Must be between 0 and 100.');
    }
  }
}
