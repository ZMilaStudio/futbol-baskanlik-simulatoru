import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

/// Genuine application acceptance/weekly/closing producer, not an authority
/// constructor or a substituted full-M65 receipt.
class B3B1ApplicationFixture {
  B3B1ApplicationFixture({bool future = true}) {
    final world = const FictionalWorldFactory().build();
    application = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 20260903),
      controlledClubId: 't1_01',
      seasonCount: 1,
      hasFutureSeasonAfterReport: future,
    );
    final boundary = application.startPreseasonPromise(
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    boundary.submit(
        pending: pending, choice: pending.context.allowedTypes.first);
    var state = application.openPreseasonWeeklyHandoff();
    for (var round = 1; round <= 30; round++) {
      state = application.advancePreseasonWeek(
        expectedState: state,
        expectedRound: round,
      );
    }
    final b1 = application.projectCommittedSeason(expectedState: state);
    source = application.closeAcceptedPromises(expectedResultCandidate: b1);
  }
  late final PlayerPresidentInteractiveDecisionApplicationSession application;
  late final PlayerPresidentAcceptedPromiseClosingCandidate source;
  List<String> get signatures => [
        ...source.finances.map((value) => value.signature),
        ...source.closingFinanceStates.map((value) => value.signature),
        ...source.sourceState.boundary.proof.initialContracts.activeContracts
            .map((value) => value.signature),
      ];
}

void main() {
  test('genuine B2 claim is exact and repeat start returns the same transition',
      () {
    final fixture = B3B1ApplicationFixture();
    final before = fixture.signatures;
    final transition = fixture.application.startPostseasonTransition(
      expectedSource: fixture.source,
    );
    expect(
        fixture.application.startPostseasonTransition(
          expectedSource: fixture.source,
        ),
        same(transition));
    final pending = transition.prepareTransfer()!;
    expect(transition.prepareTransfer(), same(pending));
    expect(transition.phase, PostseasonRuntimeTransitionPhase.transferPending);
    expect(pending.owner, same(fixture.application));
    expect(pending.context.window.decisionSeasonIndex, 1);
    expect(fixture.application.acceptedPromiseClosingCandidate,
        same(fixture.source));
    expect(fixture.signatures, before);
  });
  test('value-equal unpublished closing cannot authorize a transition', () {
    final fixture = B3B1ApplicationFixture();
    final detached = const PlayerPresidentAcceptedPromiseClosingProjection()
        .project(source: fixture.source.sourceResultCandidate);
    expect(
        () => fixture.application.startPostseasonTransition(
              expectedSource: detached,
            ),
        throwsStateError);
    expect(
        fixture.application
            .startPostseasonTransition(
              expectedSource: fixture.source,
            )
            .phase,
        PostseasonRuntimeTransitionPhase.closingReady);
  });
  test('valid answer runs suffix once and domain uses real B2 resolutions', () {
    final fixture = B3B1ApplicationFixture();
    final before = fixture.signatures;
    final transition = fixture.application.startPostseasonTransition(
      expectedSource: fixture.source,
    );
    final pending = transition.prepareTransfer()!;
    final choice =
        PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
    transition.submitTransfer(expectedPending: pending, choice: choice);
    expect(transition.phase,
        PostseasonRuntimeTransitionPhase.transferFollowupComplete);
    transition.submitTransfer(expectedPending: pending, choice: choice);
    transition.prepareDomain();
    final evidence = transition.domainSuccessor!;
    expect(evidence.clubs.length, 48);
    expect(evidence.media, isEmpty); // No fake squad-only manager statements.
    transition.prepareDomain();
    expect(transition.domainSuccessor, same(evidence));
    transition.prepareOuterSuccessor();
    expect(
        transition.phase, PostseasonRuntimeTransitionPhase.continuationReady);
    final result = fixture.application.publishPostseasonContinuation(
      expectedTransition: transition,
    );
    expect(result.targetSeasonIndex, 1);
    expect(result.managerEvidence.completedSeasons, isEmpty);
    expect(result.managerEvidence.assignments.length, 48);
    expect(result.contractCount, greaterThan(0));
    expect(result.domainEvidence, same(evidence));
    expect(transition.phase, PostseasonRuntimeTransitionPhase.moved);
    expect(
        fixture.application.publishPostseasonContinuation(
          expectedTransition: transition,
        ),
        same(result));
    expect(() => transition.prepareTransfer(), throwsStateError);
    expect(fixture.signatures, before);
    expect(fixture.source.sourceState.completedMatchCount, 720);
  });
}
