import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';

class D0PSeasonProbe extends SeasonEngine {
  D0PSeasonProbe(this.events);
  final List<String> events;
  bool fail = false;
  @override
  SeasonReport simulate(
      {required List<Club> clubs, required SimulationConfig config}) {
    events.add('league');
    if (fail) throw StateError('injected league failure');
    return super.simulate(clubs: clubs, config: config);
  }
}

class D0PEconomyProbe extends BasicEconomyEngine {
  D0PEconomyProbe(this.events);
  final List<String> events;
  final List<ClubFinanceState> initializedRows = [];
  final List<ClubFinanceState> consumedRows = [];
  @override
  List<ClubFinanceState> initialStates(
      {required List<Club> clubs,
      required int careerSeed,
      required int simulationVersion,
      int economicScaleBps = 10000}) {
    final rows = super.initialStates(
        clubs: clubs,
        careerSeed: careerSeed,
        simulationVersion: simulationVersion,
        economicScaleBps: economicScaleBps);
    initializedRows.addAll(rows);
    return rows;
  }

  @override
  List<ClubFinanceSeason> simulateSeason(
      {required List<Club> clubs,
      required List<Player> players,
      required SeasonReport seasonReport,
      required List<ClubFinanceState> openingStates,
      int economicScaleBps = 10000,
      int costScaleBps = 10000,
      Map<String, Money>? annualWagesByClub,
      Map<String, Money>? transferInstallmentIncomeByClub,
      Map<String, Money>? transferInstallmentExpenseByClub,
      Map<String, int> matchdayRevenueMultiplierBpsByClub = const {},
      Map<String, Money>? sponsorRevenueByClub}) {
    events.add('finance');
    consumedRows.addAll(openingStates);
    return super.simulateSeason(
        clubs: clubs,
        players: players,
        seasonReport: seasonReport,
        openingStates: openingStates,
        economicScaleBps: economicScaleBps,
        costScaleBps: costScaleBps,
        annualWagesByClub: annualWagesByClub,
        transferInstallmentIncomeByClub: transferInstallmentIncomeByClub,
        transferInstallmentExpenseByClub: transferInstallmentExpenseByClub,
        matchdayRevenueMultiplierBpsByClub: matchdayRevenueMultiplierBpsByClub,
        sponsorRevenueByClub: sponsorRevenueByClub);
  }
}

class D0PSponsorProbe extends SponsorSystemEngine {
  D0PSponsorProbe(this.events);
  final List<String> events;
  @override
  SponsorSeasonResolution resolveSeason(
      {required int seasonIndex,
      required List<Club> clubs,
      required Map<String, int> leaguePositions,
      required Map<String, PresidentManagementProfile> presidentProfilesByClub,
      required int careerSeed,
      required int simulationVersion,
      Map<String, FanState> fanStatesByClub = const {},
      Map<String, MediaState> mediaStatesByClub = const {},
      Iterable<SponsorContract> existingContracts = const [],
      Money totalRevenuePaid = Money.zero}) {
    events.add('sponsor');
    return super.resolveSeason(
        seasonIndex: seasonIndex,
        clubs: clubs,
        leaguePositions: leaguePositions,
        presidentProfilesByClub: presidentProfilesByClub,
        careerSeed: careerSeed,
        simulationVersion: simulationVersion,
        fanStatesByClub: fanStatesByClub,
        mediaStatesByClub: mediaStatesByClub,
        existingContracts: existingContracts,
        totalRevenuePaid: totalRevenuePaid);
  }
}

class D0PTicketProbe extends PlayerMatchdayTicketPricingDecisionProvider {
  D0PTicketProbe(this.events);
  final List<String> events;
  @override
  MatchdayTicketPricingChoice choose(
      PlayerPresidentTicketPricingDecisionContext context) {
    events.add('ticket');
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
  }

  @override
  void onApplied(PlayerPresidentTicketPricingDecision decision) =>
      events.add('applied');
}

class _Hooks extends NoopWorldCareerHooks {
  _Hooks(this.events);
  final List<String> events;
  bool invalid = false;
  @override
  List<Club> adjustClubsForSeason(
      {required int seasonIndex,
      required List<Club> squadClubs,
      required List<Player> players,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> financeStates}) {
    events.add('adjust');
    return invalid ? [] : squadClubs;
  }
}

class _ManagerImpactProbe extends ManagerImpactModel {
  int calls = 0;
  @override
  double calculate(
      {required Manager manager,
      required double fitScore,
      required double boardRelationship,
      required List<Player> players}) {
    calls++;
    return super.calculate(
        manager: manager,
        fitScore: fitScore,
        boardRelationship: boardRelationship,
        players: players);
  }
}

class _Roster extends NoopWorldRosterHooks {
  _Roster(this.events);
  final List<String> events;
  @override
  Map<String, Money>? annualWagesByClub(
      {required int seasonIndex,
      required List<Player> players,
      required List<Club> clubs,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> financeStates}) {
    events.add('wages');
    return null;
  }
}

class _Flows extends NoopWorldFinanceHooks {
  _Flows(this.events);
  final List<String> events;
  @override
  WorldFinanceSeasonFlows flowsForSeason(
      {required int seasonIndex,
      required List<Club> clubs,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> openingFinanceStates}) {
    events.add('flows');
    return const WorldFinanceSeasonFlows();
  }
}

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 42002);

  test('world pause is after adjust and before wages/flows/league/finance', () {
    final events = <String>[];
    final engine = WorldCareerEngine(
        seasonEngine: D0PSeasonProbe(events),
        economyEngine: D0PEconomyProbe(events));
    final owner = Object(), revision = Object(), provenance = Object();
    final p = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        owner: owner,
        revision: revision,
        provenance: provenance,
        advanceAfterFinalSeason: false,
        hooks: _Hooks(events),
        rosterHooks: _Roster(events),
        financeHooks: _Flows(events));
    expect(events, ['adjust']);
    engine.executePrepared(p,
        expectedOwner: owner,
        expectedRevision: revision,
        expectedProvenance: provenance);
    expect(events, [
      'adjust',
      'wages',
      'flows',
      'league',
      'finance',
      'league',
      'finance',
      'league',
      'finance'
    ]);
  });

  test(
      'genuine advanced initial opening, lazy contracts and original manager capture',
      () {
    final events = <String>[];
    final economy = D0PEconomyProbe(events);
    final impact = _ManagerImpactProbe();
    final engine = AdvancedRuntimeCareerEngine(
        managerImpactModel: impact,
        worldEngine: WorldCareerEngine(
            seasonEngine: D0PSeasonProbe(events), economyEngine: economy));
    final p = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        captureManagerAuthority: true);
    expect(events, isEmpty);
    expect(p.openingContractCount, 0);
    expect(impact.calls, 48); // One adjustment of the 48-club season.
    expect(p.origin, PreparedRuntimeOrigin.initial);
    expect(p.managerAuthority!.effectiveClubs, same(p.opening.effectiveClubs));
    expect(p.managerAuthority!.seasons, isEmpty);
    expect(
        p.managerAuthority!
            .forkDetached(
                expectedOwner: p.owner,
                expectedRevision: p.revision,
                expectedSeason: p.opening.seasonIndex)
            .finalAssignments
            .length,
        48);
    expect(p.opening.financeStates.length, 48);
    for (final row in p.opening.financeStates) {
      expect(economy.initializedRows.any((r) => identical(r, row)), isTrue);
    }
    expect(() => p.opening.financeStates.clear(), throwsUnsupportedError);
    final r = engine.executePrepared(p,
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    expect(r.checkpoint.transfer.activeContracts, isNotEmpty);
    expect(r.checkpoint.manager.seasons.length, 1);
    expect(impact.calls, 48); // Execution adopts that exact adjustment.
    for (final row in economy.consumedRows) {
      expect(p.opening.financeStates.any((r) => identical(r, row)), isTrue);
    }
    expect(p.state, PreparedExecutionState.completed);
    expect(
        () => engine.executePrepared(p,
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
    expect(
        () => p.move(
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
  });

  test('resume adopts exact finance and maintains restored controller lineage',
      () {
    const engine = AdvancedRuntimeCareerEngine();
    final source = engine
        .simulateWithCheckpoint(
            clubs: world.clubs,
            leagues: world.leagues,
            config: config,
            seasonCount: 1)
        .checkpoint;
    final signature = const AdvancedWorldSaveCodec().encode(source);
    final p =
        engine.prepareResume(checkpoint: source, captureManagerAuthority: true);
    expect(p.origin, PreparedRuntimeOrigin.resumed);
    expect(p.opening.seasonIndex, source.nextSeasonIndex);
    expect(p.openingContractCount, source.transfer.activeContracts.length);
    for (var i = 0; i < 48; i++) {
      expect(p.opening.financeStates[i],
          same(source.world.nextSeasonFinanceStates[i]));
    }
    expect(p.managerAuthority!.managers.first,
        same(source.manager.managers.first));
    expect(const AdvancedWorldSaveCodec().encode(source), signature);
    final moved = p.move(
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    expect(moved.managerLineage, same(p.managerLineage));
    expect(moved.transferLineage, same(p.transferLineage));
    expect(moved.executionIdentity, same(p.executionIdentity));
    engine.executePrepared(moved,
        expectedOwner: moved.owner,
        expectedRevision: moved.revision,
        expectedProvenance: moved.provenance);
    expect(const AdvancedWorldSaveCodec().encode(source), signature);
  });

  test(
      'foreign bindings and producer cannot consume; move invalidates old lease',
      () {
    const engine = AdvancedRuntimeCareerEngine();
    final p = engine.prepareInitial(
        clubs: world.clubs, leagues: world.leagues, config: config);
    for (var field = 0; field < 3; field++) {
      expect(
          () => p.move(
              expectedOwner: field == 0 ? Object() : p.owner,
              expectedRevision: field == 1 ? Object() : p.revision,
              expectedProvenance: field == 2 ? Object() : p.provenance),
          throwsStateError);
      expect(p.state, PreparedExecutionState.prepared);
    }
    final foreign = AdvancedRuntimeCareerEngine(
        worldEngine: WorldCareerEngine(seasonEngine: D0PSeasonProbe([])));
    expect(
        () => foreign.executePrepared(p,
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
    expect(p.state, PreparedExecutionState.prepared);
    final moved = p.move(
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    expect(p.state, PreparedExecutionState.moved);
    expect(moved.opening, same(p.opening));
    expect(
        () => p.move(
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
    expect(
        () => engine.executePrepared(p,
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
  });

  test('invalid adjustment publishes nothing and starts no execution', () {
    final events = <String>[];
    final hooks = _Hooks(events)..invalid = true;
    final engine = WorldCareerEngine(seasonEngine: D0PSeasonProbe(events));
    expect(
        () => engine.prepareInitial(
            clubs: world.clubs,
            leagues: world.leagues,
            config: config,
            owner: Object(),
            revision: Object(),
            provenance: Object(),
            hooks: hooks),
        throwsStateError);
    expect(events, ['adjust']);
  });

  test(
      'real full M65 wrapper graph prepares without sponsor/ticket/finance execution',
      () {
    final events = <String>[];
    final provider = D0PTicketProbe(events);
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        sponsorSystem: D0PSponsorProbe(events),
        playerProvider: provider,
        baseWorldEngine: WorldCareerEngine(
            seasonEngine: D0PSeasonProbe(events),
            economyEngine: D0PEconomyProbe(events)));
    final p = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        captureManagerAuthority: true);
    expect(events, isEmpty);
    expect(p.sponsorProcessedClubCount, 0);
    expect(p.sponsorSeasonRevenue, Money.zero);
    expect(p.ticketDecisionCount, 0);
    expect(p.openingContractCount, 0);
    expect(p.managerAuthority!.effectiveClubs, same(p.opening.effectiveClubs));
    final moved = p.move(
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    expect(
        () => engine.executePrepared(p,
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
    engine.executePrepared(moved,
        expectedOwner: moved.owner,
        expectedRevision: moved.revision,
        expectedProvenance: moved.provenance);
    expect(moved.sponsorProcessedClubCount, 48);
    expect(moved.ticketDecisionCount, 48);
    expect(events.where((e) => e == 'sponsor').length, 3);
    expect(events.where((e) => e == 'ticket').length, 1);
    expect(events.where((e) => e == 'finance').length, 3);
    final ticket = events.indexOf('ticket');
    expect(events[ticket + 1], 'applied');
    expect(events[ticket + 2], 'finance');
  });
}
