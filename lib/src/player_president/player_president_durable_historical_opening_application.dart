part of 'player_president_interactive_decision_application_session.dart';

/// Minted only after the trusted M76 wrapper has obtained the real boundary.
/// Retention itself is callback-free and does not change existing startup gates.
final class _HistoricalOpeningProducerProvenance {
  _HistoricalOpeningProducerProvenance._(this.application, this.boundary)
      : proof = boundary.proof;
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentPreseasonPromiseBoundary boundary;
  final IntegratedNewGameOpeningProof proof;
}

/// Immutable genuine capture values, never process-local execution rights.
final class OwnedHistoricalOpeningCapture {
  OwnedHistoricalOpeningCapture._({
    required Iterable<Club> sourceClubs,
    required Iterable<WorldLeague> sourceLeagues,
    required this.config,
    required this.controlledClubId,
    required this.expectedPlayerPresidentId,
    required this.electionInterval,
    required this.careerInstanceId,
    required this.decisionId,
    required this.contextSignature,
    required this.preparedOpeningDigest,
  })  : sourceClubs = List.unmodifiable(sourceClubs),
        sourceLeagues = List.unmodifiable(sourceLeagues);
  final List<Club> sourceClubs;
  final List<WorldLeague> sourceLeagues;
  final SimulationConfig config;
  final String controlledClubId, expectedPlayerPresidentId, careerInstanceId;
  final String decisionId, contextSignature, preparedOpeningDigest;
  final int electionInterval;
  String get origin => 'historicalBasicX1';
  String get phase => 'historicalPromisePending';
  String get runtimeProfile => 'canonicalHistoricalOpeningV1';
}

void _requireHistoricalProducer(
    PlayerPresidentInteractiveDecisionApplicationSession application,
    PlayerPresidentPreseasonPromiseBoundary boundary) {
  final record = application._historicalOpeningProducerProvenance;
  final resume = application.resumeConfig;
  if (record == null ||
      !application._canonicalOwnedProducer ||
      !identical(record.application, application) ||
      !identical(record.boundary, boundary) ||
      !identical(record.proof, boundary.proof) ||
      !identical(application._preseasonPromiseBoundary, boundary) ||
      !identical(boundary.application, application) ||
      application._ownedInitialSourceClubs == null ||
      application._ownedInitialSourceLeagues == null ||
      !application.isNewGame ||
      application._checkpoint != null ||
      application._session.pendingDecision != null ||
      application._session.answeredDecisionCount != 0 ||
      application._session.completed != null ||
      application._committedSeasonResultCandidate != null ||
      application._acceptedPromiseClosingCandidate != null ||
      application._postseasonToken != null ||
      application._activeFutureSeasonOpening != null ||
      application._futureRuntimeEntry != null ||
      boundary.proof.seasonIndex != 0 ||
      boundary.proof.controlledClubId != application._newGameControlledClubId ||
      boundary.controlledPresidentId !=
          boundary.proof.presidentOpening.controlledPresidentId ||
      resume.seasonCount != 1 ||
      !resume.hasFutureSeasonAfterReport ||
      resume.crisisActivationThreshold != 55 ||
      resume.candidateLimit != 5) {
    throw StateError('Unsupported or foreign historical opening producer.');
  }
  boundary.proof.seasonOpening.assertOpeningProjectionMatches(boundary.opening);
}

OwnedHistoricalOpeningCapture _captureOwnedHistoricalOpening(
    PlayerPresidentInteractiveDecisionApplicationSession application,
    PlayerPresidentPreseasonPromiseBoundary boundary,
    PlayerPresidentPreseasonPromisePending pending) {
  _requireHistoricalProducer(application, boundary);
  if (boundary.phase != PlayerPresidentPreseasonPromisePhase.pending ||
      boundary.applied != null ||
      !identical(boundary.pending, pending) ||
      !identical(pending.boundary, boundary) ||
      application._preseasonWeeklyState != null ||
      pending.request.kind != PlayerPresidentInteractiveDecisionKind.promise ||
      pending.request.sequence != 1 ||
      pending.request.phase != 'preseasonPromise' ||
      pending.clubId != boundary.proof.controlledClubId ||
      !identical(
          pending.request.context,
          boundary.contexts.singleWhere(
              (c) => c.controlledClubId == boundary.proof.controlledClubId))) {
    throw StateError(
        'Only the real unanswered historical Pending can be captured.');
  }
  final clubs = application._ownedInitialSourceClubs!;
  final leagues = application._ownedInitialSourceLeagues!;
  final config = boundary.proof.seasonOpening.config;
  // The original owner is reserved. Existing verification requires a distinct
  // PRISTINE source; do not bypass its M80 getter guard on the reserved owner.
  final comparison = _newHistoricalApplication(
      clubs,
      leagues,
      config,
      boundary.proof.controlledClubId,
      boundary.proof.presidentOpening.electionInterval);
  boundary.proof.verifyNewGame(
      application: comparison, sourceClubs: clubs, sourceLeagues: leagues);
  final projection = _historicalPreparedProjection(application, boundary);
  final careerId = application._ownedCareerInstanceId ??
      (() {
        final random = Random.secure();
        return List.generate(16,
                (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
            .join();
      })();
  final capture = OwnedHistoricalOpeningCapture._(
      sourceClubs: clubs,
      sourceLeagues: leagues,
      config: config,
      controlledClubId: boundary.proof.controlledClubId,
      expectedPlayerPresidentId: boundary.controlledPresidentId,
      electionInterval: boundary.proof.presidentOpening.electionInterval,
      careerInstanceId: careerId,
      contextSignature: pending.contextSignature,
      decisionId: _historicalDecisionId(
          careerId,
          boundary.proof.controlledClubId,
          boundary.controlledPresidentId,
          pending.contextSignature),
      preparedOpeningDigest: _durableSha(projection));
  M65OwnedHistoricalOpeningState.fromGenuineCapture(capture).validate();
  application._ownedCareerInstanceId = careerId;
  return capture;
}

Map<String, Object?> _observeOwnedHistoricalOpening(
    PlayerPresidentInteractiveDecisionApplicationSession application) {
  final boundary = application._preseasonPromiseBoundary;
  if (boundary == null) throw StateError('No historical opening is owned.');
  _requireHistoricalProducer(application, boundary);
  return _immutableObservation(
      _historicalPreparedProjection(application, boundary),
      boundary.applied?.activePromises ?? const []);
}

PlayerPresidentInteractiveDecisionApplicationSession _newHistoricalApplication(
        List<Club> clubs,
        List<WorldLeague> leagues,
        SimulationConfig config,
        String controlledClubId,
        int electionInterval) =>
    PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: clubs,
        leagues: leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: electionInterval,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 55,
        candidateLimit: 5);

String _historicalDecisionId(String careerId, String clubId,
        String playerPresidentId, String contextSignature) =>
    _durableSha({
      'careerInstanceId': careerId,
      'clubId': clubId,
      'playerPresidentId': playerPresidentId,
      'seasonIndex': 0,
      'phase': 'historicalPromisePending',
      'kind': 'promise',
      'contextSignature': contextSignature,
    });

sealed class PlayerPresidentDurableHistoricalOpeningStep {
  const PlayerPresidentDurableHistoricalOpeningStep._();
}

final class DurableHistoricalPromisePending
    extends PlayerPresidentDurableHistoricalOpeningStep {
  const DurableHistoricalPromisePending._(
      {required this.careerInstanceId,
      required this.clubId,
      required this.playerPresidentId,
      required this.decisionId,
      required this.context})
      : super._();
  final String careerInstanceId, clubId, playerPresidentId, decisionId;
  final PlayerPromiseDecisionContext context;
  int get seasonIndex => 0;
}

final class DurableHistoricalPromiseResolved
    extends PlayerPresidentDurableHistoricalOpeningStep {
  DurableHistoricalPromiseResolved._(
      this.consequence, Iterable<PresidentPromise> promises)
      : activePromises = List.unmodifiable(promises),
        super._();
  final PlayerPresidentPromiseConsequence consequence;
  final List<PresidentPromise> activePromises;
}

final class DurableHistoricalW0
    extends PlayerPresidentDurableHistoricalOpeningStep {
  DurableHistoricalW0._(this.fixtures, this.activePromises) : super._();
  final WeeklyWorldFixtureSnapshot fixtures;
  final List<PresidentPromise> activePromises;
}

final class DurableHistoricalW1
    extends PlayerPresidentDurableHistoricalOpeningStep {
  DurableHistoricalW1._(this.fixtures, this.activePromises) : super._();
  final WeeklyWorldFixtureSnapshot fixtures;
  final List<PresidentPromise> activePromises;
}

final class _PreparedHistoricalOpening {
  _PreparedHistoricalOpening(this.application, this.boundary, this.projection);
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentPreseasonPromiseBoundary boundary;
  final Map<String, Object?> projection;
}

/// Restores one pristine M65 historical opening into a new private genuine
/// runtime. The public surface deliberately stops after W1; only Pending saves.
final class PlayerPresidentDurableHistoricalOpeningApplication {
  PlayerPresidentDurableHistoricalOpeningApplication._(
      this._state, this._prepared) {
    final pending = _prepared.boundary.pending!;
    _step = DurableHistoricalPromisePending._(
        careerInstanceId: careerInstanceId,
        clubId: controlledClubId,
        playerPresidentId: playerPresidentId,
        decisionId: _state.decisionId,
        context: pending.context);
  }
  final M65OwnedHistoricalOpeningState _state;
  final _PreparedHistoricalOpening _prepared;
  bool _disposed = false;
  late PlayerPresidentDurableHistoricalOpeningStep _step;
  PlayerPresidentPreseasonWeeklyState? _weekly;
  List<PresidentPromise> _accepted = const [];

  factory PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
      String encoded) {
    final state = const PlayerPresidentTicketPricingRuntimeSaveCodec()
        .decodeHistoricalOpening(encoded);
    final prepared = _prepareHistoricalState(state);
    final result =
        PlayerPresidentDurableHistoricalOpeningApplication._(state, prepared);
    // No fallible producer work follows this fresh, private identity binding.
    prepared.application._ownedCareerInstanceId = state.careerInstanceId;
    return result;
  }
  static void _validateEncodedOnly(String encoded) {
    final state = const PlayerPresidentTicketPricingRuntimeSaveCodec()
        .decodeHistoricalOpening(encoded);
    _prepareHistoricalState(state); // No nonce mint/bind, no public facade.
  }

  String get careerInstanceId => _state.careerInstanceId;
  String get controlledClubId => _state.controlledClubId;
  String get playerPresidentId => _state.expectedPlayerPresidentId;
  int get seasonIndex => 0;
  bool get historicalManagerAuthorityAvailable => false;
  PlayerPresidentDurableHistoricalOpeningStep get currentStep => _step;
  Map<String, Object?> get openingObservation =>
      _immutableObservation(_prepared.projection, _accepted);
  void _requireCurrent(PlayerPresidentDurableHistoricalOpeningStep expected) {
    if (_disposed || !identical(expected, _step))
      throw StateError('Foreign, stale or disposed historical step.');
  }

  DurableHistoricalPromiseResolved submitPromise(
      {required DurableHistoricalPromisePending expectedPending,
      required PresidentPromiseType choice}) {
    _requireCurrent(expectedPending);
    final boundary = _prepared.boundary;
    final applied = boundary.submit(pending: boundary.pending!, choice: choice);
    final result = DurableHistoricalPromiseResolved._(
        applied.consequence, applied.activePromises);
    _accepted = result.activePromises;
    _step = result;
    return result;
  }

  DurableHistoricalW0 continueAfterPromise(
      {required DurableHistoricalPromiseResolved expectedResolution}) {
    _requireCurrent(expectedResolution);
    final weekly = _prepared.application.openPreseasonWeeklyHandoff();
    final result = DurableHistoricalW0._(weekly.fixtureSnapshot, _accepted);
    _weekly = weekly;
    _step = result;
    return result;
  }

  DurableHistoricalW1 advanceFirstRound(
      {required DurableHistoricalW0 expectedW0}) {
    _requireCurrent(expectedW0);
    final weekly = _prepared.application
        .advancePreseasonWeek(expectedState: _weekly!, expectedRound: 1);
    final result = DurableHistoricalW1._(weekly.fixtureSnapshot, _accepted);
    _weekly = weekly;
    _step = result;
    return result;
  }

  String encodeCurrentOpening() {
    if (_disposed || _step is! DurableHistoricalPromisePending)
      throw StateError('Only an unanswered historical opening can be saved.');
    return const PlayerPresidentTicketPricingRuntimeSaveCodec()
        .encodeHistoricalOpening(_state);
  }

  void dispose() => _disposed = true;
}

_PreparedHistoricalOpening _prepareHistoricalState(
    M65OwnedHistoricalOpeningState state) {
  try {
    state.validate();
    final application = _newHistoricalApplication(
        state.sourceClubs,
        state.sourceLeagues,
        state.config,
        state.controlledClubId,
        state.electionInterval);
    final boundary = application.startPreseasonPromise(
        sourceClubs: state.sourceClubs, sourceLeagues: state.sourceLeagues);
    _requireHistoricalProducer(application, boundary);
    final projection = _historicalPreparedProjection(application, boundary);
    if (boundary.controlledPresidentId != state.expectedPlayerPresidentId ||
        boundary.pending!.contextSignature != state.contextSignature ||
        _durableSha(projection) != state.preparedOpeningDigest ||
        _historicalDecisionId(state.careerInstanceId, state.controlledClubId,
                state.expectedPlayerPresidentId, state.contextSignature) !=
            state.decisionId) {
      throw const SaveLoadException(SaveLoadFailure.invalidPayload,
          'Historical opening witness mismatch.');
    }
    return _PreparedHistoricalOpening(application, boundary, projection);
  } on SaveLoadException {
    rethrow;
  } catch (_) {
    throw const SaveLoadException(SaveLoadFailure.invalidPayload,
        'Historical opening preparation failed.');
  }
}

Map<String, Object?> _historicalPreparedProjection(
    PlayerPresidentInteractiveDecisionApplicationSession application,
    PlayerPresidentPreseasonPromiseBoundary boundary) {
  final proof = boundary.proof;
  final config = proof.seasonOpening.config;
  final world = boundary.opening;
  final presidency = proof.presidentOpening;
  final domain = proof.presidentDomainMemory;
  final summary = domain.summary;
  final w0 = proof.seasonOpening.fixtureSnapshot;
  final effective = const TeamStrengthCalculator()
      .deriveClubs(baseClubs: world.baseClubs, players: world.players);
  final sourceClubs = application._ownedInitialSourceClubs!;
  final sourceLeagues = application._ownedInitialSourceLeagues!;
  return _freezeMap({
    'runtimeProfile': 'canonicalHistoricalOpeningV1',
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
    'resumeProfile': {
      'seasonCount': application.resumeConfig.seasonCount,
      'hasFutureSeasonAfterReport':
          application.resumeConfig.hasFutureSeasonAfterReport,
      'crisisActivationThreshold':
          application.resumeConfig.crisisActivationThreshold,
      'candidateLimit': application.resumeConfig.candidateLimit
    },
    'controlledIdentity': {
      'clubId': proof.controlledClubId,
      'playerPresidentId': boundary.controlledPresidentId
    },
    'world': {
      'clubs': [
        for (final c in world.baseClubs)
          {'id': c.id, 'name': c.name, 'strength': c.strength}
      ],
      'leagues': [
        for (final l in world.leagues)
          {'tier': l.tier.level, 'clubIds': l.clubIds}
      ],
      'players': [
        for (final p in world.players)
          {
            'id': p.id,
            'name': p.name,
            'clubId': p.clubId,
            'position': p.position.name,
            'age': p.age,
            'ability': p.ability,
            'potential': p.potential,
            'retirementAge': p.retirementAge,
            'isAcademyGraduate': p.isAcademyGraduate
          }
      ],
      'finance': [
        for (final f in world.financeStates)
          {
            'clubId': f.clubId,
            'cashMinorUnits': f.cash.minorUnits,
            'debtMinorUnits': f.debt.minorUnits
          }
      ],
      'sourceOrderWitness': {
        'clubs': [
          for (final c in sourceClubs)
            {'id': c.id, 'name': c.name, 'strength': c.strength}
        ],
        'leagues': [
          for (final l in sourceLeagues)
            {'tierLevel': l.tier.level, 'leagueId': l.id, 'clubIds': l.clubIds}
        ]
      },
    },
    'effectiveClubs': [
      for (final c in effective)
        {'id': c.id, 'name': c.name, 'strength': c.strength}
    ],
    'initialContracts': {
      'activeContracts': [
        for (final c in proof.initialContracts.activeContracts)
          {
            'playerId': c.playerId,
            'clubId': c.clubId,
            'startSeasonIndex': c.startSeasonIndex,
            'endSeasonIndex': c.endSeasonIndex,
            'annualWageMinorUnits': c.annualWage.minorUnits
          }
      ],
      'initialEvents': [
        for (final e in proof.initialContracts.initialEvents)
          {
            'seasonIndex': e.seasonIndex,
            'playerId': e.playerId,
            'type': e.type.name,
            'fromClubId': e.fromClubId,
            'toClubId': e.toClubId,
            'annualWageMinorUnits': e.annualWage?.minorUnits,
            'endSeasonIndex': e.endSeasonIndex
          }
      ]
    },
    'presidency': {
      'seasonIndex': presidency.seasonIndex,
      'electionInterval': presidency.electionInterval,
      'completedElectionTerms': presidency.completedElectionTerms,
      'seasonsIntoCurrentTerm': presidency.seasonsIntoCurrentTerm,
      'clubs': [
        for (final c in presidency.clubs)
          {
            'clubId': c.clubId,
            'presidentId': c.president.id,
            'presidentName': c.president.name,
            'tenureNumber': c.tenure.tenureNumber,
            'startedSeasonIndex': c.tenure.startedSeasonIndex,
            'reelectionsWon': c.tenure.reelectionsWon,
            'archetype': c.managementProfile.archetype.name,
            'financialDiscipline': c.managementProfile.financialDiscipline,
            'riskAppetite': c.managementProfile.riskAppetite,
            'transferAmbition': c.managementProfile.transferAmbition,
            'youthOrientation': c.managementProfile.youthOrientation,
            'managerPatience': c.managementProfile.managerPatience,
            'fanSporting': c.fan.sportingTrust,
            'fanFinancial': c.fan.financialTrust,
            'fanTransfer': c.fan.transferTrust,
            'fanIdentity': c.fan.identityTrust,
            'mediaCredibility': c.media.credibility
          }
      ],
      'domainSummary': {
        'rawHistorySeasons': domain.rawHistorySeasons,
        'completedSeasons': domain.completedSeasons,
        'seasonIndex': domain.seasonIndex,
        'electionInterval': domain.electionInterval,
        'completedElectionTerms': domain.completedElectionTerms,
        'seasonsIntoCurrentTerm': domain.seasonsIntoCurrentTerm,
        'firstElectionSeasonIndex': domain.firstElectionSeasonIndex,
        'controlledClubId': domain.controlledClubId,
        'controlledPresidentId': domain.controlledPresidentId,
        'recentFan': domain.recentFan,
        'recentMedia': domain.recentMedia,
        'resolvedCurrentTermPromises': domain.resolvedCurrentTermPromises,
        'summary': {
          'fanSnapshots': summary.fanSnapshots,
          'fanReasons': summary.fanReasons,
          'mediaStatements': summary.mediaStatements,
          'mediaContradictions': summary.mediaContradictions,
          'promisesFulfilled': summary.promisesFulfilled,
          'promisesPartial': summary.promisesPartial,
          'promisesBroken': summary.promisesBroken,
          'totalPromises': summary.totalPromises
        }
      }
    },
    'promiseContexts': [
      for (final c in boundary.contexts)
        {
          'context': _promiseContextFacts(c.context),
          'aiPromise': _promiseFacts(c.aiPromise),
          'allowedTypes': [for (final type in c.allowedTypes) type.name]
        }
    ],
    'w0': {
      'seasonIndex': w0.seasonIndex,
      'nextRound': w0.nextRound,
      'totalRounds': w0.totalRounds,
      'completedMatchCount': w0.completedMatchCount,
      'fixtures': [
        for (final e in w0.fixtures)
          {
            'tier': e.tier.level,
            'id': e.fixture.id,
            'seasonIndex': e.fixture.seasonIndex,
            'round': e.fixture.round,
            'homeClubId': e.fixture.homeClubId,
            'awayClubId': e.fixture.awayClubId,
            'result': null
          }
      ],
      'tables': {
        for (final e in w0.tables.entries)
          '${e.key.level}': [for (final r in e.value) r.toJson()]
      }
    },
  });
}
