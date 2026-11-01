import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;
import 'p2_ar_d_future_weekly_runtime_test.dart' show completedFutureApp;

class _ResolverProbe extends PromiseResolver {
  final resolutions = <PromiseResolution>[];
  final int? failAfter;
  _ResolverProbe({this.failAfter});

  @override
  PromiseResolution resolve({
    required PresidentPromise promise,
    required PresidentPromiseOutcome outcome,
  }) {
    if (resolutions.length == failAfter) {
      throw StateError('Injected genuine domain resolver failure.');
    }
    final result = super.resolve(promise: promise, outcome: outcome);
    resolutions.add(result);
    return result;
  }
}

void main() {
  test('historical domain exposes the exact existing immutable B2 snapshots',
      () {
    final fixture = B3B1ApplicationFixture();
    final app = fixture.application;
    final transition =
        app.startPostseasonTransition(expectedSource: fixture.source);
    expect(transition.completedPromiseSnapshots, isNull);
    expect(transition.domainSuccessor, isNull);
    final pending = transition.prepareTransfer()!;
    expect(transition.completedPromiseSnapshots, isNull);
    expect(() => transition.prepareDomain(), throwsStateError);
    expect(transition.completedPromiseSnapshots, isNull);
    transition.submitTransfer(
      expectedPending: pending,
      choice:
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile),
    );
    expect(transition.completedPromiseSnapshots, isNull);
    transition.prepareDomain();

    final snapshots = transition.completedPromiseSnapshots!;
    expect(snapshots, same(fixture.source.promiseSnapshots));
    expect(snapshots, hasLength(48));
    expect(() => snapshots.clear(), throwsUnsupportedError);
    expect(() => snapshots[0] = snapshots.last, throwsUnsupportedError);
    transition.prepareDomain();
    expect(transition.completedPromiseSnapshots, same(snapshots));
    transition.prepareOuterSuccessor();
    app.publishPostseasonContinuation(expectedTransition: transition);
    expect(transition.completedPromiseSnapshots, same(snapshots));
  });

  test('future settlement has no resolved promise before actual domain stage',
      () {
    final app = completedFutureApp();
    final committed =
        app.commitFutureSeason(expectedW30: app.futureWeeklyState!);
    final economy = app.handoffFutureEconomy(expectedCommitted: committed);
    economy.prepareSettlement(committed.capability);
    economy.submitTicket(
      economy.pending!,
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
      expectedRevision: economy.revision,
    );
    final settled =
        economy.executeSettlement(expectedCommitted: committed.capability);
    final transition = app.startFuturePostseasonTransition(
        expectedSettlement: settled, hasNextSeason: true);
    expect(transition.completedPromiseSnapshots, isNull);
    final pending = transition.prepareTransfer()!;
    expect(transition.completedPromiseSnapshots, isNull);
    transition.submitTransfer(
      expectedPending: pending,
      choice:
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile),
    );
    expect(transition.completedPromiseSnapshots, isNull);
    transition.prepareDomain();

    final snapshots = transition.completedPromiseSnapshots!;
    expect(snapshots, hasLength(48));
    final controlled = snapshots.singleWhere((snapshot) =>
        snapshot.context.clubId == committed.opening.controlledClubId);
    expect(controlled.promise, same(committed.applied.consequence.promise));
    expect(controlled.resolution.promise, same(controlled.promise));
    expect(controlled.context.seasonIndex, committed.targetSeasonIndex);
    expect(controlled.outcome.seasonIndex, committed.targetSeasonIndex);
    final finance = settled.receipt.results
        .singleWhere((row) => row.clubId == controlled.promise.clubId);
    expect(controlled.outcome.closingDebt, finance.closingDebt);
    expect(() => snapshots.clear(), throwsUnsupportedError);
    expect(() => snapshots[0] = snapshots.last, throwsUnsupportedError);
  });

  test('observation reads and repeated domain prepare never rerun the resolver',
      () {
    final probe = _ResolverProbe();
    final fixture = B3B1LegacyClosing(
        sourceEngine: PromiseMediaCareerEngine(
            promiseEngine: PromiseCareerEngine(resolver: probe)));
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    transition.submitTransfer(
      expectedPending: pending,
      choice:
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile),
    );
    expect(probe.resolutions, isEmpty);
    expect(transition.completedPromiseSnapshots, isNull);
    transition.prepareDomain();
    final snapshots = transition.completedPromiseSnapshots!;
    expect(probe.resolutions, hasLength(48));
    for (var index = 0; index < snapshots.length; index++) {
      expect(snapshots[index].resolution, same(probe.resolutions[index]));
    }
    transition.prepareDomain();
    for (var read = 0; read < 3; read++) {
      expect(transition.completedPromiseSnapshots, same(snapshots));
    }
    expect(probe.resolutions, hasLength(48));
  });

  test('failed production domain cannot publish partial promise observations',
      () {
    final probe = _ResolverProbe(failAfter: 3);
    final fixture = B3B1LegacyClosing(
        sourceEngine: PromiseMediaCareerEngine(
            promiseEngine: PromiseCareerEngine(resolver: probe)));
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    transition.submitTransfer(
      expectedPending: pending,
      choice:
          PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile),
    );
    expect(() => transition.prepareDomain(), throwsStateError);
    expect(probe.resolutions, hasLength(3));
    expect(transition.domainSuccessor, isNull);
    expect(transition.completedPromiseSnapshots, isNull);
    expect(() => transition.prepareDomain(), throwsStateError);
    expect(transition.completedPromiseSnapshots, isNull);
    expect(probe.resolutions, hasLength(3));
  });
}
