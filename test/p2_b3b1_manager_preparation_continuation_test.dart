import 'package:futbol_baskanlik_m0/src/manager/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;

SinglePassPostseasonRuntimeTransition readyManager(B3B1LegacyClosing fixture) {
  final transition = fixture.claim();
  final pending = transition.prepareTransfer()!;
  transition.submitTransfer(
      expectedPending: pending,
      choice:
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile));
  transition.prepareDomain();
  transition.prepareOuterSuccessor();
  return transition;
}

void main() {
  test(
      'real post-offseason review Pending keeps original history and once-only move',
      () {
    final fixture = B3B1LegacyClosing();
    final transition = readyManager(fixture);
    final pending = transition.managerPending!;
    expect(transition.phase,
        PostseasonRuntimeTransitionPhase.managerPreparationPending);
    transition.prepareOuterSuccessor();
    expect(transition.managerPending, same(pending));
    expect(pending.review.canRetain, isTrue);
    expect(
        transition.submitManagerReview(
            expectedPending: pending, choice: PlayerManagerReviewChoice.retain),
        isNull);
    expect(
        transition.submitManagerReview(
            expectedPending: pending, choice: PlayerManagerReviewChoice.retain),
        isNull);
    final successor = transition.moveOwnedAnnualContinuation();
    expect(transition.acceptedAnswers.length, 2);
    expect(successor.acceptedAnswers.length, 2);
    expect(() => successor.acceptedAnswers.clear(), throwsUnsupportedError);
    expect(() => transition.acceptedAnswers.clear(), throwsUnsupportedError);
    expect(successor.targetSeasonIndex, 1);
    expect(successor.managerEvidence.completedSeasons.length, 1);
    expect(successor.managerEvidence.assignments.length, 48);
    expect(
        successor.managerEvidence.assignments
            .singleWhere((a) => a.clubId == pending.review.clubId)
            .managerId,
        pending.review.currentManager.id);
    expect(successor.contractCount, greaterThan(0));
    expect(successor.transferLineageIdentity,
        same(fixture.closing.executionIdentity));
    expect(fixture.closing.advanced.managerOpening.seasons, isEmpty);
    expect(transition.moveOwnedAnnualContinuation(), same(successor));
  });

  test('replacement rejects foreign exact-value manager and preserves Pending',
      () {
    final fixture = B3B1LegacyClosing();
    final transition = readyManager(fixture);
    final review = transition.managerPending!;
    final replacement = transition.submitManagerReview(
        expectedPending: review, choice: PlayerManagerReviewChoice.replace)!;
    final other = readyManager(B3B1LegacyClosing());
    final foreign = other.submitManagerReview(
        expectedPending: other.managerPending!,
        choice: PlayerManagerReviewChoice.replace)!;
    expect(
        () => transition.submitManagerReplacement(
            expectedPending: replacement,
            selected: foreign.replacement!.candidates.first.manager),
        throwsArgumentError);
    expect(transition.managerPending, same(replacement));
    final selected = replacement.replacement!.candidates.last.manager;
    transition.submitManagerReplacement(
        expectedPending: replacement, selected: selected);
    transition.submitManagerReplacement(
        expectedPending: replacement, selected: selected);
    final successor = transition.moveOwnedAnnualContinuation();
    expect(transition.acceptedAnswers.length, 3);
    expect(successor.acceptedAnswers.length, 3);
    expect(
        successor.managerEvidence.assignments
            .singleWhere((a) => a.clubId == review.review.clubId)
            .managerId,
        selected.id);
    expect(successor.managerEvidence.completedSeasons.single.seasonIndex, 0);
    expect(fixture.closing.advanced.managerOpening.seasons, isEmpty);
  });
}
