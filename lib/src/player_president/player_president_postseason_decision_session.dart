import '../election/president_management_profile.dart';
import '../manager/manager.dart';
import '../manager/manager_career_controller.dart';
import '../manager/player_president_manager_control.dart';
import '../manager/player_president_manager_preparation_projection.dart';
import '../save/advanced_runtime_checkpoint.dart';
import '../transfer/player_president_transfer_strategy_control.dart';

enum PostseasonDecisionPhase {
  transferStrategy,
  awaitingOffseason,
  managerReview,
  managerReplacement,
  prepared,
  terminal,
}

enum PostseasonDecisionStatus {
  awaitingContext,
  decisionRequired,
  decisionContractUnavailable,
  notRequired,
  completed
}

/// Data requirements, NOT authority. No public constructor mints a capability.
/// The market context must be captured at the actual M54/M55 provider seam.
final class PostseasonSourceRequirements {
  const PostseasonSourceRequirements({
    required this.owner,
    required this.revision,
    required this.provenance,
    required this.transaction,
    required this.completedSeason,
    required this.hasNextSeason,
    required this.clubId,
    this.transferContext,
  });
  final Object owner, revision, provenance, transaction;
  final int completedSeason;
  int get targetSeason => completedSeason + 1;
  final bool hasNextSeason;
  final String clubId;
  final PlayerTransferStrategyDecisionContext? transferContext;
}

/// Producer deferred to B3-B. External callers cannot manufacture authority.
sealed class PostseasonSourceCapability {
  PostseasonSourceRequirements get source;
}

/// Post-offseason completion provenance is deliberately a separate capability.
/// A raw checkpoint, a reconstructed manager, or a request key is not proof.
sealed class ManagerPreparationSourceCapability {
  PostseasonSourceCapability get continuation;
  ManagerSeasonAuthority get originalOpening;
  AdvancedRuntimeCheckpoint get postOffseason;
  String get presidentId;
}

final class PostseasonDecisionRequest<T extends Object> {
  PostseasonDecisionRequest._(this.source, this.phase, this.context);
  final PostseasonSourceRequirements source;
  final PostseasonDecisionPhase phase;
  final T context;
}

final class PostseasonPending<T extends Object> implements Exception {
  PostseasonPending._(this.request);
  final PostseasonDecisionRequest<T> request;
}

final class PostseasonContractUnavailable implements Exception {
  const PostseasonContractUnavailable();
}

final class PostseasonDecisionNotRequired implements Exception {
  const PostseasonDecisionNotRequired();
}

final class PostseasonAcceptedAnswer {
  PostseasonAcceptedAnswer._(this.request, this.choice, this.consequence);
  final PostseasonDecisionRequest<Object> request;
  final Object choice;
  final Object? consequence;
}

/// Incremental decision primitive. It never owns or replays a market, world,
/// application, M73 session, or settlement. Accepted choices are not publication.
final class PostseasonDecisionSession {
  PostseasonDecisionSession.fromCapability(
      PostseasonSourceCapability capability)
      : _source = capability.source,
        _capability = capability,
        _projection = const PlayerManagerPreparationProjection() {
    _validateShape();
  }

  /// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER.
  PostseasonDecisionSession.forContractFixture(
      PostseasonSourceRequirements source,
      {PlayerManagerPreparationProjection projection =
          const PlayerManagerPreparationProjection()})
      : _source = source,
        _capability = null,
        _projection = projection {
    _validateShape();
  }

  final PostseasonSourceRequirements _source;
  final PostseasonSourceCapability? _capability;
  final List<PostseasonAcceptedAnswer> _answers = [];
  PostseasonPending? _pending;
  PostseasonDecisionPhase _phase = PostseasonDecisionPhase.transferStrategy;
  PostseasonDecisionStatus _status = PostseasonDecisionStatus.awaitingContext;
  AdvancedRuntimeCheckpoint? _managerSource;
  PlayerManagerReviewContext? _review;
  final PlayerManagerPreparationProjection _projection;

  bool get isAuthoritative => _capability != null;
  PostseasonDecisionPhase get phase => _phase;
  PostseasonDecisionStatus get status => _status;
  PostseasonPending? get pending => _pending;
  List<PostseasonAcceptedAnswer> get answers => List.unmodifiable(_answers);

  void _validateShape() {
    if (_source.completedSeason < 0 || _source.clubId.isEmpty) {
      throw ArgumentError('Invalid continuation source shape.');
    }
    if (!_source.hasNextSeason) {
      _phase = PostseasonDecisionPhase.terminal;
      _status = PostseasonDecisionStatus.notRequired;
    }
  }

  void _bind(
      {required Object owner,
      required Object revision,
      required Object provenance,
      required Object transaction}) {
    if (!identical(owner, _source.owner) ||
        !identical(revision, _source.revision) ||
        !identical(provenance, _source.provenance) ||
        !identical(transaction, _source.transaction) ||
        (_capability != null && !identical(_capability.source, _source))) {
      throw StateError('Foreign owner/revision/source/transaction.');
    }
  }

  /// Invoke only from the actual market-provider seam, not before market context
  /// exists. The primitive captures it; no market execution occurs here.
  PostseasonPending<PlayerTransferStrategyDecisionContext>? requestTransfer(
      PlayerTransferStrategyDecisionContext context) {
    if (_phase == PostseasonDecisionPhase.terminal) return null;
    if (_phase != PostseasonDecisionPhase.transferStrategy) {
      throw StateError('Transfer request is stale or in the wrong phase.');
    }
    final expected = _source.transferContext;
    if (expected == null) {
      _status = PostseasonDecisionStatus.decisionContractUnavailable;
      return null;
    }
    if (!identical(context, expected) ||
        context.controlledClubId != _source.clubId ||
        context.seasonIndex != _source.completedSeason ||
        context.decisionSeasonIndex != _source.targetSeason) {
      throw StateError('Foreign or premature market context.');
    }
    _pending ??= _newPending<PlayerTransferStrategyDecisionContext>(
        PostseasonDecisionPhase.transferStrategy, context);
    return _pending as PostseasonPending<PlayerTransferStrategyDecisionContext>;
  }

  PostseasonPending<T> _newPending<T extends Object>(
      PostseasonDecisionPhase phase, T context) {
    final pending = PostseasonPending<T>._(
        PostseasonDecisionRequest<T>._(_source, phase, context));
    _status = PostseasonDecisionStatus.decisionRequired;
    return pending;
  }

  void answer(
      {required PostseasonDecisionRequest<Object> request,
      required Object choice,
      required Object owner,
      required Object revision,
      required Object provenance,
      required Object transaction}) {
    _bind(
        owner: owner,
        revision: revision,
        provenance: provenance,
        transaction: transaction);
    if (!identical(request.source, _source) ||
        !identical(_pending?.request, request) ||
        request.phase != _phase) {
      throw StateError('Foreign, stale or completed request.');
    }
    final prior = _answers.where((a) => identical(a.request, request));
    if (prior.isNotEmpty) {
      if (!_sameChoice(prior.single.choice, choice)) {
        throw StateError('Inconsistent duplicate answer.');
      }
      return;
    }
    Object? consequence;
    switch (_phase) {
      case PostseasonDecisionPhase.transferStrategy:
        if (choice is! PlayerTransferStrategyChoice)
          throw ArgumentError('Wrong transfer choice type.');
        choice.validate();
        final context =
            request.context as PlayerTransferStrategyDecisionContext;
        consequence = choice.applyTo(context.aiProfile);
      case PostseasonDecisionPhase.managerReview:
        if (choice is! PlayerManagerReviewChoice)
          throw ArgumentError('Wrong review choice type.');
        if (choice == PlayerManagerReviewChoice.retain && !_review!.canRetain) {
          throw ArgumentError('Incumbent cannot be retained.');
        }
        // Prepare fallible next context BEFORE accepting any answer.
        if (choice == PlayerManagerReviewChoice.replace) {
          consequence = _projection.replacement(
              advanced: _managerSource!, review: _review!);
        }
      case PostseasonDecisionPhase.managerReplacement:
        if (choice is! Manager)
          throw ArgumentError('Expected exact offered manager.');
        consequence = _projection.validateSelected(
            request.context as PlayerManagerReplacementContext, choice);
      default:
        throw StateError('No decision in this phase.');
    }
    _answers.add(PostseasonAcceptedAnswer._(request, choice, consequence));
  }

  bool _sameChoice(Object a, Object b) =>
      identical(a, b) ||
      (a is PlayerTransferStrategyChoice &&
          b is PlayerTransferStrategyChoice &&
          a.signature == b.signature);

  /// Explicit acknowledgement, not execution. Retains the exact request until
  /// the captured answer is accepted by the detached caller. No callbacks here.
  void completePhase(PostseasonDecisionRequest<Object> request) {
    if (!identical(_pending?.request, request) || request.phase != _phase) {
      throw StateError('Stale phase completion.');
    }
    final accepted = _answers.where((a) => identical(a.request, request));
    if (accepted.length != 1)
      throw StateError('Phase requires an accepted answer.');
    final answer = accepted.single;
    if (_phase == PostseasonDecisionPhase.managerReview &&
        answer.choice == PlayerManagerReviewChoice.replace) {
      _phase = PostseasonDecisionPhase.managerReplacement;
      _pending = _newPending(_phase, answer.consequence!);
    } else {
      _phase = _phase == PostseasonDecisionPhase.transferStrategy
          ? PostseasonDecisionPhase.awaitingOffseason
          : PostseasonDecisionPhase.prepared;
      _pending = null;
      _status = PostseasonDecisionStatus.completed;
    }
  }

  PostseasonPending? prepareManager(ManagerPreparationSourceCapability source) {
    if (_phase == PostseasonDecisionPhase.terminal) return null;
    if (!identical(source.continuation, _capability) || _capability == null) {
      throw StateError('Foreign manager preparation capability.');
    }
    return _prepareManager(
        source.originalOpening, source.postOffseason, source.presidentId);
  }

  /// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER. No assignment/history published.
  PostseasonPending? prepareManagerForContractFixture(
      {required ManagerSeasonAuthority? originalOpening,
      required AdvancedRuntimeCheckpoint postOffseason,
      required String presidentId}) {
    if (isAuthoritative)
      throw StateError('Fixture cannot prepare production continuation.');
    return _prepareManager(originalOpening, postOffseason, presidentId);
  }

  PostseasonPending? _prepareManager(ManagerSeasonAuthority? opening,
      AdvancedRuntimeCheckpoint advanced, String presidentId) {
    if (_phase == PostseasonDecisionPhase.terminal) return null;
    if (_phase != PostseasonDecisionPhase.awaitingOffseason) {
      throw StateError(
          'Review is only available in post-offseason preparation.');
    }
    if (opening == null ||
        !identical(opening.owner, _source.owner) ||
        !identical(opening.sourceRevision, _source.revision) ||
        opening.seasonIndex != _source.completedSeason ||
        advanced.manager.seasons.isEmpty ||
        advanced.manager.seasons.last.seasonIndex != opening.seasonIndex ||
        advanced.nextSeasonIndex != _source.targetSeason) {
      _status = PostseasonDecisionStatus.decisionContractUnavailable;
      return null;
    }
    // Original opening identity coverage, not a reconstructed manager pool.
    if (opening.managers.length != advanced.manager.managers.length ||
        opening.managers.any(
            (m) => !advanced.manager.managers.any((n) => identical(m, n)))) {
      throw StateError('Foreign manager pool.');
    }
    final review = _projection.review(
        advanced: advanced, clubId: _source.clubId, presidentId: presidentId);
    if (opening.assignments[_source.clubId]?.managerId !=
        review.currentManager.id) {
      throw StateError('Completed incumbent differs from original opening.');
    }
    // Forced retirement suppresses retain/review, just as M71 does.
    final context = review.forcedRetirement
        ? _projection.replacement(advanced: advanced, review: review)
        : review;
    final phase = review.forcedRetirement
        ? PostseasonDecisionPhase.managerReplacement
        : PostseasonDecisionPhase.managerReview;
    _managerSource = advanced;
    _review = review;
    _phase = phase;
    _pending = _newPending(phase, context);
    return _pending;
  }

  PostseasonTransferDecisionAdapter get transferAdapter =>
      PostseasonTransferDecisionAdapter._(this);
}

/// Compatible with M55's provider interface. Throws typed Pending/unavailable;
/// never returns the AI profile as a missing controlled-player answer.
final class PostseasonTransferDecisionAdapter
    extends PlayerTransferStrategyDecisionProvider {
  PostseasonTransferDecisionAdapter._(this.session);
  final PostseasonDecisionSession session;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
      PlayerTransferStrategyDecisionContext context) {
    final pending = session.requestTransfer(context);
    if (pending == null) {
      if (session.status == PostseasonDecisionStatus.notRequired) {
        throw const PostseasonDecisionNotRequired();
      }
      throw const PostseasonContractUnavailable();
    }
    final accepted =
        session.answers.where((a) => identical(a.request, pending.request));
    if (accepted.isEmpty) throw pending;
    return accepted.single.choice as PlayerTransferStrategyChoice;
  }

  @override
  void onApplied(
      PlayerTransferStrategyDecisionContext context,
      PlayerTransferStrategyChoice choice,
      PresidentManagementProfile effectiveProfile) {
    final pending = session.pending;
    if (pending == null || !identical(pending.request.context, context)) {
      throw StateError('Foreign transfer application callback.');
    }
    final accepted = session.answers
        .singleWhere((a) => identical(a.request, pending.request));
    if (!session._sameChoice(accepted.choice, choice) ||
        (accepted.consequence as PresidentManagementProfile).signature !=
            effectiveProfile.signature) {
      throw StateError('Transfer callback differs from accepted consequence.');
    }
    // M55 computes a fresh immutable profile from the validated choice. Record
    // the actual callback object, without invoking the producer again.
    final index = session._answers.indexOf(accepted);
    session._answers[index] = PostseasonAcceptedAnswer._(
        accepted.request, accepted.choice, effectiveProfile);
    session.completePhase(pending.request);
  }
}
