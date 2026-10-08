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
    PlayerPresidentInteractiveDecisionSession._validateChoice(request, choice);
    final answers = List<_RecordedInteractiveDecision>.unmodifiable([
      _RecordedInteractiveDecision(requestKey: request.key, choice: choice),
    ]);
    final gateway = _InteractiveReplayGateway(
      answers,
      captureSequence: request.sequence,
      keyNamespace: request.keyNamespace,
    );
    final opening = claim.opening;
    final generator = PlayerPresidentPromiseGenerator(
      controlledClubId: opening.controlledClubId,
      decisionProvider: _FuturePromiseGatewayProvider(gateway),
    );
    final promises = <PresidentPromise>[];
    for (final context in opening.promiseContexts) {
      promises.add(generator.generate(
        context: context,
        careerSeed: opening.opening.config.careerSeed,
        simulationVersion: opening.opening.config.simulationVersion,
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
        captured.context.signature !=
            opening.controlledPromiseContext.signature ||
        captured.promise.type != choice ||
        promises.length != 48 ||
        promises.map((p) => p.clubId).toSet().length != 48 ||
        promises.map((p) => p.id).toSet().length != 48 ||
        promises.any((p) => p.seasonIndex != opening.targetSeasonIndex) ||
        !identical(
          captured.promise,
          promises.singleWhere((p) => p.clubId == opening.controlledClubId),
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
