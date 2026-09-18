import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../crisis/crisis_decision_core.dart';
import '../crisis/player_president_crisis_control.dart';
import '../crisis/player_president_facility_control.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_control.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../manager/manager_assignment.dart';
import '../manager/player_president_manager_control.dart';
import '../manager/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import '../media/media_statement.dart';
import '../media/player_president_media_statement_control.dart';
import '../promise/player_president_promise_control.dart';
import '../promise/president_promise.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../sponsor/sponsor_system.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../world/world_league.dart';
import 'player_president_unified_decision_gateway_runtime.dart';

enum PlayerPresidentInteractiveDecisionKind {
  facilityInvestment,
  sponsor,
  crisis,
  managerReview,
  managerReplacement,
  promise,
  mediaStatement,
  transferStrategy,
  ticketPricing,
}

class PlayerPresidentInteractiveDecisionRequest {
  const PlayerPresidentInteractiveDecisionRequest._({
    required this.sequence,
    required this.kind,
    required this.clubId,
    required this.contextSignature,
    required this.context,
  });

  final int sequence;
  final PlayerPresidentInteractiveDecisionKind kind;
  final String clubId;
  final String contextSignature;
  final Object context;

  String get key => '$sequence:${kind.name}:$clubId:$contextSignature';

  T contextAs<T>() {
    final value = context;
    if (value is! T) {
      throw StateError(
        'Decision ${kind.name} does not contain context type $T.',
      );
    }
    return value as T;
  }

  String get signature => key;
}

sealed class PlayerPresidentInteractiveSessionStep {
  const PlayerPresidentInteractiveSessionStep();
}

class PlayerPresidentInteractiveDecisionPending
    extends PlayerPresidentInteractiveSessionStep {
  const PlayerPresidentInteractiveDecisionPending(this.request);

  final PlayerPresidentInteractiveDecisionRequest request;
}

class PlayerPresidentInteractiveSessionCompleted
    extends PlayerPresidentInteractiveSessionStep {
  const PlayerPresidentInteractiveSessionCompleted({
    required this.result,
    required this.decisionCount,
  });

  final PlayerPresidentUnifiedManagerRuntimeCareerResult result;
  final int decisionCount;
}

/// Runtime-only base type for authoritative immediate consequences.
///
/// M90 Stage 1 defines only the typed contract seam. Concrete consequence
/// subtypes are introduced when existing domain outputs are captured in Stage
/// 2. A missing consequence therefore means "not captured yet", never a fake
/// or inferred effect.
sealed class PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentInteractiveDecisionConsequence();

  PlayerPresidentInteractiveDecisionKind get kind;
  String get controlledClubId;
}

final class PlayerPresidentFacilityInvestmentConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentFacilityInvestmentConsequence(this.decision);
  final PlayerPresidentFacilityRuntimeDecision decision;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.facilityInvestment;
  @override
  String get controlledClubId => decision.clubId;
}

final class PlayerPresidentSponsorConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentSponsorConsequence({
    required this.decision,
    required this.contract,
  });
  final PlayerPresidentSponsorRuntimeDecision decision;
  final SponsorContract contract;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.sponsor;
  @override
  String get controlledClubId => decision.clubId;
}

final class PlayerPresidentCrisisConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentCrisisConsequence(this.decision);
  final PlayerPresidentCrisisRuntimeDecision decision;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.crisis;
  @override
  String get controlledClubId => decision.clubId;
}

final class PlayerPresidentManagerReviewConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentManagerReviewConsequence({
    required this.context,
    required this.choice,
  });
  final PlayerManagerReviewContext context;
  final PlayerManagerReviewChoice choice;
  bool get retained => choice == PlayerManagerReviewChoice.retain;
  bool get replacementRequired => choice == PlayerManagerReviewChoice.replace;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.managerReview;
  @override
  String get controlledClubId => context.clubId;
}

final class PlayerPresidentManagerReplacementConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentManagerReplacementConsequence({
    required this.decision,
    required this.assignment,
  });
  final PlayerPresidentManagerRuntimeDecision decision;
  final ManagerAssignment assignment;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.managerReplacement;
  @override
  String get controlledClubId => decision.clubId;
}

final class PlayerPresidentPromiseConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentPromiseConsequence({
    required this.context,
    required this.promise,
  });
  final PlayerPromiseDecisionContext context;
  final PresidentPromise promise;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.promise;
  @override
  String get controlledClubId => context.controlledClubId;
}

final class PlayerPresidentMediaStatementConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentMediaStatementConsequence({
    required this.context,
    required this.statement,
  });
  final PlayerMediaStatementDecisionContext context;
  final MediaStatement statement;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.mediaStatement;
  @override
  String get controlledClubId => context.controlledClubId;
}

final class PlayerPresidentTransferStrategyConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentTransferStrategyConsequence({
    required this.context,
    required this.effectiveProfile,
  });
  final PlayerTransferStrategyDecisionContext context;
  final PresidentManagementProfile effectiveProfile;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.transferStrategy;
  @override
  String get controlledClubId => context.controlledClubId;
}

final class PlayerPresidentTicketPricingConsequence
    extends PlayerPresidentInteractiveDecisionConsequence {
  const PlayerPresidentTicketPricingConsequence(this.decision);
  final PlayerPresidentTicketPricingDecision decision;
  @override
  PlayerPresidentInteractiveDecisionKind get kind =>
      PlayerPresidentInteractiveDecisionKind.ticketPricing;
  @override
  String get controlledClubId => decision.context.clubId;
}

class PlayerPresidentInteractiveDecisionResolution {
  PlayerPresidentInteractiveDecisionResolution({
    required this.requestKey,
    required this.kind,
    required this.acceptedChoice,
    required this.consequence,
  }) {
    if (consequence.kind != kind) {
      throw ArgumentError(
        'Resolution kind ${kind.name} does not match consequence '
        '${consequence.kind.name}.',
      );
    }
  }

  final String requestKey;
  final PlayerPresidentInteractiveDecisionKind kind;
  final Object acceptedChoice;
  final PlayerPresidentInteractiveDecisionConsequence consequence;

  bool get hasConsequence => true;

  T choiceAs<T>() {
    final value = acceptedChoice;
    if (value is! T) {
      throw StateError(
        'Decision ${kind.name} does not contain accepted choice type $T.',
      );
    }
    return value as T;
  }

  T consequenceAs<T extends PlayerPresidentInteractiveDecisionConsequence>() {
    final value = consequence;
    if (value is! T) {
      throw StateError(
        'Decision ${kind.name} does not contain consequence type $T.',
      );
    }
    return value;
  }
}

class PlayerPresidentInteractiveDecisionSubmissionResult {
  const PlayerPresidentInteractiveDecisionSubmissionResult({
    required this.resolution,
    required this.nextStep,
  });
  final PlayerPresidentInteractiveDecisionResolution resolution;
  final PlayerPresidentInteractiveSessionStep nextStep;
}

/// M73 turns M72's synchronous application gateway into a UI-drivable
/// request/response session without changing canonical domain semantics.
///
/// The underlying M72 engine remains synchronous. The session pauses by
/// intercepting the first unanswered gateway call. After the application
/// submits a choice, M73 deterministically replays from the immutable starting
/// inputs/checkpoint, consumes the recorded answers, and stops at the next
/// unanswered decision. No partial simulation state is committed while a
/// decision is pending.
///
/// The session and its answer transcript are runtime-only. Completed state is
/// still persisted exclusively through M65's
/// [PlayerPresidentTicketPricingRuntimeCheckpoint] and save codec.
class PlayerPresidentInteractiveDecisionSession {
  PlayerPresidentInteractiveDecisionSession.start({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
    CrisisDecisionEngine aiCrisisEngine =
        const CrisisDecisionEngine(activationThreshold: 55),
    PresidentMatchdayTicketPricingPolicy ticketAiPolicy =
        const PresidentMatchdayTicketPricingPolicy(),
    int candidateLimit = 5,
  })  : _clubs = List.unmodifiable(clubs),
        _leagues = List.unmodifiable(leagues),
        _config = config,
        _controlledClubId = controlledClubId,
        _checkpoint = null,
        _seasonCount = seasonCount,
        _electionInterval = electionInterval,
        _hasFutureSeasonAfterReport = hasFutureSeasonAfterReport,
        _aiCrisisEngine = aiCrisisEngine,
        _ticketAiPolicy = ticketAiPolicy,
        _candidateLimit = candidateLimit {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }
    if (candidateLimit <= 0) {
      throw ArgumentError.value(candidateLimit, 'candidateLimit');
    }
    if (controlledClubId.isEmpty ||
        !_clubs!.any((club) => club.id == controlledClubId)) {
      throw ArgumentError.value(
        controlledClubId,
        'controlledClubId',
        'Controlled club must exist in the supplied world.',
      );
    }
  }

  PlayerPresidentInteractiveDecisionSession.resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
    CrisisDecisionEngine aiCrisisEngine =
        const CrisisDecisionEngine(activationThreshold: 55),
    PresidentMatchdayTicketPricingPolicy ticketAiPolicy =
        const PresidentMatchdayTicketPricingPolicy(),
    int candidateLimit = 5,
  })  : _clubs = null,
        _leagues = null,
        _config = null,
        _controlledClubId = null,
        _checkpoint = checkpoint,
        _seasonCount = seasonCount,
        _electionInterval = null,
        _hasFutureSeasonAfterReport = hasFutureSeasonAfterReport,
        _aiCrisisEngine = aiCrisisEngine,
        _ticketAiPolicy = ticketAiPolicy,
        _candidateLimit = candidateLimit {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (candidateLimit <= 0) {
      throw ArgumentError.value(candidateLimit, 'candidateLimit');
    }
  }

  final List<Club>? _clubs;
  final List<WorldLeague>? _leagues;
  final SimulationConfig? _config;
  final String? _controlledClubId;
  final PlayerPresidentTicketPricingRuntimeCheckpoint? _checkpoint;
  final int _seasonCount;
  final int? _electionInterval;
  final bool _hasFutureSeasonAfterReport;
  final CrisisDecisionEngine _aiCrisisEngine;
  final PresidentMatchdayTicketPricingPolicy _ticketAiPolicy;
  final int _candidateLimit;

  final List<_RecordedInteractiveDecision> _answers = [];
  PlayerPresidentInteractiveDecisionRequest? _pending;
  PlayerPresidentInteractiveSessionCompleted? _completed;

  int get answeredDecisionCount => _answers.length;
  PlayerPresidentInteractiveDecisionRequest? get pendingDecision => _pending;
  PlayerPresidentInteractiveSessionCompleted? get completed => _completed;

  PlayerPresidentInteractiveSessionStep advance() => _advanceInternal().step;

  _InteractiveAdvanceResult _advanceInternal({int? captureSequence}) {
    final completed = _completed;
    if (completed != null) return _InteractiveAdvanceResult(step: completed);
    final pending = _pending;
    if (pending != null) {
      return _InteractiveAdvanceResult(
        step: PlayerPresidentInteractiveDecisionPending(pending),
      );
    }

    final gateway = _InteractiveReplayGateway(
      _answers,
      captureSequence: captureSequence,
    );
    final engine = PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine(
      gateway: gateway,
      aiCrisisEngine: _aiCrisisEngine,
      ticketAiPolicy: _ticketAiPolicy,
      candidateLimit: _candidateLimit,
    );

    try {
      final PlayerPresidentUnifiedManagerRuntimeCareerResult result;
      final checkpoint = _checkpoint;
      if (checkpoint == null) {
        result = engine.simulateWithCheckpoint(
          clubs: _clubs!,
          leagues: _leagues!,
          config: _config!,
          controlledClubId: _controlledClubId!,
          seasonCount: _seasonCount,
          electionInterval: _electionInterval!,
          hasFutureSeasonAfterReport: _hasFutureSeasonAfterReport,
        );
      } else {
        result = engine.resume(
          checkpoint: checkpoint,
          seasonCount: _seasonCount,
          hasFutureSeasonAfterReport: _hasFutureSeasonAfterReport,
        );
      }
      if (gateway.consumedDecisionCount != _answers.length) {
        throw StateError(
          'Interactive decision replay completed before consuming the full '
          'answer transcript.',
        );
      }
      final next = PlayerPresidentInteractiveSessionCompleted(
        result: result,
        decisionCount: _answers.length,
      );
      _completed = next;
      return _InteractiveAdvanceResult(
        step: next,
        consequence: gateway.capturedConsequence,
      );
    } on _PendingInteractiveDecision catch (signal) {
      if (gateway.consumedDecisionCount != _answers.length) {
        throw StateError(
          'Interactive decision replay diverged before the pending request.',
        );
      }
      _pending = signal.request;
      return _InteractiveAdvanceResult(
        step: PlayerPresidentInteractiveDecisionPending(signal.request),
        consequence: gateway.capturedConsequence,
      );
    }
  }

  PlayerPresidentInteractiveSessionStep submit({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      submitWithResolution(request: request, choice: choice).nextStep;

  PlayerPresidentInteractiveDecisionSubmissionResult submitWithResolution({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) {
    if (_completed != null) {
      throw StateError('Interactive session is already completed.');
    }
    final pending = _pending;
    if (pending == null) {
      throw StateError('advance() must expose a pending decision first.');
    }
    if (pending.key != request.key) {
      throw StateError(
        'Stale or mismatched decision response. '
        'Expected ${pending.key}, got ${request.key}.',
      );
    }

    _validateChoice(request, choice);
    _answers.add(
      _RecordedInteractiveDecision(
        requestKey: request.key,
        choice: choice,
      ),
    );
    _pending = null;

    final advanced = _advanceInternal(captureSequence: request.sequence);
    final consequence = advanced.consequence;
    if (consequence == null) {
      throw StateError(
        'Accepted ${request.kind.name} decision did not emit an authoritative '
        'runtime consequence.',
      );
    }
    if (consequence.kind != request.kind ||
        consequence.controlledClubId != request.clubId) {
      throw StateError(
        'Captured consequence does not match submitted decision '
        '${request.key}.',
      );
    }

    return PlayerPresidentInteractiveDecisionSubmissionResult(
      resolution: PlayerPresidentInteractiveDecisionResolution(
        requestKey: request.key,
        kind: request.kind,
        acceptedChoice: choice,
        consequence: consequence,
      ),
      nextStep: advanced.step,
    );
  }

  static void _validateChoice(
    PlayerPresidentInteractiveDecisionRequest request,
    Object choice,
  ) {
    switch (request.kind) {
      case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
        if (choice is! PlayerFacilityInvestmentChoice) {
          throw ArgumentError.value(choice, 'choice', 'Expected facility choice.');
        }
        choice.validate();
        return;
      case PlayerPresidentInteractiveDecisionKind.sponsor:
        if (choice is! PlayerSponsorOfferChoice) {
          throw ArgumentError.value(choice, 'choice', 'Expected sponsor choice.');
        }
        choice.validate();
        final context = request.contextAs<PlayerSponsorDecisionContext>();
        if (!context.offers.any((offer) => offer.id == choice.offerId)) {
          throw ArgumentError.value(
            choice.offerId,
            'choice',
            'Sponsor offer is not available in this decision.',
          );
        }
        return;
      case PlayerPresidentInteractiveDecisionKind.crisis:
        if (choice is! PlayerCrisisActionChoice) {
          throw ArgumentError.value(choice, 'choice', 'Expected crisis choice.');
        }
        final context = request.contextAs<PlayerCrisisDecisionContext>();
        if (!context.availableDecisions
            .any((decision) => decision.action == choice.action)) {
          throw ArgumentError.value(
            choice.action,
            'choice',
            'Crisis action is not available in this decision.',
          );
        }
        return;
      case PlayerPresidentInteractiveDecisionKind.managerReview:
        if (choice is! PlayerManagerReviewChoice) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Expected manager review choice.',
          );
        }
        final context = request.contextAs<PlayerManagerReviewContext>();
        if (choice == PlayerManagerReviewChoice.retain && !context.canRetain) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Current manager cannot be retained.',
          );
        }
        return;
      case PlayerPresidentInteractiveDecisionKind.managerReplacement:
        if (choice is! PlayerManagerReplacementChoice) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Expected manager replacement choice.',
          );
        }
        choice.validate();
        final context = request.contextAs<PlayerManagerReplacementContext>();
        if (!context.candidates
            .any((candidate) => candidate.manager.id == choice.managerId)) {
          throw ArgumentError.value(
            choice.managerId,
            'choice',
            'Manager is not in the canonical candidate list.',
          );
        }
        return;
      case PlayerPresidentInteractiveDecisionKind.promise:
        if (choice is! PresidentPromiseType) {
          throw ArgumentError.value(choice, 'choice', 'Expected promise type.');
        }
        final context = request.contextAs<PlayerPromiseDecisionContext>();
        if (!context.allowedTypes.contains(choice)) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Promise type is not allowed in this context.',
          );
        }
        return;
      case PlayerPresidentInteractiveDecisionKind.mediaStatement:
        if (choice is! MediaStance) {
          throw ArgumentError.value(choice, 'choice', 'Expected media stance.');
        }
        final context =
            request.contextAs<PlayerMediaStatementDecisionContext>();
        if (!context.allowedStances.contains(choice)) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Media stance is not allowed in this context.',
          );
        }
        return;
      case PlayerPresidentInteractiveDecisionKind.transferStrategy:
        if (choice is! PlayerTransferStrategyChoice) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Expected transfer strategy choice.',
          );
        }
        choice.validate();
        return;
      case PlayerPresidentInteractiveDecisionKind.ticketPricing:
        if (choice is! MatchdayTicketPricingChoice) {
          throw ArgumentError.value(
            choice,
            'choice',
            'Expected ticket pricing choice.',
          );
        }
        return;
    }
  }
}

class _InteractiveAdvanceResult {
  const _InteractiveAdvanceResult({
    required this.step,
    this.consequence,
  });
  final PlayerPresidentInteractiveSessionStep step;
  final PlayerPresidentInteractiveDecisionConsequence? consequence;
}

class _RecordedInteractiveDecision {
  const _RecordedInteractiveDecision({
    required this.requestKey,
    required this.choice,
  });

  final String requestKey;
  final Object choice;
}

class _PendingInteractiveDecision implements Exception {
  const _PendingInteractiveDecision(this.request);

  final PlayerPresidentInteractiveDecisionRequest request;
}

class _InteractiveReplayGateway extends PlayerPresidentDecisionGateway {
  _InteractiveReplayGateway(
    this.answers, {
    this.captureSequence,
  });

  final List<_RecordedInteractiveDecision> answers;
  final int? captureSequence;
  int _cursor = 0;
  PlayerPresidentInteractiveDecisionRequest? _lastResolvedRequest;
  PlayerPresidentInteractiveDecisionConsequence? capturedConsequence;

  int get consumedDecisionCount => _cursor;

  T _resolve<T>({
    required PlayerPresidentInteractiveDecisionKind kind,
    required String clubId,
    required String contextSignature,
    required Object context,
  }) {
    final request = PlayerPresidentInteractiveDecisionRequest._(
      sequence: _cursor + 1,
      kind: kind,
      clubId: clubId,
      contextSignature: contextSignature,
      context: context,
    );
    if (_cursor == answers.length) {
      throw _PendingInteractiveDecision(request);
    }
    if (_cursor > answers.length) {
      throw StateError('Interactive decision transcript cursor is invalid.');
    }

    final recorded = answers[_cursor];
    if (recorded.requestKey != request.key) {
      throw StateError(
        'Interactive decision replay diverged at sequence ${request.sequence}. '
        'Expected ${recorded.requestKey}, got ${request.key}.',
      );
    }
    final choice = recorded.choice;
    if (choice is! T) {
      throw StateError(
        'Recorded ${kind.name} choice has incompatible type '
        '${choice.runtimeType}; expected $T.',
      );
    }
    _cursor++;
    _lastResolvedRequest = request;
    return choice as T;
  }

  void _capture(
    PlayerPresidentInteractiveDecisionKind kind,
    String controlledClubId,
    PlayerPresidentInteractiveDecisionConsequence consequence,
  ) {
    final target = captureSequence;
    if (target == null) return;
    final request = _lastResolvedRequest;
    if (request == null || request.sequence != target) return;
    if (request.kind != kind || consequence.kind != kind) {
      throw StateError(
        'Consequence kind does not match replay request ${request.key}.',
      );
    }
    if (request.clubId != controlledClubId ||
        consequence.controlledClubId != controlledClubId) {
      throw StateError(
        'Consequence club does not match replay request ${request.key}.',
      );
    }
    final recorded = answers[target - 1];
    if (recorded.requestKey != request.key) {
      throw StateError(
        'Consequence request binding diverged at sequence $target.',
      );
    }
    if (capturedConsequence != null) {
      throw StateError(
        'Decision ${request.key} emitted more than one consequence.',
      );
    }
    capturedConsequence = consequence;
  }

  @override
  PlayerFacilityInvestmentChoice chooseFacilityInvestment(
    PlayerFacilityInvestmentContext context,
  ) =>
      _resolve<PlayerFacilityInvestmentChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.facilityInvestment,
        clubId: context.clubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  PlayerSponsorOfferChoice chooseSponsor(PlayerSponsorDecisionContext context) =>
      _resolve<PlayerSponsorOfferChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.sponsor,
        clubId: context.clubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  PlayerCrisisActionChoice chooseCrisisAction(
    PlayerCrisisDecisionContext context,
  ) =>
      _resolve<PlayerCrisisActionChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.crisis,
        clubId: context.clubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  PlayerManagerReviewChoice reviewManager(PlayerManagerReviewContext context) =>
      _resolve<PlayerManagerReviewChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.managerReview,
        clubId: context.clubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  PlayerManagerReplacementChoice chooseManagerReplacement(
    PlayerManagerReplacementContext context,
  ) =>
      _resolve<PlayerManagerReplacementChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.managerReplacement,
        clubId: context.clubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      _resolve<PresidentPromiseType>(
        kind: PlayerPresidentInteractiveDecisionKind.promise,
        clubId: context.controlledClubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  MediaStance chooseMediaStance(
    PlayerMediaStatementDecisionContext context,
  ) =>
      _resolve<MediaStance>(
        kind: PlayerPresidentInteractiveDecisionKind.mediaStatement,
        clubId: context.controlledClubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      _resolve<PlayerTransferStrategyChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.transferStrategy,
        clubId: context.controlledClubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  MatchdayTicketPricingChoice chooseTicketPricing(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      _resolve<MatchdayTicketPricingChoice>(
        kind: PlayerPresidentInteractiveDecisionKind.ticketPricing,
        clubId: context.clubId,
        contextSignature: context.signature,
        context: context,
      );

  @override
  void onFacilityInvestmentApplied(
    PlayerPresidentFacilityRuntimeDecision decision,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.facilityInvestment,
        decision.clubId,
        PlayerPresidentFacilityInvestmentConsequence(decision),
      );

  @override
  void onSponsorApplied(
    PlayerPresidentSponsorRuntimeDecision decision,
    SponsorContract contract,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.sponsor,
        decision.clubId,
        PlayerPresidentSponsorConsequence(
          decision: decision,
          contract: contract,
        ),
      );

  @override
  void onCrisisApplied(PlayerPresidentCrisisRuntimeDecision decision) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.crisis,
        decision.clubId,
        PlayerPresidentCrisisConsequence(decision),
      );

  @override
  void onManagerReviewApplied(
    PlayerManagerReviewContext context,
    PlayerManagerReviewChoice choice,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.managerReview,
        context.clubId,
        PlayerPresidentManagerReviewConsequence(
          context: context,
          choice: choice,
        ),
      );

  @override
  void onManagerReplacementApplied(
    PlayerPresidentManagerRuntimeDecision decision,
    ManagerAssignment assignment,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.managerReplacement,
        decision.clubId,
        PlayerPresidentManagerReplacementConsequence(
          decision: decision,
          assignment: assignment,
        ),
      );

  @override
  void onPromiseApplied(
    PlayerPromiseDecisionContext context,
    PresidentPromise promise,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.promise,
        context.controlledClubId,
        PlayerPresidentPromiseConsequence(
          context: context,
          promise: promise,
        ),
      );

  @override
  void onMediaStatementApplied(
    PlayerMediaStatementDecisionContext context,
    MediaStatement statement,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.mediaStatement,
        context.controlledClubId,
        PlayerPresidentMediaStatementConsequence(
          context: context,
          statement: statement,
        ),
      );

  @override
  void onTransferStrategyApplied(
    PlayerTransferStrategyDecisionContext context,
    PlayerTransferStrategyChoice choice,
    PresidentManagementProfile effectiveProfile,
  ) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.transferStrategy,
        context.controlledClubId,
        PlayerPresidentTransferStrategyConsequence(
          context: context,
          effectiveProfile: effectiveProfile,
        ),
      );

  @override
  void onTicketPricingApplied(PlayerPresidentTicketPricingDecision decision) =>
      _capture(
        PlayerPresidentInteractiveDecisionKind.ticketPricing,
        decision.context.clubId,
        PlayerPresidentTicketPricingConsequence(decision),
      );
}
