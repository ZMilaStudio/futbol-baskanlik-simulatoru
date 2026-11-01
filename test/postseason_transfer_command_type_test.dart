import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_decision_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:test/test.dart';

import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;

class _CommandSubtype extends PlayerTransferStrategyChoice {
  _CommandSubtype({required this.invalidValues})
      : super(
          financialDiscipline: invalidValues ? 0 : 60,
          transferAmbition: invalidValues ? 0 : 60,
          riskAppetite: invalidValues ? 0 : 60,
          youthOrientation: invalidValues ? 0 : 60,
        );

  final bool invalidValues;
  int validations = 0;
  int applications = 0;
  int signatures = 0;

  @override
  void validate() {
    validations++;
    // An invalid command cannot substitute caller behavior for value checks.
  }

  @override
  PresidentManagementProfile applyTo(PresidentManagementProfile profile) {
    applications++;
    if (!invalidValues && applications == 2) {
      throw StateError('Caller override failed after the answer was consumed.');
    }
    return super.applyTo(profile);
  }

  @override
  String get signature {
    signatures++;
    return super.signature;
  }
}

void _expectUninvoked(_CommandSubtype choice) {
  expect(choice.validations, 0);
  expect(choice.applications, 0);
  expect(choice.signatures, 0);
}

(
  PlayerPresidentOwnedSeasonApplication,
  PlayerPresidentOwnedSeasonTransferPending
) _ownedTransfer() {
  final world = const FictionalWorldFactory().build();
  final app = PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: const SimulationConfig(careerSeed: 20260903),
    controlledClubId: 't1_01',
  );
  final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
  final resolved = app.submitPromise(
    expected: pending,
    choice: pending.request
        .contextAs<PlayerPromiseDecisionContext>()
        .allowedTypes
        .first,
  );
  var running = app.continueAfterPromise(expected: resolved);
  for (var round = 1; round <= 30; round++) {
    running = app.advanceRound(expected: running);
  }
  final closed = app.closeSeason(expected: running);
  final transfer = app.continueToNextSeason(expected: closed)
      as PlayerPresidentOwnedSeasonTransferPending;
  return (app, transfer);
}

void main() {
  for (final invalidValues in [true, false]) {
    final behavior = invalidValues
        ? 'invalid traits with overridden validation'
        : 'throwing effect override';
    test('raw transfer rejects $behavior before consuming the Pending', () {
      final fixture = B3B1ApplicationFixture();
      final transition = fixture.application
          .startPostseasonTransition(expectedSource: fixture.source);
      final pending = transition.prepareTransfer()!;
      final before = fixture.signatures;
      final choice = _CommandSubtype(invalidValues: invalidValues);

      expect(
          () => transition.submitTransfer(
              expectedPending: pending, choice: choice),
          throwsArgumentError);
      _expectUninvoked(choice);
      expect(
          transition.phase, PostseasonRuntimeTransitionPhase.transferPending);
      expect(transition.prepareTransfer(), same(pending));
      expect(transition.acceptedAnswers, isEmpty);
      expect(transition.domainSuccessor, isNull);
      expect(fixture.signatures, before);
      final valid =
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
      transition.submitTransfer(expectedPending: pending, choice: valid);
      expect(transition.phase,
          PostseasonRuntimeTransitionPhase.transferFollowupComplete);
      expect(transition.acceptedAnswers.single.choice, same(valid));
      expect(
          () => transition.submitTransfer(
              expectedPending: pending, choice: choice),
          throwsArgumentError);
      _expectUninvoked(choice);
      expect(transition.acceptedAnswers, hasLength(1));
      expect(transition.acceptedAnswers.single.choice, same(valid));
    });

    test('owned transfer rejects $behavior and remains answerable', () {
      final (app, pending) = _ownedTransfer();
      final opening = app.currentSeasonOpening;
      final choice = _CommandSubtype(invalidValues: invalidValues);
      expect(() => app.submitTransfer(expected: pending, choice: choice),
          throwsArgumentError);
      _expectUninvoked(choice);
      expect(app.currentStep, same(pending));
      expect(app.currentSeasonOpening, same(opening));
      final ready = app.submitTransfer(
        expected: pending,
        choice:
            PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile),
      );
      expect(ready, isA<PlayerPresidentOwnedSeasonContinuationReady>());
    });
  }

  test(
      'bound answer primitive rejects subtype before effects or duplicate checks',
      () {
    final fixture = B3B1ApplicationFixture();
    final transition = fixture.application
        .startPostseasonTransition(expectedSource: fixture.source);
    final producerPending = transition.prepareTransfer()!;
    final session = PostseasonDecisionSession.fromRuntimeTransition(transition);
    final pending = session.requestTransfer(producerPending.context)!;
    final source = pending.request.source;
    void answer(PlayerTransferStrategyChoice choice) => session.answer(
          request: pending.request,
          choice: choice,
          owner: source.owner,
          revision: source.revision,
          provenance: source.provenance,
          transaction: source.transaction,
        );
    final invalid = _CommandSubtype(invalidValues: true);
    expect(() => answer(invalid), throwsArgumentError);
    _expectUninvoked(invalid);
    expect(session.answers, isEmpty);
    expect(session.pending, same(pending));

    final valid = PlayerTransferStrategyChoice.fromProfile(
        producerPending.context.aiProfile);
    answer(valid);
    expect(session.answers.single.choice, same(valid));
    final overridden = _CommandSubtype(invalidValues: false);
    expect(() => answer(overridden), throwsArgumentError);
    _expectUninvoked(overridden);
    expect(session.answers, hasLength(1));
    expect(session.answers.single.choice, same(valid));
  });
}
