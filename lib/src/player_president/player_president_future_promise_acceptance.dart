part of 'player_president_interactive_decision_session.dart';

/// Detached M73/M56 result for one exact future-preseason request.
/// Application ownership is published by the application-session library.
final class PlayerPresidentFuturePromiseAcceptance {
  PlayerPresidentFuturePromiseAcceptance._({
    required this.request,
    required this.choice,
    required this.consequence,
    required Iterable<PresidentPromise> activePromises,
  }) : activePromises = List.unmodifiable(activePromises);

  final PlayerPresidentInteractiveDecisionRequest request;
  final PresidentPromiseType choice;
  final PlayerPresidentPromiseConsequence consequence;
  final List<PresidentPromise> activePromises;

  static PlayerPresidentFuturePromiseAcceptance accept({
    required ApplicationFuturePromiseAcceptanceClaim claim,
    required PlayerPresidentInteractiveDecisionPending pending,
    required PlayerPresidentInteractiveDecisionRequest request,
    required PresidentPromiseType choice,
  }) {
    claim.validate(pending: pending, request: request);
    final opening = claim.opening;
    return _acceptValidated(
      pending: pending,
      request: request,
      choice: choice,
      controlledClubId: opening.controlledClubId,
      promiseContexts: opening.promiseContexts,
      config: opening.opening.config,
      controlledPromiseContext: opening.controlledPromiseContext,
      targetSeasonIndex: opening.targetSeasonIndex,
    );
  }

  static PlayerPresidentFuturePromiseAcceptance acceptDurable({
    required DurableFuturePromiseAcceptanceClaim claim,
    required PlayerPresidentInteractiveDecisionPending pending,
    required PlayerPresidentInteractiveDecisionRequest request,
    required PresidentPromiseType choice,
  }) {
    claim.validate(pending: pending, request: request);
    return _acceptValidated(
      pending: pending,
      request: request,
      choice: choice,
      controlledClubId: claim.controlledClubId,
      promiseContexts: claim.promiseContexts,
      config: claim.config,
      controlledPromiseContext: claim.controlledPromiseContext,
      targetSeasonIndex: 1,
    );
  }

  static PlayerPresidentFuturePromiseAcceptance _acceptValidated({
    required PlayerPresidentInteractiveDecisionPending pending,
    required PlayerPresidentInteractiveDecisionRequest request,
    required PresidentPromiseType choice,
    required String controlledClubId,
    required List<PresidentPromiseContext> promiseContexts,
    required SimulationConfig config,
    required PlayerPromiseDecisionContext controlledPromiseContext,
    required int targetSeasonIndex,
  }) {
    PlayerPresidentInteractiveDecisionSession._validateChoice(request, choice);
    final answers = List<_RecordedInteractiveDecision>.unmodifiable([
      _RecordedInteractiveDecision(requestKey: request.key, choice: choice),
    ]);
    final gateway = _InteractiveReplayGateway(
      answers,
      captureSequence: request.sequence,
      keyNamespace: request.keyNamespace,
    );
    final generator = PlayerPresidentPromiseGenerator(
      controlledClubId: controlledClubId,
      decisionProvider: _FuturePromiseGatewayProvider(gateway),
    );
    final promises = <PresidentPromise>[];
    for (final context in promiseContexts) {
      promises.add(generator.generate(
        context: context,
        careerSeed: config.careerSeed,
        simulationVersion: config.simulationVersion,
      ));
    }
    if (gateway.consumedDecisionCount != 1) {
      throw StateError('Future promise answer was not consumed exactly once.');
    }
    final captured = _requireAuthoritativeConsequence(
      request,
      gateway.capturedConsequence,
    );
    if (captured is! PlayerPresidentPromiseConsequence ||
        captured.context.signature != controlledPromiseContext.signature ||
        captured.promise.type != choice ||
        promises.length != 48 ||
        promises.map((p) => p.clubId).toSet().length != 48 ||
        promises.map((p) => p.id).toSet().length != 48 ||
        promises.any((p) => p.seasonIndex != targetSeasonIndex) ||
        !identical(
          captured.promise,
          promises.singleWhere((p) => p.clubId == controlledClubId),
        )) {
      throw StateError('Future promise authority failed canonical validation.');
    }
    return PlayerPresidentFuturePromiseAcceptance._(
      request: request,
      choice: choice,
      consequence: captured,
      activePromises: promises,
    );
  }
}

final class _FuturePromiseGatewayProvider
    extends PlayerPromiseDecisionProvider {
  const _FuturePromiseGatewayProvider(this.gateway);
  final _InteractiveReplayGateway gateway;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      gateway.choosePromise(context);

  @override
  void onApplied(
    PlayerPromiseDecisionContext context,
    PresidentPromise promise,
  ) =>
      gateway.onPromiseApplied(context, promise);
}
