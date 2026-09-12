import '../core/money.dart';
import '../facility/president_academy_investment_orchestrator.dart';
import '../facility/president_facility_portfolio_investment_orchestrator.dart';
import '../league/club.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/facility_runtime_checkpoint.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_runtime_checkpoint.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import '../core/simulation_config.dart';
import 'facility_sponsor_crisis_runtime_composition.dart';

class PresidentFacilityInvestmentRuntimeDecision {
  const PresidentFacilityInvestmentRuntimeDecision({
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

  bool get invested =>
      academyAppliedUpgrades > 0 ||
      trainingGroundAppliedUpgrades > 0 ||
      stadiumAppliedUpgrades > 0;

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

class PresidentFacilityInvestmentRuntimeResult {
  PresidentFacilityInvestmentRuntimeResult({
    required this.checkpoint,
    required Iterable<PresidentFacilityInvestmentRuntimeDecision> decisions,
  }) : decisions = List.unmodifiable(decisions);

  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;
  final List<PresidentFacilityInvestmentRuntimeDecision> decisions;

  Money get totalSpend => decisions.fold(
        Money.zero,
        (sum, item) => sum + item.spend,
      );

  int get investedClubCount => decisions.where((item) => item.invested).length;

  String get signature =>
      '${decisions.map((item) => item.signature).join('|')}:'
      'final=${checkpoint.signature}';
}

/// Applies the existing M39 president facility policy to an M47 continuation
/// checkpoint. The current president profile is read after the completed
/// season/crisis boundary, so a turnover automatically replans the next
/// season's academy/training/stadium investment window.
class PresidentFacilityInvestmentRuntimeEngine {
  const PresidentFacilityInvestmentRuntimeEngine({
    this.academyInvestment = const PresidentAcademyInvestmentOrchestrator(),
    this.portfolioInvestment =
        const PresidentFacilityPortfolioInvestmentOrchestrator(),
  });

  final PresidentAcademyInvestmentOrchestrator academyInvestment;
  final PresidentFacilityPortfolioInvestmentOrchestrator portfolioInvestment;

  PresidentFacilityInvestmentRuntimeResult apply(
    FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
  ) {
    checkpoint.validate();
    final domain = checkpoint.runtime.domain;
    final presidentRuntime = domain.presidentRuntime;
    final world = presidentRuntime.runtime.runtime.world;
    var facilityCheckpoint = FacilityRuntimeCheckpoint(
      world: world,
      academyFacilities: checkpoint.facilities.academyFacilities,
      stadiumFacilities: checkpoint.facilities.stadiumFacilities,
      trainingGroundFacilities: checkpoint.facilities.trainingGroundFacilities,
      totalInvestmentSpent: checkpoint.facilities.totalInvestmentSpent,
    );
    final states = [...presidentRuntime.clubs]
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    final decisions = <PresidentFacilityInvestmentRuntimeDecision>[];

    for (final state in states) {
      final profile = state.managementProfile;
      final academy = academyInvestment.apply(
        checkpoint: facilityCheckpoint,
        clubId: state.clubId,
        profile: profile,
      );
      final portfolio = portfolioInvestment.apply(
        checkpoint: academy.checkpoint,
        clubId: state.clubId,
        profile: profile,
      );
      decisions.add(
        PresidentFacilityInvestmentRuntimeDecision(
          seasonIndex: checkpoint.nextSeasonIndex,
          clubId: state.clubId,
          presidentId: profile.presidentId,
          academyTargetLevel: academy.plan.targetLevel,
          academyBeforeLevel: academy.beforeLevel,
          academyAfterLevel: academy.afterLevel,
          academyAppliedUpgrades: academy.appliedUpgrades,
          academyCashReserveBasisPoints: academy.plan.cashReserveBasisPoints,
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
      facilityCheckpoint = portfolio.checkpoint;
    }

    final nextDomain = _replaceWorld(domain, facilityCheckpoint.world);
    final nextRuntime = SponsorPresidentRuntimeCheckpoint(
      domain: nextDomain,
      sponsor: checkpoint.runtime.sponsor,
    );
    final nextFacilities = FacilityPortfolioRuntimeState(
      academyFacilities: facilityCheckpoint.academyFacilities,
      stadiumFacilities: facilityCheckpoint.stadiumFacilities,
      trainingGroundFacilities: facilityCheckpoint.trainingGroundFacilities,
      totalInvestmentSpent: facilityCheckpoint.totalInvestmentSpent,
    );
    return PresidentFacilityInvestmentRuntimeResult(
      checkpoint: FacilitySponsorCrisisRuntimeCheckpoint(
        runtime: nextRuntime,
        facilities: nextFacilities,
      ),
      decisions: decisions,
    );
  }

  PresidentDomainMemoryCheckpoint _replaceWorld(
    PresidentDomainMemoryCheckpoint checkpoint,
    WorldCheckpoint world,
  ) {
    final presidentRuntime = checkpoint.presidentRuntime;
    final compact = presidentRuntime.runtime;
    final advanced = compact.runtime;
    final nextAdvanced = AdvancedRuntimeCheckpoint(
      world: world,
      transfer: advanced.transfer,
      manager: advanced.manager,
    );
    final nextCompact = CompactAdvancedRuntimeCheckpoint(
      runtime: nextAdvanced,
      history: compact.history,
      recentHistoryStartSeasonIndex: compact.recentHistoryStartSeasonIndex,
    );
    final nextPresidentRuntime = PresidentRuntimeCheckpoint(
      runtime: nextCompact,
      electionInterval: presidentRuntime.electionInterval,
      completedElectionTerms: presidentRuntime.completedElectionTerms,
      seasonsIntoCurrentTerm: presidentRuntime.seasonsIntoCurrentTerm,
      clubs: presidentRuntime.clubs,
    );
    return PresidentDomainMemoryCheckpoint(
      presidentRuntime: nextPresidentRuntime,
      summary: checkpoint.summary,
      rawHistorySeasons: checkpoint.rawHistorySeasons,
      recentFan: checkpoint.recentFan,
      recentMedia: checkpoint.recentMedia,
      currentTermPromises: checkpoint.currentTermPromises,
    );
  }
}

class PresidentFacilityInvestmentRuntimeSeasonBoundary {
  const PresidentFacilityInvestmentRuntimeSeasonBoundary({
    required this.source,
    required this.checkpoint,
    this.investment,
  });

  final FacilitySponsorCrisisRuntimeSeasonBoundary source;
  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;
  final PresidentFacilityInvestmentRuntimeResult? investment;

  int get seasonIndex => source.seasonIndex;
  bool get preparedNextSeason => investment != null;
  int get crisisCount => source.crisisCount;
  Money get sponsorRevenue => source.sponsorRevenue;
  Money get facilityInvestmentSpend => investment?.totalSpend ?? Money.zero;

  List<PresidentFacilityInvestmentRuntimeDecision> get decisions =>
      investment?.decisions ?? const [];

  String get signature =>
      'season=$seasonIndex:source=${source.signature}:'
      'investment=${investment?.signature ?? 'none'}:'
      'final=${checkpoint.signature}';
}

class PresidentFacilityInvestmentRuntimeCareerResult {
  PresidentFacilityInvestmentRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<PresidentFacilityInvestmentRuntimeSeasonBoundary>
        boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final FacilitySponsorCrisisRuntimeCheckpoint checkpoint;
  final List<PresidentFacilityInvestmentRuntimeSeasonBoundary> boundaries;

  Money get totalFacilityInvestmentSpend => boundaries.fold(
        Money.zero,
        (sum, item) => sum + item.facilityInvestmentSpend,
      );

  int get investedClubWindows => boundaries.fold(
        0,
        (sum, item) => sum + (item.investment?.investedClubCount ?? 0),
      );

  int get crisisCount => boundaries.fold(
        0,
        (sum, item) => sum + item.crisisCount,
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M48 composes the exact M39 president facility investment policy with the
/// M47 facility+sponsor+crisis runtime. Investments are made only when a
/// future season is actually required, preserving final-season semantics.
class PresidentFacilityInvestmentRuntimeCareerEngine {
  const PresidentFacilityInvestmentRuntimeCareerEngine({
    this.runtime = const FacilitySponsorCrisisRuntimeCareerEngine(),
    this.investment = const PresidentFacilityInvestmentRuntimeEngine(),
  });

  final FacilitySponsorCrisisRuntimeCareerEngine runtime;
  final PresidentFacilityInvestmentRuntimeEngine investment;

  PresidentFacilityInvestmentRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    final boundaries = <PresidentFacilityInvestmentRuntimeSeasonBoundary>[];
    final firstHasFuture = seasonCount > 1 || hasFutureSeasonAfterReport;
    final first = runtime.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: firstHasFuture,
    );
    var boundary = _finishBoundary(
      source: first.boundaries.single,
      prepareNextSeason: firstHasFuture,
    );
    boundaries.add(boundary);
    var current = boundary.checkpoint;

    for (var offset = 1; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final resumed = runtime.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      boundary = _finishBoundary(
        source: resumed.boundaries.single,
        prepareNextSeason: hasFuture,
      );
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }
    return PresidentFacilityInvestmentRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  PresidentFacilityInvestmentRuntimeCareerResult resume({
    required FacilitySponsorCrisisRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    final boundaries = <PresidentFacilityInvestmentRuntimeSeasonBoundary>[];
    var current = checkpoint;
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final resumed = runtime.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      final boundary = _finishBoundary(
        source: resumed.boundaries.single,
        prepareNextSeason: hasFuture,
      );
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }
    return PresidentFacilityInvestmentRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  PresidentFacilityInvestmentRuntimeSeasonBoundary _finishBoundary({
    required FacilitySponsorCrisisRuntimeSeasonBoundary source,
    required bool prepareNextSeason,
  }) {
    if (!prepareNextSeason) {
      return PresidentFacilityInvestmentRuntimeSeasonBoundary(
        source: source,
        checkpoint: source.checkpoint,
      );
    }
    final result = investment.apply(source.checkpoint);
    return PresidentFacilityInvestmentRuntimeSeasonBoundary(
      source: source,
      checkpoint: result.checkpoint,
      investment: result,
    );
  }
}
