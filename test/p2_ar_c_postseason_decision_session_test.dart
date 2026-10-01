import 'dart:io';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/transfer/president_transfer_strategy_world_bridge.dart';
import 'package:futbol_baskanlik_m0/src/facility/training_ground_facility.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_decision_session.dart';
import 'package:test/test.dart';

/// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER.
class PostseasonFixture {
  PostseasonFixture({bool future = true, bool contract = true}) {
    final world = const FictionalWorldFactory().build();
    context = PlayerTransferStrategyDecisionContext(
      window: PresidentTransferStrategyWindowContext(
          clubs: world.clubs,
          players: const [],
          financeStates: const [],
          careerSeed: 1,
          seasonIndex: 0,
          simulationVersion: 1),
      controlledClubId: world.clubs.first.id,
      aiProfile: const PresidentManagementProfile(
          presidentId: 'p',
          archetype: PresidentManagementArchetype.balanced,
          financialDiscipline: 50,
          riskAppetite: 50,
          transferAmbition: 50,
          youthOrientation: 50,
          managerPatience: 50),
    );
    source = PostseasonSourceRequirements(
        owner: Object(),
        revision: Object(),
        provenance: Object(),
        transaction: Object(),
        completedSeason: 0,
        hasNextSeason: future,
        clubId: context.controlledClubId,
        transferContext: contract ? context : null);
    session = PostseasonDecisionSession.forContractFixture(source);
  }
  late final PlayerTransferStrategyDecisionContext context;
  late final PostseasonSourceRequirements source;
  late final PostseasonDecisionSession session;
  static const choice = PlayerTransferStrategyChoice(
      financialDiscipline: 60,
      riskAppetite: 70,
      transferAmbition: 80,
      youthOrientation: 90);
  PostseasonPending get pending => session.requestTransfer(context)!;
  void answer(Object choice,
      {PostseasonDecisionRequest<Object>? request,
      Object? owner,
      Object? revision,
      Object? provenance,
      Object? transaction}) {
    session.answer(
        request: request ?? pending.request,
        choice: choice,
        owner: owner ?? source.owner,
        revision: revision ?? source.revision,
        provenance: provenance ?? source.provenance,
        transaction: transaction ?? source.transaction);
  }
}

class _Profiles extends PresidentTransferStrategyProfileProvider {
  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
          PresidentTransferStrategyWindowContext context) =>
      {
        for (final club in context.clubs)
          club.id: const PresidentManagementProfile(
              presidentId: 'p',
              archetype: PresidentManagementArchetype.balanced,
              financialDiscipline: 50,
              riskAppetite: 50,
              transferAmbition: 50,
              youthOrientation: 50,
              managerPatience: 50)
      };
}

class _MarketProbe extends PlayerTransferStrategyDecisionProvider {
  _MarketProbe(this.events);
  final List<String> events;
  PostseasonDecisionSession? session;
  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
      PlayerTransferStrategyDecisionContext context) {
    events.add('market context');
    // TEST FIXTURE / NOT AUTHORITATIVE PRODUCER. Context comes from actual M55
    // callback, after world orchestration has reached the real market seam.
    session = PostseasonDecisionSession.forContractFixture(
        PostseasonSourceRequirements(
            owner: Object(),
            revision: Object(),
            provenance: context.window,
            transaction: Object(),
            completedSeason: context.seasonIndex,
            hasNextSeason: true,
            clubId: context.controlledClubId,
            transferContext: context));
    return session!.transferAdapter.chooseTransferStrategy(context);
  }
}

class _LifecycleProbe extends PlayerLifecycleEngine {
  _LifecycleProbe(this.events);
  final List<String> events;
  @override
  PlayerLifecycleResult advance(
      {required List<Player> currentPlayers,
      required List<Club> currentClubs,
      required List<Club> referenceClubs,
      required int careerSeed,
      required int nextSeasonIndex,
      required int simulationVersion,
      Map<String, AcademyFacilityState> academyFacilities = const {},
      Map<String, TrainingGroundFacilityState> trainingGroundFacilities =
          const {}}) {
    events.add('lifecycle');
    return super.advance(
        currentPlayers: currentPlayers,
        currentClubs: currentClubs,
        referenceClubs: referenceClubs,
        careerSeed: careerSeed,
        nextSeasonIndex: nextSeasonIndex,
        simulationVersion: simulationVersion,
        academyFacilities: academyFacilities,
        trainingGroundFacilities: trainingGroundFacilities);
  }
}

class _StrengthProbe extends TeamStrengthCalculator {
  _StrengthProbe(this.events);
  final List<String> events;
  @override
  List<Club> deriveClubs(
      {required List<Club> baseClubs, required List<Player> players}) {
    events.add('strength');
    return super.deriveClubs(baseClubs: baseClubs, players: players);
  }
}

class _RosterProbe extends NoopWorldRosterHooks {
  _RosterProbe(this.events);
  final List<String> events;
  @override
  List<Player> prepareNextSeasonPlayers(
      {required int seasonIndex,
      required int nextSeasonIndex,
      required List<Player> activePlayers,
      required List<Player> retiredPlayers,
      required List<Player> youthIntake,
      required List<Club> clubs,
      required List<WorldLeague> leaguesForNextSeason,
      required List<ClubFinanceState> financeStates}) {
    events.add('roster');
    return super.prepareNextSeasonPlayers(
        seasonIndex: seasonIndex,
        nextSeasonIndex: nextSeasonIndex,
        activePlayers: activePlayers,
        retiredPlayers: retiredPlayers,
        youthIntake: youthIntake,
        clubs: clubs,
        leaguesForNextSeason: leaguesForNextSeason,
        financeStates: financeStates);
  }

  @override
  Map<String, int>? contractYearsRemainingForTransfer(
      {required int nextSeasonIndex, required List<Player> players}) {
    events.add('contract years');
    return super.contractYearsRemainingForTransfer(
        nextSeasonIndex: nextSeasonIndex, players: players);
  }
}

void main() {
  test('typed stable Pending; provider never falls back to AI', () {
    final f = PostseasonFixture();
    expect(f.session.status, PostseasonDecisionStatus.awaitingContext);
    expect(f.session.pending, isNull);
    final pending = f.pending;
    expect(pending,
        isA<PostseasonPending<PlayerTransferStrategyDecisionContext>>());
    expect(pending.request.context, same(f.context));
    expect(pending.request.phase, PostseasonDecisionPhase.transferStrategy);
    expect(f.session.requestTransfer(f.context), same(pending));
    for (var n = 0; n < 3; n++) {
      expect(() => f.session.transferAdapter.chooseTransferStrategy(f.context),
          throwsA(same(pending)));
    }
    expect(f.session.answers, isEmpty);
    expect(f.session.isAuthoritative, isFalse);
  });

  for (final field in ['owner', 'revision', 'provenance', 'transaction']) {
    test('foreign $field rejects without changing exact Pending/transcript',
        () {
      final f = PostseasonFixture();
      final p = f.pending;
      expect(
          () => f.answer(PostseasonFixture.choice,
              owner: field == 'owner' ? Object() : null,
              revision: field == 'revision' ? Object() : null,
              provenance: field == 'provenance' ? Object() : null,
              transaction: field == 'transaction' ? Object() : null),
          throwsStateError);
      expect(f.session.pending, same(p));
      expect(f.session.answers, isEmpty);
      expect(f.session.phase, PostseasonDecisionPhase.transferStrategy);
    });
  }

  test('value-equal foreign request is not session authority', () {
    final f = PostseasonFixture();
    final other = PostseasonDecisionSession.forContractFixture(f.source);
    final p = other.requestTransfer(f.context)!;
    expect(() => f.answer(PostseasonFixture.choice, request: p.request),
        throwsStateError);
    expect(f.session.answers, isEmpty);
  });

  test('wrong choice type and invalid traits leave state intact', () {
    final f = PostseasonFixture();
    final p = f.pending;
    expect(() => f.answer('AI'), throwsArgumentError);
    expect(
        () => f.answer(const PlayerTransferStrategyChoice(
            financialDiscipline: 19,
            riskAppetite: 50,
            transferAmbition: 50,
            youthOrientation: 50)),
        throwsArgumentError);
    expect(f.session.pending, same(p));
    expect(f.session.answers, isEmpty);
  });

  test(
      'accepted answers immutable; duplicate same idempotent; different rejected',
      () {
    final f = PostseasonFixture();
    final p = f.pending;
    f.answer(PostseasonFixture.choice);
    final transcript = f.session.answers;
    f.answer(PlayerTransferStrategyChoice.fromProfile(
        PostseasonFixture.choice.applyTo(f.context.aiProfile)));
    expect(f.session.answers, hasLength(1));
    expect(f.session.answers.single, same(transcript.single));
    expect(() => transcript.clear(), throwsUnsupportedError);
    expect(
        () => f.answer(
            PlayerTransferStrategyChoice.fromProfile(f.context.aiProfile)),
        throwsStateError);
    expect(f.session.pending, same(p));
    f.session.completePhase(p.request);
    expect(f.session.phase, PostseasonDecisionPhase.awaitingOffseason);
    expect(() => f.answer(PostseasonFixture.choice, request: p.request),
        throwsStateError);
    expect(() => f.session.completePhase(p.request), throwsStateError);
    expect(() => f.session.requestTransfer(f.context), throwsStateError);
  });

  test('M55 callback records actual profile exactly once without market replay',
      () {
    final f = PostseasonFixture();
    f.answer(PostseasonFixture.choice);
    final adapter = f.session.transferAdapter;
    final answer = adapter.chooseTransferStrategy(f.context);
    final actual = answer.applyTo(f.context.aiProfile);
    expect(() => adapter.onApplied(f.context, answer, f.context.aiProfile),
        throwsStateError);
    expect(f.session.phase, PostseasonDecisionPhase.transferStrategy);
    adapter.onApplied(f.context, answer, actual);
    expect(f.session.answers.single.consequence, same(actual));
    expect(f.session.phase, PostseasonDecisionPhase.awaitingOffseason);
    expect(
        () => adapter.onApplied(f.context, answer, actual), throwsStateError);
  });

  test('missing contract distinct from Pending and terminal notRequired', () {
    final missing = PostseasonFixture(contract: false);
    expect(missing.session.requestTransfer(missing.context), isNull);
    expect(missing.session.status,
        PostseasonDecisionStatus.decisionContractUnavailable);
    expect(
        () => missing.session.transferAdapter
            .chooseTransferStrategy(missing.context),
        throwsA(isA<PostseasonContractUnavailable>()));
    final terminal = PostseasonFixture(future: false);
    expect(terminal.session.requestTransfer(terminal.context), isNull);
    expect(terminal.session.phase, PostseasonDecisionPhase.terminal);
    expect(terminal.session.status, PostseasonDecisionStatus.notRequired);
    expect(terminal.session.answers, isEmpty);
    expect(
        () => terminal.session.transferAdapter
            .chooseTransferStrategy(terminal.context),
        throwsA(isA<PostseasonDecisionNotRequired>()));
  });

  test(
      'foreign market context rejected; initial preparation cannot precede transfer',
      () {
    final f = PostseasonFixture();
    final foreign = PlayerTransferStrategyDecisionContext(
        window: f.context.window,
        controlledClubId: f.context.controlledClubId,
        aiProfile: f.context.aiProfile);
    expect(() => f.session.requestTransfer(foreign), throwsStateError);
    expect(f.session.pending, isNull);
  });

  test(
      'AR-C has no replay, simulation, checkpoint patch or application dependency',
      () {
    final source = File(
            'lib/src/player_president/player_president_postseason_decision_session.dart')
        .readAsStringSync();
    for (final forbidden in [
      '_replay(',
      'simulateSeason(',
      'simulateWindow(',
      'simulateWithCheckpoint(',
      '_patchManagerState(',
      'PlayerPresidentInteractiveDecisionSession(',
      'player_president_interactive_decision_session.dart',
      'interactive_decision_application_session.dart'
    ]) {
      expect(source.contains(forbidden), isFalse, reason: forbidden);
    }
    // Behavioral repeated Pending/answer tests above exercise only captured DTOs;
    // no engine, application publisher, or M73 instance is accepted by this API.
  });

  test(
      'actual M54/M55 seam requests only after lifecycle/roster/strength/contract update',
      () {
    final events = <String>[];
    final provider = _MarketProbe(events);
    final world = const FictionalWorldFactory().build();
    final engine = const PlayerPresidentTransferStrategyWorldBridge().wrap(
        base: WorldCareerEngine(
            lifecycleEngine: _LifecycleProbe(events),
            strengthCalculator: _StrengthProbe(events)),
        aiProfileProvider: _Profiles(),
        controlledClubId: world.clubs.first.id,
        decisionProvider: provider);
    expect(
        () => engine.simulate(
            clubs: world.clubs,
            leagues: world.leagues,
            config: const SimulationConfig(careerSeed: 1),
            seasonCount: 2,
            rosterHooks: _RosterProbe(events)),
        throwsA(
            isA<PostseasonPending<PlayerTransferStrategyDecisionContext>>()));
    expect(events.sublist(events.length - 5), [
      'lifecycle',
      'roster',
      'strength',
      'contract years',
      'market context'
    ]);
    expect(events.where((e) => e == 'market context'), hasLength(1));
    expect(provider.session!.answers, isEmpty);
    expect(provider.session!.pending!.request.context,
        isA<PlayerTransferStrategyDecisionContext>());
    expect(provider.session!.isAuthoritative, isFalse);
    // No restarted world: no second lifecycle/market or accepted AI choice.
    expect(events.where((e) => e == 'lifecycle'), hasLength(1));
  });
}
