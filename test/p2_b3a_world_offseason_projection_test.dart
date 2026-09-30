import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/facility/training_ground_facility.dart';
import 'package:futbol_baskanlik_m0/src/world/world_offseason_projection.dart';
import 'package:test/test.dart';
import 'p2_b3a_finance_equivalence_test.dart' show B3AFixture;

class _Lifecycle extends PlayerLifecycleEngine {
  _Lifecycle(this.events);
  final List<String> events;
  @override
  PlayerLifecycleResult advance({
    required List<Player> currentPlayers,
    required List<Club> currentClubs,
    required List<Club> referenceClubs,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
    Map<String, AcademyFacilityState> academyFacilities = const {},
    Map<String, TrainingGroundFacilityState> trainingGroundFacilities =
        const {},
  }) {
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

class _Strength extends TeamStrengthCalculator {
  _Strength(this.events);
  final List<String> events;
  @override
  List<Club> deriveClubs(
      {required List<Club> baseClubs, required List<Player> players}) {
    events.add('strength');
    return super.deriveClubs(baseClubs: baseClubs, players: players);
  }
}

class _Market extends TransferMarketEngine {
  _Market(this.events);
  final List<String> events;
  @override
  TransferMarketResult simulateWindow({
    required List<Club> clubs,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required int careerSeed,
    required int seasonIndex,
    required int simulationVersion,
    Map<String, int>? contractYearsRemainingByPlayer,
    bool enableInstallments = false,
    Map<String, TransferBudgetPolicy>? budgetPoliciesByClub,
    Map<String, TransferActivityPolicy>? activityPoliciesByClub,
    Map<String, TransferNegotiationPolicy>? negotiationPoliciesByClub,
    Map<String, TransferYouthPreferencePolicy>? youthPreferencePoliciesByClub,
  }) {
    events.add('market');
    expect(contractYearsRemainingByPlayer, {'probe': 2});
    return super.simulateWindow(
        clubs: clubs,
        players: players,
        financeStates: financeStates,
        careerSeed: careerSeed,
        seasonIndex: seasonIndex,
        simulationVersion: simulationVersion,
        contractYearsRemainingByPlayer: contractYearsRemainingByPlayer,
        enableInstallments: enableInstallments);
  }
}

class _Roster extends NoopWorldRosterHooks {
  _Roster(this.events, {this.fail = false});
  final List<String> events;
  final bool fail;
  List<Player>? prepared;
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
    events.add('roster prepare');
    if (fail) throw StateError('detached roster failure');
    return prepared = List.unmodifiable(activePlayers);
  }

  @override
  Map<String, int>? contractYearsRemainingForTransfer(
      {required int nextSeasonIndex, required List<Player> players}) {
    events.add('contract years');
    expect(players, same(prepared));
    return {'probe': 2};
  }

  @override
  void onTransferWindowCompleted(
      {required int seasonIndex,
      required int nextSeasonIndex,
      required List<Player> playersBeforeWindow,
      required List<Player> playersAfterWindow,
      required List<TransferDeal> transfers,
      required List<Club> clubs,
      required List<WorldLeague> leaguesForNextSeason,
      required List<ClubFinanceState> financeStates}) {
    events.add('roster callback');
    expect(playersBeforeWindow, same(prepared));
  }
}

class _Transfer extends NoopWorldTransferHooks {
  _Transfer(this.events);
  final List<String> events;
  @override
  WorldTransferPostProcessResult afterPermanentTransfers(
      {required int seasonIndex,
      required int nextSeasonIndex,
      required List<Player> players,
      required List<ClubFinanceState> financeStates,
      required List<TransferDeal> permanentTransfers,
      required List<Club> clubs,
      required List<WorldLeague> leaguesForNextSeason}) {
    events.add('post-transfer');
    return super.afterPermanentTransfers(
        seasonIndex: seasonIndex,
        nextSeasonIndex: nextSeasonIndex,
        players: players,
        financeStates: financeStates,
        permanentTransfers: permanentTransfers,
        clubs: clubs,
        leaguesForNextSeason: leaguesForNextSeason);
  }
}

class _Career extends NoopWorldCareerHooks {
  _Career(this.events);
  final List<String> events;
  @override
  void onSeasonCompleted(
          {required int seasonIndex,
          required bool hasNextSeason,
          required List<Club> squadClubs,
          required List<Club> effectiveClubs,
          required List<Player> players,
          required List<WorldLeague> leaguesBeforeSeason,
          required List<WorldLeague> leaguesForNextSeason,
          required List<LeagueSeasonSnapshot> leagueResults,
          required List<ClubFinanceSeason> finances}) =>
      events.add('season completed');
}

void main() {
  late B3AFixture fixture;
  late B3AFixture terminalFixture;
  setUpAll(() {
    fixture = B3AFixture();
    terminalFixture = B3AFixture(future: false);
  });
  WorldOffseasonProjectionResult project(List<String> events,
      {bool future = true, bool fail = false}) {
    final source = future ? fixture : terminalFixture;
    final opening = source.w30.boundary.opening;
    return WorldOffseasonProjection(
            lifecycleEngine: _Lifecycle(events),
            strengthCalculator: _Strength(events),
            transferMarketEngine: _Market(events))
        .project(
      hasNextSeason: future,
      seasonIndex: 0,
      config: source.w30.boundary.proof.seasonOpening.config,
      players: opening.players,
      baseClubs: opening.baseClubs,
      squadClubs: source.w30.effectiveClubs,
      closingFinanceStates: source.b2.closingFinanceStates,
      nextLeagues: source.b2.candidateNextLeagues,
      rosterHooks: _Roster(events, fail: fail),
      transferHooks: _Transfer(events),
      enableTransferInstallments: true,
    );
  }

  test('future seam uses real engines in frozen lifecycle-to-immutable order',
      () {
    final before = fixture.signatures;
    final events = <String>[];
    final result = project(events);
    expect(events, [
      'lifecycle',
      'roster prepare',
      'strength',
      'contract years',
      'market',
      'roster callback',
      'post-transfer'
    ]);
    expect(result.players, isNotEmpty);
    expect(result.financeStates.length, 48);
    expect(result.nextLeagues, fixture.b2.candidateNextLeagues);
    expect(result.nextLeagues.expand((l) => l.clubIds).toSet().length, 48);
    expect(fixture.b2.movements.length, 12);
    expect(() => result.nextLeagues.clear(), throwsUnsupportedError);
    expect(() => result.players.clear(), throwsUnsupportedError);
    expect(() => result.financeStates.clear(), throwsUnsupportedError);
    expect(() => result.retired.clear(), throwsUnsupportedError);
    expect(() => result.youthIntake.clear(), throwsUnsupportedError);
    expect(() => result.transfers.clear(), throwsUnsupportedError);
    expect(() => result.cashMovements.clear(), throwsUnsupportedError);
    final repeated = project(<String>[]);
    expect(repeated.players.map((p) => p.signature),
        result.players.map((p) => p.signature));
    expect(repeated.financeStates.map((f) => f.signature),
        result.financeStates.map((f) => f.signature));
    fixture.expectUnchanged(before);
  });
  test(
      'terminal seam calls no engine/controller and preserves exact closing objects',
      () {
    final before = terminalFixture.signatures;
    final events = <String>[];
    final result = project(events, future: false);
    expect(events, isEmpty);
    final players = terminalFixture.w30.boundary.opening.players;
    for (var i = 0; i < players.length; i++) {
      expect(result.players[i], same(players[i]));
    }
    for (var i = 0; i < 48; i++) {
      expect(result.financeStates[i],
          same(terminalFixture.b2.closingFinanceStates[i]));
    }
    expect(result.retired, isEmpty);
    expect(result.youthIntake, isEmpty);
    expect(result.transfers, isEmpty);
    expect(result.cashMovements, isEmpty);
    expect(() => result.players.clear(), throwsUnsupportedError);
    expect(() => result.financeStates.clear(), throwsUnsupportedError);
    expect(result.nextLeagues, terminalFixture.b2.candidateNextLeagues);
    terminalFixture.expectUnchanged(before);
  });
  test('detached failure does not publish or mutate authoritative B2/world',
      () {
    final before = fixture.signatures;
    final events = <String>[];
    expect(() => project(events, fail: true), throwsStateError);
    expect(events, ['lifecycle', 'roster prepare']);
    fixture.expectUnchanged(before);
  });
  test(
      'WorldCareerEngine integration keeps season hook before seam, report vs checkpoint policy',
      () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20260903);
    final events = <String>[];
    final engine = WorldCareerEngine(
        lifecycleEngine: _Lifecycle(events),
        strengthCalculator: _Strength(events),
        transferMarketEngine: _Market(events));
    final terminal = engine.simulate(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        seasonCount: 1,
        hooks: _Career(events),
        rosterHooks: _Roster(events),
        transferHooks: _Transfer(events));
    expect(events.where((e) => e != 'strength'), ['season completed']);
    expect(terminal.seasons.single.transfersAfterSeason, isEmpty);
    events.clear();
    final continuation = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        seasonCount: 1,
        hooks: _Career(events),
        rosterHooks: _Roster(events),
        transferHooks: _Transfer(events));
    final hookIndex = events.indexOf('season completed');
    expect(events.sublist(hookIndex), [
      'season completed',
      'lifecycle',
      'roster prepare',
      'strength',
      'contract years',
      'market',
      'roster callback',
      'post-transfer',
      // Existing final report strength calculation remains outside the seam.
      'strength'
    ]);
    expect(continuation.checkpoint.completedSeasons, 1);
    expect(continuation.checkpoint.nextSeasonPlayers.map((p) => p.signature),
        isNot(terminal.finalPlayers.map((p) => p.signature)));
  });
  test(
      'future detached X1 controller changes only its own contracts and post-window state',
      () {
    final before = fixture.signatures;
    final opening = fixture.w30.boundary.opening;
    final x1 = fixture.w30.boundary.proof.initialContracts;
    final detached = AdvancedTransferController.restore(
      careerSeed: x1.careerSeed,
      simulationVersion: x1.simulationVersion,
      initialSeasonIndex: x1.seasonIndex,
      activeContracts: x1.activeContracts,
      contractEvents: x1.initialEvents,
      activeLoans: const [],
      loanHistory: const [],
      installmentObligations: const [],
    );
    final result = const WorldOffseasonProjection().project(
      hasNextSeason: fixture.b2.hasNextSeason,
      seasonIndex: fixture.b2.seasonIndex,
      config: fixture.w30.boundary.proof.seasonOpening.config,
      players: opening.players,
      baseClubs: opening.baseClubs,
      squadClubs: fixture.w30.effectiveClubs,
      closingFinanceStates: fixture.b2.closingFinanceStates,
      nextLeagues: fixture.b2.candidateNextLeagues,
      rosterHooks: detached,
      transferHooks: detached,
      enableTransferInstallments: true,
    );
    expect(
        detached.contractEvents.length, greaterThan(x1.initialEvents.length));
    expect(result.players, isNotEmpty);
    expect(result.financeStates.length, 48);
    expect(result.nextLeagues, fixture.b2.candidateNextLeagues);
    expect(x1.activeContracts.length, 864);
    expect(x1.initialEvents.length, 864);
    fixture.expectUnchanged(before);
  });
}
