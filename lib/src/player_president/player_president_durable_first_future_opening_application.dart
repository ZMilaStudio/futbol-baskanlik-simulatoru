part of 'player_president_interactive_decision_application_session.dart';

/// A genuine producer's immutable capture. This is not a runtime capability.
final class OwnedFirstFutureOpeningCapture {
  OwnedFirstFutureOpeningCapture._({
    required this.world,
    required this.tenureControl,
    required Iterable<Manager> managers,
    required Iterable<ManagerAssignment> assignments,
    required this.transfers,
    required this.facilities,
    required Iterable<PresidentClubRuntimeState> presidentClubs,
    required this.electionInterval,
    required Map<String, List<int>> termPromiseScores,
    required this.careerInstanceId,
    required this.decisionId,
    required this.contextSignature,
    required this.preparedOpeningDigest,
  })  : managers = List.unmodifiable(managers),
        assignments = List.unmodifiable(assignments),
        presidentClubs = List.unmodifiable(presidentClubs),
        termPromiseScores = Map.unmodifiable({
          for (final e in termPromiseScores.entries)
            e.key: List<int>.unmodifiable(e.value)
        });
  final WorldCheckpoint world;
  final PlayerPresidentTenureControlState tenureControl;
  final List<Manager> managers;
  final List<ManagerAssignment> assignments;
  final AdvancedTransferRuntimeState transfers;
  final FacilityPortfolioRuntimeState facilities;
  final List<PresidentClubRuntimeState> presidentClubs;
  final int electionInterval;
  final Map<String, List<int>> termPromiseScores;
  final String careerInstanceId,
      decisionId,
      contextSignature,
      preparedOpeningDigest;
  String get origin => 'historicalBasicX1ToFirstFuture';
  String get phase => 'firstFuturePromisePending';
  String get runtimeProfile => 'canonicalFirstFutureV1';
}

/// Only a detached restore candidate can mint this one-use preparation claim.
final class DurableFirstFuturePreparationClaim {
  DurableFirstFuturePreparationClaim._(this._application);
  final PlayerPresidentDurableFirstFutureOpeningApplication _application;
  bool _claimed = false, _pendingCreated = false;
  M65OwnedFirstFutureOpeningState get state => _application._state;
  Object get owner => _application;
  Object get revision => _application._revision;
  void claimPreparation() {
    if (!_application._preparing || _claimed || _application._disposed) {
      throw StateError('Foreign or consumed durable preparation.');
    }
    _claimed = true;
  }

  void validatePendingContext(PlayerPromiseDecisionContext context) {
    if (!_application._preparing ||
        !_claimed ||
        _pendingCreated ||
        !identical(context, _application._context) ||
        context.controlledClubId != state.tenureControl.controlledClubId ||
        context.seasonIndex != 1) {
      throw StateError('Foreign durable promise preparation.');
    }
    _pendingCreated = true;
  }
}

/// Closed, exact-live-owner proof for the shared genuine M73/M56 kernel.
final class DurableFuturePromiseAcceptanceClaim {
  DurableFuturePromiseAcceptanceClaim._(this._application, this._expected);
  final PlayerPresidentDurableFirstFutureOpeningApplication _application;
  final DurableFirstFuturePromisePending _expected;
  String get controlledClubId => _application.clubId;
  List<PresidentPromiseContext> get promiseContexts => _application._contexts;
  SimulationConfig get config => _application._prepared.opening.config;
  PlayerPromiseDecisionContext get controlledPromiseContext =>
      _application._context;
  void validate(
      {required PlayerPresidentInteractiveDecisionPending pending,
      required PlayerPresidentInteractiveDecisionRequest request}) {
    _application._requireCurrent(_expected);
    if (!identical(pending, _application._pending) ||
        !identical(request, pending.request) ||
        !identical(request.context, controlledPromiseContext) ||
        request.kind != PlayerPresidentInteractiveDecisionKind.promise ||
        request.sequence != 1 ||
        request.phase != 'preseasonPromise' ||
        request.clubId != controlledClubId ||
        request.contextSignature != controlledPromiseContext.signature) {
      throw StateError('Foreign or stale durable promise Pending.');
    }
  }
}

sealed class PlayerPresidentDurableFirstFutureOpeningStep {
  const PlayerPresidentDurableFirstFutureOpeningStep._();
}

final class DurableFirstFuturePromisePending
    extends PlayerPresidentDurableFirstFutureOpeningStep {
  const DurableFirstFuturePromisePending._(
      {required this.careerInstanceId,
      required this.clubId,
      required this.playerPresidentId,
      required this.decisionId,
      required this.context})
      : super._();
  final String careerInstanceId, clubId, playerPresidentId, decisionId;
  final PlayerPromiseDecisionContext context;
  int get seasonIndex => 1;
}

final class DurableFirstFuturePromiseResolved
    extends PlayerPresidentDurableFirstFutureOpeningStep {
  DurableFirstFuturePromiseResolved._(
      this.consequence, Iterable<PresidentPromise> promises)
      : activePromises = List.unmodifiable(promises),
        super._();
  final PlayerPresidentPromiseConsequence consequence;
  final List<PresidentPromise> activePromises;
}

final class DurableFirstFutureW0
    extends PlayerPresidentDurableFirstFutureOpeningStep {
  DurableFirstFutureW0._(this.fixtureSnapshot, this.activePromises) : super._();
  final WeeklyWorldFixtureSnapshot fixtureSnapshot;
  WeeklyWorldFixtureSnapshot get fixtures => fixtureSnapshot;
  final List<PresidentPromise> activePromises;
}

final class DurableFirstFutureW1
    extends PlayerPresidentDurableFirstFutureOpeningStep {
  DurableFirstFutureW1._(this.fixtureSnapshot, this.activePromises) : super._();
  final WeeklyWorldFixtureSnapshot fixtureSnapshot;
  WeeklyWorldFixtureSnapshot get fixtures => fixtureSnapshot;
  final List<PresidentPromise> activePromises;
}

/// First-slice process-local owner. Only the unanswered opening can be saved.
/// G1a: callers provide isolated single-writer/sequential-owner operation;
/// this facade does not establish a global lease or anti-fork policy.
final class PlayerPresidentDurableFirstFutureOpeningApplication {
  PlayerPresidentDurableFirstFutureOpeningApplication._(this._state);
  final M65OwnedFirstFutureOpeningState _state;
  final Object _revision = Object();
  bool _preparing = true, _disposed = false;
  late final DurablePreparedFirstFutureOpening _prepared;
  late final WeeklyWorldFixtureSnapshot _w0;
  late final List<PresidentPromiseContext> _contexts;
  late final PlayerPromiseDecisionContext _context;
  late final PlayerPresidentInteractiveDecisionPending _pending;
  late final Map<String, Object?> _projection;
  late PlayerPresidentDurableFirstFutureOpeningStep _step;
  List<PresidentPromise> _acceptedPromises = const [];

  factory PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
      String encoded) {
    final candidate = _prepareEncoded(encoded);
    candidate._preparing = false;
    return candidate;
  }

  // Store validation uses the same detached preparation without publishing a
  // command-capable owner alongside the genuine producer still being saved.
  static void _validateEncodedOnly(String encoded) {
    final candidate = _prepareEncoded(encoded);
    candidate.dispose();
  }

  static PlayerPresidentDurableFirstFutureOpeningApplication _prepareEncoded(
      String encoded) {
    final state = const PlayerPresidentTicketPricingRuntimeSaveCodec()
        .decodeOwnedOpening(encoded);
    final candidate =
        PlayerPresidentDurableFirstFutureOpeningApplication._(state);
    try {
      state.validate();
      final claim = DurableFirstFuturePreparationClaim._(candidate);
      candidate._prepared =
          const WorldCareerEngine().prepareDurableFirstFutureOpening(claim);
      final world = candidate._prepared.opening;
      candidate._w0 = const WeeklyWorldFixtureResultCore().prepare(
          clubs: world.effectiveClubs,
          leagues: world.leagues,
          config: world.config.copyWith(seasonIndex: 1));
      candidate._contexts = List.unmodifiable(
          const PromiseOpeningContextBuilder().build(
              seasonIndex: 1,
              effectiveClubs: world.effectiveClubs,
              leagues: world.leagues,
              openingFinanceStates: world.financeStates));
      final controlled =
          candidate._contexts.singleWhere((c) => c.clubId == candidate.clubId);
      candidate._context = PlayerPromiseDecisionContext(
          context: controlled,
          aiPromise: const PromiseGenerator().generate(
              context: controlled,
              careerSeed: world.config.careerSeed,
              simulationVersion: world.config.simulationVersion),
          allowedTypes:
              PlayerPresidentPromiseGenerator.allowedPromiseTypes(controlled));
      candidate._projection = _durablePreparedProjection(
          world,
          candidate._prepared.managerAuthority,
          candidate._contexts,
          candidate._context,
          candidate._w0);
      if (candidate._context.signature != state.contextSignature ||
          _durableSha(candidate._projection) != state.preparedOpeningDigest ||
          _durableDecisionId(state.careerInstanceId, state.tenureControl,
                  candidate._context.signature) !=
              state.decisionId) {
        throw const SaveLoadException(SaveLoadFailure.invalidPayload,
            'Durable preparation witness mismatch.');
      }
      candidate._pending =
          PlayerPresidentInteractiveDecisionRequest.durableFuturePromisePending(
              claim: claim, context: candidate._context);
      candidate._step = DurableFirstFuturePromisePending._(
          careerInstanceId: candidate.careerInstanceId,
          clubId: candidate.clubId,
          playerPresidentId: candidate.playerPresidentId,
          decisionId: state.decisionId,
          context: candidate._context);
      return candidate;
    } on SaveLoadException {
      candidate._disposed = true;
      rethrow;
    } catch (_) {
      candidate._disposed = true;
      throw const SaveLoadException(SaveLoadFailure.invalidPayload,
          'Durable first-future preparation failed.');
    }
  }

  String get careerInstanceId => _state.careerInstanceId;
  String get clubId => _state.tenureControl.controlledClubId;
  String get playerPresidentId => _state.tenureControl.playerPresidentId;
  PlayerPresidentDurableFirstFutureOpeningStep get currentStep => _step;
  Map<String, Object?> get openingObservation =>
      _immutableObservation(_projection, _acceptedPromises);

  void _requireCurrent(PlayerPresidentDurableFirstFutureOpeningStep expected) {
    if (_disposed || _preparing || !identical(_step, expected)) {
      throw StateError('Foreign, stale or disposed durable step.');
    }
  }

  DurableFirstFuturePromiseResolved submitPromise(
      {required DurableFirstFuturePromisePending expectedPending,
      required PresidentPromiseType choice}) {
    _requireCurrent(expectedPending);
    final acceptance = PlayerPresidentFuturePromiseAcceptance.acceptDurable(
        claim: DurableFuturePromiseAcceptanceClaim._(this, expectedPending),
        pending: _pending,
        request: _pending.request,
        choice: choice);
    final candidate = DurableFirstFuturePromiseResolved._(
        acceptance.consequence, acceptance.activePromises);
    _acceptedPromises = candidate.activePromises;
    _step = candidate;
    return candidate;
  }

  DurableFirstFutureW0 continueAfterPromise(
      {required DurableFirstFuturePromiseResolved expectedResolution}) {
    _requireCurrent(expectedResolution);
    final candidate = DurableFirstFutureW0._(_w0, _acceptedPromises);
    _step = candidate;
    return candidate;
  }

  DurableFirstFutureW1 advanceFirstRound(
      {required DurableFirstFutureW0 expectedW0}) {
    _requireCurrent(expectedW0);
    final snapshot = const WeeklyWorldFixtureResultCore().advanceRound(
        snapshot: expectedW0.fixtureSnapshot,
        expectedRound: 1,
        effectiveClubs: _prepared.opening.effectiveClubs);
    if (snapshot.nextRound != 2 ||
        snapshot.completedMatchCount != 24 ||
        snapshot.fixtures.length != 720) {
      throw StateError('Invalid genuine first-round result.');
    }
    final candidate = DurableFirstFutureW1._(snapshot, _acceptedPromises);
    _step = candidate;
    return candidate;
  }

  String encodeCurrentOpening() {
    if (_disposed || _preparing || _step is! DurableFirstFuturePromisePending) {
      throw StateError(
          'Only the unanswered first-future opening can be saved.');
    }
    return const PlayerPresidentTicketPricingRuntimeSaveCodec()
        .encodeOwnedOpening(_state);
  }

  void dispose() => _disposed = true;
}

String _durableSha(Object? value) =>
    sha256.convert(utf8.encode(SaveChecksum.canonicalJson(value))).toString();
String _durableDecisionId(String careerId,
        PlayerPresidentTenureControlState control, String signature) =>
    _durableSha({
      'careerInstanceId': careerId,
      'clubId': control.controlledClubId,
      'playerPresidentId': control.playerPresidentId,
      'seasonIndex': 1,
      'phase': 'firstFuturePromisePending',
      'kind': 'promise',
      'contextSignature': signature
    });
Map<String, Object?> _promiseFacts(PresidentPromise promise) => {
      'id': promise.id,
      'clubId': promise.clubId,
      'seasonIndex': promise.seasonIndex,
      'type': promise.type.name,
      'targetLeaguePosition': promise.targetLeaguePosition,
      'targetDebtReductionBps': promise.targetDebtReductionBps,
    };
Map<String, Object?> _promiseContextFacts(PresidentPromiseContext context) => {
      'clubId': context.clubId,
      'seasonIndex': context.seasonIndex,
      'tier': context.tier.level,
      'leagueSize': context.leagueSize,
      'expectedPosition': context.expectedPosition,
      'openingCashMinorUnits': context.openingCash.minorUnits,
      'openingDebtMinorUnits': context.openingDebt.minorUnits,
    };
Map<String, Object?> _durablePreparedProjection(
    PreparedWorldOpening world,
    ManagerSeasonAuthority manager,
    List<PresidentPromiseContext> contexts,
    PlayerPromiseDecisionContext controlled,
    WeeklyWorldFixtureSnapshot w0) {
  if (!manager.isCanonicalFirstFuturePreparation ||
      contexts.length != 48 ||
      contexts.map((c) => c.clubId).toSet().length != 48 ||
      w0.seasonIndex != 1 ||
      w0.nextRound != 1 ||
      w0.totalRounds != 30 ||
      w0.completedMatchCount != 0 ||
      w0.fixtures.length != 720) {
    throw StateError('Unsupported first-future preparation.');
  }
  final config = world.config.copyWith(seasonIndex: 1);
  return _freezeMap({
    'runtimeProfile': 'canonicalFirstFutureV1',
    'executionConfig': {
      'careerSeed': config.careerSeed,
      'simulationVersion': config.simulationVersion,
      'seasonIndex': config.seasonIndex,
      'homeAdvantageRating': config.homeAdvantageRating,
      'baseHomeGoals': config.baseHomeGoals,
      'baseAwayGoals': config.baseAwayGoals,
      'ratingScale': config.ratingScale,
      'minExpectedGoals': config.minExpectedGoals,
      'maxExpectedGoals': config.maxExpectedGoals
    },
    'squadClubs': [
      for (final c in world.squadClubs)
        {'id': c.id, 'name': c.name, 'strength': c.strength}
    ],
    'effectiveClubs': [
      for (final c in world.effectiveClubs)
        {'id': c.id, 'name': c.name, 'strength': c.strength}
    ],
    'managerSetup': [for (final m in manager.preparationSnapshot) m.toJson()],
    'promiseContexts': [for (final c in contexts) _promiseContextFacts(c)],
    'controlledPromise': {
      'context': _promiseContextFacts(controlled.context),
      'aiPromise': _promiseFacts(controlled.aiPromise),
      'allowedTypes': [for (final type in controlled.allowedTypes) type.name]
    },
    'w0': {
      'seasonIndex': w0.seasonIndex,
      'nextRound': w0.nextRound,
      'totalRounds': w0.totalRounds,
      'completedMatchCount': w0.completedMatchCount,
      'fixtures': [
        for (final entry in w0.fixtures)
          {
            'tier': entry.tier.level,
            'id': entry.fixture.id,
            'seasonIndex': entry.fixture.seasonIndex,
            'round': entry.fixture.round,
            'homeClubId': entry.fixture.homeClubId,
            'awayClubId': entry.fixture.awayClubId,
            'result': null
          }
      ],
      'tables': {
        for (final entry in w0.tables.entries)
          '${entry.key.level}': [for (final row in entry.value) row.toJson()]
      }
    },
  });
}

Map<String, Object?> _immutableObservation(
        Map<String, Object?> prepared, List<PresidentPromise> promises) =>
    _freezeMap({
      'prepared': prepared,
      'acceptedPromises': [
        for (final promise in promises) _promiseFacts(promise)
      ]
    });
Map<String, Object?> _freezeMap(Map<String, Object?> map) => Map.unmodifiable({
      for (final entry in map.entries) entry.key: _freezeValue(entry.value),
    });
Object? _freezeValue(Object? value) {
  if (value is Map<String, Object?>) return _freezeMap(value);
  if (value is List) return List<Object?>.unmodifiable(value.map(_freezeValue));
  return value;
}
