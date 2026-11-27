import 'dart:convert';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart'
    show SimulationConfig, PresidentPromiseType;

import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_historical_opening_persistence.dart';
import 'package:futbol_baskanlik_m0/player_president_durable_historical_opening_application.dart';
import 'package:test/test.dart';

import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart'
    show PlayerPresidentInteractiveDecisionApplicationSession;
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart'
    show FictionalWorldFactory;

import 'support/owned_career_driver.dart';
import 'support/owned_historical_opening_worker.dart' as worker;

// Open legacy interfaces are negative command inputs, not accepted authority.
class _BoundaryImpostor implements PlayerPresidentPreseasonPromiseBoundary {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Impostor getter executed');
}

class _PendingImpostor implements PlayerPresidentPreseasonPromisePending {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Impostor getter executed');
}

// Deliberately caller-implemented legacy interfaces. They are used only as
// rejected capture input; no gameplay command or restore consumes these values.
class _ClaimBoundary implements PlayerPresidentPreseasonPromiseBoundary {
  _ClaimBoundary(this.application, this.original);
  @override
  final PlayerPresidentInteractiveDecisionApplicationSession application;
  final PlayerPresidentPreseasonPromiseBoundary original;
  @override
  late final PlayerPresidentPreseasonPromisePending pending =
      _ClaimPending(this, original.pending!);
  @override
  get proof => original.proof;
  @override
  get opening => original.opening;
  @override
  get contexts => original.contexts;
  @override
  get controlledPresidentId => original.controlledPresidentId;
  @override
  get phase => PlayerPresidentPreseasonPromisePhase.pending;
  @override
  PlayerPresidentPreseasonPromiseApplied? get applied => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No forged command');
}

class _ClaimPending implements PlayerPresidentPreseasonPromisePending {
  _ClaimPending(this.boundary, this.original);
  @override
  final PlayerPresidentPreseasonPromiseBoundary boundary;
  final PlayerPresidentPreseasonPromisePending original;
  @override
  get request => original.request;
  @override
  get context => original.context;
  @override
  get phase => original.phase;
  @override
  get sequence => original.sequence;
  @override
  get kind => original.kind;
  @override
  get sourceIdentity => original.sourceIdentity;
  @override
  get clubId => original.clubId;
  @override
  get contextSignature => original.contextSignature;
  @override
  get requestKey => original.requestKey;
}

void main() {
  late String encoded;
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  setUpAll(() {
    encoded = worker.createHistoricalOpening();
  });

  test('genuine capture binds one nonce, stable identity and immutable roots',
      () {
    final original = worker.createHistoricalOpeningApplication();
    final p = original.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final first = original.captureHistoricalOpening(expectedPending: p);
    expect(original.captureHistoricalOpening(expectedPending: p), first);
    final state = codec.decodeHistoricalOpening(first);
    expect(state.seasonIndex, 0);
    expect(state.sourceClubs, hasLength(48));
    expect(state.sourceLeagues, hasLength(3));
    expect(state.historicalManagerAuthorityAvailable, isFalse);
    expect(() => state.sourceClubs.clear(), throwsUnsupportedError);
    expect(() => state.sourceLeagues.clear(), throwsUnsupportedError);
    expect(() => state.sourceLeagues.first.clubIds.clear(),
        throwsUnsupportedError);
    final other =
        codec.decodeHistoricalOpening(worker.createHistoricalOpening());
    expect(other.careerInstanceId, isNot(state.careerInstanceId));
    final observation = original.historicalOpeningObservation;
    expect(() => observation.clear(), throwsUnsupportedError);
    expect(
        () => (observation['prepared'] as Map).clear(), throwsUnsupportedError);
  });

  test(
      'foreign and stale original Pending capture preserves exact current state',
      () {
    final a = worker.createHistoricalOpeningApplication();
    final b = worker.createHistoricalOpeningApplication();
    final ap = a.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final bp = b.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final before = a.historicalOpeningObservation;
    expect(() => a.captureHistoricalOpening(expectedPending: bp),
        throwsStateError);
    expect(a.currentStep, same(ap));
    expect(a.historicalOpeningObservation, before);
    final r = a.submitPromise(
        expected: ap, choice: PresidentPromiseType.finishTopHalf);
    expect(() => a.captureHistoricalOpening(expectedPending: ap),
        throwsStateError);
    expect(a.currentStep, same(r));
    expect((a.historicalOpeningObservation['acceptedPromises'] as List),
        hasLength(48));
  });

  test(
      'original same career keeps nonce through real W30 B2 and first future v2',
      () {
    final app = worker.createHistoricalOpeningApplication();
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final historical = codec.decodeHistoricalOpening(
        app.captureHistoricalOpening(expectedPending: pending));
    final w30 = playOwnedSeason(app);
    expect(w30.completedMatchCount, 720);
    expect(() => app.captureHistoricalOpening(expectedPending: pending),
        throwsStateError);
    final b2 = app.closeSeason(expected: w30);
    expect(b2, isA<PlayerPresidentOwnedSeasonClosed>());
    expect(b2.leagueResults, hasLength(3));
    expect(() => app.captureHistoricalOpening(expectedPending: pending),
        throwsStateError);
    enterNextOwnedSeason(app, b2);
    final future = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(future.seasonIndex, 1);
    expect(() => app.captureHistoricalOpening(expectedPending: future),
        throwsStateError);
    final v2 = codec.decodeOwnedOpening(
        app.captureFirstFutureOpening(expectedPending: future));
    expect(v2.careerInstanceId, historical.careerInstanceId);
    expect(v2.world.completedSeasons, 1);
    expect(v2.assignments, hasLength(48));
    expect(v2.historicalManagerAuthorityAvailable, isFalse);
  });

  test('same genuine producer and restored owner match complete W0/W1 facts',
      () {
    final original = worker.createHistoricalOpeningApplication();
    final op = original.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final raw = original.captureHistoricalOpening(expectedPending: op);
    final restored =
        PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(raw);
    addTearDown(restored.dispose);
    expect(restored.openingObservation, original.historicalOpeningObservation);
    final p = restored.currentStep as DurableHistoricalPromisePending;
    final state = codec.decodeHistoricalOpening(raw);
    expect(p.decisionId, state.decisionId);
    expect(p.careerInstanceId, state.careerInstanceId);
    expect(p.clubId, state.controlledClubId);
    expect(p.playerPresidentId, state.expectedPlayerPresidentId);
    expect(p.seasonIndex, 0);
    expect(restored.encodeCurrentOpening(), raw);
    final or = original.submitPromise(
        expected: op, choice: PresidentPromiseType.finishTopHalf);
    final rr = restored.submitPromise(
        expectedPending: p, choice: PresidentPromiseType.finishTopHalf);
    expect(worker.consequenceFacts(rr.consequence),
        worker.consequenceFacts(or.consequence));
    expect(restored.openingObservation, original.historicalOpeningObservation);
    expect(rr.activePromises, hasLength(48));
    expect((restored.openingObservation['prepared'] as Map)['promiseContexts'],
        hasLength(48));
    expect(() => rr.activePromises.clear(), throwsUnsupportedError);
    final ow0 = original.continueAfterPromise(expected: or);
    final rw0 = restored.continueAfterPromise(expectedResolution: rr);
    expect(worker.weeklyFacts(rw0.fixtures), worker.weeklyFacts(ow0.fixtures));
    final ow1 = original.advanceRound(expected: ow0);
    final rw1 = restored.advanceFirstRound(expectedW0: rw0);
    expect(worker.weeklyFacts(rw1.fixtures), worker.weeklyFacts(ow1.fixtures));
    expect(rw1.fixtures.completedMatchCount, 24);
    expect(rw1.fixtures.nextRound, 2);
    expect(rw1.fixtures.fixtures, hasLength(720));
  });

  test(
      'nondefault finite execution configuration survives exact genuine preparation',
      () {
    const config = SimulationConfig(
        careerSeed: 20260904,
        simulationVersion: 2,
        homeAdvantageRating: 2.75,
        baseHomeGoals: 1.31,
        baseAwayGoals: 1.17,
        ratingScale: 0.019,
        minExpectedGoals: 0.23,
        maxExpectedGoals: 4.75);
    final original = worker.createHistoricalOpeningApplication(config: config);
    final pending =
        original.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final saved = original.captureHistoricalOpening(expectedPending: pending);
    final restored =
        PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
            saved);
    addTearDown(restored.dispose);
    expect(restored.openingObservation, original.historicalOpeningObservation);
    final actual = (restored.openingObservation['prepared']
        as Map)['executionConfig'] as Map;
    expect(actual, {
      'careerSeed': 20260904,
      'simulationVersion': 2,
      'seasonIndex': 0,
      'homeAdvantageRating': 2.75,
      'baseHomeGoals': 1.31,
      'baseAwayGoals': 1.17,
      'ratingScale': 0.019,
      'minExpectedGoals': 0.23,
      'maxExpectedGoals': 4.75
    });
    final a = original.submitPromise(
        expected: pending, choice: PresidentPromiseType.finishTopHalf);
    final b = restored.submitPromise(
        expectedPending:
            restored.currentStep as DurableHistoricalPromisePending,
        choice: PresidentPromiseType.finishTopHalf);
    final aw0 = original.continueAfterPromise(expected: a);
    final bw0 = restored.continueAfterPromise(expectedResolution: b);
    expect(
        worker
            .weeklyFacts(restored.advanceFirstRound(expectedW0: bw0).fixtures),
        worker.weeklyFacts(original.advanceRound(expected: aw0).fixtures));
  });

  test('foreign, stale and conflicting answers preserve exact current state',
      () {
    final a = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    final b = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final p = a.currentStep as DurableHistoricalPromisePending;
    final q = b.currentStep as DurableHistoricalPromisePending;
    expect(p.decisionId,
        q.decisionId); // Same logical save, different live handles.
    expect(
        () => a.submitPromise(
            expectedPending: q, choice: PresidentPromiseType.finishTopHalf),
        throwsStateError);
    expect(a.currentStep, same(p));
    final rejected = PresidentPromiseType.values
        .where((t) => !p.context.allowedTypes.contains(t));
    if (rejected.isNotEmpty) {
      expect(() => a.submitPromise(expectedPending: p, choice: rejected.first),
          throwsArgumentError);
      expect(a.currentStep, same(p));
    }
    final r = a.submitPromise(
        expectedPending: p, choice: PresidentPromiseType.finishTopHalf);
    expect(
        () => a.submitPromise(
            expectedPending: p, choice: PresidentPromiseType.finishTopHalf),
        throwsStateError);
    expect(
        () => a.submitPromise(
            expectedPending: p, choice: PresidentPromiseType.reduceDebt),
        throwsStateError);
    expect(a.currentStep, same(r));
    expect(() => a.encodeCurrentOpening(), throwsStateError);
    final br = b.submitPromise(
        expectedPending: q, choice: PresidentPromiseType.finishTopHalf);
    expect(
        () => a.continueAfterPromise(expectedResolution: br), throwsStateError);
    expect(a.currentStep, same(r));
    final w0 = a.continueAfterPromise(expectedResolution: r);
    expect(
        () => a.continueAfterPromise(expectedResolution: r), throwsStateError);
    expect(() => a.encodeCurrentOpening(), throwsStateError);
    expect(a.currentStep, same(w0));
    final bw0 = b.continueAfterPromise(expectedResolution: br);
    expect(() => a.advanceFirstRound(expectedW0: bw0), throwsStateError);
    expect(a.currentStep, same(w0));
    final w1 = a.advanceFirstRound(expectedW0: w0);
    expect(() => a.advanceFirstRound(expectedW0: w0), throwsStateError);
    expect(() => a.encodeCurrentOpening(), throwsStateError);
    expect(a.currentStep, same(w1));
    expect(w0.fixtures.completedMatchCount, 0);
    expect(w1.fixtures.completedMatchCount, 24);
  });

  test('premature commands and later progression are not admitted', () {
    final a = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    final b = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final p = a.currentStep;
    final r = b.submitPromise(
        expectedPending: b.currentStep as DurableHistoricalPromisePending,
        choice: PresidentPromiseType.finishTopHalf);
    final w0 = b.continueAfterPromise(expectedResolution: r);
    expect(
        () => a.continueAfterPromise(expectedResolution: r), throwsStateError);
    expect(() => a.advanceFirstRound(expectedW0: w0), throwsStateError);
    expect(a.currentStep, same(p));
    expect(() => (a as dynamic).advanceRound(), throwsNoSuchMethodError);
    expect(() => (a as dynamic).closeSeason(), throwsNoSuchMethodError);
    expect(
        () => (a as dynamic).projectCommittedSeason(), throwsNoSuchMethodError);
    expect(() => (a as dynamic).advanceFutureWeek(), throwsNoSuchMethodError);
    expect(() => (a as dynamic).commitFutureSeason(), throwsNoSuchMethodError);
    expect(
        () => (a as dynamic).handoffFutureEconomy(), throwsNoSuchMethodError);
    expect(() => (a as dynamic).startFuturePostseasonTransition(),
        throwsNoSuchMethodError);
  });

  test('dispose invalidates commands without mutating immutable observations',
      () {
    final a = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    final p = a.currentStep as DurableHistoricalPromisePending;
    final observation = a.openingObservation;
    a.dispose();
    a.dispose();
    expect(
        () => a.submitPromise(
            expectedPending: p, choice: PresidentPromiseType.finishTopHalf),
        throwsStateError);
    expect(() => a.encodeCurrentOpening(), throwsStateError);
    expect(observation['prepared'], isNotNull);
    final b = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    addTearDown(b.dispose);
    expect(
        () => b.submitPromise(
            expectedPending: p, choice: PresidentPromiseType.finishTopHalf),
        throwsStateError);
    expect(
        codec.encodeHistoricalOpening(codec.decodeHistoricalOpening(encoded)),
        encoded);
  });

  test('savepoint remains unanswered after unsaved choice and W1', () {
    final a = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    final pending = a.currentStep as DurableHistoricalPromisePending;
    final r = a.submitPromise(
        expectedPending: pending, choice: PresidentPromiseType.finishTopHalf);
    final w0 = a.continueAfterPromise(expectedResolution: r);
    a.advanceFirstRound(expectedW0: w0);
    a.dispose();
    final b = PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
        encoded);
    addTearDown(b.dispose);
    expect(b.currentStep, isA<DurableHistoricalPromisePending>());
    expect((b.currentStep as DurableHistoricalPromisePending).decisionId,
        pending.decisionId);
    expect(jsonDecode(b.encodeCurrentOpening()), jsonDecode(encoded));
  });
  test(
      'original source order, valid member order and all nine config knobs survive',
      () {
    const config = SimulationConfig(
        careerSeed: 42002,
        simulationVersion: 2,
        homeAdvantageRating: 2.75,
        baseHomeGoals: 1.31,
        baseAwayGoals: 1.17,
        ratingScale: 0.019,
        minExpectedGoals: 0.23,
        maxExpectedGoals: 4.75);
    final original = worker.createHistoricalOpeningApplication(
        config: config,
        electionInterval: 1,
        reverseLeagues: true,
        reverseMembers: true,
        reverseClubs: true);
    final raw = original.captureHistoricalOpening(
        expectedPending:
            original.currentStep as PlayerPresidentOwnedSeasonPromisePending);
    final saved = codec.decodeHistoricalOpening(raw);
    expect(saved.sourceLeagues.map((x) => x.tier.level), [3, 2, 1]);
    final world = const FictionalWorldFactory().build();
    expect(saved.sourceClubs.map((x) => x.id),
        world.clubs.reversed.map((x) => x.id));
    expect(saved.sourceLeagues.first.clubIds,
        world.leagues.last.clubIds.reversed.toList());
    expect(saved.electionInterval, 1);
    final restored =
        PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(raw);
    addTearDown(restored.dispose);
    expect(restored.openingObservation, original.historicalOpeningObservation);
    final prepared = restored.openingObservation['prepared'] as Map;
    expect((prepared['world'] as Map)['leagues'], isNotEmpty);
    expect(
        ((prepared['world'] as Map)['sourceOrderWitness'] as Map)['leagues'], [
      for (final league in saved.sourceLeagues)
        {
          'tierLevel': league.tier.level,
          'leagueId': league.id,
          'clubIds': league.clubIds
        }
    ]);
    final p = restored.currentStep as DurableHistoricalPromisePending;
    final r = restored.submitPromise(
        expectedPending: p, choice: p.context.allowedTypes.first);
    final w0 = restored.continueAfterPromise(expectedResolution: r);
    expect(
        restored.advanceFirstRound(expectedW0: w0).fixtures.completedMatchCount,
        24);
  });

  test(
      'complete opening observation is deeply immutable and stable across commands',
      () {
    final app =
        PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
            encoded);
    addTearDown(app.dispose);
    final initial = app.openingObservation;
    final frozen = jsonEncode(initial);
    void immutable(Object? value) {
      if (value is Map) {
        expect(() => value['injected'] = true, throwsUnsupportedError);
        for (final child in value.values) {
          immutable(child);
        }
      } else if (value is List) {
        expect(() => value.add(null), throwsUnsupportedError);
        for (final child in value) {
          immutable(child);
        }
      }
    }

    immutable(initial);
    final p = app.currentStep as DurableHistoricalPromisePending;
    final r = app.submitPromise(
        expectedPending: p, choice: PresidentPromiseType.finishTopHalf);
    final accepted = app.openingObservation;
    immutable(accepted);
    final w0 = app.continueAfterPromise(expectedResolution: r);
    app.advanceFirstRound(expectedW0: w0);
    expect(jsonEncode(initial), frozen);
    expect(initial['acceptedPromises'], isEmpty);
    expect(accepted['acceptedPromises'], hasLength(48));
    expect(app.openingObservation, accepted);
  });

  test(
      'direct M73 boundary retains raw submit but cannot mint trusted M76 capture',
      () {
    final world = const FictionalWorldFactory().build();
    final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 20260903),
        controlledClubId: 't1_01',
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final boundary = PlayerPresidentPreseasonPromiseBoundary.start(
        application: app,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues);
    final pending = boundary.pending!;
    expect(
        () => app.captureOwnedHistoricalOpening(
            boundary: boundary, pending: pending),
        throwsStateError);
    expect(boundary.pending, same(pending));
    expect(boundary.applied, isNull);
    final applied = boundary.submit(
        pending: pending, choice: pending.context.allowedTypes.first);
    expect(applied.activePromises, hasLength(48));
    expect(applied.acceptedRequestKey, pending.requestKey);
  });
  test(
      'H09 raw wrapper capture rejects every progressed historical cut through actual B1 B2',
      () {
    final world = const FictionalWorldFactory().build();
    final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 20260903),
        controlledClubId: 't1_01',
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final boundary = app.startPreseasonPromise(
        sourceClubs: world.clubs, sourceLeagues: world.leagues);
    final pending = boundary.pending!;
    void denied() => expect(
        () => app.captureOwnedHistoricalOpening(
            boundary: boundary, pending: pending),
        throwsStateError);
    app.captureOwnedHistoricalOpening(boundary: boundary, pending: pending);
    boundary.submit(
        pending: pending, choice: pending.context.allowedTypes.first);
    denied();
    var weekly = app.openPreseasonWeeklyHandoff();
    denied();
    for (var round = 1; round <= 30; round++) {
      weekly =
          app.advancePreseasonWeek(expectedState: weekly, expectedRound: round);
      if ([1, 29, 30].contains(round)) denied();
    }
    final b1 = app.projectCommittedSeason(expectedState: weekly);
    denied();
    expect(app.committedSeasonResultCandidate, same(b1));
    final b2 = app.closeAcceptedPromises(expectedResultCandidate: b1);
    denied();
    expect(app.acceptedPromiseClosingCandidate, same(b2));
    expect(app.preseasonWeeklyState, same(weekly));
    expect(weekly.completedMatchCount, 720);
  });

  test(
      'H18 forged open-interface handles and direct claims never become producer provenance',
      () {
    final world = const FictionalWorldFactory().build();
    final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 20260903),
        controlledClubId: 't1_01',
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final boundary = app.startPreseasonPromise(
        sourceClubs: world.clubs, sourceLeagues: world.leagues);
    final pending = boundary.pending!;
    expect(
        () => app.captureOwnedHistoricalOpening(
            boundary: _BoundaryImpostor(), pending: pending),
        throwsStateError);
    expect(
        () => app.captureOwnedHistoricalOpening(
            boundary: boundary, pending: _PendingImpostor()),
        throwsStateError);
    expect(
        () => app.claimPreseasonPromiseBoundary(
            boundary: _BoundaryImpostor(),
            proof: boundary.proof,
            sourceClubs: world.clubs,
            sourceLeagues: world.leagues),
        throwsStateError);
    expect(app.preseasonPromiseBoundary, same(boundary));
    expect(boundary.pending, same(pending));
    expect(boundary.applied, isNull);
    final capture =
        app.captureOwnedHistoricalOpening(boundary: boundary, pending: pending);
    expect(capture.careerInstanceId, matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('H09 noncanonical resume profiles cannot capture or bind identity', () {
    final world = const FictionalWorldFactory().build();
    for (final knobs in [
      (2, true, 55, 5),
      (1, false, 55, 5),
      (1, true, 54, 5),
      (1, true, 55, 4)
    ]) {
      final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
          clubs: world.clubs,
          leagues: world.leagues,
          config: const SimulationConfig(careerSeed: 20260903),
          controlledClubId: 't1_01',
          seasonCount: knobs.$1,
          hasFutureSeasonAfterReport: knobs.$2,
          crisisActivationThreshold: knobs.$3,
          candidateLimit: knobs.$4);
      final boundary = app.startPreseasonPromise(
          sourceClubs: world.clubs, sourceLeagues: world.leagues);
      final pending = boundary.pending!;
      expect(
          () => app.captureOwnedHistoricalOpening(
              boundary: boundary, pending: pending),
          throwsStateError);
      expect(boundary.pending, same(pending));
      expect(boundary.applied, isNull);
    }
  });
  test(
      'H18 accepted legacy direct interface claim still cannot mint historical capture provenance',
      () {
    final world = const FictionalWorldFactory().build();
    PlayerPresidentInteractiveDecisionApplicationSession start() =>
        PlayerPresidentInteractiveDecisionApplicationSession.start(
            clubs: world.clubs,
            leagues: world.leagues,
            config: const SimulationConfig(careerSeed: 20260903),
            controlledClubId: 't1_01',
            seasonCount: 1,
            hasFutureSeasonAfterReport: true);
    final producer = start();
    final genuine = producer.startPreseasonPromise(
        sourceClubs: world.clubs, sourceLeagues: world.leagues);
    final raw = start();
    final claimed = _ClaimBoundary(raw, genuine);
    // Existing raw claim contract is unchanged. The new trusted wrapper was NOT called.
    raw.claimPreseasonPromiseBoundary(
        boundary: claimed,
        proof: genuine.proof,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues);
    expect(raw.preseasonPromiseBoundary, same(claimed));
    expect(
        () => raw.captureOwnedHistoricalOpening(
            boundary: claimed, pending: claimed.pending),
        throwsStateError);
    expect(() => raw.ownedHistoricalOpeningObservation(), throwsStateError);
    expect(raw.appliedPreseasonPromises, isNull);
    expect(claimed.phase, PlayerPresidentPreseasonPromisePhase.pending);
    // Actual trusted producer remains untouched and is still eligible.
    final capture = producer.captureOwnedHistoricalOpening(
        boundary: genuine, pending: genuine.pending!);
    expect(capture.controlledClubId, 't1_01');
    expect(genuine.applied, isNull);
  });
}
