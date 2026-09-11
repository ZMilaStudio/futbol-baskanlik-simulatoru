import '../core/money.dart';
import '../election/president_management_profile.dart';
import '../save/facility_runtime_career_engine.dart';
import '../save/facility_runtime_checkpoint.dart';
import 'president_academy_investment_orchestrator.dart';
import 'president_facility_portfolio_investment_orchestrator.dart';

typedef PresidentFacilityPortfolioProfileProvider =
    PresidentManagementProfile Function({
  required int seasonIndex,
  required String clubId,
});

class PresidentFacilityPortfolioSeasonDecision {
  const PresidentFacilityPortfolioSeasonDecision({
    required this.seasonIndex,
    required this.clubId,
    required this.presidentId,
    required this.academyTargetLevel,
    required this.academyBeforeLevel,
    required this.academyAfterLevel,
    required this.academyAppliedUpgrades,
    required this.academyCashReserveBasisPoints,
    required this.trainingGroundTargetLevel,
    required this.trainingGroundBeforeLevel,
    required this.trainingGroundAfterLevel,
    required this.trainingGroundAppliedUpgrades,
    required this.stadiumTargetLevel,
    required this.stadiumBeforeLevel,
    required this.stadiumAfterLevel,
    required this.stadiumAppliedUpgrades,
    required this.portfolioCashReserveBasisPoints,
    required this.spend,
  });

  final int seasonIndex;
  final String clubId;
  final String presidentId;
  final int academyTargetLevel;
  final int academyBeforeLevel;
  final int academyAfterLevel;
  final int academyAppliedUpgrades;
  final int academyCashReserveBasisPoints;
  final int trainingGroundTargetLevel;
  final int trainingGroundBeforeLevel;
  final int trainingGroundAfterLevel;
  final int trainingGroundAppliedUpgrades;
  final int stadiumTargetLevel;
  final int stadiumBeforeLevel;
  final int stadiumAfterLevel;
  final int stadiumAppliedUpgrades;
  final int portfolioCashReserveBasisPoints;
  final Money spend;

  String get signature =>
      '$seasonIndex:$clubId:$presidentId:'
      'academy=$academyBeforeLevel->$academyAfterLevel/'
      '$academyTargetLevel+$academyAppliedUpgrades:'
      'training=$trainingGroundBeforeLevel->$trainingGroundAfterLevel/'
      '$trainingGroundTargetLevel+$trainingGroundAppliedUpgrades:'
      'stadium=$stadiumBeforeLevel->$stadiumAfterLevel/'
      '$stadiumTargetLevel+$stadiumAppliedUpgrades:'
      'reserve=$academyCashReserveBasisPoints/'
      '$portfolioCashReserveBasisPoints:spend=${spend.minorUnits}';
}

class PresidentFacilityPortfolioDecisionLoopResult {
  const PresidentFacilityPortfolioDecisionLoopResult({
    required this.checkpoint,
    required this.decisions,
    required this.youthIntakeSignatures,
  });

  final FacilityRuntimeCheckpoint checkpoint;
  final List<PresidentFacilityPortfolioSeasonDecision> decisions;
  final List<String> youthIntakeSignatures;
}

class PresidentFacilityPortfolioDecisionLoopEngine {
  const PresidentFacilityPortfolioDecisionLoopEngine({
    this.academyInvestment = const PresidentAcademyInvestmentOrchestrator(),
    this.portfolioInvestment =
        const PresidentFacilityPortfolioInvestmentOrchestrator(),
    this.career = const FacilityRuntimeCareerEngine(),
  });

  final PresidentAcademyInvestmentOrchestrator academyInvestment;
  final PresidentFacilityPortfolioInvestmentOrchestrator portfolioInvestment;
  final FacilityRuntimeCareerEngine career;

  PresidentFacilityPortfolioDecisionLoopResult run({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
    required PresidentFacilityPortfolioProfileProvider profileProvider,
  }) {
    checkpoint.validate();
    if (seasonCount < 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint;
    final decisions = <PresidentFacilityPortfolioSeasonDecision>[];
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

        // Academy remains first and uses the exact M36/M37 policy path.
        final academy = academyInvestment.apply(
          checkpoint: current,
          clubId: clubId,
          profile: profile,
        );
        final portfolio = portfolioInvestment.apply(
          checkpoint: academy.checkpoint,
          clubId: clubId,
          profile: profile,
        );

        decisions.add(
          PresidentFacilityPortfolioSeasonDecision(
            seasonIndex: seasonIndex,
            clubId: clubId,
            presidentId: profile.presidentId,
            academyTargetLevel: academy.plan.targetLevel,
            academyBeforeLevel: academy.beforeLevel,
            academyAfterLevel: academy.afterLevel,
            academyAppliedUpgrades: academy.appliedUpgrades,
            academyCashReserveBasisPoints:
                academy.plan.cashReserveBasisPoints,
            trainingGroundTargetLevel:
                portfolio.plan.trainingGroundTargetLevel,
            trainingGroundBeforeLevel: portfolio.beforeTrainingGroundLevel,
            trainingGroundAfterLevel: portfolio.afterTrainingGroundLevel,
            trainingGroundAppliedUpgrades:
                portfolio.appliedTrainingGroundUpgrades,
            stadiumTargetLevel: portfolio.plan.stadiumTargetLevel,
            stadiumBeforeLevel: portfolio.beforeStadiumLevel,
            stadiumAfterLevel: portfolio.afterStadiumLevel,
            stadiumAppliedUpgrades: portfolio.appliedStadiumUpgrades,
            portfolioCashReserveBasisPoints:
                portfolio.plan.cashReserveBasisPoints,
            spend: academy.spend + portfolio.spend,
          ),
        );
        current = portfolio.checkpoint;
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

    return PresidentFacilityPortfolioDecisionLoopResult(
      checkpoint: current,
      decisions: List.unmodifiable(decisions),
      youthIntakeSignatures: List.unmodifiable(youthIntakeSignatures),
    );
  }
}
