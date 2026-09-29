import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/src/sponsor/player_president_sponsor_control.dart';
import 'package:test/test.dart';

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  final world = const FictionalWorldFactory().build();

  PlayerPresidentInteractiveDecisionApplicationSession app({
    String controlledClubId = 't1_01',
  }) =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
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
    expect(pending.request.phase, 'preseasonPromise');
    expect(pending.request.kind, PlayerPresidentInteractiveDecisionKind.promise);
    expect(pending.request.contextAs<PlayerPromiseDecisionContext>(),
        same(pending.context));
    expect(pending.request.key, pending.requestKey);
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
    expect(session.preseasonPromiseBoundary, same(boundary));
    expect(session.appliedPreseasonPromises, same(applied));
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
    expect(session.preseasonPromiseBoundary, isNull);
    expect(session.advance(), isA<PlayerPresidentInteractiveDecisionPending>());
  });

  test('P2-A1b2 rejects annual Pending and already accepted annual answer', () {
    final exposed = app();
    final annual = exposed.advance() as PlayerPresidentInteractiveDecisionPending;
    expect(exposed.answeredDecisionCount, 0);
    expect(exposed.pendingDecision, same(annual.request));
    expect(
      () => PlayerPresidentPreseasonPromiseBoundary.start(
        application: exposed,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(exposed.pendingDecision, same(annual.request));
    final context = annual.request.contextAs<PlayerSponsorDecisionContext>();
    exposed.submit(
      request: annual.request,
      choice: PlayerSponsorOfferChoice(offerId: context.aiChoice.id),
    );
    expect(exposed.answeredDecisionCount, 1);
    expect(
      () => PlayerPresidentPreseasonPromiseBoundary.start(
        application: exposed,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
  });

  test('P2-A1b2 public claim cannot create an orphan reservation', () {
    final session = app();
    final foreign = app().startPreseasonPromise(
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    expect(
      () => session.claimPreseasonPromiseBoundary(
        boundary: foreign,
        proof: foreign.proof,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(session.preseasonPromiseBoundary, isNull);
    expect(session.canPersistBootstrap, isTrue);
    expect(session.advance(), isA<PlayerPresidentInteractiveDecisionPending>());
    expect(
      () => session.claimPreseasonPromiseBoundary(
        boundary: foreign,
        proof: foreign.proof,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
  });

  test('P2-A1b2 duplicate proof-bound reservation and legacy paths fail closed',
      () {
    final session = app();
    final boundary = PlayerPresidentPreseasonPromiseBoundary.start(
      application: session,
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final annualFromOther = app().advance()
        as PlayerPresidentInteractiveDecisionPending;
    expect(
      () => session.claimPreseasonPromiseBoundary(
        boundary: boundary,
        proof: boundary.proof,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(
      () => PlayerPresidentPreseasonPromiseBoundary.start(
        application: session,
        sourceClubs: world.clubs,
        sourceLeagues: world.leagues,
      ),
      throwsStateError,
    );
    expect(() => session.advance(), throwsStateError);
    expect(
      () => session.submitWithResolution(
        request: annualFromOther.request,
        choice: Object(),
      ),
      throwsStateError,
    );
    expect(
      () => session.submit(
        request: annualFromOther.request,
        choice: Object(),
      ),
      throwsStateError,
    );
    expect(() => session.continuePlayerCareerToNextSeason(), throwsStateError);
    expect(() => session.newGameBootstrapSnapshot, throwsStateError);
    expect(() => session.encodeNewGameBootstrapSnapshot(), throwsStateError);
    expect(() => session.persistenceBundle, throwsStateError);
    expect(() => session.encodePersistenceBundle(), throwsStateError);
    expect(() => session.checkpoint, throwsStateError);
    expect(session.canPersistBootstrap, isFalse);
    expect(session.canPersist, isFalse);
    expect(boundary.pending, isNotNull);
  });

  test('P2-A1b2 M73 rejects wrong phase/key/club and foreign typed request',
      () {
    final first = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final second = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(controlledClubId: 't1_02'),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final actual = first.pending!;
    final choice = actual.context.allowedTypes.first;
    final annualRequest = (app().advance()
            as PlayerPresidentInteractiveDecisionPending)
        .request;
    expect(annualRequest.phase, 'annual');
    expect(annualRequest.key, isNot(startsWith('preseason-promise/v1:')));
    expect(
      () => first.submit(
        pending: actual,
        choice: choice,
        request: annualRequest,
      ),
      throwsStateError,
    );
    expect(second.pending!.clubId, 't1_02');
    expect(second.pending!.request.key, isNot(actual.request.key));
    expect(
      () => first.submit(
        pending: actual,
        choice: choice,
        request: second.pending!.request,
      ),
      throwsStateError,
    );
    final sameSourceForeign = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    expect(sameSourceForeign.pending!.request.key, actual.request.key);
    expect(
      () => first.submit(
        pending: actual,
        choice: choice,
        request: sameSourceForeign.pending!.request,
      ),
      throwsStateError,
    );
    expect(first.pending, same(actual));
    expect(first.applied, isNull);
    expect(first.submit(pending: actual, choice: choice).activePromises,
        hasLength(48));
  });

  test('P2-A1b2 uses M56 callback and preserves all 47 AI exact signatures',
      () {
    final boundary = PlayerPresidentPreseasonPromiseBoundary.start(
      application: app(),
      sourceClubs: world.clubs,
      sourceLeagues: world.leagues,
    );
    final pending = boundary.pending!;
    final activeBefore = boundary.applied;
    expect(activeBefore, isNull);
    final applied = boundary.submit(
      pending: pending,
      choice: pending.context.allowedTypes.last,
    );
    expect(applied.acceptedRequestKey, pending.request.key);
    expect(applied.consequence.kind, PlayerPresidentInteractiveDecisionKind.promise);
    expect(applied.consequence.controlledClubId, pending.clubId);
    expect(applied.consequence.context.signature, pending.context.signature);
    expect(applied.consequence.promise.type, pending.context.allowedTypes.last);
    final byId = {
      for (final promise in applied.activePromises) promise.clubId: promise
    };
    for (final context in boundary.contexts) {
      final actual = byId[context.controlledClubId]!;
      expect(actual.id, 'promise_${context.controlledClubId}_s0');
      if (context.controlledClubId != pending.clubId) {
        final expected = const PromiseGenerator().generate(
          context: context.context,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        expect(actual.signature, expected.signature);
      } else {
        expect(actual, same(applied.consequence.promise));
      }
    }
    expect(() => applied.activePromises.clear(), throwsUnsupportedError);
    expect(boundary.pending, isNull);
    expect(boundary.applied, same(applied));
    expect(
      () => boundary.submit(
        pending: pending,
        choice: pending.context.allowedTypes.last,
      ),
      throwsStateError,
    );
    expect(boundary.applied, same(applied));
    expect(boundary.proof.seasonOpening.fixtureSnapshot.completedMatchCount, 0);
    expect(boundary.proof.seasonOpening.fixtureSnapshot.nextRound, 1);
  });
}
