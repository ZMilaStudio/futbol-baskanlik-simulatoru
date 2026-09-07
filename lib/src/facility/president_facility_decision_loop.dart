import '../election/president_management_profile.dart';
import '../save/facility_runtime_career_engine.dart';
import '../save/facility_runtime_checkpoint.dart';
import 'president_academy_investment_orchestrator.dart';

typedef PresidentFacilityProfileProvider = PresidentManagementProfile Function({
  required int seasonIndex,
  required String clubId,
});

class PresidentFacilitySeasonDecision {
  const PresidentFacilitySeasonDecision({
    required this.seasonIndex,
    required this.clubId,
    required this.presidentId,
    required this.targetLevel,
    required this.beforeLevel,
    required this.afterLevel,
    required this.appliedUpgrades,
    required this.cashReserveBasisPoints,
  });

  final int seasonIndex;
  final String clubId;
  final String presidentId;
  final int targetLevel;
  final int beforeLevel;
  final int afterLevel;
  final int appliedUpgrades;
  final int cashReserveBasisPoints;

  String get signature =>
      '$seasonIndex:$clubId:$presidentId:target=$targetLevel:'
      '$beforeLevel->$afterLevel:upgrades=$appliedUpgrades:'
      'reserve=$cashReserveBasisPoints';
}

class PresidentFacilityDecisionLoopResult {
  const PresidentFacilityDecisionLoopResult({
    required this.checkpoint,
    required this.decisions,
    required this.youthIntakeSignatures,
  });

  final FacilityRuntimeCheckpoint checkpoint;
  final List<PresidentFacilitySeasonDecision> decisions;
  final List<String> youthIntakeSignatures;
}

class PresidentFacilityDecisionLoopEngine {
  const PresidentFacilityDecisionLoopEngine({
    this.investment = const PresidentAcademyInvestmentOrchestrator(),
    this.career = const FacilityRuntimeCareerEngine(),
  });

  final PresidentAcademyInvestmentOrchestrator investment;
  final FacilityRuntimeCareerEngine career;

  PresidentFacilityDecisionLoopResult run({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
    required PresidentFacilityProfileProvider profileProvider,
  }) {
    checkpoint.validate();
    if (seasonCount < 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint;
    final decisions = <PresidentFacilitySeasonDecision>[];
    final youthIntakeSignatures = <String>[];

    for (var i = 0; i < seasonCount; i++) {
      final seasonIndex = current.nextSeasonIndex;
      final clubIds = current.academyFacilities.map((item) => item.clubId).toList()
        ..sort();

      for (final clubId in clubIds) {
        final profile = profileProvider(
          seasonIndex: seasonIndex,
          clubId: clubId,
        );
        final applied = investment.apply(
          checkpoint: current,
          clubId: clubId,
          profile: profile,
        );
        decisions.add(
          PresidentFacilitySeasonDecision(
            seasonIndex: seasonIndex,
            clubId: clubId,
            presidentId: profile.presidentId,
            targetLevel: applied.plan.targetLevel,
            beforeLevel: applied.beforeLevel,
            afterLevel: applied.afterLevel,
            appliedUpgrades: applied.appliedUpgrades,
            cashReserveBasisPoints: applied.plan.cashReserveBasisPoints,
          ),
        );
        current = applied.checkpoint;
      }

      final resumed = career.resumeWithReport(
        checkpoint: current,
        seasonCount: 1,
      );
      youthIntakeSignatures.addAll(
        resumed.report.seasons
            .expand((season) => season.youthIntakeAfterSeason)
            .map((player) => player.signature),
      );
      current = resumed.checkpoint;
    }

    return PresidentFacilityDecisionLoopResult(
      checkpoint: current,
      decisions: List.unmodifiable(decisions),
      youthIntakeSignatures: List.unmodifiable(youthIntakeSignatures),
    );
  }
}
