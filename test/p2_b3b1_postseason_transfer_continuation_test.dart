import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';
import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;

void main() {
  test('value-equal Pending from another owned transition cannot answer', () {
    final first = B3B1ApplicationFixture();
    final second = B3B1ApplicationFixture();
    final owned = first.application
        .startPostseasonTransition(expectedSource: first.source);
    final foreign = second.application
        .startPostseasonTransition(expectedSource: second.source)
        .prepareTransfer()!;
    final pending = owned.prepareTransfer()!;
    expect(
        () => owned.submitTransfer(
            expectedPending: foreign,
            choice: PlayerTransferStrategyChoice.fromProfile(
                foreign.context.aiProfile)),
        throwsStateError);
    expect(owned.prepareTransfer(), same(pending));
    expect(owned.acceptedAnswers, isEmpty);
    expect(owned.phase, PostseasonRuntimeTransitionPhase.transferPending);
  });
  test('invalid answer retains exact Pending; accepted duplicate has no effect',
      () {
    final fixture = B3B1ApplicationFixture();
    final transition = fixture.application.startPostseasonTransition(
      expectedSource: fixture.source,
    );
    final pending = transition.prepareTransfer()!;
    final before = fixture.signatures;
    expect(
        () => transition.submitTransfer(
              expectedPending: pending,
              choice: const PlayerTransferStrategyChoice(
                financialDiscipline: 0,
                transferAmbition: 50,
                riskAppetite: 50,
                youthOrientation: 50,
              ),
            ),
        throwsArgumentError);
    expect(transition.phase, PostseasonRuntimeTransitionPhase.transferPending);
    expect(transition.prepareTransfer(), same(pending));
    final choice =
        PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
    transition.submitTransfer(expectedPending: pending, choice: choice);
    transition.submitTransfer(expectedPending: pending, choice: choice);
    expect(transition.phase,
        PostseasonRuntimeTransitionPhase.transferFollowupComplete);
    expect(
        () => transition.submitTransfer(
              expectedPending: pending,
              choice: PlayerTransferStrategyChoice(
                financialDiscipline: choice.financialDiscipline == 50 ? 51 : 50,
                transferAmbition: choice.transferAmbition,
                riskAppetite: choice.riskAppetite,
                youthOrientation: choice.youthOrientation,
              ),
            ),
        throwsStateError);
    expect(fixture.signatures, before);
  });
  test('terminal source creates no lifecycle, market or decision', () {
    final fixture = B3B1ApplicationFixture(future: false);
    final before = fixture.signatures;
    final transition = fixture.application.startPostseasonTransition(
      expectedSource: fixture.source,
    );
    expect(transition.prepareTransfer(), isNull);
    expect(transition.prepareTransfer(), isNull);
    expect(transition.phase, PostseasonRuntimeTransitionPhase.closingReady);
    expect(fixture.application.postseasonContinuation, isNull);
    expect(fixture.signatures, before);
  });
}
