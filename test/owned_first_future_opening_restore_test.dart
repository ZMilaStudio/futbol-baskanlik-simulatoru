import 'dart:convert';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart'
    show SimulationConfig;

import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_first_future_opening_persistence.dart';
import 'package:futbol_baskanlik_m0/player_president_durable_first_future_opening_application.dart';
import 'package:test/test.dart';

import 'support/owned_career_driver.dart';
import 'support/owned_first_future_opening_worker.dart' as worker;

void main() {
  late String encoded;
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  setUpAll(() {
    encoded = worker.createGenuineOpening();
  });

  test('genuine capture binds one nonce, stable identity and immutable roots',
      () {
    final original = worker.createGenuineOpeningApplication();
    final p = original.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final first = original.captureFirstFutureOpening(expectedPending: p);
    expect(original.captureFirstFutureOpening(expectedPending: p), first);
    final state = codec.decodeOwnedOpening(first);
    expect(state.world.completedSeasons, 1);
    expect(state.world.config.seasonIndex, 0);
    expect(state.seasonIndex, 1);
    expect(state.assignments, hasLength(48));
    expect(state.historicalManagerAuthorityAvailable, isFalse);
    expect(
        state.assignments.every(
            (a) => a.appointedSeasonIndex == 1 && a.completedSeasons == 0),
        isTrue);
    expect(() => state.assignments.clear(), throwsUnsupportedError);
    expect(() => state.termPromiseScores.clear(), throwsUnsupportedError);
    expect(() => state.termPromiseScores.values.first.clear(),
        throwsUnsupportedError);
    final other = codec.decodeOwnedOpening(worker.createGenuineOpening());
    expect(other.careerInstanceId, isNot(state.careerInstanceId));
    final observation = original.firstFutureOpeningObservation;
    expect(() => observation.clear(), throwsUnsupportedError);
    expect(
        () => (observation['prepared'] as Map).clear(), throwsUnsupportedError);
  });

  test('capture rejects historical and foreign Pending without mutation', () {
    final historical = startOwnedCareer();
    final hp =
        historical.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(() => historical.captureFirstFutureOpening(expectedPending: hp),
        throwsStateError);
    expect(historical.currentStep, same(hp));
    final a = worker.createGenuineOpeningApplication();
    final b = worker.createGenuineOpeningApplication();
    final ap = a.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final bp = b.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    expect(() => a.captureFirstFutureOpening(expectedPending: bp),
        throwsStateError);
    expect(a.currentStep, same(ap));
    a.submitPromise(expected: ap, choice: PresidentPromiseType.finishTopHalf);
    expect(() => a.captureFirstFutureOpening(expectedPending: ap),
        throwsStateError);
  });

  test('same genuine producer and restored owner match complete W0/W1 facts',
      () {
    final original = worker.createGenuineOpeningApplication();
    final op = original.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final raw = original.captureFirstFutureOpening(expectedPending: op);
    final restored =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(raw);
    addTearDown(restored.dispose);
    expect(restored.openingObservation, original.firstFutureOpeningObservation);
    final p = restored.currentStep as DurableFirstFuturePromisePending;
    final state = codec.decodeOwnedOpening(raw);
    expect(p.decisionId, state.decisionId);
    expect(p.careerInstanceId, state.careerInstanceId);
    expect(p.clubId, state.controlledClubId);
    expect(p.playerPresidentId, state.playerPresidentId);
    expect(p.seasonIndex, 1);
    expect(restored.encodeCurrentOpening(), raw);
    final or = original.submitPromise(
        expected: op, choice: PresidentPromiseType.finishTopHalf);
    final rr = restored.submitPromise(
        expectedPending: p, choice: PresidentPromiseType.finishTopHalf);
    expect(worker.consequenceFacts(rr.consequence),
        worker.consequenceFacts(or.consequence));
    expect(restored.openingObservation, original.firstFutureOpeningObservation);
    expect(rr.activePromises, hasLength(48));
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
    final original = worker.createGenuineOpeningApplication(config: config);
    final pending =
        original.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final saved = original.captureFirstFutureOpening(expectedPending: pending);
    final restored =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            saved);
    addTearDown(restored.dispose);
    expect(restored.openingObservation, original.firstFutureOpeningObservation);
    final actual = (restored.openingObservation['prepared']
        as Map)['executionConfig'] as Map;
    expect(actual, {
      'careerSeed': 20260904,
      'simulationVersion': 2,
      'seasonIndex': 1,
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
            restored.currentStep as DurableFirstFuturePromisePending,
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
    final a =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    final b =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final p = a.currentStep as DurableFirstFuturePromisePending;
    final q = b.currentStep as DurableFirstFuturePromisePending;
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
    final a =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    final b =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final p = a.currentStep;
    final r = b.submitPromise(
        expectedPending: b.currentStep as DurableFirstFuturePromisePending,
        choice: PresidentPromiseType.finishTopHalf);
    final w0 = b.continueAfterPromise(expectedResolution: r);
    expect(
        () => a.continueAfterPromise(expectedResolution: r), throwsStateError);
    expect(() => a.advanceFirstRound(expectedW0: w0), throwsStateError);
    expect(a.currentStep, same(p));
    expect(() => (a as dynamic).advanceFutureWeek(), throwsNoSuchMethodError);
    expect(() => (a as dynamic).commitFutureSeason(), throwsNoSuchMethodError);
    expect(
        () => (a as dynamic).handoffFutureEconomy(), throwsNoSuchMethodError);
    expect(() => (a as dynamic).startFuturePostseasonTransition(),
        throwsNoSuchMethodError);
  });

  test('dispose invalidates commands without mutating immutable observations',
      () {
    final a =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    final p = a.currentStep as DurableFirstFuturePromisePending;
    final observation = a.openingObservation;
    a.dispose();
    a.dispose();
    expect(
        () => a.submitPromise(
            expectedPending: p, choice: PresidentPromiseType.finishTopHalf),
        throwsStateError);
    expect(() => a.encodeCurrentOpening(), throwsStateError);
    expect(observation['prepared'], isNotNull);
    final b =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    addTearDown(b.dispose);
    expect(
        () => b.submitPromise(
            expectedPending: p, choice: PresidentPromiseType.finishTopHalf),
        throwsStateError);
    expect(
        codec.encodeOwnedOpening(codec.decodeOwnedOpening(encoded)), encoded);
  });

  test('savepoint remains unanswered after unsaved choice and W1', () {
    final a =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    final pending = a.currentStep as DurableFirstFuturePromisePending;
    final r = a.submitPromise(
        expectedPending: pending, choice: PresidentPromiseType.finishTopHalf);
    final w0 = a.continueAfterPromise(expectedResolution: r);
    a.advanceFirstRound(expectedW0: w0);
    a.dispose();
    final b =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    addTearDown(b.dispose);
    expect(b.currentStep, isA<DurableFirstFuturePromisePending>());
    expect((b.currentStep as DurableFirstFuturePromisePending).decisionId,
        pending.decisionId);
    expect(jsonDecode(b.encodeCurrentOpening()), jsonDecode(encoded));
  });
}
