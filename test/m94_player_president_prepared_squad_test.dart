import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_prepared_squad_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/world/world_opening_state_initializer.dart';
import 'package:test/test.dart';

Object _choiceFor(PlayerPresidentInteractiveDecisionRequest request) {
  switch (request.kind) {
    case PlayerPresidentInteractiveDecisionKind.facilityInvestment:
      return PlayerFacilityInvestmentChoice.hold;
    case PlayerPresidentInteractiveDecisionKind.sponsor:
      final context = request.contextAs<PlayerSponsorDecisionContext>();
      return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
    case PlayerPresidentInteractiveDecisionKind.crisis:
      final context = request.contextAs<PlayerCrisisDecisionContext>();
      return PlayerCrisisActionChoice(action: context.aiDecision.action);
    case PlayerPresidentInteractiveDecisionKind.managerReview:
      return PlayerManagerReviewChoice.replace;
    case PlayerPresidentInteractiveDecisionKind.managerReplacement:
      final context = request.contextAs<PlayerManagerReplacementContext>();
      return PlayerManagerReplacementChoice(
        managerId: context.candidates.first.manager.id,
      );
    case PlayerPresidentInteractiveDecisionKind.promise:
      return request.contextAs<PlayerPromiseDecisionContext>().aiPromise.type;
    case PlayerPresidentInteractiveDecisionKind.mediaStatement:
      return request
          .contextAs<PlayerMediaStatementDecisionContext>()
          .aiStatement
          .stance;
    case PlayerPresidentInteractiveDecisionKind.transferStrategy:
      final context =
          request.contextAs<PlayerTransferStrategyDecisionContext>();
      return PlayerTransferStrategyChoice.fromProfile(context.aiProfile);
    case PlayerPresidentInteractiveDecisionKind.ticketPricing:
      return request
          .contextAs<PlayerPresidentTicketPricingDecisionContext>()
          .aiChoice;
  }
}

PlayerPresidentInteractiveSessionCompleted _drive(
  PlayerPresidentInteractiveDecisionApplicationSession session,
) {
  PlayerPresidentInteractiveSessionStep step = session.advance();
  for (var guard = 0; guard < 100; guard++) {
    if (step is PlayerPresidentInteractiveSessionCompleted) return step;
    final pending = step as PlayerPresidentInteractiveDecisionPending;
    step = session.submit(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
  }
  throw StateError('M94 fixture did not complete.');
}

PlayerPresidentPreparedSquadPlayer _player({
  required String id,
  required String name,
  required PlayerPosition position,
  required double ability,
  int age = 24,
  double potential = 80,
  bool academy = false,
}) =>
    PlayerPresidentPreparedSquadPlayer(
      playerId: id,
      name: name,
      position: position,
      age: age,
      ability: ability,
      potential: potential,
      isAcademyGraduate: academy,
    );

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
    crisisActivationThreshold: 0,
    candidateLimit: 5,
  );
  const checkpointCodec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String controlledClubId;
  late PlayerPresidentInteractiveSessionCompleted completed;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    completed = _drive(
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      ),
    );
  });

  PlayerPresidentInteractiveDecisionApplicationSession fresh() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      );

  test('01 fresh new-game prepared squad uses canonical opening players', () {
    final snapshot = fresh().preparedSquad;
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    final expected = opening.players
        .where((player) => player.clubId == controlledClubId)
        .map((player) => player.id)
        .toSet();
    expect(snapshot.controlledClubId, controlledClubId);
    expect(snapshot.seasonIndex, config.seasonIndex);
    expect(snapshot.players.map((player) => player.playerId).toSet(), expected);
  });

  test('02 new-game projection contains exact controlled-club subset', () {
    final snapshot = fresh().preparedSquad;
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    final byId = {for (final player in opening.players) player.id: player};
    expect(snapshot.players, isNotEmpty);
    for (final player in snapshot.players) {
      expect(byId[player.playerId]!.clubId, controlledClubId);
    }
  });

  test('03 deterministic repeat preserves signature', () {
    expect(fresh().preparedSquad.signature, fresh().preparedSquad.signature);
  });

  test('04 position ordering is explicit goalkeeper to forward', () {
    final snapshot = PlayerPresidentPreparedSquadSnapshot(
      controlledClubId: 'club',
      seasonIndex: 0,
      players: [
        _player(
          id: 'f',
          name: 'F',
          position: PlayerPosition.forward,
          ability: 90,
        ),
        _player(
          id: 'g',
          name: 'G',
          position: PlayerPosition.goalkeeper,
          ability: 60,
        ),
        _player(
          id: 'm',
          name: 'M',
          position: PlayerPosition.midfielder,
          ability: 80,
        ),
        _player(
          id: 'd',
          name: 'D',
          position: PlayerPosition.defender,
          ability: 70,
        ),
      ],
    );
    expect(
      snapshot.players.map((player) => player.position).toList(),
      [
        PlayerPosition.goalkeeper,
        PlayerPosition.defender,
        PlayerPosition.midfielder,
        PlayerPosition.forward,
      ],
    );
  });

  test('05 ability is descending inside one position', () {
    final snapshot = PlayerPresidentPreparedSquadSnapshot(
      controlledClubId: 'club',
      seasonIndex: 0,
      players: [
        _player(
          id: 'a',
          name: 'A',
          position: PlayerPosition.defender,
          ability: 60,
        ),
        _player(
          id: 'b',
          name: 'B',
          position: PlayerPosition.defender,
          ability: 80,
        ),
      ],
    );
    expect(snapshot.players.map((player) => player.playerId), ['b', 'a']);
  });

  test('06 name is the second tie-break inside one position', () {
    final snapshot = PlayerPresidentPreparedSquadSnapshot(
      controlledClubId: 'club',
      seasonIndex: 0,
      players: [
        _player(
          id: 'z',
          name: 'Zeki',
          position: PlayerPosition.midfielder,
          ability: 70,
        ),
        _player(
          id: 'a',
          name: 'Ali',
          position: PlayerPosition.midfielder,
          ability: 70,
        ),
      ],
    );
    expect(snapshot.players.map((player) => player.name), ['Ali', 'Zeki']);
  });

  test('07 playerId is the final stable tie-break', () {
    final snapshot = PlayerPresidentPreparedSquadSnapshot(
      controlledClubId: 'club',
      seasonIndex: 0,
      players: [
        _player(
          id: 'b',
          name: 'Aynı',
          position: PlayerPosition.forward,
          ability: 70,
        ),
        _player(
          id: 'a',
          name: 'Aynı',
          position: PlayerPosition.forward,
          ability: 70,
        ),
      ],
    );
    expect(snapshot.players.map((player) => player.playerId), ['a', 'b']);
  });

  test('08 free agents are not part of the checkpoint playing squad', () {
    final checkpoint = completed.result.checkpoint;
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final worldCheckpoint =
        checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime.world;
    final freeAgentIds = worldCheckpoint.nextSeasonPlayers
        .where((player) => player.isFreeAgent)
        .map((player) => player.id)
        .toSet();
    expect(
      session.preparedSquad.players
          .where((player) => freeAgentIds.contains(player.playerId)),
      isEmpty,
    );
  });

  test('09 M80 restore preserves prepared squad parity', () {
    final session = fresh();
    final signature = session.preparedSquad.signature;
    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession
            .restoreEncodedNewGameBootstrap(
      clubs: world.clubs,
      leagues: world.leagues,
      encodedBootstrap: session.encodeNewGameBootstrapSnapshot(),
    );
    expect(restored.preparedSquad.signature, signature);
  });

  test('10 accepted transcript growth does not change prepared squad', () {
    final session = fresh();
    final before = session.preparedSquad;
    final pending = session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(request: pending.request, choice: _choiceFor(pending.request));
    expect(session.preparedSquad, same(before));
  });

  test('11 checkpoint projection is exact nextSeasonPlayers subset', () {
    final checkpoint = completed.result.checkpoint;
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final worldCheckpoint =
        checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime.world;
    final expected = worldCheckpoint.nextSeasonPlayers
        .where((player) => player.clubId == checkpoint.controlledClubId)
        .map((player) => player.id)
        .toSet();
    expect(session.preparedSquad.players.map((player) => player.playerId).toSet(),
        expected);
  });

  test('12 M65 codec round-trip preserves prepared squad parity', () {
    final checkpoint = completed.result.checkpoint;
    final decoded = checkpointCodec.decode(checkpointCodec.encode(checkpoint));
    final a = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final b = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: decoded,
      resumeConfig: resumeConfig,
    );
    expect(b.preparedSquad.signature, a.preparedSquad.signature);
  });

  test('13 M75 restore derives the same squad without persisting it', () {
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: completed.result.checkpoint,
      resumeConfig: resumeConfig,
    );
    final signature = session.preparedSquad.signature;
    final encoded = session.encodePersistenceBundle();
    final restored =
        PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: encoded,
    );
    expect(restored.preparedSquad.signature, signature);
    expect(restored.encodePersistenceBundle(), encoded);
  });

  test('14 advance does not mutate the prepared squad', () {
    final session = fresh();
    final before = session.preparedSquad;
    session.advance();
    expect(session.preparedSquad, same(before));
  });

  test('15 submit does not mutate the prepared squad', () {
    final session = fresh();
    final before = session.preparedSquad;
    final pending = session.advance() as PlayerPresidentInteractiveDecisionPending;
    session.submit(request: pending.request, choice: _choiceFor(pending.request));
    expect(session.preparedSquad, same(before));
  });

  test('16 resolution submission does not mutate the prepared squad', () {
    final session = fresh();
    final before = session.preparedSquad;
    final pending = session.advance() as PlayerPresidentInteractiveDecisionPending;
    final result = session.submitWithResolution(
      request: pending.request,
      choice: _choiceFor(pending.request),
    );
    expect(result.resolution.requestKey, pending.request.key);
    expect(session.preparedSquad, same(before));
  });

  test('17 snapshot defensively copies the provided iterable', () {
    final source = <PlayerPresidentPreparedSquadPlayer>[
      _player(
        id: 'a',
        name: 'A',
        position: PlayerPosition.goalkeeper,
        ability: 60,
      ),
    ];
    final snapshot = PlayerPresidentPreparedSquadSnapshot(
      controlledClubId: 'club',
      seasonIndex: 0,
      players: source,
    );
    source.add(
      _player(
        id: 'b',
        name: 'B',
        position: PlayerPosition.forward,
        ability: 70,
      ),
    );
    expect(snapshot.players, hasLength(1));
  });

  test('18 runtime-only signature is stable and observational', () {
    final snapshot = fresh().preparedSquad;
    expect(snapshot.signature, snapshot.signature);
    expect(snapshot.signature, contains(controlledClubId));
  });

  test('19 next-season handoff creates a fresh checkpoint-origin snapshot', () {
    final session = fresh();
    final opening = session.preparedSquad;
    final completedSession = _drive(session);
    expect(completedSession.result.checkpoint.nextSeasonIndex, 1);
    final next = session.continuePlayerCareerToNextSeason();
    expect(next.preparedSquad, isNot(same(opening)));
    expect(next.preparedSquad.seasonIndex, opening.seasonIndex + 1);
  });

  test('20 active loan membership follows loanClubId/player.clubId', () {
    final checkpoint = completed.result.checkpoint;
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final advanced =
        checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime;
    final ids =
        session.preparedSquad.players.map((player) => player.playerId).toSet();
    expect(advanced.transfer.activeLoans, isNotEmpty);
    for (final loan in advanced.transfer.activeLoans) {
      expect(ids.contains(loan.playerId),
          loan.loanClubId == checkpoint.controlledClubId);
    }
  });

  test('21 active loan parent ownership never overrides playing membership', () {
    final checkpoint = completed.result.checkpoint;
    final session = PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
    );
    final advanced =
        checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime;
    final ids =
        session.preparedSquad.players.map((player) => player.playerId).toSet();
    for (final loan in advanced.transfer.activeLoans) {
      if (loan.parentClubId == checkpoint.controlledClubId) {
        expect(ids.contains(loan.playerId), isFalse);
      }
    }
  });

  test('22 duplicate player IDs fail closed', () {
    final player = _player(
      id: 'same',
      name: 'A',
      position: PlayerPosition.goalkeeper,
      ability: 60,
    );
    expect(
      () => PlayerPresidentPreparedSquadSnapshot(
        controlledClubId: 'club',
        seasonIndex: 0,
        players: [player, player],
      ),
      throwsStateError,
    );
  });

  test('23 missing controlled club fails closed', () {
    expect(
      () => PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: '__missing_club__',
        seasonCount: 1,
      ),
      throwsA(anything),
    );
  });

  test('24 empty prepared roster fails closed', () {
    expect(
      () => PlayerPresidentPreparedSquadSnapshot(
        controlledClubId: 'club',
        seasonIndex: 0,
        players: const [],
      ),
      throwsStateError,
    );
  });

  test('25 repeated getter is identity-stable and side-effect free', () {
    final session = fresh();
    final beforeAnswers = session.answeredDecisionCount;
    final first = session.preparedSquad;
    final second = session.preparedSquad;
    expect(second, same(first));
    expect(session.answeredDecisionCount, beforeAnswers);
  });
}
