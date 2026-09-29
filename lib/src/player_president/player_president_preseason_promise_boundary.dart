part of 'player_president_interactive_decision_session.dart';

enum PlayerPresidentPreseasonPromisePhase { unstarted, pending, applied }

/// The only active-state owner for the opt-in, in-memory preseason boundary.
/// M73 owns the typed request, transcript binding and real onApplied capture.
class PlayerPresidentPreseasonPromiseBoundary {
  PlayerPresidentPreseasonPromiseBoundary._({
    required this.application,
    required this.proof,
    required this.opening,
    required Iterable<PlayerPromiseDecisionContext> contexts,
    required this.controlledPresidentId,
  }) : contexts = List.unmodifiable(contexts);

  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final IntegratedNewGameOpeningProof proof;
  final WorldOpeningState opening;
  final List<PlayerPromiseDecisionContext> contexts;
  final String controlledPresidentId;

  _PreseasonPromiseState _state = const _PreseasonPromiseState();

  PlayerPresidentPreseasonPromisePhase get phase => _state.applied != null
      ? PlayerPresidentPreseasonPromisePhase.applied
      : _state.pending != null
          ? PlayerPresidentPreseasonPromisePhase.pending
          : PlayerPresidentPreseasonPromisePhase.unstarted;
  PlayerPresidentPreseasonPromisePending? get pending => _state.pending;
  PlayerPresidentPreseasonPromiseApplied? get applied => _state.applied;

  factory PlayerPresidentPreseasonPromiseBoundary.start({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
  }) {
    // A legacy advance exposes a Pending without adding a transcript entry.
    // Refuse it before attempting or reserving a second decision owner.
    if (application.pendingDecision != null ||
        application.answeredDecisionCount != 0 ||
        application.completed != null) {
      throw StateError('Preseason requires an untouched M79 decision session.');
    }
    final bootstrap = application.newGameBootstrapSnapshot;
    final proof = IntegratedNewGameOpeningProof.fromNewGame(
      application: application,
      sourceClubs: sourceClubs,
      sourceLeagues: sourceLeagues,
      expectedSeasonIndex: 0,
      expectedControlledClubId: bootstrap.controlledClubId,
    );
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: sourceClubs,
      leagues: sourceLeagues,
      config: bootstrap.config,
    );
    proof.seasonOpening.assertOpeningProjectionMatches(opening);
    final effective = const TeamStrengthCalculator().deriveClubs(
      baseClubs: opening.baseClubs,
      players: opening.players,
    );
    final openingContexts = const PromiseOpeningContextBuilder().build(
      seasonIndex: bootstrap.config.seasonIndex,
      effectiveClubs: effective,
      leagues: opening.leagues,
      openingFinanceStates: opening.financeStates,
    );
    if (openingContexts.length != 48 ||
        openingContexts.map((c) => c.clubId).toSet().length != 48) {
      throw StateError('Preseason promise context must cover 48 clubs once.');
    }
    final contexts = <PlayerPromiseDecisionContext>[
      for (final context in openingContexts)
        PlayerPromiseDecisionContext(
          context: context,
          aiPromise: const PromiseGenerator().generate(
            context: context,
            careerSeed: bootstrap.config.careerSeed,
            simulationVersion: bootstrap.config.simulationVersion,
          ),
          allowedTypes: PlayerPresidentPromiseGenerator.allowedPromiseTypes(
            context,
          ),
        ),
    ];
    final controlled = contexts.singleWhere(
      (item) => item.controlledClubId == bootstrap.controlledClubId,
    );

    // M73's exact private gateway produces the typed request, including the
    // independent preseason namespace; no handwritten Pending or capture path.
    final namespace =
        'preseason-promise/v1:${proof.seasonOpening.originSourceDigest}';
    final gateway = _InteractiveReplayGateway(
      const <_RecordedInteractiveDecision>[],
      keyNamespace: namespace,
    );
    late final PlayerPresidentInteractiveDecisionRequest request;
    try {
      gateway.choosePromise(controlled);
      throw StateError('M73 did not expose the preseason promise Pending.');
    } on _PendingInteractiveDecision catch (signal) {
      request = signal.request;
    }
    if (request.phase != 'preseasonPromise' ||
        request.sequence != 1 ||
        request.kind != PlayerPresidentInteractiveDecisionKind.promise ||
        request.clubId != bootstrap.controlledClubId ||
        request.contextSignature != controlled.signature ||
        !identical(request.context, controlled)) {
      throw StateError('M73 preseason request binding is inconsistent.');
    }
    final boundary = PlayerPresidentPreseasonPromiseBoundary._(
      application: application,
      proof: proof,
      opening: opening,
      contexts: contexts,
      controlledPresidentId: proof.presidentOpening.controlledPresidentId!,
    );
    final next = _PreseasonPromiseState(
      pending: PlayerPresidentPreseasonPromisePending._(
        boundary: boundary,
        request: request,
      ),
    );

    // This public reservation method independently verifies the supplied
    // proof against the same pristine M79 source before changing any flag.
    application.claimPreseasonPromiseBoundary(
      boundary: boundary,
      proof: proof,
      sourceClubs: sourceClubs,
      sourceLeagues: sourceLeagues,
    );
    boundary._state = next;
    return boundary;
  }

  PlayerPresidentPreseasonPromiseApplied submit({
    required PlayerPresidentPreseasonPromisePending pending,
    required PresidentPromiseType choice,
    PlayerPresidentInteractiveDecisionRequest? request,
  }) {
    if (!identical(application.preseasonPromiseBoundary, this)) {
      throw StateError('A foreign or unowned preseason boundary cannot submit.');
    }
    final current = _state.pending;
    final submitted = request ?? pending.request;
    if (current == null ||
        !identical(current, pending) ||
        !identical(current.request, submitted) ||
        submitted.phase != 'preseasonPromise' ||
        submitted.sequence != 1 ||
        submitted.kind != PlayerPresidentInteractiveDecisionKind.promise ||
        submitted.clubId != proof.controlledClubId ||
        submitted.keyNamespace !=
            'preseason-promise/v1:${proof.seasonOpening.originSourceDigest}') {
      throw StateError('Preseason submission requires the exact M73 Pending.');
    }
    PlayerPresidentInteractiveDecisionSession._validateChoice(
      submitted,
      choice,
    );
    final controlled = submitted.contextAs<PlayerPromiseDecisionContext>();
    final answers = List<_RecordedInteractiveDecision>.unmodifiable([
      _RecordedInteractiveDecision(requestKey: submitted.key, choice: choice),
    ]);
    final gateway = _InteractiveReplayGateway(
      answers,
      captureSequence: submitted.sequence,
      keyNamespace: submitted.keyNamespace,
    );

    // M56 is the only production generator. Its actual provider callbacks
    // consume the M73 recorded answer and emit the authoritative consequence.
    final generator = PlayerPresidentPromiseGenerator(
      controlledClubId: submitted.clubId,
      decisionProvider: _PreseasonPromiseGatewayProvider(gateway),
    );
    final promises = <PresidentPromise>[];
    for (final item in contexts) {
      final candidate = generator.generate(
        context: item.context,
        careerSeed: proof.seasonOpening.config.careerSeed,
        simulationVersion: proof.seasonOpening.config.simulationVersion,
      );
      if (item.controlledClubId != submitted.clubId &&
          candidate.signature != item.aiPromise.signature) {
        throw StateError('AI promise candidate parity failed.');
      }
      promises.add(candidate);
    }
    if (gateway.consumedDecisionCount != answers.length) {
      throw StateError('M73 did not consume exactly one promise response.');
    }
    final captured = _requireAuthoritativeConsequence(
      submitted,
      gateway.capturedConsequence,
    );
    if (captured is! PlayerPresidentPromiseConsequence ||
        captured.context.signature != controlled.signature ||
        captured.promise.type != choice ||
        captured.promise.id !=
            'promise_${submitted.clubId}_s${proof.seasonIndex}' ||
        promises.length != 48 ||
        promises.map((promise) => promise.clubId).toSet().length != 48 ||
        !identical(
          captured.promise,
          promises.singleWhere((promise) => promise.clubId == submitted.clubId),
        )) {
      throw StateError('Preseason candidate publication validation failed.');
    }
    final result = PlayerPresidentPreseasonPromiseApplied._(
      sourceIdentity: proof.seasonOpening.originSourceDigest,
      seasonIndex: proof.seasonIndex,
      controlledClubId: submitted.clubId,
      controlledPresidentId: controlledPresidentId,
      acceptedRequestKey: submitted.key,
      acceptedChoice: choice,
      consequence: captured,
      activePromises: promises,
    );

    // Only one authoritative pointer. Every fallible step is complete above.
    _state = _PreseasonPromiseState(applied: result);
    return result;
  }
}

class _PreseasonPromiseState {
  const _PreseasonPromiseState({this.pending, this.applied});
  final PlayerPresidentPreseasonPromisePending? pending;
  final PlayerPresidentPreseasonPromiseApplied? applied;
}

class PlayerPresidentPreseasonPromisePending {
  PlayerPresidentPreseasonPromisePending._({
    required this.boundary,
    required this.request,
  });

  final PlayerPresidentPreseasonPromiseBoundary boundary;
  final PlayerPresidentInteractiveDecisionRequest request;

  PlayerPromiseDecisionContext get context =>
      request.contextAs<PlayerPromiseDecisionContext>();
  String get phase => request.phase;
  int get sequence => request.sequence;
  String get kind => request.kind.name;
  String get sourceIdentity => boundary.proof.seasonOpening.originSourceDigest;
  String get clubId => request.clubId;
  String get contextSignature => request.contextSignature;
  String get requestKey => request.key;
}

class PlayerPresidentPreseasonPromiseApplied {
  PlayerPresidentPreseasonPromiseApplied._({
    required this.sourceIdentity,
    required this.seasonIndex,
    required this.controlledClubId,
    required this.controlledPresidentId,
    required this.acceptedRequestKey,
    required this.acceptedChoice,
    required this.consequence,
    required Iterable<PresidentPromise> activePromises,
  }) : activePromises = List.unmodifiable(activePromises);

  final String sourceIdentity;
  final int seasonIndex;
  final String controlledClubId;
  final String controlledPresidentId;
  final String acceptedRequestKey;
  final PresidentPromiseType acceptedChoice;
  final PlayerPresidentPromiseConsequence consequence;
  final List<PresidentPromise> activePromises;
}

// Only an adapter: the real M56 generator still calls M73's one gateway.
// No separate answer store, synthetic consequence or capture implementation.
class _PreseasonPromiseGatewayProvider extends PlayerPromiseDecisionProvider {
  const _PreseasonPromiseGatewayProvider(this.gateway);
  final _InteractiveReplayGateway gateway;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      gateway.choosePromise(context);

  @override
  void onApplied(
    PlayerPromiseDecisionContext context,
    PresidentPromise promise,
  ) => gateway.onPromiseApplied(context, promise);
}
