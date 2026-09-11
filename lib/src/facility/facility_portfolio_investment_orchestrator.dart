import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../save/facility_runtime_checkpoint.dart';
import '../world/world_checkpoint.dart';
import 'stadium_facility.dart';
import 'training_ground_facility.dart';

enum FacilityPortfolioType { stadium, trainingGround }

class FacilityPortfolioInvestmentResult {
  const FacilityPortfolioInvestmentResult({
    required this.checkpoint,
    required this.type,
    required this.beforeLevel,
    required this.afterLevel,
    required this.cost,
    required this.applied,
  });

  final FacilityRuntimeCheckpoint checkpoint;
  final FacilityPortfolioType type;
  final int beforeLevel;
  final int afterLevel;
  final Money cost;
  final bool applied;
}

class FacilityPortfolioInvestmentOrchestrator {
  const FacilityPortfolioInvestmentOrchestrator({
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
    this.trainingGroundPolicy = const TrainingGroundInvestmentPolicy(),
  });

  final StadiumInvestmentPolicy stadiumPolicy;
  final TrainingGroundInvestmentPolicy trainingGroundPolicy;

  FacilityPortfolioInvestmentResult upgradeStadium({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
  }) {
    checkpoint.validate();
    final before = checkpoint.stadiumFor(clubId);
    final decision = stadiumPolicy.upgrade(before);
    if (!decision.upgraded || !_canAfford(checkpoint, clubId, decision.cost)) {
      return FacilityPortfolioInvestmentResult(
        checkpoint: checkpoint,
        type: FacilityPortfolioType.stadium,
        beforeLevel: before.level,
        afterLevel: before.level,
        cost: decision.cost,
        applied: false,
      );
    }

    final updated = FacilityRuntimeCheckpoint(
      world: _charge(checkpoint, clubId, decision.cost),
      academyFacilities: checkpoint.academyFacilities,
      stadiumFacilities: checkpoint.stadiumFacilities.map(
        (state) => state.clubId == clubId ? decision.after : state,
      ),
      trainingGroundFacilities: checkpoint.trainingGroundFacilities,
      totalInvestmentSpent: checkpoint.totalInvestmentSpent + decision.cost,
    );
    return FacilityPortfolioInvestmentResult(
      checkpoint: updated,
      type: FacilityPortfolioType.stadium,
      beforeLevel: before.level,
      afterLevel: decision.after.level,
      cost: decision.cost,
      applied: true,
    );
  }

  FacilityPortfolioInvestmentResult upgradeTrainingGround({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
  }) {
    checkpoint.validate();
    final before = checkpoint.trainingGroundFor(clubId);
    final decision = trainingGroundPolicy.upgrade(before);
    if (!decision.upgraded || !_canAfford(checkpoint, clubId, decision.cost)) {
      return FacilityPortfolioInvestmentResult(
        checkpoint: checkpoint,
        type: FacilityPortfolioType.trainingGround,
        beforeLevel: before.level,
        afterLevel: before.level,
        cost: decision.cost,
        applied: false,
      );
    }

    final updated = FacilityRuntimeCheckpoint(
      world: _charge(checkpoint, clubId, decision.cost),
      academyFacilities: checkpoint.academyFacilities,
      stadiumFacilities: checkpoint.stadiumFacilities,
      trainingGroundFacilities: checkpoint.trainingGroundFacilities.map(
        (state) => state.clubId == clubId ? decision.after : state,
      ),
      totalInvestmentSpent: checkpoint.totalInvestmentSpent + decision.cost,
    );
    return FacilityPortfolioInvestmentResult(
      checkpoint: updated,
      type: FacilityPortfolioType.trainingGround,
      beforeLevel: before.level,
      afterLevel: decision.after.level,
      cost: decision.cost,
      applied: true,
    );
  }

  FacilityRuntimeCheckpoint upgradeStadiumTowardTarget({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
    required int targetLevel,
  }) {
    if (targetLevel < 0 || targetLevel > StadiumInvestmentPolicy.maxLevel) {
      throw ArgumentError.value(targetLevel, 'targetLevel');
    }
    var current = checkpoint;
    while (current.stadiumFor(clubId).level < targetLevel) {
      final result = upgradeStadium(checkpoint: current, clubId: clubId);
      if (!result.applied) break;
      current = result.checkpoint;
    }
    return current;
  }

  FacilityRuntimeCheckpoint upgradeTrainingGroundTowardTarget({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
    required int targetLevel,
  }) {
    if (targetLevel < 0 ||
        targetLevel > TrainingGroundInvestmentPolicy.maxLevel) {
      throw ArgumentError.value(targetLevel, 'targetLevel');
    }
    var current = checkpoint;
    while (current.trainingGroundFor(clubId).level < targetLevel) {
      final result = upgradeTrainingGround(
        checkpoint: current,
        clubId: clubId,
      );
      if (!result.applied) break;
      current = result.checkpoint;
    }
    return current;
  }

  bool _canAfford(
    FacilityRuntimeCheckpoint checkpoint,
    String clubId,
    Money cost,
  ) {
    final finance = checkpoint.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == clubId);
    return finance.cash >= cost;
  }

  WorldCheckpoint _charge(
    FacilityRuntimeCheckpoint checkpoint,
    String clubId,
    Money cost,
  ) {
    final updatedFinances = checkpoint.world.nextSeasonFinanceStates
        .map(
          (state) => state.clubId == clubId
              ? ClubFinanceState(
                  clubId: state.clubId,
                  cash: state.cash - cost,
                  debt: state.debt,
                )
              : state,
        )
        .toList(growable: false);
    return WorldCheckpoint(
      config: checkpoint.world.config,
      completedSeasons: checkpoint.world.completedSeasons,
      baseClubs: checkpoint.world.baseClubs,
      nextSeasonLeagues: checkpoint.world.nextSeasonLeagues,
      nextSeasonPlayers: checkpoint.world.nextSeasonPlayers,
      nextSeasonFinanceStates: updatedFinances,
    );
  }
}
