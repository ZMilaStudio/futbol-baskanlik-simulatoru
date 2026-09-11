import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../save/facility_runtime_checkpoint.dart';
import '../world/world_checkpoint.dart';
import 'academy_facility.dart';

class FacilityInvestmentResult {
  const FacilityInvestmentResult({
    required this.checkpoint,
    required this.decision,
    required this.applied,
  });

  final FacilityRuntimeCheckpoint checkpoint;
  final AcademyInvestmentDecision decision;
  final bool applied;
}

class FacilityInvestmentOrchestrator {
  const FacilityInvestmentOrchestrator({
    this.policy = const AcademyInvestmentPolicy(),
  });

  final AcademyInvestmentPolicy policy;

  FacilityInvestmentResult upgradeAcademy({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
  }) {
    checkpoint.validate();
    final before = checkpoint.facilityFor(clubId);
    final decision = policy.upgrade(before);
    if (!decision.upgraded) {
      return FacilityInvestmentResult(
        checkpoint: checkpoint,
        decision: decision,
        applied: false,
      );
    }

    final finance = checkpoint.world.nextSeasonFinanceStates
        .firstWhere((state) => state.clubId == clubId);
    if (finance.cash < decision.cost) {
      return FacilityInvestmentResult(
        checkpoint: checkpoint,
        decision: decision,
        applied: false,
      );
    }

    final updatedFinances = checkpoint.world.nextSeasonFinanceStates
        .map(
          (state) => state.clubId == clubId
              ? ClubFinanceState(
                  clubId: state.clubId,
                  cash: state.cash - decision.cost,
                  debt: state.debt,
                )
              : state,
        )
        .toList(growable: false);
    final updatedFacilities = checkpoint.academyFacilities
        .map((state) => state.clubId == clubId ? decision.after : state)
        .toList(growable: false);
    final updatedWorld = WorldCheckpoint(
      config: checkpoint.world.config,
      completedSeasons: checkpoint.world.completedSeasons,
      baseClubs: checkpoint.world.baseClubs,
      nextSeasonLeagues: checkpoint.world.nextSeasonLeagues,
      nextSeasonPlayers: checkpoint.world.nextSeasonPlayers,
      nextSeasonFinanceStates: updatedFinances,
    );

    return FacilityInvestmentResult(
      checkpoint: FacilityRuntimeCheckpoint(
        world: updatedWorld,
        academyFacilities: updatedFacilities,
        stadiumFacilities: checkpoint.stadiumFacilities,
        trainingGroundFacilities: checkpoint.trainingGroundFacilities,
        totalInvestmentSpent: checkpoint.totalInvestmentSpent + decision.cost,
      ),
      decision: decision,
      applied: true,
    );
  }

  FacilityRuntimeCheckpoint upgradeTowardTarget({
    required FacilityRuntimeCheckpoint checkpoint,
    required String clubId,
    required int targetLevel,
  }) {
    if (targetLevel < 0 || targetLevel > AcademyInvestmentPolicy.maxLevel) {
      throw ArgumentError.value(targetLevel, 'targetLevel');
    }
    var current = checkpoint;
    while (current.facilityFor(clubId).level < targetLevel) {
      final result = upgradeAcademy(checkpoint: current, clubId: clubId);
      if (!result.applied) break;
      current = result.checkpoint;
    }
    return current;
  }

  Money spendForClub({
    required FacilityRuntimeCheckpoint before,
    required FacilityRuntimeCheckpoint after,
  }) => after.totalInvestmentSpent - before.totalInvestmentSpent;
}
