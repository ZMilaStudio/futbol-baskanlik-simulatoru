import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_preseason_promise_boundary.dart';
import 'package:test/test.dart';

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();

  PlayerPresidentInteractiveDecisionApplicationSession app() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: 't1_01',
        seasonCount: 1,
        hasFutureSeasonAfterReport: true,
      );

  test('P2-A1b2 publishes 47 AI plus one real player promise atomically', () {
    final session = app();
    final boundary = PlayerPresidentPreseasonPromiseBoundary.start(
      application: session,
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    expect(boundary.phase, PlayerPresidentPreseasonPromisePhase.pending);
    expect(pending.phase, 'preseasonPromise');
    expect(pending.sequence, 1);
    expect(pending.kind, 'promise');
    expect(pending.clubId, 't1_01');
    expect(pending.contextSignature, pending.context.signature);
    expect(pending.sourceIdentity,
        boundary.proof.seasonOpening.originSourceDigest);
    expect(pending.requestKey, startsWith('preseason-promise/v1:'));
    expect(session.canPersist, isFalse);
    expect(session.canPersistBootstrap, isFalse);
    expect(() => session.newGameBootstrapSnapshot, throwsStateError);
    expect(() => session.encodeNewGameBootstrapSnapshot(), throwsStateError);
    expect(() => session.advance(), throwsStateError);
    final applied = boundary.submit(
      pending: pending,
      choice: pending.context.allowedTypes.first,
    );
    expect(boundary.phase, PlayerPresidentPreseasonPromisePhase.applied);
    expect(applied.activePromises, hasLength(48));
    expect(
      applied.activePromises.map((item) => item.clubId).toSet(),
      hasLength(48),
    );
    expect(
      applied.consequence.promise,
      same(
        applied.activePromises.singleWhere((item) => item.clubId == 't1_01'),
      ),
    );
    expect(applied.sourceIdentity,
        boundary.proof.seasonOpening.originSourceDigest);
    expect(applied.seasonIndex, 0);
    expect(applied.controlledClubId, 't1_01');
    expect(applied.controlledPresidentId,
        boundary.proof.presidentOpening.controlledPresidentId);
    expect(applied.acceptedRequestKey, pending.requestKey);
    expect(applied.acceptedChoice, pending.context.allowedTypes.first);
    expect(
      applied.activePromises.every(
        (promise) => promise.id == 'promise_${promise.clubId}_s0',
      ),
      isTrue,
    );
    expect(
      () => boundary.submit(
        pending: pending,
        choice: pending.context.allowedTypes.first,
      ),
      throwsStateError,
    );
  });

  test(
    'P2-A1b2 invalid choice preserves the exact pending object for retry',
    () {
      final boundary = PlayerPresidentPreseasonPromiseBoundary.start(
        application: app(),
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      );
      final pending = boundary.pending!;
      final invalid = PresidentPromiseType.values.firstWhere(
        (item) => !pending.context.allowedTypes.contains(item),
      );
      expect(
        () => boundary.submit(pending: pending, choice: invalid),
        throwsArgumentError,
      );
      expect(boundary.pending, same(pending));
      expect(boundary.applied, isNull);
      final applied = boundary.submit(
        pending: pending,
        choice: pending.context.allowedTypes.first,
      );
      expect(
          applied.consequence.promise.type, pending.context.allowedTypes.first);
    },
  );

  test('P2-A1b2 rejects a Pending owned by another pristine opening', () {
    final first = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final second = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );

    expect(
      () => first.submit(
        pending: second.pending!,
        choice: second.pending!.context.allowedTypes.first,
      ),
      throwsStateError,
    );
    expect(first.pending, isNotNull);
    expect(first.applied, isNull);
  });

  test('P2-A1b2 preserves the 48 effective opening contexts', () {
    final boundary = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );

    expect(boundary.contexts, hasLength(48));
    expect(
      boundary.contexts.map((item) => item.context.clubId).toSet(),
      hasLength(48),
    );
    expect(
      boundary.contexts.map((item) => item.context.signature).toSet(),
      hasLength(48),
    );
    expect(
      boundary.pending!.context.context.clubId,
      boundary.proof.presidentOpening.controlledClubId,
    );
  });

  test('P2-A1b2 does not reserve M79 when source proof rejects the world', () {
    final session = app();

    expect(
      () => PlayerPresidentPreseasonPromiseBoundary.start(
        application: session,
        sourceClubs: world.clubs.sublist(1),
        sourceLeagues: world.leagues,
      ),
      throwsA(isA<SaveLoadException>()),
    );
    expect(session.canPersistBootstrap, isTrue);
    expect(session.canPersist, isFalse);
  });
}
