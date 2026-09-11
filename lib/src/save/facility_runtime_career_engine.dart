import '../core/money.dart';
import '../facility/academy_facility.dart';
import '../facility/stadium_facility.dart';
import '../facility/training_ground_facility.dart';
import '../finance/basic_economy_engine.dart';
import '../finance/club_finance_season.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_lifecycle_engine.dart';
import '../season/season_report.dart';
import '../world/world_career_engine.dart';
import '../world/world_career_report.dart';
import 'facility_runtime_checkpoint.dart';

class FacilityRuntimeCareerSimulationResult {
  const FacilityRuntimeCareerSimulationResult({
    required this.report,
    required this.checkpoint,
  });

  final WorldCareerReport report;
  final FacilityRuntimeCheckpoint checkpoint;
}

class FacilityRuntimeCareerEngine {
  const FacilityRuntimeCareerEngine({this.worldEngine = const WorldCareerEngine()});

  final WorldCareerEngine worldEngine;

  FacilityRuntimeCheckpoint resume({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) =>
      resumeWithReport(
        checkpoint: checkpoint,
        seasonCount: seasonCount,
      ).checkpoint;

  FacilityRuntimeCareerSimulationResult resumeWithReport({
    required FacilityRuntimeCheckpoint checkpoint,
    required int seasonCount,
  }) {
    checkpoint.validate();
    final academiesByClub = Map<String, AcademyFacilityState>.unmodifiable({
      for (final facility in checkpoint.academyFacilities)
        facility.clubId: facility,
    });
    final stadiumsByClub = Map<String, StadiumFacilityState>.unmodifiable({
      for (final facility in checkpoint.stadiumFacilities)
        facility.clubId: facility,
    });
    final trainingGroundsByClub =
        Map<String, TrainingGroundFacilityState>.unmodifiable({
      for (final facility in checkpoint.trainingGroundFacilities)
        facility.clubId: facility,
    });
    final integratedWorldEngine = WorldCareerEngine(
      seasonEngine: worldEngine.seasonEngine,
      poolGenerator: worldEngine.poolGenerator,
      lifecycleEngine: _FacilityAwareLifecycleEngine(
        delegate: worldEngine.lifecycleEngine,
        academyFacilities: academiesByClub,
        trainingGroundFacilities: trainingGroundsByClub,
      ),
      strengthCalculator: worldEngine.strengthCalculator,
      economyEngine: _FacilityAwareEconomyEngine(
        delegate: worldEngine.economyEngine,
        stadiumFacilities: stadiumsByClub,
      ),
      transferMarketEngine: worldEngine.transferMarketEngine,
    );
    final resumed = integratedWorldEngine.resume(
      checkpoint: checkpoint.world,
      seasonCount: seasonCount,
    );
    return FacilityRuntimeCareerSimulationResult(
      report: resumed.report,
      checkpoint: FacilityRuntimeCheckpoint(
        world: resumed.checkpoint,
        academyFacilities: checkpoint.academyFacilities,
        stadiumFacilities: checkpoint.stadiumFacilities,
        trainingGroundFacilities: checkpoint.trainingGroundFacilities,
        totalInvestmentSpent: checkpoint.totalInvestmentSpent,
      ),
    );
  }
}

class _FacilityAwareLifecycleEngine extends PlayerLifecycleEngine {
  _FacilityAwareLifecycleEngine({
    required this.delegate,
    required this.academyFacilities,
    required this.trainingGroundFacilities,
  });

  final PlayerLifecycleEngine delegate;
  final Map<String, AcademyFacilityState> academyFacilities;
  final Map<String, TrainingGroundFacilityState> trainingGroundFacilities;

  @override
  PlayerLifecycleResult advance({
    required List<Player> currentPlayers,
    required List<Club> currentClubs,
    required List<Club> referenceClubs,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
    Map<String, AcademyFacilityState> academyFacilities = const {},
    Map<String, TrainingGroundFacilityState> trainingGroundFacilities =
        const {},
  }) =>
      delegate.advance(
        currentPlayers: currentPlayers,
        currentClubs: currentClubs,
        referenceClubs: referenceClubs,
        careerSeed: careerSeed,
        nextSeasonIndex: nextSeasonIndex,
        simulationVersion: simulationVersion,
        academyFacilities: this.academyFacilities,
        trainingGroundFacilities: this.trainingGroundFacilities,
      );
}

class _FacilityAwareEconomyEngine extends BasicEconomyEngine {
  _FacilityAwareEconomyEngine({
    required this.delegate,
    required this.stadiumFacilities,
  });

  final BasicEconomyEngine delegate;
  final Map<String, StadiumFacilityState> stadiumFacilities;
  final StadiumInvestmentPolicy stadiumPolicy = const StadiumInvestmentPolicy();

  @override
  List<ClubFinanceSeason> simulateSeason({
    required List<Club> clubs,
    required List<Player> players,
    required SeasonReport seasonReport,
    required List<ClubFinanceState> openingStates,
    int economicScaleBps = 10000,
    int costScaleBps = 10000,
    Map<String, Money>? annualWagesByClub,
    Map<String, Money>? transferInstallmentIncomeByClub,
    Map<String, Money>? transferInstallmentExpenseByClub,
    Map<String, int> matchdayRevenueMultiplierBpsByClub = const {},
  }) {
    for (final entry in stadiumFacilities.entries) {
      if (entry.key != entry.value.clubId) {
        throw ArgumentError('Stadium facility key must match its clubId.');
      }
    }

    final positionByClub = <String, int>{};
    for (var i = 0; i < seasonReport.table.length; i++) {
      positionByClub[seasonReport.table[i].clubId] = i + 1;
    }

    final multipliers = <String, int>{};
    for (final club in clubs) {
      final stadium = stadiumFacilities[club.id];
      if (stadium == null) {
        throw StateError('Missing stadium facility state for ${club.id}.');
      }
      final leaguePosition = positionByClub[club.id];
      if (leaguePosition == null) {
        throw StateError('Missing league position for ${club.id}.');
      }
      multipliers[club.id] = stadiumPolicy
          .attendanceProfile(
            level: stadium.level,
            clubStrength: club.strength,
            leaguePosition: leaguePosition,
          )
          .revenueMultiplierBps;
    }

    return delegate.simulateSeason(
      clubs: clubs,
      players: players,
      seasonReport: seasonReport,
      openingStates: openingStates,
      economicScaleBps: economicScaleBps,
      costScaleBps: costScaleBps,
      annualWagesByClub: annualWagesByClub,
      transferInstallmentIncomeByClub: transferInstallmentIncomeByClub,
      transferInstallmentExpenseByClub: transferInstallmentExpenseByClub,
      matchdayRevenueMultiplierBpsByClub: multipliers,
    );
  }
}
