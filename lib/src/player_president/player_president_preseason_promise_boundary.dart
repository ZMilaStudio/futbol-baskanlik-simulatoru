import '../league/club.dart';
import '../player/team_strength_calculator.dart';
import '../promise/player_president_promise_control.dart';
import '../promise/president_promise.dart';
import '../promise/promise_generator.dart';
import '../promise/promise_opening_context_builder.dart';
import '../season/integrated_new_game_opening_proof.dart';
import '../world/world_league.dart';
import '../world/world_opening_state_initializer.dart';
import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_session.dart';

enum PlayerPresidentPreseasonPromisePhase { unstarted, pending, applied }

/// A runtime-only, candidate-first preseason promise boundary. It owns neither
/// a career state nor persistence; publication occurs once after every promise
/// and the real M56 consequence have been successfully constructed.
class PlayerPresidentPreseasonPromiseBoundary {
  PlayerPresidentPreseasonPromiseBoundary._({
    required this.application,
    required this.proof,
    required this.contexts,
    required this.controlledPresidentId,
  });

  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final IntegratedNewGameOpeningProof proof;
  final List<PlayerPromiseDecisionContext> contexts;
  final String controlledPresidentId;
  PlayerPresidentPreseasonPromisePhase _phase =
      PlayerPresidentPreseasonPromisePhase.unstarted;
  PlayerPresidentPreseasonPromisePending? _pending;
  PlayerPresidentPreseasonPromiseApplied? _applied;

  PlayerPresidentPreseasonPromisePhase get phase => _phase;
  PlayerPresidentPreseasonPromisePending? get pending => _pending;
  PlayerPresidentPreseasonPromiseApplied? get applied => _applied;

  factory PlayerPresidentPreseasonPromiseBoundary.start({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
  }) {
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
      seasonIndex: 0,
      effectiveClubs: effective,
      leagues: opening.leagues,
      openingFinanceStates: opening.financeStates,
    );
    if (openingContexts.length != 48 ||
        openingContexts.map((c) => c.clubId).toSet().length != 48) {
      throw StateError('Preseason promise context must cover 48 clubs once.');
    }
    final controlled = openingContexts.singleWhere(
      (context) => context.clubId == bootstrap.controlledClubId,
    );
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
    final boundary = PlayerPresidentPreseasonPromiseBoundary._(
      application: application,
      proof: proof,
      contexts: List.unmodifiable(contexts),
      controlledPresidentId: proof.presidentOpening.controlledPresidentId!,
    );
    boundary._pending = PlayerPresidentPreseasonPromisePending._(
      boundary: boundary,
      context: contexts.singleWhere(
        (item) => item.context.clubId == controlled.clubId,
      ),
    );
    boundary._phase = PlayerPresidentPreseasonPromisePhase.pending;
    application.reservePreseasonPromisePhase();
    return boundary;
  }

  PlayerPresidentPreseasonPromiseApplied submit({
    required PlayerPresidentPreseasonPromisePending pending,
    required PresidentPromiseType choice,
  }) {
    final current = _pending;
    if (_phase != PlayerPresidentPreseasonPromisePhase.pending ||
        current == null ||
        !identical(current, pending)) {
      throw StateError(
        'Preseason promise submission must use the exact Pending.',
      );
    }
    final context = current.context;
    if (!context.allowedTypes.contains(choice)) {
      throw ArgumentError.value(
        choice,
        'choice',
        'Promise type is not allowed.',
      );
    }
    final capture = _CaptureProvider(choice);
    final promises = <PresidentPromise>[];
    for (final item in contexts) {
      final controlled = item.context.clubId == context.controlledClubId;
      final generator = controlled
          ? PlayerPresidentPromiseGenerator(
              controlledClubId: context.controlledClubId,
              decisionProvider: capture,
            )
          : const PromiseGenerator();
      final candidate = generator.generate(
        context: item.context,
        careerSeed: proof.seasonOpening.config.careerSeed,
        simulationVersion: proof.seasonOpening.config.simulationVersion,
      );
      if (!controlled && candidate.signature != item.aiPromise.signature) {
        throw StateError('AI promise candidate parity failed.');
      }
      promises.add(candidate);
    }
    final consequence = capture.consequence;
    if (consequence == null ||
        capture.applicationCount != 1 ||
        consequence.context.signature != context.signature ||
        consequence.promise.type != choice ||
        consequence.promise.clubId != context.controlledClubId ||
        consequence.promise.signature !=
            promises
                .singleWhere((item) => item.clubId == context.controlledClubId)
                .signature ||
        promises.length != 48 ||
        promises.map((p) => p.clubId).toSet().length != 48) {
      throw StateError('Preseason candidate publication validation failed.');
    }
    final result = PlayerPresidentPreseasonPromiseApplied._(
      sourceIdentity: proof.seasonOpening.originSourceDigest,
      seasonIndex: 0,
      controlledClubId: context.controlledClubId,
      controlledPresidentId: controlledPresidentId,
      acceptedRequestKey: current.requestKey,
      acceptedChoice: choice,
      consequence: consequence,
      activePromises: promises,
    );
    _applied = result;
    _pending = null;
    _phase = PlayerPresidentPreseasonPromisePhase.applied;
    return result;
  }
}

class PlayerPresidentPreseasonPromisePending {
  PlayerPresidentPreseasonPromisePending._({
    required this.boundary,
    required this.context,
  });
  final PlayerPresidentPreseasonPromiseBoundary boundary;
  final PlayerPromiseDecisionContext context;
  String get phase => 'preseasonPromise';
  int get sequence => 1;
  String get kind => 'promise';
  String get sourceIdentity => boundary.proof.seasonOpening.originSourceDigest;
  String get clubId => context.controlledClubId;
  String get contextSignature => context.signature;
  String get requestKey =>
      'preseason-promise/v1:$sourceIdentity:$sequence:$kind:$clubId:$contextSignature';
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

class _CaptureProvider extends PlayerPromiseDecisionProvider {
  _CaptureProvider(this.choice);
  final PresidentPromiseType choice;
  PlayerPresidentPromiseConsequence? consequence;
  int applicationCount = 0;
  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      choice;
  @override
  void onApplied(
    PlayerPromiseDecisionContext context,
    PresidentPromise promise,
  ) {
    applicationCount += 1;
    consequence = PlayerPresidentPromiseConsequence(
      context: context,
      promise: promise,
    );
  }
}
