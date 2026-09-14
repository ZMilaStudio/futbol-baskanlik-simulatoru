import '../core/seeded_rng.dart';
import '../core/simulation_config.dart';
import '../core/stable_hash.dart';
import '../crisis/player_president_tenure_gated_facility_sponsor_crisis_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_runtime_checkpoint.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../world/league_tier.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import 'manager.dart';
import 'manager_assignment.dart';
import 'manager_career_season.dart';
import 'manager_fit_model.dart';
import 'player_president_manager_control.dart';

class PlayerPresidentUnifiedManagerRuntimeSeasonBoundary {
  PlayerPresidentUnifiedManagerRuntimeSeasonBoundary({
    required this.source,
    required this.checkpoint,
    this.managerDecision,
  });

  final PlayerPresidentTicketPricingRuntimeSeasonBoundary source;
  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  final PlayerPresidentManagerRuntimeDecision? managerDecision;

  int get seasonIndex => source.seasonIndex;

  String get signature =>
      'season=$seasonIndex:source=${source.signature}:'
      'manager=${managerDecision?.signature ?? 'ai'}:'
      'final=${checkpoint.signature}';
}

class PlayerPresidentUnifiedManagerRuntimeCareerResult {
  PlayerPresidentUnifiedManagerRuntimeCareerResult({
    required this.checkpoint,
    required Iterable<PlayerPresidentUnifiedManagerRuntimeSeasonBoundary>
        boundaries,
  }) : boundaries = List.unmodifiable(boundaries);

  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  final List<PlayerPresidentUnifiedManagerRuntimeSeasonBoundary> boundaries;

  List<PlayerPresidentManagerRuntimeDecision> get managerDecisions =>
      List.unmodifiable(
        boundaries
            .map((item) => item.managerDecision)
            .whereType<PlayerPresidentManagerRuntimeDecision>(),
      );

  String get signature =>
      '${boundaries.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M71 adds M52 manager review/replacement control to M70's seven-provider
/// player-president runtime while retaining M65's checkpoint/save codec as the
/// single persisted authority.
///
/// The manager decision is applied only after a completed season when another
/// season exists. It mutates only the controlled club's canonical manager
/// assignment/history inside the existing M65 checkpoint. Persisted tenure loss
/// or an incumbent mismatch leaves the M70 AI manager result untouched.
class PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine {
  const PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine({
    this.managerProvider,
    this.sourceEngine =
        const PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine(),
    this.fitModel = const ManagerFitModel(),
    this.candidateLimit = 5,
  }) : assert(candidateLimit > 0);

  final PlayerManagerDecisionProvider? managerProvider;
  final PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine
      sourceEngine;
  final ManagerFitModel fitModel;
  final int candidateLimit;

  PlayerPresidentUnifiedManagerRuntimeCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }

    if (managerProvider == null) {
      final source = sourceEngine.simulateWithCheckpoint(
        clubs: clubs,
        leagues: leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: seasonCount,
        electionInterval: electionInterval,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );
      return PlayerPresidentUnifiedManagerRuntimeCareerResult(
        checkpoint: source.checkpoint,
        boundaries: source.boundaries.map(
          (boundary) => PlayerPresidentUnifiedManagerRuntimeSeasonBoundary(
            source: boundary,
            checkpoint: boundary.checkpoint,
          ),
        ),
      );
    }

    final boundaries = <PlayerPresidentUnifiedManagerRuntimeSeasonBoundary>[];
    PlayerPresidentTicketPricingRuntimeCheckpoint? current;
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final PlayerPresidentTicketPricingRuntimeCareerResult segment;
      if (current == null) {
        segment = sourceEngine.simulateWithCheckpoint(
          clubs: clubs,
          leagues: leagues,
          config: config,
          controlledClubId: controlledClubId,
          seasonCount: 1,
          electionInterval: electionInterval,
          hasFutureSeasonAfterReport: hasFuture,
        );
      } else {
        segment = sourceEngine.resume(
          checkpoint: current,
          seasonCount: 1,
          hasFutureSeasonAfterReport: hasFuture,
        );
      }
      current = segment.checkpoint;
      PlayerPresidentManagerRuntimeDecision? managerDecision;
      if (hasFuture && current.tenureControl.active) {
        final applied = _applyManagerDecision(current);
        current = applied.checkpoint;
        managerDecision = applied.decision;
      }
      boundaries.add(
        PlayerPresidentUnifiedManagerRuntimeSeasonBoundary(
          source: segment.boundaries.single,
          checkpoint: current,
          managerDecision: managerDecision,
        ),
      );
    }

    return PlayerPresidentUnifiedManagerRuntimeCareerResult(
      checkpoint: current!,
      boundaries: boundaries,
    );
  }

  PlayerPresidentUnifiedManagerRuntimeCareerResult resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    if (managerProvider == null) {
      final source = sourceEngine.resume(
        checkpoint: checkpoint,
        seasonCount: seasonCount,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );
      return PlayerPresidentUnifiedManagerRuntimeCareerResult(
        checkpoint: source.checkpoint,
        boundaries: source.boundaries.map(
          (boundary) => PlayerPresidentUnifiedManagerRuntimeSeasonBoundary(
            source: boundary,
            checkpoint: boundary.checkpoint,
          ),
        ),
      );
    }

    final boundaries = <PlayerPresidentUnifiedManagerRuntimeSeasonBoundary>[];
    var current = checkpoint;
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final segment = sourceEngine.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      current = segment.checkpoint;
      PlayerPresidentManagerRuntimeDecision? managerDecision;
      if (hasFuture && current.tenureControl.active) {
        final applied = _applyManagerDecision(current);
        current = applied.checkpoint;
        managerDecision = applied.decision;
      }
      boundaries.add(
        PlayerPresidentUnifiedManagerRuntimeSeasonBoundary(
          source: segment.boundaries.single,
          checkpoint: current,
          managerDecision: managerDecision,
        ),
      );
    }
    return PlayerPresidentUnifiedManagerRuntimeCareerResult(
      checkpoint: current,
      boundaries: boundaries,
    );
  }

  _AppliedUnifiedManagerDecision _applyManagerDecision(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
  ) {
    final controlledClubId = checkpoint.controlledClubId;
    final advanced = _advanced(checkpoint);
    if (advanced.manager.seasons.isEmpty) {
      throw StateError('Manager decision requires a completed manager season.');
    }
    final season = advanced.manager.seasons.last;
    final clubSeason = season.clubs.firstWhere(
      (item) => item.clubId == controlledClubId,
    );
    final currentManager = advanced.manager.managers.firstWhere(
      (item) => item.id == clubSeason.managerId,
    );
    final aiChanges = season.changesAfterSeason
        .where((item) => item.clubId == controlledClubId)
        .toList(growable: false);
    if (aiChanges.length > 1) {
      throw StateError('Controlled club has multiple manager changes in one season.');
    }
    final aiChange = aiChanges.isEmpty ? null : aiChanges.single;
    final aiAssignment = advanced.manager.assignments.firstWhere(
      (item) => item.clubId == controlledClubId,
    );
    final aiNextManager = advanced.manager.managers.firstWhere(
      (item) => item.id == aiAssignment.managerId,
    );
    final president = _domain(checkpoint).presidentRuntime.clubs.firstWhere(
      (item) => item.clubId == controlledClubId,
    );

    if (president.tenure.president.id != checkpoint.tenureControl.playerPresidentId) {
      return _AppliedUnifiedManagerDecision(
        checkpoint: checkpoint,
        decision: null,
      );
    }

    final forcedRetirement = aiChange?.reason == ManagerChangeReason.retirement;
    final oldManagerUsedElsewhere = advanced.manager.assignments.any(
      (item) =>
          item.clubId != controlledClubId && item.managerId == currentManager.id,
    );
    final canRetain = !forcedRetirement && !oldManagerUsedElsewhere;
    final reviewContext = PlayerManagerReviewContext(
      seasonIndex: season.seasonIndex,
      clubId: controlledClubId,
      presidentId: president.tenure.president.id,
      currentManager: currentManager,
      season: clubSeason,
      aiWouldReplace: aiChange != null,
      aiReason: aiChange?.reason,
      aiNextManager: aiNextManager,
      canRetain: canRetain,
      forcedRetirement: forcedRetirement,
    );

    final PlayerManagerReviewChoice reviewChoice;
    final bool reviewProviderCalled;
    if (forcedRetirement) {
      reviewChoice = PlayerManagerReviewChoice.replace;
      reviewProviderCalled = false;
    } else {
      reviewChoice = managerProvider!.review(reviewContext);
      reviewProviderCalled = true;
      if (reviewChoice == PlayerManagerReviewChoice.retain && !canRetain) {
        throw ArgumentError(
          'Controlled manager cannot be retained because the manager is unavailable.',
        );
      }
    }

    if (reviewChoice == PlayerManagerReviewChoice.retain) {
      if (aiChange == null) {
        return _AppliedUnifiedManagerDecision(
          checkpoint: checkpoint,
          decision: PlayerPresidentManagerRuntimeDecision(
            reviewContext: reviewContext,
            reviewChoice: reviewChoice,
            reviewProviderCalled: reviewProviderCalled,
          ),
        );
      }
      final nextAssignment = _retainedAssignment(
        advanced: advanced,
        clubSeason: clubSeason,
      );
      final patched = _patchManagerState(
        checkpoint: checkpoint,
        controlledClubId: controlledClubId,
        assignment: nextAssignment,
        changedAfterSeason: false,
        change: null,
        oldChange: aiChange,
      );
      return _AppliedUnifiedManagerDecision(
        checkpoint: patched,
        decision: PlayerPresidentManagerRuntimeDecision(
          reviewContext: reviewContext,
          reviewChoice: reviewChoice,
          reviewProviderCalled: reviewProviderCalled,
        ),
      );
    }

    final replacementReason = aiChange?.reason ?? ManagerChangeReason.boardBreakdown;
    final candidates = _replacementCandidates(
      advanced: advanced,
      clubId: controlledClubId,
      outgoingManager: currentManager,
      preferredAiManager: aiChange == null ? null : aiNextManager,
    );
    if (candidates.isEmpty) {
      throw StateError('No eligible manager candidates are available.');
    }
    final aiCandidate = aiChange == null
        ? candidates.first
        : candidates.firstWhere(
            (item) => item.manager.id == aiNextManager.id,
            orElse: () => candidates.first,
          );
    final replacementContext = PlayerManagerReplacementContext(
      seasonIndex: advanced.nextSeasonIndex,
      clubId: controlledClubId,
      presidentId: president.tenure.president.id,
      outgoingManager: currentManager,
      reason: replacementReason,
      candidates: candidates,
      aiChoice: aiCandidate.manager,
    );
    final choice = managerProvider!.chooseReplacement(replacementContext)
      ..validate();
    final selectedMatches = candidates
        .where((item) => item.manager.id == choice.managerId)
        .toList(growable: false);
    if (selectedMatches.length != 1) {
      throw ArgumentError.value(
        choice.managerId,
        'managerId',
        'Player manager choice must select one offered manager.',
      );
    }
    final selected = selectedMatches.single;

    if (aiChange != null && selected.manager.id == aiNextManager.id) {
      return _AppliedUnifiedManagerDecision(
        checkpoint: checkpoint,
        decision: PlayerPresidentManagerRuntimeDecision(
          reviewContext: reviewContext,
          reviewChoice: reviewChoice,
          reviewProviderCalled: reviewProviderCalled,
          replacementContext: replacementContext,
          replacementChoice: choice,
          selectedManager: selected.manager,
        ),
      );
    }

    final nextAssignment = _newAssignment(
      advanced: advanced,
      clubId: controlledClubId,
      candidate: selected,
    );
    final nextChange = ManagerChange(
      clubId: controlledClubId,
      fromManagerId: currentManager.id,
      toManagerId: selected.manager.id,
      reason: replacementReason,
    );
    final patched = _patchManagerState(
      checkpoint: checkpoint,
      controlledClubId: controlledClubId,
      assignment: nextAssignment,
      changedAfterSeason: true,
      change: nextChange,
      oldChange: aiChange,
    );
    return _AppliedUnifiedManagerDecision(
      checkpoint: patched,
      decision: PlayerPresidentManagerRuntimeDecision(
        reviewContext: reviewContext,
        reviewChoice: reviewChoice,
        reviewProviderCalled: reviewProviderCalled,
        replacementContext: replacementContext,
        replacementChoice: choice,
        selectedManager: selected.manager,
      ),
    );
  }

  List<PlayerManagerCandidate> _replacementCandidates({
    required AdvancedRuntimeCheckpoint advanced,
    required String clubId,
    required Manager outgoingManager,
    Manager? preferredAiManager,
  }) {
    final world = advanced.world;
    final assignedElsewhere = advanced.manager.assignments
        .where((item) => item.clubId != clubId)
        .map((item) => item.managerId)
        .toSet();
    final club = world.baseClubs.firstWhere((item) => item.id == clubId);
    final players = world.nextSeasonPlayers
        .where((item) => item.clubId == clubId)
        .toList(growable: false);
    final finance = world.nextSeasonFinanceStates.firstWhere(
      (item) => item.clubId == clubId,
    );
    final tier = _tierFor(world, clubId);
    final candidates = <PlayerManagerCandidate>[];
    for (final manager in advanced.manager.managers) {
      if (manager.id == outgoingManager.id ||
          assignedElsewhere.contains(manager.id) ||
          _ageAt(manager, world) >= manager.retirementAge) {
        continue;
      }
      final fit = fitModel.score(
        manager: manager,
        club: club,
        players: players,
        leagueTier: tier,
        financeState: finance,
      );
      candidates.add(
        PlayerManagerCandidate(
          manager: manager,
          fitScore: fit,
          selectionScore: _selectionScore(
            manager: manager,
            fitScore: fit,
            clubId: clubId,
            tier: tier,
            world: world,
          ),
        ),
      );
    }
    candidates.sort((a, b) {
      final score = b.selectionScore.compareTo(a.selectionScore);
      return score != 0 ? score : a.manager.id.compareTo(b.manager.id);
    });

    final selected = <PlayerManagerCandidate>[];
    if (preferredAiManager != null) {
      final preferred = candidates.where(
        (item) => item.manager.id == preferredAiManager.id,
      );
      if (preferred.isNotEmpty) selected.add(preferred.first);
    }
    for (final candidate in candidates) {
      if (selected.any((item) => item.manager.id == candidate.manager.id)) {
        continue;
      }
      selected.add(candidate);
      if (selected.length >= candidateLimit) break;
    }
    return List.unmodifiable(selected);
  }

  double _selectionScore({
    required Manager manager,
    required double fitScore,
    required String clubId,
    required LeagueTier tier,
    required WorldCheckpoint world,
  }) {
    final targetReputation = switch (tier) {
      LeagueTier.first => 74,
      LeagueTier.second => 62,
      LeagueTier.third => 54,
    };
    final mismatch = (manager.reputation - targetReputation).abs().toDouble();
    return fitScore * 0.55 +
        manager.reputation * 0.25 +
        manager.coaching * 0.20 -
        mismatch * 0.10 +
        _jitter(
          clubId: clubId,
          managerId: manager.id,
          seasonIndex: world.nextSeasonIndex,
          world: world,
          salt: 17,
          amplitude: 4,
        );
  }

  ManagerAssignment _newAssignment({
    required AdvancedRuntimeCheckpoint advanced,
    required String clubId,
    required PlayerManagerCandidate candidate,
  }) {
    final world = advanced.world;
    final manager = candidate.manager;
    final relationship = (52.0 +
            candidate.fitScore * 0.18 +
            (manager.boardCooperation - 50) * 0.08 +
            _jitter(
              clubId: clubId,
              managerId: manager.id,
              seasonIndex: world.nextSeasonIndex,
              world: world,
              salt: 29,
              amplitude: 6,
            ))
        .clamp(48.0, 78.0)
        .toDouble();
    return ManagerAssignment(
      clubId: clubId,
      managerId: manager.id,
      appointedSeasonIndex: world.nextSeasonIndex,
      completedSeasons: 0,
      boardRelationship: relationship,
    );
  }

  ManagerAssignment _retainedAssignment({
    required AdvancedRuntimeCheckpoint advanced,
    required ManagerClubSeason clubSeason,
  }) {
    var completed = 0;
    for (final season in advanced.manager.seasons.reversed) {
      final record = season.clubs.firstWhere(
        (item) => item.clubId == clubSeason.clubId,
      );
      if (record.managerId != clubSeason.managerId) break;
      completed++;
    }
    return ManagerAssignment(
      clubId: clubSeason.clubId,
      managerId: clubSeason.managerId,
      appointedSeasonIndex: advanced.nextSeasonIndex - completed,
      completedSeasons: completed,
      boardRelationship: clubSeason.relationshipAfter,
    );
  }

  PlayerPresidentTicketPricingRuntimeCheckpoint _patchManagerState({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required String controlledClubId,
    required ManagerAssignment assignment,
    required bool changedAfterSeason,
    required ManagerChange? change,
    required ManagerChange? oldChange,
  }) {
    final advanced = _advanced(checkpoint);
    final assignments = advanced.manager.assignments
        .map((item) => item.clubId == controlledClubId ? assignment : item)
        .toList(growable: false);
    final oldSeason = advanced.manager.seasons.last;
    final clubs = oldSeason.clubs
        .map(
          (item) => item.clubId != controlledClubId
              ? item
              : ManagerClubSeason(
                  clubId: item.clubId,
                  managerId: item.managerId,
                  managerAge: item.managerAge,
                  fitScore: item.fitScore,
                  strengthImpact: item.strengthImpact,
                  relationshipBefore: item.relationshipBefore,
                  relationshipAfter: item.relationshipAfter,
                  expectedPosition: item.expectedPosition,
                  actualPosition: item.actualPosition,
                  changedAfterSeason: changedAfterSeason,
                ),
        )
        .toList(growable: false);
    final changes = oldSeason.changesAfterSeason
        .where((item) => item.clubId != controlledClubId)
        .toList();
    if (change != null) changes.add(change);
    changes.sort((a, b) => a.clubId.compareTo(b.clubId));
    final nextSeason = ManagerCareerSeason(
      seasonIndex: oldSeason.seasonIndex,
      clubs: clubs,
      changesAfterSeason: changes,
    );
    final seasons = [...advanced.manager.seasons];
    seasons[seasons.length - 1] = nextSeason;
    final manager = ManagerRuntimeState(
      managers: advanced.manager.managers,
      assignments: assignments,
      seasons: seasons,
    );
    final nextAdvanced = AdvancedRuntimeCheckpoint(
      world: advanced.world,
      transfer: advanced.transfer,
      manager: manager,
    );

    final domain = _domain(checkpoint);
    final presidentRuntime = domain.presidentRuntime;
    final compact = presidentRuntime.runtime;
    final history = _adjustHistory(
      compact.history,
      oldChange: oldChange,
      newChange: change,
    );
    final nextCompact = CompactAdvancedRuntimeCheckpoint(
      runtime: nextAdvanced,
      history: history,
      recentHistoryStartSeasonIndex: compact.recentHistoryStartSeasonIndex,
    );
    final nextPresidentRuntime = PresidentRuntimeCheckpoint(
      runtime: nextCompact,
      electionInterval: presidentRuntime.electionInterval,
      completedElectionTerms: presidentRuntime.completedElectionTerms,
      seasonsIntoCurrentTerm: presidentRuntime.seasonsIntoCurrentTerm,
      clubs: presidentRuntime.clubs,
    );
    final nextDomain = PresidentDomainMemoryCheckpoint(
      presidentRuntime: nextPresidentRuntime,
      summary: domain.summary,
      rawHistorySeasons: domain.rawHistorySeasons,
      recentFan: domain.recentFan,
      recentMedia: domain.recentMedia,
      currentTermPromises: domain.currentTermPromises,
    );
    final sponsorPresident = checkpoint.runtime.runtime;
    final nextSponsorPresident = SponsorPresidentRuntimeCheckpoint(
      domain: nextDomain,
      sponsor: sponsorPresident.sponsor,
    );
    return PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: FacilitySponsorCrisisRuntimeCheckpoint(
        runtime: nextSponsorPresident,
        facilities: checkpoint.runtime.facilities,
      ),
      tenureControl: checkpoint.tenureControl,
    );
  }

  AdvancedHistorySummary _adjustHistory(
    AdvancedHistorySummary history, {
    required ManagerChange? oldChange,
    required ManagerChange? newChange,
  }) {
    final counts = <ManagerChangeReason, int>{
      for (final reason in ManagerChangeReason.values)
        reason: history.managerChangesByReason[reason] ?? 0,
    };
    var total = history.managerChangeCount;
    if (oldChange != null) {
      counts[oldChange.reason] = (counts[oldChange.reason] ?? 0) - 1;
      total--;
    }
    if (newChange != null) {
      counts[newChange.reason] = (counts[newChange.reason] ?? 0) + 1;
      total++;
    }
    return AdvancedHistorySummary(
      completedSeasons: history.completedSeasons,
      contractEventCount: history.contractEventCount,
      contractEventsByType: history.contractEventsByType,
      loanCount: history.loanCount,
      loanFeeMinorUnits: history.loanFeeMinorUnits,
      managerSeasonCount: history.managerSeasonCount,
      managerChangeCount: total,
      managerChangesByReason: counts,
    );
  }

  int _ageAt(Manager manager, WorldCheckpoint world) =>
      manager.startAge + (world.nextSeasonIndex - world.config.seasonIndex);

  LeagueTier _tierFor(WorldCheckpoint world, String clubId) =>
      world.nextSeasonLeagues
          .firstWhere((league) => league.clubIds.contains(clubId))
          .tier;

  double _jitter({
    required String clubId,
    required String managerId,
    required int seasonIndex,
    required WorldCheckpoint world,
    required int salt,
    required double amplitude,
  }) {
    final seed = StableHash.combine32([
      world.config.careerSeed,
      world.config.simulationVersion,
      seasonIndex,
      salt,
      StableHash.string32(clubId),
      StableHash.string32(managerId),
    ]);
    final rng = SeededRng(seed);
    return (rng.nextDouble() - 0.5) * amplitude;
  }

  AdvancedRuntimeCheckpoint _advanced(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
  ) =>
      _domain(checkpoint).presidentRuntime.runtime.runtime;

  PresidentDomainMemoryCheckpoint _domain(
    PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
  ) =>
      checkpoint.runtime.runtime.domain;
}

class _AppliedUnifiedManagerDecision {
  const _AppliedUnifiedManagerDecision({
    required this.checkpoint,
    required this.decision,
  });

  final PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint;
  final PlayerPresidentManagerRuntimeDecision? decision;
}
