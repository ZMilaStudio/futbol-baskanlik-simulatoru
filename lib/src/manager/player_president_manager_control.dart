import 'dart:convert';

import '../core/seeded_rng.dart';
import '../core/simulation_config.dart';
import '../core/stable_hash.dart';
import '../crisis/crisis_decision_core.dart';
import '../crisis/facility_sponsor_crisis_runtime_composition.dart';
import '../crisis/player_president_crisis_control.dart';
import '../crisis/player_president_facility_control.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_runtime_checkpoint.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../sponsor/sponsor_runtime_integration.dart';
import '../sponsor/sponsor_system.dart';
import '../world/league_tier.dart';
import '../world/world_checkpoint.dart';
import '../world/world_league.dart';
import 'manager.dart';
import 'manager_assignment.dart';
import 'manager_career_season.dart';
import 'manager_fit_model.dart';

enum PlayerManagerReviewChoice { retain, replace }

class PlayerManagerReviewContext {
  const PlayerManagerReviewContext({
    required this.seasonIndex,
    required this.clubId,
    required this.presidentId,
    required this.currentManager,
    required this.season,
    required this.aiWouldReplace,
    required this.aiReason,
    required this.aiNextManager,
    required this.canRetain,
    required this.forcedRetirement,
  });

  final int seasonIndex;
  final String clubId;
  final String presidentId;
  final Manager currentManager;
  final ManagerClubSeason season;
  final bool aiWouldReplace;
  final ManagerChangeReason? aiReason;
  final Manager aiNextManager;
  final bool canRetain;
  final bool forcedRetirement;

  String get signature =>
      '$seasonIndex:$clubId:$presidentId:manager=${currentManager.id}:'
      'finish=${season.expectedPosition}>${season.actualPosition}:'
      'relationship=${season.relationshipAfter.toStringAsFixed(3)}:'
      'ai=${aiWouldReplace ? 'replace' : 'retain'}:'
      'reason=${aiReason?.name ?? 'none'}:next=${aiNextManager.id}:'
      'canRetain=$canRetain:retirement=$forcedRetirement';
}

class PlayerManagerCandidate {
  const PlayerManagerCandidate({
    required this.manager,
    required this.fitScore,
    required this.selectionScore,
  });

  final Manager manager;
  final double fitScore;
  final double selectionScore;

  String get signature =>
      '${manager.id}:fit=${fitScore.toStringAsFixed(3)}:'
      'score=${selectionScore.toStringAsFixed(3)}';
}

class PlayerManagerReplacementContext {
  PlayerManagerReplacementContext({
    required this.seasonIndex,
    required this.clubId,
    required this.presidentId,
    required this.outgoingManager,
    required this.reason,
    required Iterable<PlayerManagerCandidate> candidates,
    required this.aiChoice,
  }) : candidates = List.unmodifiable(candidates);

  final int seasonIndex;
  final String clubId;
  final String presidentId;
  final Manager outgoingManager;
  final ManagerChangeReason reason;
  final List<PlayerManagerCandidate> candidates;
  final Manager aiChoice;

  String get signature =>
      '$seasonIndex:$clubId:$presidentId:out=${outgoingManager.id}:'
      'reason=${reason.name}:ai=${aiChoice.id}:candidates='
      '${candidates.map((item) => item.signature).join('|')}';
}

class PlayerManagerReplacementChoice {
  const PlayerManagerReplacementChoice({required this.managerId});

  final String managerId;

  void validate() {
    if (managerId.isEmpty) {
      throw ArgumentError('managerId cannot be empty.');
    }
  }

  String get signature => managerId;
}

abstract class PlayerManagerDecisionProvider {
  const PlayerManagerDecisionProvider();

  PlayerManagerReviewChoice review(PlayerManagerReviewContext context);

  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  );
}

class PlayerPresidentManagerRuntimeDecision {
  const PlayerPresidentManagerRuntimeDecision({
    required this.reviewContext,
    required this.reviewChoice,
    required this.reviewProviderCalled,
    this.replacementContext,
    this.replacementChoice,
    this.selectedManager,
  });

  final PlayerManagerReviewContext reviewContext;
  final PlayerManagerReviewChoice reviewChoice;
  final bool reviewProviderCalled;
  final PlayerManagerReplacementContext? replacementContext;
  final PlayerManagerReplacementChoice? replacementChoice;
  final Manager? selectedManager;

  int get seasonIndex => reviewContext.seasonIndex;
  String get clubId => reviewContext.clubId;
  String get presidentId => reviewContext.presidentId;
  bool get replaced => reviewChoice == PlayerManagerReviewChoice.replace;
  bool get changedFromAi {
    if (replaced != reviewContext.aiWouldReplace) return true;
    if (!replaced) return false;
    return selectedManager?.id != reviewContext.aiNextManager.id;
  }

  String get signature =>
      '${reviewContext.signature}:review=${reviewChoice.name}:'
      'provider=$reviewProviderCalled:'
      'replacement=${replacementContext?.signature ?? 'none'}:'
      'choice=${replacementChoice?.signature ?? 'none'}:'
      'selected=${selectedManager?.id ?? 'none'}';
}

class PlayerPresidentManagerControlCheckpoint {
  PlayerPresidentManagerControlCheckpoint({required this.control}) {
    validate();
  }

  final PlayerPresidentCrisisControlCheckpoint control;

  int get nextSeasonIndex => control.nextSeasonIndex;
  int get completedSeasons => control.completedSeasons;
  String get controlledClubId => control.controlledClubId;

  void validate() => control.validate();

  String get signature => 'manager-control:${control.signature}';
}

class PlayerPresidentManagerControlSaveCodec {
  const PlayerPresidentManagerControlSaveCodec({
    this.controlCodec = const PlayerPresidentCrisisControlSaveCodec(),
  });

  static const String format = 'zmila-fbs-player-president-manager-control';
  static const int currentSaveVersion = 1;

  final PlayerPresidentCrisisControlSaveCodec controlCodec;

  String encode(PlayerPresidentManagerControlCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'controlSave': controlCodec.encode(checkpoint.control),
    };
    final checksum = SaveChecksum.forPayload(
      saveVersion: currentSaveVersion,
      payload: payload,
    );
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': checksum,
    });
  }

  PlayerPresidentManagerControlCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Player-president manager save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Player-president manager save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown player-president manager save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported player-president manager save version $version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Player-president manager save checksum mismatch.',
      );
    }
    if (version != 1 || payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president manager save payload is invalid.',
      );
    }
    final map = Map<String, Object?>.from(payload);
    final controlSave = map['controlSave'];
    if (controlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president manager control payload is invalid.',
      );
    }
    try {
      return PlayerPresidentManagerControlCheckpoint(
        control: controlCodec.decode(controlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid player-president manager payload: $error',
      );
    }
  }
}

class PlayerPresidentManagerControlCareerResult {
  PlayerPresidentManagerControlCareerResult({
    required this.checkpoint,
    required Iterable<PlayerPresidentCrisisControlCareerResult> sourceSegments,
    required Iterable<PlayerPresidentManagerRuntimeDecision> managerDecisions,
  })  : sourceSegments = List.unmodifiable(sourceSegments),
        managerDecisions = List.unmodifiable(managerDecisions);

  final PlayerPresidentManagerControlCheckpoint checkpoint;
  final List<PlayerPresidentCrisisControlCareerResult> sourceSegments;
  final List<PlayerPresidentManagerRuntimeDecision> managerDecisions;

  List<PlayerPresidentFacilityControlSeasonBoundary> get boundaries =>
      List.unmodifiable(sourceSegments.expand((item) => item.boundaries));

  List<PlayerPresidentCrisisRuntimeDecision> get crisisDecisions =>
      List.unmodifiable(sourceSegments.expand((item) => item.crisisDecisions));

  List<PlayerPresidentSponsorRuntimeDecision> get sponsorDecisions =>
      List.unmodifiable(
        sourceSegments.expand((item) => item.source.sponsorDecisions),
      );

  String get signature =>
      'manager=${managerDecisions.map((item) => item.signature).join('||')}:'
      'source=${sourceSegments.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M52 gives the player-controlled president the final say on the club's
/// season-end manager review and, when a change is required, the next manager.
///
/// M51 remains the authoritative simulation source. With no manager provider,
/// the exact M51 multi-season path is delegated unchanged. With a provider,
/// M51 advances one season at a time and the controlled club's manager state is
/// adjusted only after the completed season and before the next season starts.
/// Retirement remains mandatory. Replacement choices are limited to a small,
/// deterministic set of real managers that are not assigned to another club.
class PlayerPresidentManagerControlCareerEngine {
  const PlayerPresidentManagerControlCareerEngine({
    this.managerProvider,
    this.crisisProvider,
    this.sponsorProvider,
    this.facilityProvider,
    this.offerEngine = const SponsorOfferEngine(),
    this.aiSponsorPolicy = const PresidentSponsorDecisionPolicy(),
    this.aiCrisisEngine = const CrisisDecisionEngine(activationThreshold: 55),
    this.fitModel = const ManagerFitModel(),
    this.candidateLimit = 5,
  }) : assert(candidateLimit > 0);

  final PlayerManagerDecisionProvider? managerProvider;
  final PlayerCrisisDecisionProvider? crisisProvider;
  final PlayerSponsorDecisionProvider? sponsorProvider;
  final PlayerFacilityInvestmentDecisionProvider? facilityProvider;
  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy aiSponsorPolicy;
  final CrisisDecisionEngine aiCrisisEngine;
  final ManagerFitModel fitModel;
  final int candidateLimit;

  PlayerPresidentManagerControlCareerResult simulateWithCheckpoint({
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
    final sourceEngine = _sourceEngine();
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
      return PlayerPresidentManagerControlCareerResult(
        checkpoint: PlayerPresidentManagerControlCheckpoint(
          control: source.checkpoint,
        ),
        sourceSegments: [source],
        managerDecisions: const [],
      );
    }

    final segments = <PlayerPresidentCrisisControlCareerResult>[];
    final decisions = <PlayerPresidentManagerRuntimeDecision>[];
    final firstHasFuture = seasonCount > 1 || hasFutureSeasonAfterReport;
    final first = sourceEngine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: firstHasFuture,
    );
    segments.add(first);
    var current = first.checkpoint;
    if (firstHasFuture) {
      final applied = _applyManagerDecision(current);
      current = applied.checkpoint;
      decisions.add(applied.decision);
    }

    for (var offset = 1; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final source = sourceEngine.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      segments.add(source);
      current = source.checkpoint;
      if (hasFuture) {
        final applied = _applyManagerDecision(current);
        current = applied.checkpoint;
        decisions.add(applied.decision);
      }
    }

    return PlayerPresidentManagerControlCareerResult(
      checkpoint: PlayerPresidentManagerControlCheckpoint(control: current),
      sourceSegments: segments,
      managerDecisions: decisions,
    );
  }

  PlayerPresidentManagerControlCareerResult resume({
    required PlayerPresidentManagerControlCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    final sourceEngine = _sourceEngine();
    if (managerProvider == null) {
      final source = sourceEngine.resume(
        checkpoint: checkpoint.control,
        seasonCount: seasonCount,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );
      return PlayerPresidentManagerControlCareerResult(
        checkpoint: PlayerPresidentManagerControlCheckpoint(
          control: source.checkpoint,
        ),
        sourceSegments: [source],
        managerDecisions: const [],
      );
    }

    final segments = <PlayerPresidentCrisisControlCareerResult>[];
    final decisions = <PlayerPresidentManagerRuntimeDecision>[];
    var current = checkpoint.control;
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final source = sourceEngine.resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      segments.add(source);
      current = source.checkpoint;
      if (hasFuture) {
        final applied = _applyManagerDecision(current);
        current = applied.checkpoint;
        decisions.add(applied.decision);
      }
    }
    return PlayerPresidentManagerControlCareerResult(
      checkpoint: PlayerPresidentManagerControlCheckpoint(control: current),
      sourceSegments: segments,
      managerDecisions: decisions,
    );
  }

  PlayerPresidentCrisisControlCareerEngine _sourceEngine() =>
      PlayerPresidentCrisisControlCareerEngine(
        crisisProvider: crisisProvider,
        sponsorProvider: sponsorProvider,
        facilityProvider: facilityProvider,
        offerEngine: offerEngine,
        aiSponsorPolicy: aiSponsorPolicy,
        aiCrisisEngine: aiCrisisEngine,
      );

  _AppliedManagerDecision _applyManagerDecision(
    PlayerPresidentCrisisControlCheckpoint checkpoint,
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
    final presidentRuntime = _domain(checkpoint).presidentRuntime;
    final president = presidentRuntime.clubs.firstWhere(
      (item) => item.clubId == controlledClubId,
    );
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
        return _AppliedManagerDecision(
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
      return _AppliedManagerDecision(
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
      return _AppliedManagerDecision(
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
    return _AppliedManagerDecision(
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

  PlayerPresidentCrisisControlCheckpoint _patchManagerState({
    required PlayerPresidentCrisisControlCheckpoint checkpoint,
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

    final facility = checkpoint.control.control.runtime;
    final sponsorPresident = facility.runtime;
    final nextSponsorPresident = SponsorPresidentRuntimeCheckpoint(
      domain: nextDomain,
      sponsor: sponsorPresident.sponsor,
    );
    final nextFacility = FacilitySponsorCrisisRuntimeCheckpoint(
      runtime: nextSponsorPresident,
      facilities: facility.facilities,
    );
    return PlayerPresidentCrisisControlCheckpoint(
      control: PlayerPresidentSponsorControlCheckpoint(
        control: PlayerPresidentFacilityControlCheckpoint(
          runtime: nextFacility,
          controlledClubId: checkpoint.controlledClubId,
        ),
      ),
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
    PlayerPresidentCrisisControlCheckpoint checkpoint,
  ) =>
      _domain(checkpoint).presidentRuntime.runtime.runtime;

  PresidentDomainMemoryCheckpoint _domain(
    PlayerPresidentCrisisControlCheckpoint checkpoint,
  ) =>
      checkpoint.control.control.runtime.runtime.domain;
}

class _AppliedManagerDecision {
  const _AppliedManagerDecision({
    required this.checkpoint,
    required this.decision,
  });

  final PlayerPresidentCrisisControlCheckpoint checkpoint;
  final PlayerPresidentManagerRuntimeDecision decision;
}
