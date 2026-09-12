import '../core/money.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../world/world_league.dart';
import 'crisis_runtime_integration.dart';

class SponsorCrisisRuntimeSeasonBoundary {
  SponsorCrisisRuntimeSeasonBoundary({
    required this.sponsor,
    required this.crisis,
    required this.checkpoint,
  }) {
    validate();
  }

  final SponsorRuntimeSeasonBoundary sponsor;
  final CrisisRuntimeBoundaryResult crisis;
  final SponsorPresidentRuntimeCheckpoint checkpoint;

  int get seasonIndex => sponsor.seasonIndex;
  int get crisisCount => crisis.crisisCount;
  Money get sponsorRevenue => sponsor.totalRevenue;

  void validate() {
    if (sponsor.seasonIndex != crisis.seasonIndex) {
      throw StateError(
        'Sponsor and crisis boundaries must describe the same season: '
        '${sponsor.seasonIndex} != ${crisis.seasonIndex}.',
      );
    }
    if (checkpoint.nextSeasonIndex != sponsor.checkpoint.nextSeasonIndex) {
      throw StateError(
        'Combined checkpoint season cursor must match sponsor boundary.',
      );
    }
    if (checkpoint.sponsor.signature != sponsor.checkpoint.sponsor.signature) {
      throw StateError('Crisis composition must not mutate sponsor state.');
    }
    if (checkpoint.domain.signature != crisis.checkpoint.signature) {
      throw StateError('Combined checkpoint must carry crisis-adjusted domain.');
    }
  }

  String get signature =>
      'season=$seasonIndex:'
      'sponsor=${sponsor.signature}:'
      'crisis=${crisis.signature}:'
      'final=${checkpoint.signature}';
}

class SponsorCrisisRuntimeCareerResult {
  SponsorCrisisRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<SponsorCrisisRuntimeSeasonBoundary> boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final SponsorPresidentRuntimeCheckpoint checkpoint;
  final List<SponsorCrisisRuntimeSeasonBoundary> boundaries;

  int get crisisCount => boundaries.fold<int>(
        0,
        (sum, boundary) => sum + boundary.crisisCount,
      );

  Money get totalSponsorRevenue => boundaries.fold<Money>(
        Money.zero,
        (sum, boundary) => sum + boundary.sponsorRevenue,
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M46 composes the M45 sponsor-aware economy with the M44 crisis boundary.
///
/// One PresidentDomain/world season is simulated exactly once. Sponsor revenue
/// is resolved inside that real economy season, then the resulting domain
/// checkpoint is passed through the stateless crisis boundary before it is
/// used as the opening state of the next sponsor-aware season.
class SponsorCrisisRuntimeCareerEngine {
  const SponsorCrisisRuntimeCareerEngine({
    this.sponsorRuntime = const SponsorRuntimeCareerEngine(),
    this.crisisIntegration = const CrisisRuntimeIntegrationEngine(),
  });

  final SponsorRuntimeCareerEngine sponsorRuntime;
  final CrisisRuntimeIntegrationEngine crisisIntegration;

  SponsorCrisisRuntimeCareerResult simulateWithCheckpoint({
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

    final first = sponsorRuntime.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport:
          seasonCount > 1 || hasFutureSeasonAfterReport,
    );
    var boundary = _compose(first.boundaries.single);
    var current = boundary.checkpoint;
    final boundaries = <SponsorCrisisRuntimeSeasonBoundary>[boundary];

    for (var offset = 1; offset < seasonCount; offset++) {
      final next = sponsorRuntime.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      boundary = _compose(next.boundaries.single);
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }

    return SponsorCrisisRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  SponsorCrisisRuntimeCareerResult resume({
    required SponsorPresidentRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint;
    final boundaries = <SponsorCrisisRuntimeSeasonBoundary>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final next = sponsorRuntime.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport:
            offset < seasonCount - 1 || hasFutureSeasonAfterReport,
      );
      final boundary = _compose(next.boundaries.single);
      boundaries.add(boundary);
      current = boundary.checkpoint;
    }

    return SponsorCrisisRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  SponsorCrisisRuntimeSeasonBoundary _compose(
    SponsorRuntimeSeasonBoundary sponsorBoundary,
  ) {
    final crisis = crisisIntegration.apply(sponsorBoundary.checkpoint.domain);
    final checkpoint = SponsorPresidentRuntimeCheckpoint(
      domain: crisis.checkpoint,
      sponsor: sponsorBoundary.checkpoint.sponsor,
    );
    return SponsorCrisisRuntimeSeasonBoundary(
      sponsor: sponsorBoundary,
      crisis: crisis,
      checkpoint: checkpoint,
    );
  }
}
