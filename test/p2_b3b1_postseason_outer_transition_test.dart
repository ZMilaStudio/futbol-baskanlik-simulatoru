import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_runtime_transition.dart';
import 'package:futbol_baskanlik_m0/src/transfer/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/crisis/crisis_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/manager/player_president_manager_control.dart';
import 'package:test/test.dart';
import 'p2_ar_d0p_owned_season_preparation_test.dart'
    show D0PSeasonProbe, D0PEconomyProbe;

class B3B1MediaProbe extends MediaCareerEngine {
  int calls = 0;
  @override
  MediaSeasonSnapshot projectClubSeason({
    required MediaState priorState,
    required ManagerClubSeason clubSeason,
    required int seasonIndex,
    required bool managerChanged,
    required SimulationConfig config,
  }) {
    calls++;
    return super.projectClubSeason(
        priorState: priorState,
        clubSeason: clubSeason,
        seasonIndex: seasonIndex,
        managerChanged: managerChanged,
        config: config);
  }
}

class B3B1ForeignPromiseGenerator extends PromiseGenerator {
  const B3B1ForeignPromiseGenerator();
  @override
  PresidentPromise generate({
    required PresidentPromiseContext context,
    required int careerSeed,
    required int simulationVersion,
  }) =>
      PresidentPromise(
          id: 'foreign',
          clubId: 'foreign-club',
          seasonIndex: context.seasonIndex,
          type: PresidentPromiseType.finishTopHalf,
          targetLeaguePosition: 8);
}

class B3B1CrisisProbe extends CrisisRuntimeIntegrationEngine {
  int calls = 0;
  @override
  CrisisRuntimeEffects projectEffects({
    required int seasonIndex,
    required Iterable<PresidentClubRuntimeState> presidentClubs,
    required Iterable<ClubFinanceState> financeStates,
  }) {
    calls++;
    return super.projectEffects(
        seasonIndex: seasonIndex,
        presidentClubs: presidentClubs,
        financeStates: financeStates);
  }
}

class B3B1InvestmentProbe extends PresidentFacilityInvestmentRuntimeEngine {
  int calls = 0;
  @override
  PresidentFacilityInvestmentEffects projectRuntimeView({
    required FacilityRuntimeCheckpoint facilities,
    required Map<String, PresidentManagementProfile> profiles,
  }) {
    calls++;
    return super.projectRuntimeView(facilities: facilities, profiles: profiles);
  }
}

class B3B1ControlProbe extends PlayerPresidentTenureControlGate {
  int calls = 0;
  @override
  PlayerPresidentTenureControlState refreshRuntimeView({
    required PlayerPresidentTenureControlState state,
    required PresidentClubRuntimeState incumbent,
    required int completedSeasons,
  }) {
    calls++;
    return super.refreshRuntimeView(
        state: state, incumbent: incumbent, completedSeasons: completedSeasons);
  }
}

class B3B1PromiseResolverProbe extends PromiseResolver {
  int calls = 0;
  @override
  PromiseResolution resolve({
    required PresidentPromise promise,
    required PresidentPromiseOutcome outcome,
  }) {
    calls++;
    return super.resolve(promise: promise, outcome: outcome);
  }
}

class B3B1MarketProbe extends TransferMarketEngine {
  B3B1MarketProbe(this.events, {this.fail = false});
  final List<String> events;
  final bool fail;
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
    if (fail) throw StateError('injected owned market failure');
    return super.simulateWindow(
        clubs: clubs,
        players: players,
        financeStates: financeStates,
        careerSeed: careerSeed,
        seasonIndex: seasonIndex,
        simulationVersion: simulationVersion,
        contractYearsRemainingByPlayer: contractYearsRemainingByPlayer,
        enableInstallments: enableInstallments,
        budgetPoliciesByClub: budgetPoliciesByClub,
        activityPoliciesByClub: activityPoliciesByClub,
        negotiationPoliciesByClub: negotiationPoliciesByClub,
        youthPreferencePoliciesByClub: youthPreferencePoliciesByClub);
  }
}

class B3B1LifecycleProbe extends PlayerLifecycleEngine {
  B3B1LifecycleProbe(this.events, {this.fail = false});
  final List<String> events;
  final bool fail;
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
    if (fail) throw StateError('injected owned lifecycle failure');
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

/// Uses the real legacy production prepared graph and annual call. This is
/// neither an AR-D committed capability fixture nor future application proof.
class B3B1LegacyClosing {
  B3B1LegacyClosing(
      {bool future = true,
      PromiseMediaCareerEngine sourceEngine = const PromiseMediaCareerEngine(),
      CrisisRuntimeIntegrationEngine crisis =
          const CrisisRuntimeIntegrationEngine(),
      PresidentFacilityInvestmentRuntimeEngine investment =
          const PresidentFacilityInvestmentRuntimeEngine(),
      PlayerPresidentTenureControlGate tenureGate =
          const PlayerPresidentTenureControlGate(),
      SimulationConfig config = const SimulationConfig(careerSeed: 42002),
      WorldCareerEngine worldEngine = const WorldCareerEngine()}) {
    final world = const FictionalWorldFactory().build();
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        baseWorldEngine: worldEngine,
        sourceEngine: sourceEngine,
        crisisIntegration: crisis,
        investment: investment,
        tenureGate: tenureGate);
    prepared = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: 't1_01',
        captureManagerAuthority: true);
    closing = engine.captureAnnualClosing(prepared,
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance,
        hasNextSeason: future);
  }
  late final PreparedTicketRuntimeSeason prepared;
  late final OwnedAnnualClosingBoundary closing;
  SinglePassPostseasonRuntimeTransition claim() =>
      SinglePassPostseasonRuntimeTransition.fromOwnedAnnualClosing(
          source: closing,
          expectedOwner: closing.owner,
          expectedRevision: closing.revision,
          expectedProvenance: closing.provenance);
}

void main() {
  test('malformed producer promise cannot publish an owned annual boundary',
      () {
    final world = const FictionalWorldFactory().build();
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        sourceEngine: PromiseMediaCareerEngine(
            promiseEngine:
                PromiseCareerEngine(generator: B3B1ForeignPromiseGenerator())));
    final prepared = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 42002),
        controlledClubId: 't1_01',
        captureManagerAuthority: true);
    expect(
        () => engine.captureAnnualClosing(prepared,
            expectedOwner: prepared.owner,
            expectedRevision: prepared.revision,
            expectedProvenance: prepared.provenance,
            hasNextSeason: true),
        throwsStateError);
    expect(
        () => engine.executePrepared(prepared,
            expectedOwner: prepared.owner,
            expectedRevision: prepared.revision,
            expectedProvenance: prepared.provenance),
        throwsStateError);
  });
  test('original prepared policy instances drive each successor kernel once',
      () {
    final media = B3B1MediaProbe();
    final crisis = B3B1CrisisProbe();
    final investment = B3B1InvestmentProbe();
    final control = B3B1ControlProbe();
    final fixture = B3B1LegacyClosing(
        sourceEngine: PromiseMediaCareerEngine(mediaEngine: media),
        crisis: crisis,
        investment: investment,
        tenureGate: control);
    expect([media.calls, crisis.calls, investment.calls, control.calls],
        [0, 0, 0, 0]);
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    transition.submitTransfer(
        expectedPending: pending,
        choice: PlayerTransferStrategyChoice.fromProfile(
            pending.context.aiProfile));
    transition.prepareDomain();
    transition.prepareDomain();
    expect(media.calls, 48);
    transition.prepareOuterSuccessor();
    transition.prepareOuterSuccessor();
    expect([media.calls, crisis.calls, investment.calls, control.calls],
        [48, 1, 1, 1]);
    fixture.closing.validate();
  });

  test('nonzero career opening keeps the exact N to N+1 successor cursor', () {
    final fixture = B3B1LegacyClosing(
        config: const SimulationConfig(careerSeed: 42002, seasonIndex: 7));
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    expect(pending.context.window.decisionSeasonIndex, 8);
    transition.submitTransfer(
        expectedPending: pending,
        choice: PlayerTransferStrategyChoice.fromProfile(
            pending.context.aiProfile));
    transition.prepareDomain();
    transition.prepareOuterSuccessor();
    final review = transition.managerPending!;
    final replacement = review.replacement == null
        ? transition.submitManagerReview(
            expectedPending: review, choice: PlayerManagerReviewChoice.replace)!
        : review;
    transition.submitManagerReplacement(
        expectedPending: replacement,
        selected: replacement.replacement!.candidates.first.manager);
    final graph = transition.moveOwnedAnnualContinuation();
    expect(graph.targetSeasonIndex, 8);
    expect(graph.worldSuccessor.config.seasonIndex, 7);
    expect(graph.worldSuccessor.completedSeasons, 1);
    expect(graph.managerEvidence.completedSeasons.single.seasonIndex, 7);
    fixture.closing.validate();
  });
  test(
      'actual market failure is terminal and cannot replay the accepted suffix',
      () {
    final events = <String>[];
    final fixture = B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(
            transferMarketEngine: B3B1MarketProbe(events, fail: true)));
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    final choice =
        PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
    expect(
        () =>
            transition.submitTransfer(expectedPending: pending, choice: choice),
        throwsStateError);
    expect(transition.phase, PostseasonRuntimeTransitionPhase.failed);
    expect(events, ['market']);
    expect(
        () =>
            transition.submitTransfer(expectedPending: pending, choice: choice),
        throwsStateError);
    expect(events, ['market']);
    fixture.closing.validate();
  });
  test('real lost-control resume creates no player transfer or manager Pending',
      () {
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    const gate = PlayerPresidentTenureControlGate();
    final world = const FictionalWorldFactory().build();
    final before = engine
        .simulateWithCheckpoint(
            clubs: world.clubs,
            leagues: world.leagues,
            config: const SimulationConfig(careerSeed: 20260903),
            controlledClubId: 't1_01',
            seasonCount: 3,
            hasFutureSeasonAfterReport: true)
        .checkpoint;
    final after = engine
        .resume(
            checkpoint: before,
            seasonCount: 1,
            hasFutureSeasonAfterReport: true)
        .checkpoint;
    final beforeDomain = before.runtime.runtime.domain.presidentRuntime;
    final afterDomain = after.runtime.runtime.domain.presidentRuntime;
    final club = beforeDomain.clubs
        .firstWhere((previous) =>
            afterDomain.clubs
                .singleWhere((c) => c.clubId == previous.clubId)
                .tenure
                .president
                .id !=
            previous.tenure.president.id)
        .clubId;
    // Capture and refresh actual incumbent identities from production outputs.
    // No fabricated president checkpoint/history or arbitrary lost identity.
    final control = gate.refresh(
        state: gate.capture(
            presidentRuntime: beforeDomain, controlledClubId: club),
        presidentRuntime: afterDomain);
    expect(control.lost, isTrue);
    final prepared = engine.prepareResume(
        checkpoint: PlayerPresidentTicketPricingRuntimeCheckpoint(
            runtime: after.runtime, tenureControl: control),
        captureManagerAuthority: true);
    final source = engine.captureAnnualClosing(prepared,
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance,
        hasNextSeason: true);
    final transition =
        SinglePassPostseasonRuntimeTransition.fromOwnedAnnualClosing(
            source: source,
            expectedOwner: source.owner,
            expectedRevision: source.revision,
            expectedProvenance: source.provenance);
    expect(transition.prepareTransfer(), isNull);
    expect(transition.phase,
        PostseasonRuntimeTransitionPhase.transferFollowupComplete);
    expect(transition.acceptedAnswers, isEmpty);
    transition.prepareDomain();
    transition.prepareOuterSuccessor();
    expect(transition.managerPending, isNull);
    expect(
        transition.phase, PostseasonRuntimeTransitionPhase.continuationReady);
    final graph = transition.moveOwnedAnnualContinuation();
    expect(graph.control.lost, isTrue);
    expect(graph.control, same(control));
    expect(graph.acceptedAnswers, isEmpty);
    source.validate();
  });
  test('owned domain uses the original resolver exactly once per promise', () {
    final resolver = B3B1PromiseResolverProbe();
    final fixture = B3B1LegacyClosing(
        sourceEngine: PromiseMediaCareerEngine(
            promiseEngine: PromiseCareerEngine(resolver: resolver)));
    expect(resolver.calls, 0);
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    transition.submitTransfer(
        expectedPending: pending,
        choice: PlayerTransferStrategyChoice.fromProfile(
            pending.context.aiProfile));
    transition.prepareDomain();
    expect(resolver.calls, 48);
    transition.prepareDomain();
    expect(resolver.calls, 48);
    fixture.closing.validate();
  });
  test(
      'single-pass prefix, Pending and suffix never replay annual/lifecycle work',
      () {
    final events = <String>[];
    final fixture = B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(
            seasonEngine: D0PSeasonProbe(events),
            economyEngine: D0PEconomyProbe(events),
            transferMarketEngine: B3B1MarketProbe(events),
            lifecycleEngine: B3B1LifecycleProbe(events)));
    expect(events.where((e) => e == 'league').length, 3);
    expect(events.where((e) => e == 'finance').length, 3);
    expect(events.where((e) => e == 'lifecycle'), isEmpty);
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    expect(events.where((e) => e == 'lifecycle').length, 1);
    final before = List.of(events);
    expect(transition.prepareTransfer(), same(pending));
    expect(events, before);
    final choice =
        PlayerTransferStrategyChoice.fromProfile(pending.context.aiProfile);
    transition.submitTransfer(expectedPending: pending, choice: choice);
    final after = List.of(events);
    transition.submitTransfer(expectedPending: pending, choice: choice);
    expect(events, after);
    expect(events.where((e) => e == 'league').length, 3);
    expect(events.where((e) => e == 'finance').length, 3);
    expect(events.where((e) => e == 'lifecycle').length, 1);
    expect(events.where((e) => e == 'market').length, 1);
    expect(transition.acceptedAnswers.length, 1);
  });

  test('foreign admission is recoverable; actual lifecycle failure is terminal',
      () {
    final events = <String>[];
    final fixture = B3B1LegacyClosing(
        worldEngine: WorldCareerEngine(
            lifecycleEngine: B3B1LifecycleProbe(events, fail: true)));
    final source = fixture.closing;
    expect(
        () => SinglePassPostseasonRuntimeTransition.fromOwnedAnnualClosing(
            source: source,
            expectedOwner: Object(),
            expectedRevision: source.revision,
            expectedProvenance: source.provenance),
        throwsStateError);
    final transition = fixture.claim();
    final before =
        source.advanced.world.finances.map((f) => f.signature).toList();
    expect(() => transition.prepareTransfer(), throwsStateError);
    expect(transition.phase, PostseasonRuntimeTransitionPhase.failed);
    expect(() => transition.prepareTransfer(), throwsStateError);
    expect(events, ['lifecycle']);
    expect(source.advanced.world.finances.map((f) => f.signature).toList(),
        before);
    expect(source.advanced.managerOpening.seasons, isEmpty);
    source.validate();
  });
  test('production annual boundary owns real results before manager/offseason',
      () {
    final fixture = B3B1LegacyClosing();
    final source = fixture.closing;
    source.validate();
    expect(source.advanced.world.reports.length, 3);
    expect(
        source.advanced.world.reports.expand((r) => r.report.fixtures).length,
        720);
    expect(source.advanced.managerOpening.seasons, isEmpty);
    expect(source.acceptedPromises.length, 48);
    expect(source.promiseContexts.length, 48);
    expect(fixture.prepared.ticketDecisionCount, 48);
    expect(fixture.prepared.sponsorProcessedClubCount, 48);
    final originalRows = source.advanced.world.finances;
    expect(originalRows.length, 48);
    final transition = fixture.claim();
    final pending = transition.prepareTransfer()!;
    expect(transition.prepareTransfer(), same(pending));
    expect(pending.owner, same(source.owner));
    expect(source.advanced.managerOpening.seasons, isEmpty);
    transition.submitTransfer(
        expectedPending: pending,
        choice: PlayerTransferStrategyChoice.fromProfile(
            pending.context.aiProfile));
    transition.prepareDomain();
    expect(transition.domainSuccessor!.clubs.length, 48);
    expect(source.advanced.world.finances, same(originalRows));
    source.validate();
    expect(() => fixture.claim(), throwsStateError);
    expect(
        () => const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine()
            .executePrepared(fixture.prepared,
                expectedOwner: source.owner,
                expectedRevision: source.revision,
                expectedProvenance: source.provenance),
        throwsStateError);
  });

  test('terminal owned annual source completes manager without future market',
      () {
    final fixture = B3B1LegacyClosing(future: false);
    final transition = fixture.claim();
    expect(transition.prepareTransfer(), isNull);
    expect(transition.phase, PostseasonRuntimeTransitionPhase.managerCompleted);
    expect(fixture.closing.advanced.managerOpening.seasons, isEmpty);
    fixture.closing.validate();
  });
}
